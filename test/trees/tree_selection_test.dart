import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTreeSelectionController — independent mode', () {
    late List<LayrzTreeNode<String>> roots;

    setUp(() {
      roots = const [
        LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          children: [
            LayrzTreeNode<String>(id: 'child-1', content: 'Child 1'),
            LayrzTreeNode<String>(id: 'child-2', content: 'Child 2'),
          ],
        ),
      ];
    });

    test('defaults to LayrzTreeSelectionMode.independent', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      expect(controller.mode, LayrzTreeSelectionMode.independent);
    });

    test('selecting a parent does not select its children', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);

      controller.toggle('root');

      expect(controller.isSelected('root'), isTrue);
      expect(controller.isSelected('child-1'), isFalse);
      expect(controller.isSelected('child-2'), isFalse);
    });

    test('selecting a child does not affect the parent', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);

      controller.toggle('child-1');

      expect(controller.isSelected('child-1'), isTrue);
      expect(controller.isSelected('root'), isFalse);
    });

    test('never reports partial selection in independent mode', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);

      controller.toggle('child-1');

      expect(controller.isPartiallySelected('root'), isFalse);
    });

    test('toggle is a true toggle: selecting twice deselects', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);

      controller.toggle('child-1');
      controller.toggle('child-1');

      expect(controller.isSelected('child-1'), isFalse);
    });

    test('clear empties the selection', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);

      controller.toggle('child-1');
      controller.toggle('child-2');
      controller.clear();

      expect(controller.selectedIds, isEmpty);
    });

    test('notifies listeners on toggle and on clear', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.toggle('child-1');
      expect(notifications, 1);

      controller.clear();
      expect(notifications, 2);
    });

    test('clear on an already-empty selection does not notify', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.clear();

      expect(notifications, 0);
    });

    test('toggling an unknown id is a no-op', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.toggle('does-not-exist');

      expect(controller.selectedIds, isEmpty);
      expect(notifications, 0);
    });

    test('selectedIds is unmodifiable', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      controller.toggle('child-1');

      expect(() => controller.selectedIds.add('x'), throwsUnsupportedError);
    });

    test('honours initialSelectedIds', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        initialSelectedIds: {'child-1'},
      );

      expect(controller.isSelected('child-1'), isTrue);
      expect(controller.isSelected('child-2'), isFalse);
    });

    test('setting mode to the same value does not notify', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.mode = LayrzTreeSelectionMode.independent;

      expect(notifications, 0);
    });

    test('setting mode to a new value notifies', () {
      final controller = LayrzTreeSelectionController<String>(roots: roots);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.mode = LayrzTreeSelectionMode.cascading;

      expect(notifications, 1);
      expect(controller.mode, LayrzTreeSelectionMode.cascading);
    });
  });

  group('LayrzTreeSelectionController — cascading mode', () {
    late List<LayrzTreeNode<String>> roots;

    setUp(() {
      roots = const [
        LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          children: [
            LayrzTreeNode<String>(
              id: 'branch',
              content: 'Branch',
              children: [
                LayrzTreeNode<String>(id: 'leaf-1', content: 'Leaf 1'),
                LayrzTreeNode<String>(id: 'leaf-2', content: 'Leaf 2'),
              ],
            ),
            LayrzTreeNode<String>(id: 'leaf-3', content: 'Leaf 3'),
          ],
        ),
      ];
    });

    test('selecting a parent selects every descendant', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('branch');

      expect(controller.isSelected('branch'), isTrue);
      expect(controller.isSelected('leaf-1'), isTrue);
      expect(controller.isSelected('leaf-2'), isTrue);
      // Sibling of the toggled subtree must be unaffected.
      expect(controller.isSelected('leaf-3'), isFalse);
    });

    test('selecting the root selects the entire tree', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('root');

      expect(controller.isSelected('root'), isTrue);
      expect(controller.isSelected('branch'), isTrue);
      expect(controller.isSelected('leaf-1'), isTrue);
      expect(controller.isSelected('leaf-2'), isTrue);
      expect(controller.isSelected('leaf-3'), isTrue);
    });

    test('deselecting a parent deselects every descendant', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('branch');
      controller.toggle('branch');

      expect(controller.isSelected('branch'), isFalse);
      expect(controller.isSelected('leaf-1'), isFalse);
      expect(controller.isSelected('leaf-2'), isFalse);
    });

    test('selecting all children fully selects the parent', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('leaf-1');
      controller.toggle('leaf-2');

      expect(controller.isSelected('branch'), isTrue);
      expect(controller.isPartiallySelected('branch'), isFalse);
    });

    test('selecting only one of two children reports the parent as partially selected', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('leaf-1');

      expect(controller.isSelected('branch'), isFalse);
      expect(controller.isPartiallySelected('branch'), isTrue);
    });

    test('a partially-selected branch propagates partial state up to the root', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('leaf-1');

      // 'root' has one fully-selected-or-partial descendant subtree (branch,
      // partial) and one untouched leaf (leaf-3), so root itself is neither
      // fully selected nor unselected — it must read as partial too.
      expect(controller.isSelected('root'), isFalse);
      expect(controller.isPartiallySelected('root'), isTrue);
    });

    test('fully selecting the whole tree leaves no node partially selected', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('root');

      expect(controller.isPartiallySelected('root'), isFalse);
      expect(controller.isPartiallySelected('branch'), isFalse);
    });

    test('a leaf node is never reported as partially selected', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      expect(controller.isPartiallySelected('leaf-1'), isFalse);
    });

    test('re-selecting the parent after a partial state fully selects the remaining child', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      controller.toggle('leaf-1');
      expect(controller.isPartiallySelected('branch'), isTrue);

      controller.toggle('branch');

      expect(controller.isSelected('branch'), isTrue);
      expect(controller.isSelected('leaf-1'), isTrue);
      expect(controller.isSelected('leaf-2'), isTrue);
    });

    test('updateRoots lets the controller resolve descendants of a replaced tree shape', () {
      final controller = LayrzTreeSelectionController<String>(
        roots: roots,
        mode: LayrzTreeSelectionMode.cascading,
      );

      final newRoots = [
        const LayrzTreeNode<String>(
          id: 'root',
          content: 'Root',
          children: [
            LayrzTreeNode<String>(id: 'new-leaf', content: 'New leaf'),
          ],
        ),
      ];
      controller.updateRoots(newRoots);
      controller.toggle('new-leaf');

      expect(controller.isSelected('root'), isTrue);
    });
  });
}
