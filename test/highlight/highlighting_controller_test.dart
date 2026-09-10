import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

/// A fixed color assigned per scope, distinct enough to tell spans apart by
/// their resolved [TextStyle.color] in assertions.
const Map<LayrzHighlightScope, Color> _scopeColors = {
  LayrzHighlightScope.text: Color(0xFF000000),
  LayrzHighlightScope.keyword: Color(0xFF0000FF),
  LayrzHighlightScope.builtin: Color(0xFF00FFFF),
  LayrzHighlightScope.function: Color(0xFFFF00FF),
  LayrzHighlightScope.string: Color(0xFF00FF00),
  LayrzHighlightScope.number: Color(0xFFFF9900),
  LayrzHighlightScope.comment: Color(0xFF808080),
  LayrzHighlightScope.constant: Color(0xFF990000),
  LayrzHighlightScope.decorator: Color(0xFF009900),
  LayrzHighlightScope.variable: Color(0xFF3366CC),
};

TextStyle _resolveStyle(LayrzHighlightScope scope) => TextStyle(color: _scopeColors[scope]);

/// Pumps a bare [Builder] and returns the [BuildContext] it captures, giving
/// tests a real context without pulling in any layrz_ui theme machinery —
/// this controller has none.
Future<BuildContext> _pumpBareContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('LayrzHighlightingController.buildTextSpan', () {
    testWidgets('merges scope color while preserving base style properties', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final context = await _pumpBareContext(tester);
      final controller = LayrzHighlightingController(
        language: LayrzCodeLanguage.python,
        resolveStyle: _resolveStyle,
        text: 'def foo(): pass',
      );
      addTearDown(controller.dispose);

      const baseStyle = TextStyle(fontSize: 14);
      final span = controller.buildTextSpan(context: context, style: baseStyle, withComposing: false);

      expect(span.style, baseStyle);
      expect(span.children, isNotEmpty);

      final keywordSpan = span.children!.cast<TextSpan>().firstWhere((s) => s.text == 'def');
      expect(keywordSpan.style!.color, _scopeColors[LayrzHighlightScope.keyword]);
      expect(keywordSpan.style!.fontSize, 14, reason: 'base fontSize must survive the merge');
    });

    testWidgets('reconstructs the full source text from span children', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final context = await _pumpBareContext(tester);
      const code = 'GET_SENSOR("speed") + 1';
      final controller = LayrzHighlightingController(
        language: LayrzCodeLanguage.lcl,
        resolveStyle: _resolveStyle,
        text: code,
      );
      addTearDown(controller.dispose);

      final span = controller.buildTextSpan(context: context, style: const TextStyle(), withComposing: false);
      final reconstructed = span.children!.cast<TextSpan>().map((s) => s.text ?? '').join();
      expect(reconstructed, code);

      final functionSpan = span.children!.cast<TextSpan>().firstWhere((s) => s.text == 'GET_SENSOR');
      expect(functionSpan.style!.color, _scopeColors[LayrzHighlightScope.function]);

      final stringSpan = span.children!.cast<TextSpan>().firstWhere((s) => s.text == '"speed"');
      expect(stringSpan.style!.color, _scopeColors[LayrzHighlightScope.string]);
    });

    testWidgets('falls back to a flat TextSpan when the composing range is invalid', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final context = await _pumpBareContext(tester);
      final controller = LayrzHighlightingController(
        language: LayrzCodeLanguage.python,
        resolveStyle: _resolveStyle,
        text: 'x = 1',
      );
      addTearDown(controller.dispose);

      final span = controller.buildTextSpan(context: context, style: const TextStyle(), withComposing: true);
      expect(span.children, isNotEmpty);
    });

    testWidgets('underlines only the slice inside an active composing range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final context = await _pumpBareContext(tester);
      const code = 'foobar';
      final controller = LayrzHighlightingController(
        language: LayrzCodeLanguage.python,
        resolveStyle: _resolveStyle,
        text: code,
      );
      addTearDown(controller.dispose);

      controller.value = controller.value.copyWith(
        text: code,
        selection: const TextSelection.collapsed(offset: 6),
        composing: const TextRange(start: 3, end: 6),
      );

      final span = controller.buildTextSpan(context: context, style: const TextStyle(), withComposing: true);
      final flatChildren = span.children!.cast<TextSpan>();

      final reconstructed = flatChildren.map((s) => s.text ?? '').join();
      expect(reconstructed, code);

      // "foobar" has no grammar rule matching bare identifiers, so each
      // character becomes its own `text`-scope token; the composing range
      // therefore underlines three adjacent single-character spans rather
      // than one merged span. Assert on the reconstructed substrings, which
      // is what the renderer's output actually needs to preserve.
      final underlined = flatChildren.where((s) => s.style?.decoration == TextDecoration.underline).toList();
      expect(underlined.map((s) => s.text).join(), 'bar');

      final plain = flatChildren.where((s) => s.style?.decoration != TextDecoration.underline).toList();
      expect(plain.map((s) => s.text).join(), 'foo');
    });

    testWidgets('resolves a distinct style per scope value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final context = await _pumpBareContext(tester);
      const code = '# comment\n@dec\ndef f():\n    return "s" + 1 + True + len(x)';
      final controller = LayrzHighlightingController(
        language: LayrzCodeLanguage.python,
        resolveStyle: _resolveStyle,
        text: code,
      );
      addTearDown(controller.dispose);

      final span = controller.buildTextSpan(context: context, style: const TextStyle(), withComposing: false);
      final colors = span.children!.cast<TextSpan>().map((s) => s.style?.color).toSet();

      expect(colors, contains(_scopeColors[LayrzHighlightScope.comment]));
      expect(colors, contains(_scopeColors[LayrzHighlightScope.decorator]));
      expect(colors, contains(_scopeColors[LayrzHighlightScope.keyword]));
      expect(colors, contains(_scopeColors[LayrzHighlightScope.string]));
      expect(colors, contains(_scopeColors[LayrzHighlightScope.number]));
      expect(colors, contains(_scopeColors[LayrzHighlightScope.constant]));
      expect(colors, contains(_scopeColors[LayrzHighlightScope.builtin]));
    });
  });
}
