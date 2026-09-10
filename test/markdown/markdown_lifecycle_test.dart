import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Regression coverage for [LayrzMarkdown]'s `TapGestureRecognizer` lifecycle.
///
/// A leaked, undisposed recognizer trips a framework-level assertion at test
/// teardown ("A TapGestureRecognizer was not disposed"), so a passing suite
/// here is itself proof the widget disposed every recognizer it created —
/// there is nothing further to assert once the pump/teardown completes
/// without that exception.
///
/// **Why every "rebuild" step here tears the tree down first.** [pumpThemed]
/// wraps its child in a fresh `Overlay(initialEntries: [...])` on every
/// call, but `Overlay`'s `initialEntries` is only consumed once by its
/// `OverlayState` — calling [pumpThemed] a second time in the same test
/// reuses that already-initialized `OverlayState` and its original entry,
/// so the "new" child never actually replaces what is on screen (verified
/// directly: pumping `'AAA'` then `'BBB'` through [pumpThemed] twice in one
/// test still finds `'AAA'` and never `'BBB'`). Tearing down to an empty
/// widget between steps (as [_pumpFreshThemed] does) forces a real
/// `Overlay`/`OverlayState` teardown and recreation, so the next
/// [pumpThemed] call genuinely reflects the new widget and, just as
/// importantly, genuinely disposes the previous [LayrzMarkdown]'s
/// recognizers rather than silently keeping the old element alive.
Future<void> _pumpFreshThemed(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await pumpThemed(tester, child);
}

void main() {
  const wideSize = Size(1600, 1200);

  group('LayrzMarkdown — recognizer lifecycle', () {
    testWidgets('disposing after pumping links does not leak a TapGestureRecognizer', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzMarkdown(
          data: '[first link](https://a.example) and [second link](https://b.example)',
        ),
      );

      // Replace the whole tree with something unrelated — this disposes the
      // previous LayrzMarkdown (and, with it, every recognizer it created).
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilding with fewer links disposes the surplus recognizers without throwing', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpFreshThemed(
        tester,
        const LayrzMarkdown(
          data: '[one](https://a.example) [two](https://b.example) [three](https://c.example)',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzMarkdown), findsOneWidget);

      await _pumpFreshThemed(
        tester,
        const LayrzMarkdown(data: '[one](https://a.example)'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzMarkdown), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilding with more links than before does not throw or leak', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpFreshThemed(
        tester,
        const LayrzMarkdown(data: '[one](https://a.example)'),
      );
      expect(tester.takeException(), isNull);

      await _pumpFreshThemed(
        tester,
        const LayrzMarkdown(
          data: '[one](https://a.example) [two](https://b.example) [three](https://c.example)',
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilding to data with no links at all disposes every prior recognizer', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpFreshThemed(
        tester,
        const LayrzMarkdown(data: '[one](https://a.example) [two](https://b.example)'),
      );
      expect(tester.takeException(), isNull);

      await _pumpFreshThemed(
        tester,
        const LayrzMarkdown(data: 'No links here at all.'),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('repeated rebuilds across many link-count changes never leak', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final variants = <String>[
        '[a](https://a.example)',
        '[a](https://a.example) [b](https://b.example)',
        'no links',
        '[a](https://a.example) [b](https://b.example) [c](https://c.example)',
        '[solo](https://solo.example)',
      ];

      for (final data in variants) {
        await _pumpFreshThemed(tester, LayrzMarkdown(data: data));
        expect(tester.takeException(), isNull, reason: 'while pumping "$data"');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
