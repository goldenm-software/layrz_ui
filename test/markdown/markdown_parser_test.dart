import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:layrz_ui/src/markdown/src/markdown_block.dart';
import 'package:layrz_ui/src/markdown/src/markdown_parser.dart';

/// Flattens an inline AST node's text content, for terse assertions on what
/// a block's inline run actually reads as plain text.
String _plainText(List<md.Node> nodes) => nodes.map((n) => n.textContent).join();

void main() {
  group('LayrzMarkdownParser.parseBlocks — headings', () {
    for (var level = 1; level <= 6; level++) {
      test('parses a level-$level heading with the correct level', () {
        final hashes = '#' * level;
        final blocks = LayrzMarkdownParser.parseBlocks('$hashes Heading $level');

        expect(blocks, hasLength(1));
        final block = blocks.single;
        expect(block, isA<LayrzMarkdownHeadingBlock>());
        final heading = block as LayrzMarkdownHeadingBlock;
        expect(heading.level, level);
        expect(_plainText(heading.inlineNodes), 'Heading $level');
      });
    }
  });

  group('LayrzMarkdownParser.parseBlocks — paragraph and lists', () {
    test('parses a plain paragraph', () {
      final blocks = LayrzMarkdownParser.parseBlocks('Just a paragraph of text.');

      expect(blocks, hasLength(1));
      expect(blocks.single, isA<LayrzMarkdownParagraphBlock>());
      final paragraph = blocks.single as LayrzMarkdownParagraphBlock;
      expect(_plainText(paragraph.inlineNodes), 'Just a paragraph of text.');
    });

    test('parses an unordered list with each item as a paragraph block', () {
      final blocks = LayrzMarkdownParser.parseBlocks('- one\n- two\n- three');

      expect(blocks, hasLength(1));
      expect(blocks.single, isA<LayrzMarkdownUnorderedListBlock>());
      final list = blocks.single as LayrzMarkdownUnorderedListBlock;
      expect(list.level, 0);
      expect(list.items, hasLength(3));

      final texts = list.items.map((item) {
        final paragraph = item.nestedBlocks.single as LayrzMarkdownParagraphBlock;
        return _plainText(paragraph.inlineNodes);
      }).toList();
      expect(texts, ['one', 'two', 'three']);
    });

    test('parses an ordered list with a non-1 start', () {
      final blocks = LayrzMarkdownParser.parseBlocks('3. third\n4. fourth\n5. fifth');

      expect(blocks, hasLength(1));
      expect(blocks.single, isA<LayrzMarkdownOrderedListBlock>());
      final list = blocks.single as LayrzMarkdownOrderedListBlock;
      expect(list.start, 3);
      expect(list.level, 0);
      expect(list.items, hasLength(3));
    });

    test('defaults an ordered list with no explicit start to 1', () {
      final blocks = LayrzMarkdownParser.parseBlocks('1. first\n2. second');

      final list = blocks.single as LayrzMarkdownOrderedListBlock;
      expect(list.start, 1);
    });

    test('a nested list increments the level of the inner list', () {
      final blocks = LayrzMarkdownParser.parseBlocks('- outer one\n  - inner one\n  - inner two\n- outer two');

      expect(blocks, hasLength(1));
      final outerList = blocks.single as LayrzMarkdownUnorderedListBlock;
      expect(outerList.level, 0);
      expect(outerList.items, hasLength(2));

      // The first outer item's nested blocks contain its own paragraph plus
      // the nested inner list, which must carry level 1.
      final firstItemBlocks = outerList.items.first.nestedBlocks;
      final nestedList = firstItemBlocks.whereType<LayrzMarkdownUnorderedListBlock>().single;
      expect(nestedList.level, 1);
      expect(nestedList.items, hasLength(2));
    });

    test('a nested ordered list under an unordered item also increments level', () {
      final blocks = LayrzMarkdownParser.parseBlocks('- outer\n  1. inner one\n  2. inner two');

      final outerList = blocks.single as LayrzMarkdownUnorderedListBlock;
      final firstItemBlocks = outerList.items.first.nestedBlocks;
      final nestedList = firstItemBlocks.whereType<LayrzMarkdownOrderedListBlock>().single;
      expect(nestedList.level, 1);
      expect(nestedList.start, 1);
    });
  });

  group('LayrzMarkdownParser.parseBlocks — fenced code', () {
    test('parses a fenced code block with its info string', () {
      final blocks = LayrzMarkdownParser.parseBlocks('```python\nprint("hi")\n```');

      expect(blocks, hasLength(1));
      expect(blocks.single, isA<LayrzMarkdownCodeFenceBlock>());
      final fence = blocks.single as LayrzMarkdownCodeFenceBlock;
      expect(fence.infoString, 'python');
      expect(fence.code, 'print("hi")');
    });

    test('parses a fenced code block with no info string as null', () {
      final blocks = LayrzMarkdownParser.parseBlocks('```\nplain\n```');

      final fence = blocks.single as LayrzMarkdownCodeFenceBlock;
      expect(fence.infoString, isNull);
      expect(fence.code, 'plain');
    });

    test('preserves multi-line code content inside the fence', () {
      final blocks = LayrzMarkdownParser.parseBlocks('```python\nline one\nline two\n```');

      final fence = blocks.single as LayrzMarkdownCodeFenceBlock;
      expect(fence.code, 'line one\nline two');
    });
  });

  group('LayrzMarkdownParser.parseBlocks — raw HTML is dropped', () {
    test('a <script> tag produces no heading/paragraph element from the tag', () {
      final blocks = LayrzMarkdownParser.parseBlocks('<script>alert(1)</script>');

      // The raw HTML block is dropped entirely by the whitelist-by-tag
      // walker — it must never surface as a rendered element.
      for (final block in blocks) {
        expect(block, isNot(isA<LayrzMarkdownHeadingBlock>()));
      }
      // No block should carry the script's inline JS as recognized element
      // content (i.e. nothing wraps it in a heading/paragraph/list/etc. that
      // would render it as markup).
      final hasScriptElementBlock = blocks.any(
        (b) => b is LayrzMarkdownParagraphBlock && _plainText(b.inlineNodes).contains('<script>'),
      );
      expect(hasScriptElementBlock, isFalse);
    });

    test('a <b>hi</b> raw HTML inline tag is not rendered as a bold element', () {
      final blocks = LayrzMarkdownParser.parseBlocks('<b>hi</b>');

      // package:markdown treats a standalone `<b>hi</b>` line as an inline
      // HTML run inside an ordinary paragraph — it surfaces as the literal
      // text "<b>hi</b>", never as an actual bold/strong inline node. So the
      // only block produced is a plain paragraph, and its inline content
      // must never include a `strong`/`b`-tagged element (which would mean
      // the tag was interpreted as markup rather than displayed literally).
      expect(blocks, hasLength(1));
      final paragraph = blocks.single as LayrzMarkdownParagraphBlock;
      expect(_plainText(paragraph.inlineNodes), '<b>hi</b>');
      final hasElementNode = paragraph.inlineNodes.any((n) => n is md.Element);
      expect(hasElementNode, isFalse, reason: 'the tag must never be parsed into a real element node');
    });

    test('an <img> tag with an event-handler attribute produces no element block', () {
      final blocks = LayrzMarkdownParser.parseBlocks('<img src=x onerror=y>');

      expect(blocks, isEmpty);
    });

    test('raw HTML mixed with real paragraphs only drops the HTML, keeps the paragraphs', () {
      final blocks = LayrzMarkdownParser.parseBlocks('Before\n\n<div>raw</div>\n\nAfter');

      final paragraphs = blocks.whereType<LayrzMarkdownParagraphBlock>().map((p) => _plainText(p.inlineNodes));
      expect(paragraphs, containsAll(['Before', 'After']));
      // No block should be a heading or list constructed from the raw <div>.
      for (final block in blocks) {
        expect(block, isNot(isA<LayrzMarkdownHeadingBlock>()));
      }
    });
  });

  group('LayrzMarkdownParser.parseBlocks — empty and whitespace input', () {
    test('an empty string produces no blocks and does not throw', () {
      expect(() => LayrzMarkdownParser.parseBlocks(''), returnsNormally);
      final blocks = LayrzMarkdownParser.parseBlocks('');
      expect(blocks, isEmpty);
    });

    test('a whitespace-only string produces no blocks and does not throw', () {
      expect(() => LayrzMarkdownParser.parseBlocks('   \n\n\t  \n'), returnsNormally);
      final blocks = LayrzMarkdownParser.parseBlocks('   \n\n\t  \n');
      expect(blocks, isEmpty);
    });
  });

  group('LayrzMarkdownParser.parseBlocks — malformed input is stable', () {
    test('an unclosed bold marker does not throw and produces a paragraph', () {
      expect(() => LayrzMarkdownParser.parseBlocks('**bold'), returnsNormally);
      final blocks = LayrzMarkdownParser.parseBlocks('**bold');

      expect(blocks, hasLength(1));
      expect(blocks.single, isA<LayrzMarkdownParagraphBlock>());
      final paragraph = blocks.single as LayrzMarkdownParagraphBlock;
      // The literal, unrendered marker text must still be present somewhere
      // in the parsed content rather than silently vanishing.
      expect(_plainText(paragraph.inlineNodes), contains('bold'));
    });

    test('an unterminated fence does not throw and produces a stable block', () {
      expect(() => LayrzMarkdownParser.parseBlocks('```python\nprint(1)'), returnsNormally);
      final blocks = LayrzMarkdownParser.parseBlocks('```python\nprint(1)');

      expect(blocks, hasLength(1));
      expect(blocks.single, isA<LayrzMarkdownCodeFenceBlock>());
      final fence = blocks.single as LayrzMarkdownCodeFenceBlock;
      expect(fence.infoString, 'python');
      expect(fence.code, contains('print(1)'));
    });

    test('parsing the same malformed input twice yields structurally identical blocks', () {
      const source = '**bold\n\n```js\nunterminated';
      final first = LayrzMarkdownParser.parseBlocks(source);
      final second = LayrzMarkdownParser.parseBlocks(source);

      expect(first.length, second.length);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].runtimeType, second[i].runtimeType);
      }
    });
  });

  group('LayrzMarkdownParser.splitForStreaming — isStreaming: false', () {
    test('commits every block and leaves pending null', () {
      const source = '# Title\n\nSome paragraph text.\n\n```python\nprint(1)\n```';
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming(source, isStreaming: false);

      expect(pending, isNull);
      expect(committed, hasLength(3));
      expect(committed[0], isA<LayrzMarkdownHeadingBlock>());
      expect(committed[1], isA<LayrzMarkdownParagraphBlock>());
      expect(committed[2], isA<LayrzMarkdownCodeFenceBlock>());
    });

    test('an unterminated fence is still fully committed when not streaming', () {
      const source = '```python\nprint(1)';
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming(source, isStreaming: false);

      expect(pending, isNull);
      expect(committed, hasLength(1));
      expect(committed.single, isA<LayrzMarkdownCodeFenceBlock>());
    });
  });

  group('LayrzMarkdownParser.splitForStreaming — isStreaming: true', () {
    test('a trailing unterminated fence becomes the pending block', () {
      const source = 'Finished paragraph.\n\n```python\nprint("still typing"';
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming(source, isStreaming: true);

      expect(committed, hasLength(1));
      expect(committed.single, isA<LayrzMarkdownParagraphBlock>());

      expect(pending, isNotNull);
      expect(pending, isA<LayrzMarkdownPendingBlock>());
      final pendingBlock = pending! as LayrzMarkdownPendingBlock;
      expect(pendingBlock.inner, isA<LayrzMarkdownCodeFenceBlock>());
      final fence = pendingBlock.inner! as LayrzMarkdownCodeFenceBlock;
      expect(fence.infoString, 'python');
    });

    test('source not ending in a newline holds the last block back as pending', () {
      const source = '# Title\n\nA finished paragraph.\n\nAn unfinished line without trailing newline';
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming(source, isStreaming: true);

      expect(committed, hasLength(2));
      expect(committed[0], isA<LayrzMarkdownHeadingBlock>());
      expect(committed[1], isA<LayrzMarkdownParagraphBlock>());

      expect(pending, isNotNull);
      final pendingBlock = pending! as LayrzMarkdownPendingBlock;
      expect(pendingBlock.inner, isA<LayrzMarkdownParagraphBlock>());
      final innerParagraph = pendingBlock.inner! as LayrzMarkdownParagraphBlock;
      expect(_plainText(innerParagraph.inlineNodes), contains('unfinished line'));
    });

    test('source ending with a newline commits everything with no pending block', () {
      const source = '# Title\n\nA complete paragraph.\n';
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming(source, isStreaming: true);

      expect(pending, isNull);
      expect(committed, hasLength(2));
    });

    test('an empty source while streaming produces no blocks and no pending, without throwing', () {
      expect(() => LayrzMarkdownParser.splitForStreaming('', isStreaming: true), returnsNormally);
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming('', isStreaming: true);

      expect(committed, isEmpty);
      expect(pending, isNull);
    });

    test('a blank line inside an open fence does not split the fence into two segments', () {
      const source = '```python\nline one\n\nline two\n```\n';
      final (committed, pending) = LayrzMarkdownParser.splitForStreaming(source, isStreaming: true);

      expect(pending, isNull);
      expect(committed, hasLength(1));
      final fence = committed.single as LayrzMarkdownCodeFenceBlock;
      expect(fence.code, contains('line one'));
      expect(fence.code, contains('line two'));
    });

    test('feeding progressive prefixes of a document never throws', () {
      const fullDocument =
          '# Heading\n\nA paragraph of text that keeps going.\n\n'
          '- item one\n- item two\n\n'
          '```python\ndef f():\n    return 1\n```\n\n'
          'Trailing paragraph.';

      for (var i = 1; i <= fullDocument.length; i++) {
        final prefix = fullDocument.substring(0, i);
        expect(
          () => LayrzMarkdownParser.splitForStreaming(prefix, isStreaming: true),
          returnsNormally,
          reason: 'prefix of length $i: "$prefix"',
        );
      }
    });
  });
}
