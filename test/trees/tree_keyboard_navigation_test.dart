import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// A three-level fixture, all expanded, used for most navigation tests:
/// ```
/// Root                (depth 0)
///   Branch A            (depth 1)
///     Leaf A1            (depth 2)
///   Branch B            (depth 1)
/// ```
List<LayrzTreeNode<String>> _expandedThreeLevelTree() => const [
  LayrzTreeNode<String>(
    id: 'root',
    content: 'Root',
    initiallyExpanded: true,
    children: [
      LayrzTreeNode<String>(
        id: 'branch-a',
        content: 'Branch A',
        initiallyExpanded: true,
        children: [LayrzTreeNode<String>(id: 'leaf-a1', content: 'Leaf A1')],
      ),
      LayrzTreeNode<String>(id: 'branch-b', content: 'Branch B'),
    ],
  ),
];

Future<void> _pumpSliverTree(
  WidgetTester tester,
  Widget sliver,
) async {
  await pumpThemed(
    tester,
    SizedBox(
      width: 400,
      height: 600,
      child: CustomScrollView(slivers: [sliver]),
    ),
  );
}

/// Requests keyboard focus on the tree so subsequent [WidgetTester.sendKeyEvent]
/// calls reach [LayrzSliverTreeView]'s own `Focus`/`onKeyEvent` handler rather
/// than being ignored for lack of any focused node.
///
/// `LayrzSliverTreeView` deliberately does not autofocus itself (a tree
/// embedded in a page should not steal keyboard focus unsolicited on mount),
/// so tests exercising keyboard navigation must request focus explicitly --
/// exactly as a real user would by clicking into the tree or tabbing to it.
Future<void> _focusTree(WidgetTester tester) async {
  final focusWidget = tester.widget<Focus>(
    find.byWidgetPredicate((widget) => widget is Focus && widget.focusNode?.debugLabel == 'LayrzSliverTreeView'),
  );
  focusWidget.focusNode!.requestFocus();
  await tester.pump();
}

