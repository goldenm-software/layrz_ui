import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  const wideSize = Size(1600, 1200);

  /// Pumps [fenceInfo] as a fenced code block's info string and returns the
  /// [LayrzCodeSnippet] it renders as.
  Future<LayrzCodeSnippet> pumpFence(WidgetTester tester, {String? fenceInfo, String code = 'value'}) async {
    final info = fenceInfo ?? '';
    final data = '```$info\n$code\n```';
    await pumpThemed(tester, LayrzMarkdown(data: data));
    final snippetFinder = find.byType(LayrzCodeSnippet);
    expect(snippetFinder, findsOneWidget);
    return tester.widget<LayrzCodeSnippet>(snippetFinder);
  }

  group('LayrzMarkdown fenced code — language mapping end to end', () {
    testWidgets('a python fence maps to LayrzCodeLanguage.python', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final snippet = await pumpFence(tester, fenceInfo: 'python', code: 'x = 1');
      expect(snippet.language, LayrzCodeLanguage.python);
      expect(snippet.code, 'x = 1');
    });

    testWidgets('an lcl fence maps to LayrzCodeLanguage.lcl', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final snippet = await pumpFence(tester, fenceInfo: 'lcl', code: 'GET_SENSOR("x")');
      expect(snippet.language, LayrzCodeLanguage.lcl);
    });

    testWidgets('an lml fence maps to LayrzCodeLanguage.lml', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final snippet = await pumpFence(tester, fenceInfo: 'lml', code: '{{assetName}}');
      expect(snippet.language, LayrzCodeLanguage.lml);
    });

    testWidgets('an unknown info string (js) maps to LayrzCodeLanguage.plain', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final snippet = await pumpFence(tester, fenceInfo: 'js', code: 'const x = 1;');
      expect(snippet.language, LayrzCodeLanguage.plain);
    });

    testWidgets('no info string at all maps to LayrzCodeLanguage.plain', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final snippet = await pumpFence(tester, fenceInfo: null, code: 'raw text');
      expect(snippet.language, LayrzCodeLanguage.plain);
    });
  });

  group('LayrzMarkdown fenced code — spacing and multiple fences', () {
    testWidgets('multiple fences in one document each render their own LayrzCodeSnippet', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const data = '```python\nx = 1\n```\n\n```lcl\nGET_SENSOR("y")\n```';
      await pumpThemed(tester, const LayrzMarkdown(data: data));

      final snippets = find.byType(LayrzCodeSnippet).evaluate().map((e) => e.widget as LayrzCodeSnippet).toList();
      expect(snippets, hasLength(2));
      expect(snippets[0].language, LayrzCodeLanguage.python);
      expect(snippets[1].language, LayrzCodeLanguage.lcl);
    });
  });
}
