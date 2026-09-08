import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/search/src/semantics_walker.dart';

import '../helpers/root_semantics_node.dart';

void main() {
  group('walkSemantics', () {
    testWidgets('finds matches across nodes in reading order', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('First mango paragraph'),
              Text('Second paragraph, no fruit here'),
              Text('Third mango and another mango'),
            ],
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();

        final root = rootSemanticsNode();

        final matches = walkSemantics(root, 'mango');

        expect(matches.length, 2);
        expect(matches[0].label, 'First mango paragraph');
        expect(matches[0].hits.length, 1);
        expect(matches[1].label, 'Third mango and another mango');
        expect(matches[1].hits.length, 2);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('returns const [] for an empty or whitespace query', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Anything at all'),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();
        final root = rootSemanticsNode();

        expect(walkSemantics(root, ''), isEmpty);
        expect(walkSemantics(root, '   '), isEmpty);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('excludes nodes hidden via ExcludeSemantics', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visible mango text'),
              ExcludeSemantics(
                child: Text('Excluded mango text'),
              ),
            ],
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();
        final root = rootSemanticsNode();

        final matches = walkSemantics(root, 'mango');

        expect(matches.length, 1);
        expect(matches.single.label, 'Visible mango text');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('includes a scrolled-out-of-view (isHidden) match by default, flagged isHidden', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            controller: controller,
            itemCount: 60,
            itemExtent: 40,
            itemBuilder: (context, index) => Text('Row $index mango marker'),
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();
        final root = rootSemanticsNode();

        // At a 300px viewport with a 40px itemExtent, rows 0-7 are on
        // screen. Flutter's Scrollable also keeps a bounded cache-extent's
        // worth of already-built rows just past the fold (empirically rows
        // 8-13 here) and marks those isHidden rather than dropping their
        // semantics nodes entirely — that is exactly the "built but scrolled
        // out of view" case this walk must still surface. Row 8 is the
        // first such row: on screen it would not exist, but it does, hidden.
        final defaultMatches = walkSemantics(root, 'mango');
        final visibleRow = defaultMatches.firstWhere((m) => m.label.contains('Row 0 '));
        expect(visibleRow.isHidden, isFalse);

        final hiddenMatch = defaultMatches.where((m) => m.label.contains('Row 8 '));
        expect(
          hiddenMatch,
          isNotEmpty,
          reason: 'a built-but-offscreen row must still be returned by default (includeHidden: true)',
        );
        expect(hiddenMatch.single.isHidden, isTrue);

        // includeHidden: false restores the pre-correction "visible only"
        // behavior, for callers that explicitly want it.
        final visibleOnlyMatches = walkSemantics(root, 'mango', includeHidden: false);
        expect(visibleOnlyMatches.any((m) => m.label.contains('Row 8 ')), isFalse);
        expect(visibleOnlyMatches.any((m) => m.label.contains('Row 0 ')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('excludeSubtreeRootIds prunes a node and its descendants', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final excludedKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outer mango paragraph'),
              // `container: true` forces this region to own its own
              // SemanticsNode (a plain Column/RenderFlex creates none of its
              // own — it just lets its children's nodes merge upward), which
              // is what makes `key.currentContext!.findRenderObject()` below
              // resolve to a RenderObject that actually has a
              // `debugSemantics` node to key off — exactly the situation the
              // real find bar's own root widget is in.
              Semantics(
                key: excludedKey,
                container: true,
                explicitChildNodes: true,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find bar mango query text'),
                    Text('Find bar mango counter label'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpAndSettle();
        final root = rootSemanticsNode();

        final unfiltered = walkSemantics(root, 'mango');
        expect(unfiltered.length, 3);

        final excludedRenderObject = excludedKey.currentContext!.findRenderObject()!;
        final excludedId = excludedRenderObject.debugSemantics!.id;

        final filtered = walkSemantics(root, 'mango', excludeSubtreeRootIds: {excludedId});

        expect(filtered.length, 1);
        expect(filtered.single.label, 'Outer mango paragraph');
      } finally {
        handle.dispose();
      }
    });

    // Regression coverage for the DESIGN-* find-in-page highlight-scale bug:
    // walkSemantics used to accumulate the root SemanticsNode's OWN transform
    // (the logical-to-physical devicePixelRatio scale applied by RenderView)
    // into every descendant's globalRect, so at any devicePixelRatio other
    // than 1.0 every match's rect came out `devicePixelRatio` times too large
    // and offset — invisible at DPR 1.0 (scale factor of 1 hides the bug),
    // reproducible at DPR 2.0. The fix seeds the accumulation at the root's
    // children with Matrix4.identity so the root's own transform is excluded.
    //
    // The apples-to-apples check the live-app measurement used: a match's
    // globalRect must equal (to sub-pixel) the backing RenderParagraph's own
    // localToGlobal rect — the same "logical, root-relative" space the render
    // chain and the paint canvas both use — at every devicePixelRatio.
    group('globalRect stays in logical (root-relative) space at any devicePixelRatio', () {
      Future<void> expectGlobalRectMatchesRenderChain(WidgetTester tester, double devicePixelRatio) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = devicePixelRatio;
        addTearDown(tester.view.reset);

        final textKey = GlobalKey();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text('A mango paragraph', key: textKey),
            ),
          ),
        );

        final handle = tester.ensureSemantics();
        try {
          await tester.pumpAndSettle();

          final root = rootSemanticsNode();
          final matches = walkSemantics(root, 'mango');

          expect(matches, hasLength(1));

          final renderParagraph = textKey.currentContext!.findRenderObject()! as RenderBox;
          final renderChainRect = Rect.fromPoints(
            renderParagraph.localToGlobal(Offset.zero),
            renderParagraph.localToGlobal(
              Offset.zero + Offset(renderParagraph.size.width, renderParagraph.size.height),
            ),
          );

          const epsilon = 0.5;
          final semanticsRect = matches.single.globalRect;
          expect(
            (semanticsRect.left - renderChainRect.left).abs(),
            lessThan(epsilon),
            reason: 'left: semantics=$semanticsRect render=$renderChainRect dpr=$devicePixelRatio',
          );
          expect(
            (semanticsRect.top - renderChainRect.top).abs(),
            lessThan(epsilon),
            reason: 'top: semantics=$semanticsRect render=$renderChainRect dpr=$devicePixelRatio',
          );
          expect(
            (semanticsRect.width - renderChainRect.width).abs(),
            lessThan(epsilon),
            reason: 'width: semantics=$semanticsRect render=$renderChainRect dpr=$devicePixelRatio',
          );
          expect(
            (semanticsRect.height - renderChainRect.height).abs(),
            lessThan(epsilon),
            reason: 'height: semantics=$semanticsRect render=$renderChainRect dpr=$devicePixelRatio',
          );
        } finally {
          handle.dispose();
        }
      }

      testWidgets('at devicePixelRatio 1.0 (the pre-fix blind spot)', (tester) async {
        await expectGlobalRectMatchesRenderChain(tester, 1.0);
      });

      testWidgets('at devicePixelRatio 1.5 (web-typical)', (tester) async {
        await expectGlobalRectMatchesRenderChain(tester, 1.5);
      });

      testWidgets('at devicePixelRatio 2.0 (the measured, clearly-broken case)', (tester) async {
        await expectGlobalRectMatchesRenderChain(tester, 2.0);
      });

      testWidgets('at devicePixelRatio 3.0', (tester) async {
        await expectGlobalRectMatchesRenderChain(tester, 3.0);
      });
    });
  });
}
