import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import 'package:example/src/sections/find_in_page/find_spike.dart';

/// Pumps [LayrzFindSpike] into the minimal themed, sized tree it needs: a
/// [LayrzTheme] ancestor (every child widget reads `context.tokens`), a real
/// [Navigator] (so a root [Overlay] exists for [LayrzFindSpike] to insert its
/// highlight [OverlayEntry] into — see `_ensureHighlightOverlayInserted`'s doc
/// in `find_spike.dart`), sized to a real viewport (the spike's own [Stack]
/// fills whatever box it's given, and its content — 20 rows, a rich text, an
/// editable field, a custom-painted label, and a 40-item virtualized list —
/// needs real space to lay out at all).
///
/// Pumps twice after the initial [WidgetTester.pumpWidget]: the first extra
/// pump lets [LayrzFindSpike]'s [State.initState] post-frame callback run
/// (which is what actually inserts the highlight [OverlayEntry] — see that
/// callback's doc for why insertion can't happen synchronously in
/// `initState`); tests that need a further frame for a debounce or a
/// highlight resolution still pump additionally themselves, as before.
Future<void> _pumpFindSpike(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [DefaultWidgetsLocalizations.delegate, LayrzUiL10nDelegate()],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Navigator(
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SizedBox(width: 800, height: 900, child: LayrzFindSpike()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The live [FindHighlightPainter] currently painting the spike's highlight
/// overlay — the only externally observable proxy for the widget's private
/// `_highlights`/`currentIndex` state, since [FindHighlightPainter.highlights]
/// and [FindHighlightPainter.currentIndex] are both public.
FindHighlightPainter _currentPainter(WidgetTester tester) {
  final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
  return customPaints.map((w) => w.painter).whereType<FindHighlightPainter>().single;
}

void main() {
  group('LayrzFindSpike', () {
    testWidgets('typing multiple characters quickly triggers only ONE walk, after the debounce settles', (
      tester,
    ) async {
      await _pumpFindSpike(tester);

      // Five separate onChanged events within the same debounce window —
      // each call resets the pending Timer (see _handleQueryChanged's doc),
      // so only the LAST of these should ever produce a walk.
      await tester.enterText(find.byType(EditableText).first, 'm');
      await tester.enterText(find.byType(EditableText).first, 'ma');
      await tester.enterText(find.byType(EditableText).first, 'man');
      await tester.enterText(find.byType(EditableText).first, 'mang');
      await tester.enterText(find.byType(EditableText).first, 'mango');

      // Still well inside the 300ms debounce window — no walk has run yet,
      // so the counter must still read its initial "0 of 0".
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('0 of 0'), findsOneWidget);

      // Past the debounce window from the LAST keystroke — exactly one walk
      // should now have run, against "mango" (never against "m"/"ma"/"man"
      // /"mang", which would each have produced a different, wrong count).
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('0 of 0'), findsNothing);
      expect(find.textContaining(' of '), findsOneWidget);
    });

    testWidgets('clearing the query field clears both the counter and the painted highlights instantly', (
      tester,
    ) async {
      await _pumpFindSpike(tester);

      await tester.enterText(find.byType(EditableText).first, 'mango');
      await tester.pump(const Duration(milliseconds: 300));
      // The debounced walk itself completes within the pump above (its
      // setState runs synchronously inside the Timer callback the pump's
      // clock-advance fires), but the resulting highlight resolution is
      // deferred one further frame via addPostFrameCallback (see
      // _scheduleHighlightResolution's doc) — an extra pump lets that frame
      // actually happen before checking the painter.
      await tester.pump();
      expect(find.text('0 of 0'), findsNothing);
      expect(_currentPainter(tester).highlights, isNotEmpty);

      // Clearing must NOT wait out the debounce — see _handleQueryChanged's
      // doc for why this bypasses it entirely. A single pump (no delay) must
      // already show the fully cleared state, since the clear path commits
      // both _matches and _highlights synchronously in the same setState —
      // no post-frame resolution is involved for the "clear everything"
      // outcome.
      await tester.enterText(find.byType(EditableText).first, '');
      await tester.pump();

      expect(find.text('0 of 0'), findsOneWidget);
      expect(_currentPainter(tester).highlights, isEmpty);
    });

    testWidgets('changing the query from "m" to "mango" leaves highlights resolved for "mango", never "m"', (
      tester,
    ) async {
      await _pumpFindSpike(tester);

      // Let "m" fully settle and resolve on its own first — this reproduces
      // the exact sequence the on-device sync bug was caught with: a prior
      // query's walk AND highlight resolution both completing before the
      // next query starts, rather than being coalesced away by the
      // debounce. The fix must hold even so.
      await tester.enterText(find.byType(EditableText).first, 'm');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      final mHighlights = _currentPainter(tester).highlights;
      expect(mHighlights, isNotEmpty);

      await tester.enterText(find.byType(EditableText).first, 'mango');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      final mangoHighlights = _currentPainter(tester).highlights;
      expect(mangoHighlights, isNotEmpty);
      // The two resolved sets must differ — "m" matches roughly fifty
      // "Sample paragraph"/"mango" substrings across the document, "mango"
      // matches only whole-word "mango" occurrences, so their highlight
      // geometry cannot coincide. A failure here (mangoHighlights still
      // equal to mHighlights) is exactly the stale-highlight sync bug this
      // test exists to catch.
      expect(mangoHighlights, isNot(equals(mHighlights)));
    });

    testWidgets('the "Walk & Highlight" button forces an immediate walk, bypassing the debounce', (tester) async {
      await _pumpFindSpike(tester);

      await tester.enterText(find.byType(EditableText).first, 'mango');
      // No debounce wait at all — only the button's immediate walk should
      // produce a result within a single pump.
      await tester.tap(find.text('Walk & Highlight'));
      await tester.pump();

      expect(find.text('0 of 0'), findsNothing);
    });
  });
}
