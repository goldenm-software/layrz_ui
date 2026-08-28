import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// A three-level fixture used to assert depth ("level X of Y") is announced
/// correctly for a node nested more than one level deep:
/// ```
/// Root                (depth 0)
///   Branch             (depth 1)
///     Leaf             (depth 2)
/// ```
List<LayrzTreeNode<String>> _threeLevelTree() => const [
  LayrzTreeNode<String>(
    id: 'root',
    content: 'Root',
    initiallyExpanded: true,
    children: [
      LayrzTreeNode<String>(
        id: 'branch',
        content: 'Branch',
        initiallyExpanded: true,
        children: [LayrzTreeNode<String>(id: 'leaf', content: 'Leaf')],
      ),
    ],
  ),
];

Future<void> _pumpSliverTree(WidgetTester tester, Widget sliver) async {
  await pumpThemed(
    tester,
    SizedBox(
      width: 400,
      height: 600,
      child: CustomScrollView(slivers: [sliver]),
    ),
  );
}

void main() {
  group('LayrzTreeView / LayrzSliverTreeView accessibility', () {
    guardedTestWidgets('a leaf row announces role and depth with no expansion state', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(
          tester,
          const LayrzSliverTreeView<String>(
            nodes: [LayrzTreeNode<String>(id: 'lone', content: 'Lone leaf')],
          ),
        );

        final semantics = tester.getSemantics(find.text('Lone leaf'));
        expect(semantics.label, contains('Level 1 of 1'));
        // A leaf carries no expansion state at all -- not "collapsed", which
        // would wrongly imply it can be opened. hasExpandedState: false
        // (matchesSemantics' default) is exactly "no expansion state".
        expect(semantics, matchesSemantics(hasExpandedState: false));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a collapsed parent row announces its collapsed expansion state', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(
          tester,
          const LayrzSliverTreeView<String>(
            nodes: [
              LayrzTreeNode<String>(
                id: 'root',
                content: 'Root',
                children: [LayrzTreeNode<String>(id: 'child', content: 'Child')],
              ),
            ],
          ),
        );

        final semantics = tester.getSemantics(find.text('Root'));
        expect(semantics.label, contains('Level 1 of 2'));
        expect(
          semantics,
          matchesSemantics(hasExpandedState: true, isExpanded: false, hasTapAction: true),
        );

        // A collapsed node's child must not be reachable at all yet -- a
        // screen-reader user must not be able to "find" content that isn't
        // actually disclosed, which would contradict the announced collapsed
        // state.
        expect(find.text('Child'), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('an expanded parent row announces its expanded expansion state', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(
          tester,
          const LayrzSliverTreeView<String>(
            nodes: [
              LayrzTreeNode<String>(
                id: 'root',
                content: 'Root',
                initiallyExpanded: true,
                children: [LayrzTreeNode<String>(id: 'child', content: 'Child')],
              ),
            ],
          ),
        );

        final semantics = tester.getSemantics(find.text('Root'));
        expect(
          semantics,
          matchesSemantics(hasExpandedState: true, isExpanded: true, hasTapAction: true),
        );
        expect(find.text('Child'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('depth is announced correctly for a node nested two levels deep', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: _threeLevelTree()));

        // "Level 1 of 3" for the root, "Level 2 of 3" for the branch, and
        // "Level 3 of 3" for the leaf -- depth is stated explicitly rather
        // than left for a screen-reader user to infer from indentation alone,
        // which they cannot see.
        expect(tester.getSemantics(find.text('Root')).label, contains('Level 1 of 3'));
        expect(tester.getSemantics(find.text('Branch')).label, contains('Level 2 of 3'));
        expect(tester.getSemantics(find.text('Leaf')).label, contains('Level 3 of 3'));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a row with selection enabled announces its selected state', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      final selection = LayrzTreeSelectionController<String>(
        roots: const [LayrzTreeNode<String>(id: 'a', content: 'Alpha')],
      );
      addTearDown(selection.dispose);

      try {
        await _pumpSliverTree(
          tester,
          LayrzSliverTreeView<String>(
            nodes: const [LayrzTreeNode<String>(id: 'a', content: 'Alpha')],
            selectable: true,
            selectionController: selection,
          ),
        );

        expect(
          tester.getSemantics(find.text('Alpha')),
          matchesSemantics(hasSelectedState: true, isSelected: false, hasTapAction: true),
        );

        selection.toggle('a');
        await tester.pump();

        expect(
          tester.getSemantics(find.text('Alpha')),
          matchesSemantics(hasSelectedState: true, isSelected: true, hasTapAction: true),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a row carries no selected-state semantics when the tree is not selectable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(
          tester,
          const LayrzSliverTreeView<String>(
            nodes: [LayrzTreeNode<String>(id: 'a', content: 'Alpha')],
          ),
        );

        // hasSelectedState defaults to false: a non-selectable tree must not
        // merely report "not selected" -- it must carry no selection concept
        // at all, since it offers no way to select anything.
        expect(tester.getSemantics(find.text('Alpha')), matchesSemantics(hasSelectedState: false));
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a collapsed row carries an activation hint describing what double-tap does', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(
          tester,
          const LayrzSliverTreeView<String>(
            nodes: [
              LayrzTreeNode<String>(
                id: 'root',
                content: 'Root',
                children: [LayrzTreeNode<String>(id: 'child', content: 'Child')],
              ),
            ],
          ),
        );

        expect(tester.getSemantics(find.text('Root')).hint, contains('expand'));
      } finally {
        handle.dispose();
      }
    });
  });
}
