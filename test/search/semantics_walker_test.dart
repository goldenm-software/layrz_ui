import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/search/src/semantics_walker.dart';

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

        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

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
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

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
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

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
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

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
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

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
  });
}