void main() {
  group('LayrzSliverTreeView keyboard navigation', () {
    guardedTestWidgets('ArrowDown moves the active row to the first row when nothing is active yet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _expandedThreeLevelTree(), controller: controller),
      );
      await _focusTree(tester);

      expect(controller.activeId, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(controller.activeId, 'root');

      // Second half: the newly-active row must actually render differently,
      // not just move an invisible cursor. Proven here via the row's own
      // outline colour -- see tree_row_test.dart for the direct proof that
      // removing `isActive` from the border collapses this to transparent.
      // LayrzTreeRow's own DecoratedBox is the outermost match: the chevron's
      // LayrzTappable also renders a DecoratedBox further down, so `.first`
      // picks the row's own chrome rather than the chevron's.
      final rootRow = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(LayrzTreeRow<String>).first, matching: find.byType(DecoratedBox)).first,
      );
      final rootBorder = (rootRow.decoration as BoxDecoration).border as Border;
      expect(rootBorder.top.color.a, greaterThan(0));
    });

    guardedTestWidgets('ArrowDown moves across visible rows only, skipping collapsed children', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      // Root is expanded but its children (Branch A, Branch B) start
      // collapsed -- Branch A's own child (Leaf A1) must not be reachable by
      // ArrowDown until Branch A itself is expanded.
      final nodes = [
        const LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          initiallyExpanded: true,
          children: [
            LayrzTreeNode<String>(
              id: 'branch-a',
              content: 'Branch A',
              children: [LayrzTreeNode<String>(id: 'leaf-a1', content: 'Leaf A1')],
            ),
            LayrzTreeNode<String>(id: 'branch-b', content: 'Branch B'),
          ],
        ),
      ];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> root
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> branch-a
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> branch-b (leaf-a1 is skipped, hidden)
      await tester.pump();

      expect(controller.activeId, 'branch-b');
    });

    guardedTestWidgets('ArrowUp moves the active row to the previous visible row', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _expandedThreeLevelTree(), controller: controller),
      );
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> root
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> branch-a
      await tester.pump();
      expect(controller.activeId, 'branch-a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); // -> root
      await tester.pump();
      expect(controller.activeId, 'root');
    });

    guardedTestWidgets('ArrowDown/ArrowUp stop at the last/first row rather than wrapping', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final nodes = [
        const LayrzTreeNode<String>(id: 'a', content: 'A'),
        const LayrzTreeNode<String>(id: 'b', content: 'B'),
      ];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> a
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> b
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // stays at b (last row)
      await tester.pump();
      expect(controller.activeId, 'b');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); // -> a
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); // stays at a (first row)
      await tester.pump();
      expect(controller.activeId, 'a');
    });

    guardedTestWidgets('ArrowRight expands a collapsed active row without moving the active id', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final nodes = [
        const LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          children: [LayrzTreeNode<String>(id: 'child', content: 'Child')],
        ),
      ];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> root
      await tester.pump();
      expect(controller.isExpanded('root'), isFalse);
      expect(find.text('Child'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(controller.isExpanded('root'), isTrue);
      expect(controller.activeId, 'root');
      expect(find.text('Child'), findsOneWidget);
    });

    guardedTestWidgets('ArrowRight on an already-expanded row descends into its first child', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _expandedThreeLevelTree(), controller: controller),
      );
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> root
      await tester.pump();
      expect(controller.activeId, 'root');
      expect(controller.isExpanded('root'), isTrue); // already expanded via initiallyExpanded

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.activeId, 'branch-a');
    });

    guardedTestWidgets('ArrowRight on a leaf is a no-op that keeps the active id unchanged', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final nodes = [const LayrzTreeNode<String>(id: 'lone', content: 'Lone leaf')];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> lone
      await tester.pump();
      expect(controller.activeId, 'lone');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.activeId, 'lone');
    });

    guardedTestWidgets('ArrowLeft collapses an expanded active row without moving the active id', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final nodes = [
        const LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          initiallyExpanded: true,
          children: [LayrzTreeNode<String>(id: 'child', content: 'Child')],
        ),
      ];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> root
      await tester.pump();
      expect(controller.isExpanded('root'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(controller.isExpanded('root'), isFalse);
      expect(controller.activeId, 'root');
      expect(find.text('Child'), findsNothing);
    });

    guardedTestWidgets('ArrowLeft on an already-collapsed row ascends to its parent', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _expandedThreeLevelTree(), controller: controller),
      );
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> root
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> branch-a
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> leaf-a1
      await tester.pump();
      expect(controller.activeId, 'leaf-a1');

      // leaf-a1 is a leaf (nothing to collapse), so ArrowLeft ascends to its
      // parent, branch-a, in one step.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(controller.activeId, 'branch-a');
    });

    guardedTestWidgets('ArrowLeft on a root leaf with no parent is a no-op that keeps the active id unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final nodes = [const LayrzTreeNode<String>(id: 'lone', content: 'Lone leaf')];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> lone
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(controller.activeId, 'lone');
    });

    guardedTestWidgets('arrow keys never mutate selection -- moving the active row is not selecting it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);
      final selection = LayrzTreeSelectionController<String>(roots: _expandedThreeLevelTree());
      addTearDown(selection.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _expandedThreeLevelTree(),
          controller: controller,
          selectable: true,
          selectionController: selection,
        ),
      );
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.activeId, isNotNull);
      expect(selection.selectedIds, isEmpty);
    });

    guardedTestWidgets('the newly-active row renders a visible outline while the previously-active row does not', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final nodes = [
        const LayrzTreeNode<String>(id: 'a', content: 'A'),
        const LayrzTreeNode<String>(id: 'b', content: 'B'),
      ];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes, controller: controller));
      await _focusTree(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> a
      await tester.pump();

      Border borderOf(String text) {
        final decoratedBox = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.ancestor(of: find.text(text), matching: find.byType(LayrzTreeRow<String>)),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (decoratedBox.decoration as BoxDecoration).border as Border;
      }

      expect(borderOf('A').top.color.a, greaterThan(0));
      expect(borderOf('B').top.color.a, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> b
      await tester.pump();

      // This is the assertion that would fail if the active-row visual were
      // ever removed while the key handling stayed: the render must move
      // with the active id, row by row.
      expect(borderOf('A').top.color.a, 0);
      expect(borderOf('B').top.color.a, greaterThan(0));
    });

    guardedTestWidgets('the active row is discoverable to assistive tech via focused semantics', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      final handle = tester.ensureSemantics();
      try {
        await _pumpSliverTree(
          tester,
          LayrzSliverTreeView<String>(nodes: _expandedThreeLevelTree(), controller: controller),
        );
        await _focusTree(tester);

        // Root is expandable, so it always carries a tap action for its
        // chevron -- hasExpandedState/isExpanded/hasTapAction are asserted
        // alongside isFocused/isFocusable so this remains a real assertion on
        // the full semantics node, not a subset that would also match a
        // focused-but-otherwise-wrong node.
        expect(
          tester.getSemantics(find.text('Root')),
          matchesSemantics(
            hasExpandedState: true,
            isExpanded: true,
            hasTapAction: true,
            isFocused: false,
            isFocusable: false,
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(
          tester.getSemantics(find.text('Root')),
          matchesSemantics(
            hasExpandedState: true,
            isExpanded: true,
            hasTapAction: true,
            isFocused: true,
            isFocusable: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
