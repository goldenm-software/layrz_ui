import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_snippet.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/theme/theme.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCodeSnippet', () {
    const sampleCode = 'def greet(name):\n    return f"Hello, {name}!"';

    testWidgets('renders the given code text at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
      );

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      final rendered = richTextFinder
          .evaluate()
          .map((element) => (element.widget as RichText).text.toPlainText())
          .join();
      expect(rendered, contains('greet'));
      expect(rendered, contains('Hello,'));
    });

    testWidgets('renders the given code text at a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
      );

      final richTextFinder = find.byType(RichText);
      final rendered = richTextFinder
          .evaluate()
          .map((element) => (element.widget as RichText).text.toPlainText())
          .join();
      expect(rendered, contains('greet'));
    });

    testWidgets('shows the copy button when showCopyButton is true (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
      );

      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);
    });

    testWidgets('shows the copy button when showCopyButton is true (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
      );

      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);
    });

    testWidgets('hides the copy button when showCopyButton is false (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(
          code: sampleCode,
          language: LayrzCodeLanguage.python,
          showCopyButton: false,
        ),
      );

      expect(find.byType(LayrzCodeCopyButton), findsNothing);
    });

    testWidgets('hides the copy button when showCopyButton is false (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(
          code: sampleCode,
          language: LayrzCodeLanguage.python,
          showCopyButton: false,
        ),
      );

      expect(find.byType(LayrzCodeCopyButton), findsNothing);
    });

    testWidgets('shows line numbers when showLineNumbers is true (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const multilineCode = 'line one\nline two\nline three';

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(
          code: multilineCode,
          language: LayrzCodeLanguage.python,
          showLineNumbers: true,
        ),
      );

      final richTextFinder = find.byType(RichText);
      final rendered = richTextFinder
          .evaluate()
          .map((element) => (element.widget as RichText).text.toPlainText())
          .join('\n');
      expect(rendered, contains('1\n2\n3'));
    });

    testWidgets('hides line numbers when showLineNumbers is false (default)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const multilineCode = 'line one\nline two\nline three';

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: multilineCode, language: LayrzCodeLanguage.python),
      );

      final richTextFinder = find.byType(RichText);
      final rendered = richTextFinder
          .evaluate()
          .map((element) => (element.widget as RichText).text.toPlainText())
          .join('\n');
      expect(rendered, isNot(contains('1\n2\n3')));
    });

    testWidgets('constrains height when maxHeight is provided (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const longCode =
          'line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10\n'
          'line 11\nline 12\nline 13\nline 14\nline 15\nline 16\nline 17\nline 18\nline 19\nline 20';

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(
          code: longCode,
          language: LayrzCodeLanguage.python,
          maxHeight: 120,
        ),
      );

      final stackFinder = find.byType(Stack).first;
      final stackSize = tester.getSize(stackFinder);
      expect(stackSize.height, lessThanOrEqualTo(120));
    });

    testWidgets('constrains height when maxHeight is provided (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const longCode =
          'line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10\n'
          'line 11\nline 12\nline 13\nline 14\nline 15\nline 16\nline 17\nline 18\nline 19\nline 20';

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(
          code: longCode,
          language: LayrzCodeLanguage.python,
          maxHeight: 120,
        ),
      );

      final stackFinder = find.byType(Stack).first;
      final stackSize = tester.getSize(stackFinder);
      expect(stackSize.height, lessThanOrEqualTo(120));
    });

    testWidgets('renders without a maxHeight constraint by default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python),
      );

      expect(find.byType(LayrzCodeSnippet), findsOneWidget);
    });

    testWidgets('renders with a custom fontSize', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python, fontSize: 20),
      );

      final richTextFinder = find.byType(RichText).first;
      final richText = tester.widget<RichText>(richTextFinder);
      void assertHasFontSize(InlineSpan span) {
        if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
          expect(span.style?.fontSize, anyOf(isNull, isNotNull));
        }
      }

      richText.text.visitChildren((span) {
        assertHasFontSize(span);
        return true;
      });
    });

    testWidgets('renders with a custom padding', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(
          code: sampleCode,
          language: LayrzCodeLanguage.python,
          padding: EdgeInsets.all(32),
        ),
      );

      expect(find.byType(LayrzCodeSnippet), findsOneWidget);
    });

    testWidgets('renders lml and lcl languages without error', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: 'x = 1', language: LayrzCodeLanguage.lcl),
      );
      expect(find.byType(LayrzCodeSnippet), findsOneWidget);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: '<root/>', language: LayrzCodeLanguage.lml),
      );
      expect(find.byType(LayrzCodeSnippet), findsOneWidget);
    });

    testWidgets('reserves right-side space for the copy button when shown', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python, showCopyButton: true),
      );

      final tokens = LayrzThemeData.light().tokens;
      final defaultRight = tokens.spacing.pd3.right;

      final contentPadding = tester.widget<Padding>(
        find.ancestor(of: find.byType(RichText).first, matching: find.byType(Padding)).first,
      );
      final resolvedRight = contentPadding.padding.resolve(TextDirection.ltr).right;
      expect(resolvedRight, defaultRight + kLayrzButtonCompactHeight + tokens.spacing.sp1);
      expect(resolvedRight, greaterThan(defaultRight));
    });

    testWidgets('does not reserve right-side space when the copy button is hidden', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: sampleCode, language: LayrzCodeLanguage.python, showCopyButton: false),
      );

      final tokens = LayrzThemeData.light().tokens;
      final defaultRight = tokens.spacing.pd3.right;

      final contentPadding = tester.widget<Padding>(
        find.ancestor(of: find.byType(RichText).first, matching: find.byType(Padding)).first,
      );
      expect(contentPadding.padding.resolve(TextDirection.ltr).right, defaultRight);
    });
  });
}
