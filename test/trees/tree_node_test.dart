import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTreeNode', () {
    test('exposes id, content, children, and initiallyExpanded', () {
      const node = LayrzTreeNode<String>(
        id: 'a',
        content: 'Alpha',
        children: [LayrzTreeNode<String>(id: 'b', content: 'Beta')],
        initiallyExpanded: true,
      );

      expect(node.id, 'a');
      expect(node.content, 'Alpha');
      expect(node.children, hasLength(1));
      expect(node.initiallyExpanded, isTrue);
    });

    test('defaults to no children and collapsed', () {
      const node = LayrzTreeNode<String>(id: 'a', content: 'Alpha');

      expect(node.children, isEmpty);
      expect(node.initiallyExpanded, isFalse);
    });

    test('equality and hashCode are based solely on id', () {
      const first = LayrzTreeNode<String>(id: 'a', content: 'One');
      const second = LayrzTreeNode<String>(id: 'a', content: 'Different content');
      const third = LayrzTreeNode<String>(id: 'b', content: 'One');

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first, isNot(equals(third)));
    });

    test('identical instances are equal', () {
      const node = LayrzTreeNode<String>(id: 'a', content: 'Alpha');
      // ignore: prefer_const_declarations
      final sameNode = node;

      expect(identical(node, sameNode), isTrue);
      expect(node, equals(sameNode));
    });

    test('is not equal to a non-LayrzTreeNode object', () {
      const node = LayrzTreeNode<String>(id: 'a', content: 'Alpha');

      // ignore: unrelated_type_equality_checks
      expect(node == 'a', isFalse);
    });
  });
}
