import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// The tree fixture shared by most tests below:
/// ```
/// Root
///   Child A
///   Child B
/// ```
List<LayrzTreeNode<String>> _twoLevelTree() => const [
  LayrzTreeNode<String>(
    id: 'root',
    content: 'Root',
    children: [
      LayrzTreeNode<String>(id: 'child-a', content: 'Child A'),
      LayrzTreeNode<String>(id: 'child-b', content: 'Child B'),
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

/// Like [_pumpSliverTree], but calls [WidgetTester.pumpWidget] directly
/// instead of going through [pumpThemed].
///
/// [pumpThemed] wraps its child in a brand-new [OverlayEntry] on every call,
/// which is essential for widgets needing an [Overlay] (e.g. [RawTooltip]),
/// but a *new* [OverlayEntry] identity on a second call makes [Overlay]
/// treat the whole subtree as freshly mounted rather than updated -- so
/// [State.didUpdateWidget] never fires and tests exercising it
/// (`didUpdateWidget`'s node-diffing / controller-rebinding logic) would
/// silently test nothing. This tree module renders no tooltips and needs no
/// [Overlay], so pumping directly through the same [LayrzTheme] subtree
/// across repeated calls is both correct and what actually exercises
/// [State.didUpdateWidget].
Future<void> _repumpSliverTree(
  WidgetTester tester,
  Widget sliver,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: SizedBox(
          width: 400,
          height: 600,
          child: CustomScrollView(slivers: [sliver]),
        ),
      ),
    ),
  );
}

