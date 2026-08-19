import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzScaffoldShell', () {
    test('constructor accepts required parameters', () {
      final controller = LayrzScaffoldController<String>();
      final items = <String>[];

      final shell = LayrzScaffoldShell(
        items: items,
        controller: controller,
        onBuild: (context, item) => LayrzScaffoldValueTile(
          titleRichText: const TextSpan(text: 'Test'),
        ),
        onDetailsBuild: (context, item) => const SizedBox(),
      );

      expect(shell, isNotNull);
      controller.dispose();
    });

    test('with generic type parameter', () {
      final controller = LayrzScaffoldController<Map<String, dynamic>>();
      final items = <Map<String, dynamic>>[];

      final shell = LayrzScaffoldShell<Map<String, dynamic>>(
        items: items,
        controller: controller,
        onBuild: (context, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item['title'] ?? 'Test'),
        ),
        onDetailsBuild: (context, item) => const SizedBox(),
      );

      expect(shell, isNotNull);
      controller.dispose();
    });

    test('default values for optional parameters', () {
      final controller = LayrzScaffoldController<String>();
      final shell = LayrzScaffoldShell(
        items: const [],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: const TextSpan(text: 'Test'),
        ),
        onDetailsBuild: (_, item) => const SizedBox(),
      );

      expect(shell.footer, isNull);
      expect(shell.searchable, isTrue);
      expect(shell.onSearch, isNull);

      controller.dispose();
    });

    test('all optional parameters can be provided', () {
      final controller = LayrzScaffoldController<String>();
      final footer = Container();
      var searchCalled = false;

      final shell = LayrzScaffoldShell(
        items: const ['a', 'b'],
        controller: controller,
        onBuild: (context, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item),
        ),
        onDetailsBuild: (context, item) => Text(item),
        footer: footer,
        searchable: false,
        onSearch: (query) {
          searchCalled = true;
        },
      );

      expect(shell.footer, equals(footer));
      expect(shell.searchable, isFalse);
      expect(searchCalled, isFalse);
      expect(shell.onSearch, isNotNull);
      controller.dispose();
    });

    test('state is created correctly', () {
      final controller = LayrzScaffoldController<String>();
      final shell = LayrzScaffoldShell(
        items: const [],
        controller: controller,
        onBuild: (context, item) => LayrzScaffoldValueTile(
          titleRichText: const TextSpan(text: 'Test'),
        ),
        onDetailsBuild: (context, item) => const SizedBox(),
      );

      final state = shell.createState();
      expect(state, isNotNull);
      controller.dispose();
    });
  });

  group('LayrzScaffoldShell rendering', () {
    testWidgets('renders with footer widget', (tester) async {
      final controller = LayrzScaffoldController<String>();
      final footerWidget = Container();

      final shell = LayrzScaffoldShell(
        items: const ['a', 'b', 'c'],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: 'Item: $item'),
        ),
        onDetailsBuild: (_, item) => Text('Detail: $item'),
        footer: footerWidget,
        searchable: true,
      );

      expect(shell, isNotNull);
      expect(shell.footer, equals(footerWidget));
      controller.dispose();
    });

    testWidgets('renders with searchable false', (tester) async {
      final controller = LayrzScaffoldController<String>();

      final shell = LayrzScaffoldShell(
        items: const ['a', 'b'],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item),
        ),
        onDetailsBuild: (_, item) => Text(item),
        searchable: false,
      );

      expect(shell, isNotNull);
      expect(shell.searchable, isFalse);
      controller.dispose();
    });

    testWidgets('renders with search callback', (tester) async {
      final controller = LayrzScaffoldController<String>();
      var searchQuerys = <String>[];

      final shell = LayrzScaffoldShell(
        items: const ['a', 'b'],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item),
        ),
        onDetailsBuild: (_, item) => Text(item),
        onSearch: (query) {
          searchQuerys.add(query);
        },
      );

      expect(shell, isNotNull);
      expect(shell.onSearch, isNotNull);
      controller.dispose();
    });

    testWidgets('controller remains usable after unmount', (tester) async {
      final controller = LayrzScaffoldController<String>();
      int listenerCount = 0;
      controller.addListener(() => listenerCount++);

      final shell = LayrzScaffoldShell(
        items: const ['item'],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item),
        ),
        onDetailsBuild: (_, item) => Text(item),
      );

      expect(shell, isNotNull);
      final before = listenerCount;

      controller.open('item');

      expect(listenerCount, greaterThan(before));
      controller.dispose();
    });

    testWidgets('custom == override on items works', (tester) async {
      final item1a = _TestItem(id: '1', name: 'Item1');
      final item1b = _TestItem(id: '1', name: 'Item1');
      final item2 = _TestItem(id: '2', name: 'Item2');

      expect(item1a, equals(item1b));
      expect(identical(item1a, item1b), isFalse);

      final controller = LayrzScaffoldController<_TestItem>();
      controller.open(item1a);

      final shell = LayrzScaffoldShell<_TestItem>(
        items: [item1b, item2],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item.name),
        ),
        onDetailsBuild: (_, item) => Text(item.name),
      );

      expect(shell, isNotNull);
      expect(controller.opened, equals(item1a));
      controller.dispose();
    });

    testWidgets('initialized with all parameters', (tester) async {
      final controller = LayrzScaffoldController<_TestItem>();
      final item1 = _TestItem(id: '1', name: 'First');
      final item2 = _TestItem(id: '2', name: 'Second');
      final footerWidget = Container();

      final shell = LayrzScaffoldShell<_TestItem>(
        items: [item1, item2],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item.name),
        ),
        onDetailsBuild: (_, item) => Text(item.name),
        footer: footerWidget,
        searchable: false,
        onSearch: (query) {},
      );

      expect(shell, isNotNull);
      expect(shell.items.length, equals(2));
      expect(shell.footer, equals(footerWidget));
      expect(shell.searchable, isFalse);
      expect(shell.onSearch, isNotNull);
      controller.dispose();
    });

    testWidgets('multiple items with different callbacks', (tester) async {
      final controller = LayrzScaffoldController<String>();
      var tappedItem = '';
      var searchQuery = '';

      final shell = LayrzScaffoldShell(
        items: const ['apple', 'banana', 'cherry'],
        controller: controller,
        onBuild: (_, item) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: item.toUpperCase()),
        ),
        onDetailsBuild: (_, item) => Text('Selected: $item'),
        onSearch: (query) {
          searchQuery = query;
        },
        searchable: true,
      );

      expect(shell, isNotNull);
      expect(shell.items.length, equals(3));
      expect(tappedItem, isEmpty);
      expect(searchQuery, isEmpty);
      controller.dispose();
    });

    test('_PlainItem without custom equality comparison', () {
      final item1 = _PlainItem('test');
      final item2 = _PlainItem('test');

      expect(item1 == item2, isFalse);
      expect(identical(item1, item2), isFalse);
    });

    test('_TestItem with custom equality comparison', () {
      final item1 = _TestItem(id: '1', name: 'test');
      final item2 = _TestItem(id: '1', name: 'test');

      expect(item1 == item2, isTrue);
      expect(item1.hashCode == item2.hashCode, isTrue);
    });
  });

  group('LayrzScaffoldValueTile', () {
    test('equality and copyWith', () {
      final tile1 = LayrzScaffoldValueTile(
        titleRichText: const TextSpan(text: 'Title'),
        subtitleRichText: const TextSpan(text: 'Subtitle'),
      );

      final tile2 = tile1.copyWith(
        titleRichText: const TextSpan(text: 'Title'),
      );

      expect(tile1, equals(tile2));

      final tile3 = tile1.copyWith(
        titleRichText: const TextSpan(text: 'Different'),
      );

      expect(tile1 == tile3, isFalse);
    });

    test('copyWith with actions', () {
      final tile = LayrzScaffoldValueTile(
        titleRichText: const TextSpan(text: 'Title'),
        actions: const [],
      );

      expect(tile.actions, isEmpty);

      final updated = tile.copyWith();
      expect(updated.titleRichText.toPlainText(), 'Title');
    });

    test('hashCode consistency', () {
      final tile1 = LayrzScaffoldValueTile(
        titleRichText: const TextSpan(text: 'Same'),
      );

      final tile2 = LayrzScaffoldValueTile(
        titleRichText: const TextSpan(text: 'Same'),
      );

      expect(tile1.hashCode, tile2.hashCode);
    });
  });
}

/// Test item class with custom == override.
class _TestItem {
  final String id;
  final String name;

  _TestItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _TestItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Plain item class without custom == override.
class _PlainItem {
  final String name;

  _PlainItem(this.name);
}
