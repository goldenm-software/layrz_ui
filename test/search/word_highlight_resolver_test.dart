import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/search/src/find_match.dart';
import 'package:layrz_ui/src/search/src/render_text_walker.dart';
import 'package:layrz_ui/src/search/src/word_highlight_resolver.dart';

/// A standalone, never-attached [RenderObject] used purely so tests can
/// construct a [RenderTextSource] without a real widget tree — these tests
/// exercise [resolveWordHighlights]'s text/geometry logic against
/// hand-written [RenderTextSource]s, and never touch
/// `RenderTextSource.renderObject` itself (that field exists for render-tree
/// ancestry checks a caller like `find_spike.dart`'s diagnostic logging
/// needs, not for this module's own matching logic), so any distinct
/// [RenderObject] instance works as a placeholder.
RenderObject _fakeRenderObject() => RenderErrorBox();

void main() {
  group('resolveWordHighlights', () {
    test('resolves word-level boxes from the matching source, not the whole-node rect', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 20);
      const wordRect = Rect.fromLTWH(0, 0, 40, 20);

      final match = const FindMatch(
        nodeId: 1,
        globalRect: nodeRect,
        label: 'A paragraph mentioning mango here',
        hits: [TextRange(start: 23, end: 28)],
      );

      final source = RenderTextSource(
        plainText: 'A paragraph mentioning mango here',
        globalRect: nodeRect,
        boxesForSelection: (selection) {
          expect(selection.start, 23);
          expect(selection.end, 28);
          return const [wordRect];
        },
        renderObject: _fakeRenderObject(),
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: [source]);

      expect(highlight.isWordLevel, isTrue);
      expect(highlight.rects, [wordRect]);
    });

    test('includes one box per occurrence when the query appears more than once', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 20);
      const firstBox = Rect.fromLTWH(0, 0, 40, 20);
      const secondBox = Rect.fromLTWH(120, 0, 40, 20);

      final match = const FindMatch(
        nodeId: 2,
        globalRect: nodeRect,
        label: 'mango and another mango',
        hits: [TextRange(start: 0, end: 5), TextRange(start: 19, end: 24)],
      );

      final source = RenderTextSource(
        plainText: 'mango and another mango',
        globalRect: nodeRect,
        boxesForSelection: (selection) {
          if (selection.start == 0) return const [firstBox];
          return const [secondBox];
        },
        renderObject: _fakeRenderObject(),
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: [source]);

      expect(highlight.isWordLevel, isTrue);
      expect(highlight.rects, [firstBox, secondBox]);
    });

    test('includes every box for a query that wraps across a line break', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 40);
      const firstLineBox = Rect.fromLTWH(180, 0, 20, 20);
      const secondLineBox = Rect.fromLTWH(0, 20, 20, 20);

      final match = const FindMatch(
        nodeId: 3,
        globalRect: nodeRect,
        label: 'wrapped mango text',
        hits: [TextRange(start: 8, end: 13)],
      );

      final source = RenderTextSource(
        plainText: 'wrapped mango text',
        globalRect: nodeRect,
        boxesForSelection: (_) => const [firstLineBox, secondLineBox],
        renderObject: _fakeRenderObject(),
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: [source]);

      expect(highlight.rects, [firstLineBox, secondLineBox]);
    });

    test('falls back to the whole-node rect when no source resolves against the match', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 20);
      final match = const FindMatch(
        nodeId: 4,
        globalRect: nodeRect,
        label: 'A custom-painted mango label',
        hits: [TextRange(start: 17, end: 22)],
      );

      final farSource = RenderTextSource(
        plainText: 'unrelated text elsewhere',
        globalRect: const Rect.fromLTWH(1000, 1000, 100, 20),
        boxesForSelection: (_) => const [],
        renderObject: _fakeRenderObject(),
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: [farSource]);

      expect(highlight.isWordLevel, isFalse);
      expect(highlight.rects, [nodeRect]);
    });

    test('falls back to the whole-node rect when the source is empty', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 20);
      final match = const FindMatch(
        nodeId: 5,
        globalRect: nodeRect,
        label: 'mango label',
        hits: [TextRange(start: 0, end: 5)],
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: const []);

      expect(highlight.isWordLevel, isFalse);
      expect(highlight.rects, [nodeRect]);
    });

    test('falls back when the resolved source painted text does not contain the query', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 20);
      final match = const FindMatch(
        nodeId: 6,
        globalRect: nodeRect,
        label: 'mango label',
        hits: [TextRange(start: 0, end: 5)],
      );

      // Resolves geometrically (its rect matches), but its painted text
      // genuinely does not contain "mango" as a literal substring — the
      // fallback path, not a crash, is the correct behavior.
      final source = RenderTextSource(
        plainText: 'a completely different sentence',
        globalRect: nodeRect,
        boxesForSelection: (_) => const [Rect.fromLTWH(0, 0, 10, 10)],
        renderObject: _fakeRenderObject(),
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: [source]);

      expect(highlight.isWordLevel, isFalse);
      expect(highlight.rects, [nodeRect]);
    });

    test('is case-insensitive by default, matching walkSemantics default behavior', () {
      const nodeRect = Rect.fromLTWH(0, 0, 200, 20);
      const wordRect = Rect.fromLTWH(0, 0, 40, 20);

      final match = const FindMatch(
        nodeId: 7,
        globalRect: nodeRect,
        label: 'A Mango label',
        hits: [TextRange(start: 2, end: 7)],
      );

      final source = RenderTextSource(
        plainText: 'A Mango label',
        globalRect: nodeRect,
        boxesForSelection: (_) => const [wordRect],
        renderObject: _fakeRenderObject(),
      );

      final highlight = resolveWordHighlights(match: match, query: 'mango', sources: [source]);

      expect(highlight.isWordLevel, isTrue);
      expect(highlight.rects, [wordRect]);
    });
  });

  group('MatchHighlight', () {
    test('equal when rects and isWordLevel match', () {
      const a = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true);
      const b = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when isWordLevel differs', () {
      const a = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true);
      const b = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: false);
      expect(a == b, isFalse);
    });

    test('not equal when rects differ', () {
      const a = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true);
      const b = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 20, 20)], isWordLevel: true);
      expect(a == b, isFalse);
    });

    test('not equal when rects list lengths differ', () {
      const a = MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true);
      const b = MatchHighlight(
        rects: [Rect.fromLTWH(0, 0, 10, 10), Rect.fromLTWH(20, 0, 10, 10)],
        isWordLevel: true,
      );
      expect(a == b, isFalse);
    });
  });
}
