import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTreeRow', () {
    guardedTestWidgets('renders its child content', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          child: const Text('Alpha'),
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
    });

    guardedTestWidgets('a leaf row renders no chevron toggle affordance', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var toggled = false;

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          onToggle: () => toggled = true,
          child: const Text('Alpha'),
        ),
      );

      // Even though onToggle is technically supplied here, isLeaf: true is
      // the contract a leaf row is built under in tree_sliver_view.dart
      // (onToggle is always null there for a leaf) — this row still must not
      // expose a tappable chevron for a leaf. There is no chevron icon to tap.
      expect(find.byType(AnimatedRotation), findsNothing);
      expect(toggled, isFalse);
    });

    guardedTestWidgets('a parent row renders a tappable chevron that calls onToggle', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var toggled = false;

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: false,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 1,
          onToggle: () => toggled = true,
          child: const Text('Alpha'),
        ),
      );

      expect(find.byType(AnimatedRotation), findsOneWidget);

      await tester.tap(find.byType(AnimatedRotation));
      await tester.pump();

      expect(toggled, isTrue);
    });

    guardedTestWidgets('no checkbox affordance and no selected-state semantics when onSelect is null', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          LayrzTreeRow<String>(
            node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
            depth: 0,
            isExpanded: false,
            isLeaf: true,
            isSelected: false,
            isPartiallySelected: false,
            totalDepth: 0,
            child: const Text('Alpha'),
          ),
        );

        // hasSelectedState defaults to false in matchesSemantics: with no
        // onSelect, the row must carry no selection semantics at all, not
        // merely report "not selected".
        expect(tester.getSemantics(find.byType(LayrzTreeRow<String>)), matchesSemantics());
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a checkbox affordance appears and toggles selection when onSelect is provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var selected = false;

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 0,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 0,
          onSelect: () => selected = true,
          child: const Text('Alpha'),
        ),
      );

      // The checkbox affordance is the only additional LayrzTappable beyond
      // the (absent, since isLeaf) chevron, so a single tap on it is
      // unambiguous here.
      await tester.tap(find.byType(LayrzTappable));
      await tester.pump();

      expect(selected, isTrue);
    });

    guardedTestWidgets('indentation grows the row width used by deeper nodes', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzTreeRow<String>(
          node: const LayrzTreeNode<String>(id: 'a', content: 'Alpha'),
          depth: 3,
          isExpanded: false,
          isLeaf: true,
          isSelected: false,
          isPartiallySelected: false,
          totalDepth: 3,
          child: const Text('Alpha'),
        ),
      );

      final guide = tester.widget<LayrzTreeIndentGuide>(find.byType(LayrzTreeIndentGuide));
      expect(guide.depth, 3);
    });
  });
}
