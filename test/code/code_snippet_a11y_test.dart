import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_snippet.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCodeSnippet accessibility', () {
    const sampleCode = 'print("hello")';

    testWidgets('copy button exposes button semantics at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
        );

        final buttonFinder = find.byType(LayrzCodeCopyButton);
        expect(buttonFinder, findsOneWidget);

        expect(
          tester.getSemantics(buttonFinder),
          matchesSemantics(
            isButton: true,
            label: 'Copy',
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('copy button exposes button semantics at a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
        );

        final buttonFinder = find.byType(LayrzCodeCopyButton);
        expect(buttonFinder, findsOneWidget);

        expect(
          tester.getSemantics(buttonFinder),
          matchesSemantics(
            isButton: true,
            label: 'Copy',
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('no button semantics are exposed when showCopyButton is false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzCodeSnippet(
            code: sampleCode,
            language: LayrzCodeLanguage.python,
            showCopyButton: false,
          ),
        );

        expect(find.byType(LayrzCodeCopyButton), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });
}
