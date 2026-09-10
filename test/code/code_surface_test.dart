import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/code/src/code_surface.dart';
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/theme/theme.dart';

import '../helpers/pump_themed.dart';

/// Concatenates the plain text of every leaf [TextSpan] under [span], in
/// visiting order, so it can be compared against the original source string.
String _plainTextOf(InlineSpan span) {
  final buffer = StringBuffer();
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null) {
      buffer.write(child.text);
    }
    return true;
  });
  return buffer.toString();
}

/// Collects every leaf [TextSpan] under [span], in visiting order.
List<TextSpan> _leafSpansOf(InlineSpan span) {
  final leaves = <TextSpan>[];
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null) {
      leaves.add(child);
    }
    return true;
  });
  return leaves;
}

void main() {
  group('LayrzCodeSurface', () {
    testWidgets('renders a RichText whose plain text equals the code (wide viewport)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'def greet():\n    print("hi")\n';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: code, language: LayrzCodeLanguage.python),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(_plainTextOf(richText.text), code);
    });

    testWidgets('renders a RichText whose plain text equals the code (compact viewport)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'x = 1 + 2';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: code, language: LayrzCodeLanguage.python),
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(_plainTextOf(richText.text), code);
    });

    testWidgets('showLineNumbers renders exactly one gutter entry per line', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'a = 1\nb = 2\nc = 3';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(
          code: code,
          language: LayrzCodeLanguage.python,
          showLineNumbers: true,
        ),
      );

      // Two RichText widgets: the gutter and the code body.
      final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
      expect(richTexts.length, 2);

      final gutterText = _plainTextOf(richTexts.first.text);
      expect(gutterText, '1\n2\n3');
    });

    testWidgets('showLineNumbers is absent by default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'a = 1\nb = 2';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: code, language: LayrzCodeLanguage.python),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('background uses the dark code theme color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'x = 1';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: code, language: LayrzCodeLanguage.python),
      );

      const codeTheme = LayrzCodeThemeExtension.dark();
      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, codeTheme.background);
    });

    testWidgets('tokenized spans carry distinct styles for string and function scopes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'GET_SENSOR("ignition")';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: code, language: LayrzCodeLanguage.lcl),
      );

      const codeTheme = LayrzCodeThemeExtension.dark();
      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final leaves = _leafSpansOf(richText.text);

      final stringStyle = codeTheme.styleForScope(LayrzHighlightScope.string, fontSize: 14);
      final functionStyle = codeTheme.styleForScope(LayrzHighlightScope.function, fontSize: 14);

      final hasStringSpan = leaves.any((span) => span.style?.color == stringStyle.color);
      final hasFunctionSpan = leaves.any((span) => span.style?.color == functionStyle.color);

      expect(hasStringSpan, isTrue, reason: 'expected at least one span styled as a string literal');
      expect(hasFunctionSpan, isTrue, reason: 'expected at least one span styled as a function call');
      expect(stringStyle.color, isNot(equals(functionStyle.color)));
    });

    testWidgets('maxHeight constrains the scroll area', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'a = 1\nb = 2\nc = 3\nd = 4';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(
          code: code,
          language: LayrzCodeLanguage.python,
          maxHeight: 40,
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox).first);
      expect(constrainedBox.constraints.maxHeight, 40);
    });

    testWidgets('renders correctly for an empty code string', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: '', language: LayrzCodeLanguage.python, showLineNumbers: true),
      );

      final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
      final gutterText = _plainTextOf(richTexts.first.text);
      expect(gutterText, '1');
    });

    testWidgets('reservedTrailingSpace adds extra right padding to the code content', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'x = 1';
      final reserve = kLayrzButtonCompactHeight + 4;
      await pumpThemed(
        tester,
        LayrzCodeSurface(code: code, language: LayrzCodeLanguage.python, reservedTrailingSpace: reserve),
      );

      final tokens = LayrzThemeData.light().tokens;
      final defaultPadding = tokens.spacing.pd3;

      final contentPadding = tester.widget<Padding>(
        find.ancestor(of: find.byType(RichText).first, matching: find.byType(Padding)).first,
      );
      expect(
        contentPadding.padding.resolve(TextDirection.ltr).right,
        defaultPadding.right + reserve,
      );
    });

    testWidgets('reservedTrailingSpace defaults to 0 (no extra right padding)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const code = 'x = 1';
      await pumpThemed(
        tester,
        const LayrzCodeSurface(code: code, language: LayrzCodeLanguage.python),
      );

      final tokens = LayrzThemeData.light().tokens;
      final defaultPadding = tokens.spacing.pd3;

      final contentPadding = tester.widget<Padding>(
        find.ancestor(of: find.byType(RichText).first, matching: find.byType(Padding)).first,
      );
      expect(contentPadding.padding.resolve(TextDirection.ltr).right, defaultPadding.right);
    });
  });
}
