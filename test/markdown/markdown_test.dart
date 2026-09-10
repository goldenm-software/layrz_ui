import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Walks [span] and every descendant, collecting each leaf [TextSpan] that
/// carries non-empty text — used to inspect the exact resolved style/text of
/// individual runs inside a rendered [Text.rich]/[RichText] tree.
List<TextSpan> _leafTextSpans(InlineSpan span) {
  final leaves = <TextSpan>[];
  if (span is TextSpan) {
    if (span.text != null && span.text!.isNotEmpty) {
      leaves.add(span);
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      leaves.addAll(_leafTextSpans(child));
    }
  }
  return leaves;
}

/// Collects every [TextSpan] anywhere in [span]'s tree (root included) that
/// carries a non-null [TextSpan.recognizer].
///
/// A link's recognizer is attached to the wrapping span the inline renderer
/// builds for the `a` element itself, not to the plain-text leaf(ves) inside
/// it, so callers that need to fire a link's tap must search for the
/// recognizer-carrying span rather than the leaf.
List<TextSpan> _spansWithRecognizer(InlineSpan span) {
  final found = <TextSpan>[];
  if (span is TextSpan) {
    if (span.recognizer != null) {
      found.add(span);
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      found.addAll(_spansWithRecognizer(child));
    }
  }
  return found;
}

/// Finds the first [RichText] widget whose plain text contains [needle].
RichText _richTextContaining(WidgetTester tester, String needle) {
  final candidates = find
      .byType(RichText)
      .evaluate()
      .map((e) => e.widget as RichText)
      .where((rt) => rt.text.toPlainText().contains(needle));
  expect(candidates, isNotEmpty, reason: 'no RichText found containing "$needle"');
  return candidates.first;
}

