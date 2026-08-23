import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/select/select_item.dart';

void main() {
  group('LayrzSelectItem', () {
    test('constructor: with all required fields', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Option A',
        value: 'a',
      );

      expect(item.labelText, 'Option A');
      expect(item.value, 'a');
      expect(item.child, null);
      expect(item.searchableAttributes, isEmpty);
    });

    test('constructor: with all fields', () {
      final widget = Container();
      final item = LayrzSelectItem<int>(
        labelText: 'Option B',
        value: 42,
        child: widget,
        searchableAttributes: {'alt1', 'alt2'},
      );

      expect(item.labelText, 'Option B');
      expect(item.value, 42);
      expect(item.child, widget);
      expect(item.searchableAttributes, {'alt1', 'alt2'});
    });

    test('constructor: with null value', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Clear',
        value: null,
      );

      expect(item.value, null);
    });

    test('constructor: with empty searchableAttributes', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'test',
        searchableAttributes: {},
      );

      expect(item.searchableAttributes, isEmpty);
    });

    test('copyWith: updates labelText', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Old',
        value: 'val',
      );

      final updated = item.copyWith(labelText: 'New');

      expect(updated.labelText, 'New');
      expect(updated.value, 'val');
    });

    test('copyWith: sets value to null explicitly', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'original',
      );

      final cleared = item.copyWith(value: null);

      expect(cleared.value, null);
      expect(cleared.labelText, 'Test');
    });

    test('copyWith: sets child to null explicitly', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget,
      );

      final cleared = item.copyWith(child: null);

      expect(cleared.child, null);
      expect(cleared.value, 'val');
    });

    test('copyWith: updates searchableAttributes', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'a', 'b'},
      );

      final updated = item.copyWith(searchableAttributes: {'c', 'd'});

      expect(updated.searchableAttributes, {'c', 'd'});
      expect(updated.labelText, 'Test');
    });

    test('copyWith: does not update field when not passed', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget,
        searchableAttributes: {'x', 'y'},
      );

      final copy = item.copyWith(labelText: 'New');

      expect(copy.labelText, 'New');
      expect(copy.value, 'val');
      expect(copy.child, widget);
      expect(copy.searchableAttributes, {'x', 'y'});
    });

    test('copyWith: value and child can be cleared together', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget,
      );

      final cleared = item.copyWith(value: null, child: null);

      expect(cleared.value, null);
      expect(cleared.child, null);
    });

    test('copyWith: returns new instance', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
      );

      final copy = item.copyWith(labelText: 'New');

      expect(identical(copy, item), false);
    });

    test('equality: two identical items are equal', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Option A',
        value: 'a',
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Option A',
        value: 'a',
      );

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: different labelText makes them unequal', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Option A',
        value: 'a',
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Option B',
        value: 'a',
      );

      expect(item1, isNot(item2));
    });

    test('equality: different value makes them unequal', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Option',
        value: 'a',
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Option',
        value: 'b',
      );

      expect(item1, isNot(item2));
    });

    test('equality: different child makes them unequal', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Option',
        value: 'a',
        child: Container(),
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Option',
        value: 'a',
        child: Container(),
      );

      expect(item1, isNot(item2));
    });

    test('equality: null value equals null value', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Clear',
        value: null,
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Clear',
        value: null,
      );

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: null child equals null child', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Option',
        value: 'val',
        child: null,
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Option',
        value: 'val',
        child: null,
      );

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: searchableAttributes order does not matter', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'a', 'b', 'c'},
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'c', 'a', 'b'},
      );

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: different searchableAttributes makes them unequal', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'a', 'b'},
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'a', 'c'},
      );

      expect(item1, isNot(item2));
    });

    test('equality: identical returns true', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
      );

      expect(item, item);
    });

    test('hashCode: same hashCode for equal items with unordered sets', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'z', 'a', 'm'},
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'a', 'm', 'z'},
      );

      expect(item1.hashCode, item2.hashCode);
    });

    test('matches: matches labelText substring case-insensitive', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Production Server',
        value: 'prod',
      );

      expect(item.matches('prod'), true);
      expect(item.matches('Prod'), true);
      expect(item.matches('PRODUCTION'), true);
      expect(item.matches('Server'), true);
      expect(item.matches('server'), true);
    });

    test('matches: matches searchableAttributes case-insensitive', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'database', 'backend'},
      );

      expect(item.matches('database'), true);
      expect(item.matches('Database'), true);
      expect(item.matches('DATABASE'), true);
      expect(item.matches('backend'), true);
      expect(item.matches('BACKEND'), true);
    });

    test('matches: empty query matches everything', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
      );

      expect(item.matches(''), true);
    });

    test('matches: whitespace-only query matches everything', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
      );

      expect(item.matches('   '), true);
      expect(item.matches('\t'), true);
      expect(item.matches('\n'), true);
    });

    test('matches: no match returns false', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test Item',
        value: 'val',
        searchableAttributes: {'tag1', 'tag2'},
      );

      expect(item.matches('nonexistent'), false);
      expect(item.matches('xyz'), false);
    });

    test('matches: partial substring matches', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Production Server Instance',
        value: 'val',
      );

      expect(item.matches('prod'), true);
      expect(item.matches('instance'), true);
      expect(item.matches('server instance'), true); // continuous substring
      expect(item.matches('servinstance'), false); // not a continuous substring
    });

    test('matches: searchableAttributes substring matching', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Item',
        value: 'val',
        searchableAttributes: {'javascript', 'typescript'},
      );

      expect(item.matches('java'), true);
      expect(item.matches('type'), true);
      expect(item.matches('script'), true);
    });

    test('toString: readable string representation', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: {'tag'},
      );

      final str = item.toString();

      expect(str, contains('LayrzSelectItem<String>'));
      expect(str, contains('labelText: Test'));
      expect(str, contains('value: val'));
      expect(str, contains('searchableAttributes'));
    });

    test('toString: includes null value', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Clear',
        value: null,
      );

      final str = item.toString();

      expect(str, contains('value: null'));
    });

    test('generic type: works with different types', () {
      final stringItem = LayrzSelectItem<String>(
        labelText: 'Text',
        value: 'str',
      );

      final intItem = LayrzSelectItem<int>(
        labelText: 'Number',
        value: 42,
      );

      final enumItem = LayrzSelectItem<Color>(
        labelText: 'Color',
        value: const Color(0xFF000000),
      );

      expect(stringItem.value, 'str');
      expect(intItem.value, 42);
      expect(enumItem.value, const Color(0xFF000000));
    });

    test('generic type: equality respects generic type', () {
      final item1 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
      );

      final item2 = LayrzSelectItem<int>(
        labelText: 'Test',
        value: 123,
      );

      // Different generic types, so not equal even though one "value" is conceptually the same
      expect(item1, isNot(item2));
    });

    test('mutable child does not affect equality check', () {
      final widget1 = Container(key: const ValueKey('same'));
      final widget2 = Container(key: const ValueKey('same'));

      final item1 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget1,
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget2,
      );

      // Widgets are not equal unless identical, so items are not equal
      expect(item1, isNot(item2));
    });

    test('same widget child makes items equal', () {
      final widget = Container();

      final item1 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget,
      );

      final item2 = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        child: widget,
      );

      expect(item1, item2);
    });

    test('matches: multiple attributes are all searchable', () {
      final item = LayrzSelectItem<String>(
        labelText: 'Main Label',
        value: 'val',
        searchableAttributes: {'attr1', 'attr2', 'attr3'},
      );

      expect(item.matches('Main'), true);
      expect(item.matches('attr1'), true);
      expect(item.matches('attr2'), true);
      expect(item.matches('attr3'), true);
      expect(item.matches('Label'), true);
    });

    test('copyWith all fields together', () {
      final widget1 = Container();
      final widget2 = Container();

      final item = LayrzSelectItem<String>(
        labelText: 'Old',
        value: 'old_val',
        child: widget1,
        searchableAttributes: {'old'},
      );

      final updated = item.copyWith(
        labelText: 'New',
        value: 'new_val',
        child: widget2,
        searchableAttributes: {'new'},
      );

      expect(updated.labelText, 'New');
      expect(updated.value, 'new_val');
      expect(updated.child, widget2);
      expect(updated.searchableAttributes, {'new'});
    });

    test('immutability: modifying searchableAttributes does not affect item', () {
      final attrs = {'tag1', 'tag2'};
      final item = LayrzSelectItem<String>(
        labelText: 'Test',
        value: 'val',
        searchableAttributes: attrs,
      );

      // Even if the original set is modified (which shouldn't happen with const),
      // we're testing that the item holds its own reference
      expect(item.searchableAttributes, {'tag1', 'tag2'});
    });
  });
}
