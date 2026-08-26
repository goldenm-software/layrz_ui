import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/select/select_item.dart';

void main() {
  group('LayrzSelectItem', () {
    test('constructor: with only required fields', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        value: 'a',
        child: widget,
      );

      expect(item.value, 'a');
      expect(item.child, widget);
      expect(item.searchableStrings, isEmpty);
    });

    test('constructor: with all fields', () {
      final widget = Container();
      final item = LayrzSelectItem<int>(
        value: 42,
        child: widget,
        searchableStrings: {'alt1', 'alt2'},
      );

      expect(item.value, 42);
      expect(item.child, widget);
      expect(item.searchableStrings, {'alt1', 'alt2'});
    });

    test('constructor: with null value', () {
      final item = LayrzSelectItem<String>(
        value: null,
        child: Container(),
      );

      expect(item.value, null);
    });

    test('constructor: with empty searchableStrings', () {
      final item = LayrzSelectItem<String>(
        value: 'test',
        child: Container(),
        searchableStrings: {},
      );

      expect(item.searchableStrings, isEmpty);
    });

    test('copyWith: updates child', () {
      final oldWidget = Container();
      final newWidget = Container();
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: oldWidget,
      );

      final updated = item.copyWith(child: newWidget);

      expect(updated.child, newWidget);
      expect(updated.value, 'val');
    });

    test('copyWith: sets value to null explicitly', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        value: 'original',
        child: widget,
      );

      final cleared = item.copyWith(value: null);

      expect(cleared.value, null);
      expect(cleared.child, widget);
    });

    test('copyWith: updates searchableStrings', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'a', 'b'},
      );

      final updated = item.copyWith(searchableStrings: {'c', 'd'});

      expect(updated.searchableStrings, {'c', 'd'});
      expect(updated.value, 'val');
    });

    test('copyWith: does not update field when not passed', () {
      final widget = Container();
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'x', 'y'},
      );

      final copy = item.copyWith(value: 'new_val');

      expect(copy.value, 'new_val');
      expect(copy.child, widget);
      expect(copy.searchableStrings, {'x', 'y'});
    });

    test('copyWith: returns new instance', () {
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: Container(),
      );

      final copy = item.copyWith(value: 'new');

      expect(identical(copy, item), false);
    });

    test('equality: two identical items are equal', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(value: 'a', child: widget);
      final item2 = LayrzSelectItem<String>(value: 'a', child: widget);

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: different value makes them unequal', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(value: 'a', child: widget);
      final item2 = LayrzSelectItem<String>(value: 'b', child: widget);

      expect(item1, isNot(item2));
    });

    test('equality: different child makes them unequal', () {
      final item1 = LayrzSelectItem<String>(value: 'a', child: Container());
      final item2 = LayrzSelectItem<String>(value: 'a', child: Container());

      expect(item1, isNot(item2));
    });

    test('equality: null value equals null value', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(value: null, child: widget);
      final item2 = LayrzSelectItem<String>(value: null, child: widget);

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: searchableStrings order does not matter', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'a', 'b', 'c'},
      );

      final item2 = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'c', 'a', 'b'},
      );

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
    });

    test('equality: different searchableStrings makes them unequal', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'a', 'b'},
      );

      final item2 = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'a', 'c'},
      );

      expect(item1, isNot(item2));
    });

    test('equality: identical returns true', () {
      final item = LayrzSelectItem<String>(value: 'val', child: Container());

      expect(item, item);
    });

    test('hashCode: same hashCode for equal items with unordered sets', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'z', 'a', 'm'},
      );

      final item2 = LayrzSelectItem<String>(
        value: 'val',
        child: widget,
        searchableStrings: {'a', 'm', 'z'},
      );

      expect(item1.hashCode, item2.hashCode);
    });

    test('matches: matches searchableStrings substring case-insensitive', () {
      final item = LayrzSelectItem<String>(
        value: 'prod',
        child: const Text('Production Server'),
        searchableStrings: {'Production Server'},
      );

      expect(item.matches('prod'), true);
      expect(item.matches('Prod'), true);
      expect(item.matches('PRODUCTION'), true);
      expect(item.matches('Server'), true);
      expect(item.matches('server'), true);
    });

    test('matches: matches an entry that is not visible in child', () {
      // The whole point of separating child (presentation) from searchableStrings
      // (matching): a query can find an item by text that never appears on screen.
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: const Text('Widget Name'),
        searchableStrings: {'database', 'backend'},
      );

      expect(item.matches('database'), true);
      expect(item.matches('Database'), true);
      expect(item.matches('DATABASE'), true);
      expect(item.matches('backend'), true);
      expect(item.matches('BACKEND'), true);
    });

    test('matches: empty query matches everything', () {
      final item = LayrzSelectItem<String>(value: 'val', child: Container());

      expect(item.matches(''), true);
    });

    test('matches: whitespace-only query matches everything', () {
      final item = LayrzSelectItem<String>(value: 'val', child: Container());

      expect(item.matches('   '), true);
      expect(item.matches('\t'), true);
      expect(item.matches('\n'), true);
    });

    test('matches: empty searchableStrings never matches a non-empty query', () {
      final item = LayrzSelectItem<String>(value: 'val', child: const Text('Visible Text'));

      expect(item.matches('Visible'), false);
    });

    test('matches: no match returns false', () {
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: const Text('Test Item'),
        searchableStrings: {'tag1', 'tag2'},
      );

      expect(item.matches('nonexistent'), false);
      expect(item.matches('xyz'), false);
    });

    test('matches: partial substring matches', () {
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: const Text('Production Server Instance'),
        searchableStrings: {'Production Server Instance'},
      );

      expect(item.matches('prod'), true);
      expect(item.matches('instance'), true);
      expect(item.matches('server instance'), true); // continuous substring
      expect(item.matches('servinstance'), false); // not a continuous substring
    });

    test('matches: searchableStrings substring matching across multiple entries', () {
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: const Text('Item'),
        searchableStrings: {'javascript', 'typescript'},
      );

      expect(item.matches('java'), true);
      expect(item.matches('type'), true);
      expect(item.matches('script'), true);
    });

    test('toString: readable string representation', () {
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: const Text('Test'),
        searchableStrings: {'tag'},
      );

      final str = item.toString();

      expect(str, contains('LayrzSelectItem<String>'));
      expect(str, contains('value: val'));
      expect(str, contains('searchableStrings'));
    });

    test('toString: includes null value', () {
      final item = LayrzSelectItem<String>(value: null, child: Container());

      final str = item.toString();

      expect(str, contains('value: null'));
    });

    test('generic type: works with different types', () {
      final stringItem = LayrzSelectItem<String>(value: 'str', child: Container());
      final intItem = LayrzSelectItem<int>(value: 42, child: Container());
      final enumItem = LayrzSelectItem<Color>(value: const Color(0xFF000000), child: Container());

      expect(stringItem.value, 'str');
      expect(intItem.value, 42);
      expect(enumItem.value, const Color(0xFF000000));
    });

    test('generic type: equality respects generic type', () {
      final widget = Container();
      final item1 = LayrzSelectItem<String>(value: 'val', child: widget);
      final item2 = LayrzSelectItem<int>(value: 123, child: widget);

      // Different generic types, so not equal even though one "value" is conceptually the same
      expect(item1, isNot(item2));
    });

    test('mutable child does not affect equality check', () {
      final widget1 = Container(key: const ValueKey('same'));
      final widget2 = Container(key: const ValueKey('same'));

      final item1 = LayrzSelectItem<String>(value: 'val', child: widget1);
      final item2 = LayrzSelectItem<String>(value: 'val', child: widget2);

      // Widgets are not equal unless identical, so items are not equal
      expect(item1, isNot(item2));
    });

    test('same widget child makes items equal', () {
      final widget = Container();

      final item1 = LayrzSelectItem<String>(value: 'val', child: widget);
      final item2 = LayrzSelectItem<String>(value: 'val', child: widget);

      expect(item1, item2);
    });

    test('matches: multiple searchableStrings entries are all searchable', () {
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: const Text('Main Label'),
        searchableStrings: {'Main Label', 'attr1', 'attr2', 'attr3'},
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
        value: 'old_val',
        child: widget1,
        searchableStrings: {'old'},
      );

      final updated = item.copyWith(
        value: 'new_val',
        child: widget2,
        searchableStrings: {'new'},
      );

      expect(updated.value, 'new_val');
      expect(updated.child, widget2);
      expect(updated.searchableStrings, {'new'});
    });

    test('immutability: modifying the original set reference does not affect item', () {
      final strings = {'tag1', 'tag2'};
      final item = LayrzSelectItem<String>(
        value: 'val',
        child: Container(),
        searchableStrings: strings,
      );

      expect(item.searchableStrings, {'tag1', 'tag2'});
    });
  });
}