void main() {
  const wideSize = Size(1600, 1200);

  group('LayrzMarkdown — heading styles', () {
    testWidgets('h1 uses the headline typography style', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '# Heading One'));

      final richText = _richTextContaining(tester, 'Heading One');
      final leaf = _leafTextSpans(richText.text).firstWhere((s) => s.text == 'Heading One');
      final headlineStyle = LayrzThemeData.light().tokens.typography.headline;

      expect(leaf.style?.fontSize, headlineStyle.fontSize);
      final fontVariations = leaf.style?.fontVariations;
      final headlineVariations = headlineStyle.fontVariations;
      if (headlineVariations != null && headlineVariations.isNotEmpty) {
        expect(fontVariations, headlineVariations);
      }
    });

    testWidgets('h2 uses the title typography style', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '## Heading Two'));

      final richText = _richTextContaining(tester, 'Heading Two');
      final leaf = _leafTextSpans(richText.text).firstWhere((s) => s.text == 'Heading Two');
      final titleStyle = LayrzThemeData.light().tokens.typography.title;

      expect(leaf.style?.fontSize, titleStyle.fontSize);
    });

    testWidgets('h3 style differs from the plain body style (weight steps down via fontVariations)', (
      tester,
    ) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '### Heading Three'));

      final richText = _richTextContaining(tester, 'Heading Three');
      final leaf = _leafTextSpans(richText.text).firstWhere((s) => s.text == 'Heading Three');
      final bodyStyle = LayrzThemeData.light().tokens.typography.body;

      // h3 merges body with a `wght 600` FontVariation — the resolved style
      // must therefore differ from the plain body style.
      expect(leaf.style, isNot(equals(bodyStyle)));
      expect(leaf.style?.fontVariations, isNotNull);
      expect(
        leaf.style!.fontVariations!.any((v) => v.axis == 'wght' && v.value == 600),
        isTrue,
      );
    });

    testWidgets('h6 steps weight down to 300 via fontVariations', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '###### Heading Six'));

      final richText = _richTextContaining(tester, 'Heading Six');
      final leaf = _leafTextSpans(richText.text).firstWhere((s) => s.text == 'Heading Six');
      expect(
        leaf.style!.fontVariations!.any((v) => v.axis == 'wght' && v.value == 300),
        isTrue,
      );
    });
  });

  group('LayrzMarkdown — paragraph and lists render', () {
    testWidgets('renders a paragraph without error', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: 'Plain paragraph text.'));

      expect(find.textContaining('Plain paragraph text.'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an unordered list without error', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '- first item\n- second item'));

      expect(find.textContaining('first item'), findsWidgets);
      expect(find.textContaining('second item'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an ordered list with the correct numbering markers', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '3. third\n4. fourth'));

      expect(find.textContaining('3.'), findsOneWidget);
      expect(find.textContaining('4.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders inline code as a distinct chip without error', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: 'Use `myVar` in code.'));

      expect(find.textContaining('myVar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzMarkdown — inline bold/italic spans', () {
    testWidgets('bold text produces a span with fontVariations wght 700', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: 'A **bold** word.'));

      final richText = _richTextContaining(tester, 'bold');
      final leaves = _leafTextSpans(richText.text);
      final boldLeaf = leaves.firstWhere((s) => s.text == 'bold');

      expect(
        boldLeaf.style?.fontVariations?.any((v) => v.axis == 'wght' && v.value == 700),
        isTrue,
      );
    });

    testWidgets('italic text produces a span with FontStyle.italic', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: 'An *italic* word.'));

      final richText = _richTextContaining(tester, 'italic');
      final leaves = _leafTextSpans(richText.text);
      final italicLeaf = leaves.firstWhere((s) => s.text == 'italic');

      expect(italicLeaf.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('plain surrounding text is neither bold nor italic', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: 'A **bold** word.'));

      final richText = _richTextContaining(tester, 'A ');
      final leaves = _leafTextSpans(richText.text);
      final plainLeaf = leaves.firstWhere((s) => s.text == 'A ');

      expect(plainLeaf.style?.fontStyle, isNot(FontStyle.italic));
      final hasBoldVariation = plainLeaf.style?.fontVariations?.any((v) => v.axis == 'wght' && v.value == 700);
      expect(hasBoldVariation ?? false, isFalse);
    });
  });

  group('LayrzMarkdown — fenced code blocks', () {
    testWidgets('a python fence renders a LayrzCodeSnippet with language python', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '```python\nprint(1)\n```'));

      final snippetFinder = find.byType(LayrzCodeSnippet);
      expect(snippetFinder, findsOneWidget);
      final snippet = tester.widget<LayrzCodeSnippet>(snippetFinder);
      expect(snippet.language, LayrzCodeLanguage.python);
      expect(snippet.code, 'print(1)');
    });

    testWidgets('a json fence (unmapped language) renders a LayrzCodeSnippet with language plain', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '```json\n{"a": 1}\n```'));

      final snippetFinder = find.byType(LayrzCodeSnippet);
      expect(snippetFinder, findsOneWidget);
      final snippet = tester.widget<LayrzCodeSnippet>(snippetFinder);
      expect(snippet.language, LayrzCodeLanguage.plain);
    });
  });

  group('LayrzMarkdown — links', () {
    testWidgets('tapping a link fires onTapLink with the correct href and title', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? capturedHref;
      String? capturedTitle;

      await pumpThemed(
        tester,
        LayrzMarkdown(
          data: '[Click here](https://example.com "Example title")',
          onTapLink: (href, title) {
            capturedHref = href;
            capturedTitle = title;
          },
        ),
      );

      final richText = _richTextContaining(tester, 'Click here');
      final linkSpans = _spansWithRecognizer(richText.text);
      expect(linkSpans, hasLength(1));
      final linkSpan = linkSpans.single;
      expect(linkSpan.toPlainText(), 'Click here');
      expect(linkSpan.recognizer, isA<TapGestureRecognizer>());

      (linkSpan.recognizer! as TapGestureRecognizer).onTap!();

      expect(capturedHref, 'https://example.com');
      expect(capturedTitle, 'Example title');
    });

    testWidgets('tapping a link with onTapLink null does not throw', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '[a link](https://example.com)'));

      final richText = _richTextContaining(tester, 'a link');
      final linkSpans = _spansWithRecognizer(richText.text);
      expect(linkSpans, hasLength(1));
      final linkSpan = linkSpans.single;

      expect(() => (linkSpan.recognizer! as TapGestureRecognizer).onTap!(), returnsNormally);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty link text displays the href as the visible text', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzMarkdown(data: '[](https://x.com)'));

      final richText = _richTextContaining(tester, 'https://x.com');
      final leaves = _leafTextSpans(richText.text);
      final linkLeaf = leaves.firstWhere((s) => s.text == 'https://x.com');

      expect(linkLeaf.text, 'https://x.com');
      expect(linkLeaf.recognizer, isA<TapGestureRecognizer>());
    });
  });

  group('LayrzMarkdown — style overrides', () {
    testWidgets('bodyStyleOverride is applied to paragraph text', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const overrideStyle = TextStyle(fontSize: 42);
      await pumpThemed(
        tester,
        const LayrzMarkdown(data: 'Overridden paragraph.', bodyStyleOverride: overrideStyle),
      );

      final richText = _richTextContaining(tester, 'Overridden paragraph.');
      final leaf = _leafTextSpans(richText.text).firstWhere((s) => s.text == 'Overridden paragraph.');
      expect(leaf.style?.fontSize, 42);
    });

    testWidgets('crossAxisAlignment is applied to the root Column', (tester) async {
      tester.view.physicalSize = wideSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzMarkdown(data: 'Text', crossAxisAlignment: CrossAxisAlignment.center),
      );

      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
    });
  });
}
