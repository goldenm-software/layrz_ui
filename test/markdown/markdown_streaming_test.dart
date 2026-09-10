import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Repeatedly pumping a widget through [pumpThemed] in the same test does
/// not force a full rebuild from the new widget's data — probed directly
/// against this shared helper: pumping `'AAA'` then `'BBB'` through it
/// leaves `'AAA'` findable and `'BBB'` absent, independent of anything
/// `LayrzMarkdown`-specific. Tearing the tree down to an empty widget
/// in between (as this helper does) forces a real teardown/rebuild, so a
/// second [pumpThemed] afterward genuinely reflects the new widget.
Future<void> _pumpFreshThemed(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await pumpThemed(tester, child);
}

void main() {
  const wideSize = Size(1600, 1200);

  group('LayrzMarkdown — streaming', () {
    testWidgets('a trailing unterminated fence while streaming does not render broken fence markup as text', (
      tester,
    ) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const partialData = 'Intro paragraph.\n\n```python\nprint("still typing"';

      await pumpThemed(tester, const LayrzMarkdown(data: partialData, isStreaming: true));
      expect(tester.takeException(), isNull);

      // The pending block is best-effort parsed as a code fence, so it must
      // render as a LayrzCodeSnippet — never as a raw paragraph containing
      // the literal ``` markers.
      expect(find.byType(LayrzCodeSnippet), findsOneWidget);
      final rawFenceMarkerFinder = find.textContaining('```');
      expect(rawFenceMarkerFinder, findsNothing);
    });

    testWidgets('a partially-streamed fence renders the pending code parsed so far', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const partialData = 'Intro paragraph.\n\n```python\nprint("done"';

      await pumpThemed(tester, const LayrzMarkdown(data: partialData, isStreaming: true));
      expect(tester.takeException(), isNull);

      final snippetFinder = find.byType(LayrzCodeSnippet);
      expect(snippetFinder, findsOneWidget);
      final snippet = tester.widget<LayrzCodeSnippet>(snippetFinder);
      expect(snippet.code, 'print("done"');
      expect(snippet.language, LayrzCodeLanguage.python);
    });

    testWidgets('the same source, once complete and not streaming, renders the finished code', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const completeData = 'Intro paragraph.\n\n```python\nprint("done")\n```';

      await pumpThemed(tester, const LayrzMarkdown(data: completeData, isStreaming: false));
      expect(tester.takeException(), isNull);

      final snippetFinder = find.byType(LayrzCodeSnippet);
      expect(snippetFinder, findsOneWidget);
      final snippet = tester.widget<LayrzCodeSnippet>(snippetFinder);
      expect(snippet.code, 'print("done")');
      expect(snippet.language, LayrzCodeLanguage.python);
    });

    testWidgets('a mid-line source with no trailing newline still renders without throwing', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzMarkdown(data: 'This sentence is not yet finis', isStreaming: true),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('This sentence is not yet finis'), findsWidgets);
    });

    testWidgets('feeding a sequence of growing prefixes never throws', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const fullDocument =
          '# Heading\n\nA paragraph of streamed text that keeps going.\n\n'
          '- item one\n- item two\n\n'
          '```python\ndef f():\n    return 1\n```\n\n'
          'Trailing paragraph after the fence.';

      // Sample at a stride rather than every single character to keep the
      // test fast, while still covering many distinct partial-document
      // shapes (mid-heading, mid-list, mid-fence, mid-trailing-paragraph).
      // Each iteration tears the tree down and rebuilds fresh (see
      // `_pumpFreshThemed`) so every prefix is genuinely (re)parsed rather
      // than reusing a previous build.
      for (var i = 1; i <= fullDocument.length; i += 7) {
        final prefix = fullDocument.substring(0, i);
        await _pumpFreshThemed(tester, LayrzMarkdown(data: prefix, isStreaming: true));
        expect(tester.takeException(), isNull, reason: 'while streaming prefix of length $i');
      }

      // And the final, complete document.
      await _pumpFreshThemed(tester, const LayrzMarkdown(data: fullDocument, isStreaming: true));
      expect(tester.takeException(), isNull);
    });
  });
}
