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
}