void main() {
  group('LayrzSliverTreeView', () {
    guardedTestWidgets('renders root nodes and starts collapsed', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree()),
      );

      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Child A'), findsNothing);
      expect(find.text('Child B'), findsNothing);
    });

    guardedTestWidgets('a node with initiallyExpanded: true starts with children visible', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final nodes = [
        const LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          initiallyExpanded: true,
          children: [LayrzTreeNode<String>(id: 'child-a', content: 'Child A')],
        ),
      ];

      await _pumpSliverTree(tester, LayrzSliverTreeView<String>(nodes: nodes));

      expect(find.text('Child A'), findsOneWidget);
    });

    guardedTestWidgets('tapping the chevron expands and reveals children', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree()),
      );

      expect(find.text('Child A'), findsNothing);

      await tester.tap(find.byType(AnimatedRotation));
      await tester.pumpAndSettle();

      expect(find.text('Child A'), findsOneWidget);
      expect(find.text('Child B'), findsOneWidget);
    });

    guardedTestWidgets('a leaf node renders no chevron', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpSliverTree(
        tester,
        const LayrzSliverTreeView<String>(
          nodes: [LayrzTreeNode<String>(id: 'lone', content: 'Lone leaf')],
        ),
      );

      expect(find.text('Lone leaf'), findsOneWidget);
      expect(find.byType(AnimatedRotation), findsNothing);
    });

    guardedTestWidgets('selectable: false renders no selection affordance even with a selectionController', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selection = LayrzTreeSelectionController<String>(roots: _twoLevelTree());
      addTearDown(selection.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectionController: selection,
        ),
      );

      // No checkbox tap target beyond the chevron itself should exist.
      expect(find.byType(LayrzTappable), findsOneWidget); // the chevron only
    });

    guardedTestWidgets('selectable: true renders a checkbox affordance and toggles selection on tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Set<Object> lastSelection = {};

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          onSelectionChanged: (ids) => lastSelection = ids,
        ),
      );

      // Two LayrzTappables on the root row: the chevron and the checkbox.
      expect(find.byType(LayrzTappable), findsNWidgets(2));

      await tester.tap(find.byType(LayrzTappable).last);
      await tester.pump();

      expect(lastSelection, {'root'});
    });

    guardedTestWidgets('independent selection mode does not select children when a parent is selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selection = LayrzTreeSelectionController<String>(roots: _twoLevelTree());
      addTearDown(selection.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          selectionController: selection,
        ),
      );

      selection.toggle('root');
      await tester.pump();

      // Expand to check the children were not swept in.
      await tester.tap(find.byType(AnimatedRotation));
      await tester.pumpAndSettle();

      expect(selection.isSelected('root'), isTrue);
      expect(selection.isSelected('child-a'), isFalse);
      expect(selection.isSelected('child-b'), isFalse);
    });

    guardedTestWidgets('cascading selection mode selects children when a parent is selected', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selection = LayrzTreeSelectionController<String>(
        roots: _twoLevelTree(),
        mode: LayrzTreeSelectionMode.cascading,
      );
      addTearDown(selection.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          selectionController: selection,
        ),
      );

      selection.toggle('root');
      await tester.pump();

      expect(selection.isSelected('root'), isTrue);
      expect(selection.isSelected('child-a'), isTrue);
      expect(selection.isSelected('child-b'), isTrue);
    });

    guardedTestWidgets('a partially-selected cascading parent renders the indeterminate checkbox glyph', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selection = LayrzTreeSelectionController<String>(
        roots: _twoLevelTree(),
        mode: LayrzTreeSelectionMode.cascading,
      );
      addTearDown(selection.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          selectionController: selection,
        ),
      );

      selection.toggle('child-a');
      await tester.pump();

      expect(selection.isSelected('root'), isFalse);
      expect(selection.isPartiallySelected('root'), isTrue);

      final row = tester.widget<LayrzTreeRow<String>>(find.byType(LayrzTreeRow<String>).first);
      expect(row.isPartiallySelected, isTrue);
      expect(row.isSelected, isFalse);
    });

    guardedTestWidgets('a custom nodeBuilder is used for row content', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          nodeBuilder: (context, node, depth, isExpanded, isLeaf, isSelected, isPartiallySelected, onToggle, onSelect) {
            return Text('custom:${node.content}');
          },
        ),
      );

      expect(find.text('custom:Root'), findsOneWidget);
      expect(find.text('Root'), findsNothing);
    });

    guardedTestWidgets('LayrzTreeController.expandAll/collapseAll drive the tree programmatically', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree(), controller: controller),
      );

      expect(find.text('Child A'), findsNothing);

      controller.expandAll();
      await tester.pumpAndSettle();

      expect(find.text('Child A'), findsOneWidget);

      controller.collapseAll();
      await tester.pumpAndSettle();

      expect(find.text('Child A'), findsNothing);
    });

    guardedTestWidgets('LayrzTreeController.toggle expands and collapses a specific node by id', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree(), controller: controller),
      );

      expect(controller.isExpanded('root'), isFalse);

      controller.toggle('root');
      await tester.pumpAndSettle();

      expect(controller.isExpanded('root'), isTrue);
      expect(find.text('Child A'), findsOneWidget);
    });

    guardedTestWidgets('LayrzTreeController.expand/collapse/isExpanded drive a specific node by id', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree(), controller: controller),
      );

      expect(controller.isExpanded('root'), isFalse);

      controller.expand('root');
      await tester.pumpAndSettle();

      expect(controller.isExpanded('root'), isTrue);
      expect(find.text('Child A'), findsOneWidget);

      // Expanding an already-expanded node is a no-op, not a toggle back to
      // collapsed -- unlike toggle, expand must be idempotent.
      controller.expand('root');
      await tester.pumpAndSettle();
      expect(controller.isExpanded('root'), isTrue);

      controller.collapse('root');
      await tester.pumpAndSettle();

      expect(controller.isExpanded('root'), isFalse);
      expect(find.text('Child A'), findsNothing);

      // Collapsing an already-collapsed node is a no-op too.
      controller.collapse('root');
      await tester.pumpAndSettle();
      expect(controller.isExpanded('root'), isFalse);
    });

    guardedTestWidgets('expand/collapse/toggle/isExpanded for an id that does not exist are safe no-ops', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzTreeController();
      addTearDown(controller.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree(), controller: controller),
      );

      expect(controller.isExpanded('does-not-exist'), isFalse);
      controller.expand('does-not-exist');
      controller.collapse('does-not-exist');
      controller.toggle('does-not-exist');
      await tester.pumpAndSettle();

      expect(controller.isExpanded('root'), isFalse);
    });

    guardedTestWidgets('a node three levels deep is found and toggled correctly by id', (tester) async {
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

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: nodes, controller: controller),
      );

      expect(find.text('Leaf'), findsOneWidget);
      expect(controller.isExpanded('branch'), isTrue);

      controller.toggle('branch');
      await tester.pumpAndSettle();

      expect(controller.isExpanded('branch'), isFalse);
      expect(find.text('Leaf'), findsNothing);
    });

    guardedTestWidgets('replacing the nodes list rebuilds the SDK tree and preserves the selection controller', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selection = LayrzTreeSelectionController<String>(roots: _twoLevelTree());
      addTearDown(selection.dispose);

      await _repumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          selectionController: selection,
        ),
      );

      final newNodes = [
        const LayrzTreeNode<String>(id: 'root', content: 'Root', initiallyExpanded: true),
      ];

      await _repumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: newNodes,
          selectable: true,
          selectionController: selection,
        ),
      );

      // The old tree's children are gone; the new (leaf) root is present.
      expect(find.text('Child A'), findsNothing);
      expect(find.text('Root'), findsOneWidget);

      // The same selection controller instance is still wired up and
      // resolves against the new tree shape (via updateRoots).
      selection.toggle('root');
      await tester.pump();
      expect(selection.isSelected('root'), isTrue);
    });

    guardedTestWidgets('replacing an internally-created selectionController re-wires the listener', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // No selectionController is passed here, so LayrzSliverTreeView owns
      // its own internal LayrzTreeSelectionController across both pumps --
      // this exercises the didUpdateWidget branch where
      // oldWidget.selectionController != widget.selectionController
      // (both null, an internal one behind each) is false, i.e. the ordinary
      // "nothing changed" path through that comparison.
      Set<Object> lastSelection = {};

      await _repumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          onSelectionChanged: (ids) => lastSelection = ids,
        ),
      );

      await _repumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(
          nodes: _twoLevelTree(),
          selectable: true,
          onSelectionChanged: (ids) => lastSelection = ids,
        ),
      );

      await tester.tap(find.byType(LayrzTappable).last);
      await tester.pump();

      expect(lastSelection, {'root'});
    });

    testWidgets('changing controller instance between builds asserts', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controllerA = LayrzTreeController();
      final controllerB = LayrzTreeController();
      addTearDown(controllerA.dispose);
      addTearDown(controllerB.dispose);

      await _pumpSliverTree(
        tester,
        LayrzSliverTreeView<String>(nodes: _twoLevelTree(), controller: controllerA),
      );

      await tester.pumpWidget(
        SizedBox(
          width: 400,
          height: 600,
          child: CustomScrollView(
            slivers: [LayrzSliverTreeView<String>(nodes: _twoLevelTree(), controller: controllerB)],
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}
