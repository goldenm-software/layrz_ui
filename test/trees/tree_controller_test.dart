import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTreeController — unbound', () {
    test('reports safe defaults before any binding is installed', () {
      final controller = LayrzTreeController();

      expect(controller.isExpanded('a'), isFalse);
      expect(controller.activeId, isNull);
      // These must not throw even with nothing bound.
      controller.expand('a');
      controller.collapse('a');
      controller.toggle('a');
      controller.expandAll();
      controller.collapseAll();
      controller.setActive('a');
    });
  });

  group('LayrzTreeController — bound', () {
    test('forwards every call to the installed binding', () {
      final controller = LayrzTreeController();

      final expandedIds = <Object>{};
      Object? activeId;
      var expandAllCalls = 0;
      var collapseAllCalls = 0;

      controller.bind(
        LayrzTreeControllerBinding(
          isExpanded: expandedIds.contains,
          expand: expandedIds.add,
          collapse: expandedIds.remove,
          toggle: (id) => expandedIds.contains(id) ? expandedIds.remove(id) : expandedIds.add(id),
          expandAll: () => expandAllCalls++,
          collapseAll: () => collapseAllCalls++,
          getActiveId: () => activeId,
          setActive: (id) => activeId = id,
        ),
      );

      controller.expand('a');
      expect(controller.isExpanded('a'), isTrue);

      controller.collapse('a');
      expect(controller.isExpanded('a'), isFalse);

      controller.toggle('a');
      expect(controller.isExpanded('a'), isTrue);

      controller.expandAll();
      expect(expandAllCalls, 1);

      controller.collapseAll();
      expect(collapseAllCalls, 1);

      controller.setActive('a');
      expect(controller.activeId, 'a');
    });

    test('unbind reverts to safe defaults', () {
      final controller = LayrzTreeController();
      controller.bind(
        LayrzTreeControllerBinding(
          isExpanded: (_) => true,
          expand: (_) {},
          collapse: (_) {},
          toggle: (_) {},
          expandAll: () {},
          collapseAll: () {},
          getActiveId: () => 'a',
          setActive: (_) {},
        ),
      );

      expect(controller.isExpanded('a'), isTrue);
      expect(controller.activeId, 'a');

      controller.unbind();

      expect(controller.isExpanded('a'), isFalse);
      expect(controller.activeId, isNull);
    });
  });
}
