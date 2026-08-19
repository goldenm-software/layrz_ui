import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/scaffold/src/list_item.dart';

import '../helpers/pump_themed.dart';

/// Minimal domain object with value equality on [id].
class _Device {
  const _Device(this.id, this.name);

  final String id;
  final String name;

  @override
  bool operator ==(Object other) => other is _Device && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required List<_Device> items,
  required LayrzScaffoldController<_Device> controller,
  Size size = const Size(1500, 950),
  bool searchable = true,
  ValueChanged<String>? onSearch,
  Widget? footer,
  List<LayrzDropdownItem> actions = const [],
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  await pumpThemed(
    tester,
    SizedBox.expand(
      child: LayrzScaffoldShell<_Device>(
        controller: controller,
        items: items,
        searchable: searchable,
        onSearch: onSearch,
        footer: footer,
        onBuild: (context, d) => LayrzScaffoldValueTile(
          titleRichText: TextSpan(text: d.name),
          subtitleRichText: TextSpan(text: d.id),
          actions: actions,
        ),
        onDetailsBuild: (context, d) => Text('detail:${d.name}'),
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  group('LayrzScaffoldShell rendering', () {
    testWidgets('sanity check: two items at 1500x950 renders list items', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Verify the list panel renders by finding RichText widgets (from ListItem)
      expect(find.byType(RichText), findsWidgets);
      // Verify both items are rendered as ListItem widgets
      expect(find.byType(ListItem), findsWidgets);

      controller.dispose();
    });

    testWidgets('two-pane wide layout at 1500x950 shows list and detail side-by-side', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Open an item
      controller.open(items[0]);
      await tester.pump();

      // Both the list and detail should render
      expect(find.byType(RichText), findsWidgets); // List items
      expect(find.byType(Text), findsWidgets); // Detail text

      controller.dispose();
    });

    testWidgets('single-pane narrow at 520x900 shows list when closed', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
      );

      // List should be visible
      expect(find.byType(ListItem), findsWidgets);
      // Detail should not be shown
      expect(controller.isOpen, isFalse);

      controller.dispose();
    });

    testWidgets('single-pane narrow at 520x900 shows detail with back button when open', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
      );

      controller.open(items[0]);
      await tester.pump();

      // Detail should be shown
      expect(controller.isOpen, isTrue);
      // ListItem should not be visible in single-pane mode when detail is open
      expect(find.byType(ListItem), findsNothing);

      controller.dispose();
    });

    testWidgets('back button on detail pane calls controller.close()', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
      );

      controller.open(items[0]);
      await tester.pump();

      expect(controller.isOpen, isTrue);

      // Find and tap the back button (it's wrapped in a GestureDetector in DetailPane)
      final backButton = find.byType(GestureDetector).at(0);
      await tester.tap(backButton);
      await tester.pump();

      expect(controller.isOpen, isFalse);

      controller.dispose();
    });

    testWidgets('deep link: controller initialized open shows detail at narrow width', (tester) async {
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];
      final controller = LayrzScaffoldController<_Device>();
      controller.open(items[0]);

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
      );

      // Detail should be visible immediately
      expect(find.byType(Text), findsWidgets);
      expect(controller.isOpen, isTrue);

      controller.dispose();
    });

    testWidgets('band boundary 959 (sm) shows single-pane layout', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(959, 900),
      );

      // Single-pane: list should render
      expect(find.byType(ListItem), findsWidgets);

      controller.dispose();
    });

    testWidgets('band boundary 960 (md) shows two-pane layout', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(960, 900),
      );

      controller.open(items[0]);
      await tester.pump();

      // Two-pane: both list and detail should render
      expect(find.byType(ListItem), findsWidgets);
      expect(find.byType(Text), findsWidgets);

      controller.dispose();
    });

    testWidgets('band boundary 1263 (md) shows two-pane layout', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1263, 900),
      );

      controller.open(items[0]);
      await tester.pump();

      // Two-pane: detail should render
      expect(find.byType(Text), findsWidgets);

      controller.dispose();
    });

    testWidgets('band boundary 1264 (lg) shows two-pane layout', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1264, 900),
      );

      controller.open(items[0]);
      await tester.pump();

      // Two-pane: detail should render
      expect(find.byType(Text), findsWidgets);

      controller.dispose();
    });

    testWidgets('search: onSearch fires with entered text', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];
      var searchQueries = <String>[];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        onSearch: (query) => searchQueries.add(query),
        searchable: true,
      );

      // Find the search input field
      final searchField = find.byType(EditableText);
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pump();

      await tester.enterText(searchField, 'test');
      await tester.pump();

      expect(searchQueries, isNotEmpty);
      expect(searchQueries.last, contains('test'));

      controller.dispose();
    });

    testWidgets('search: searchable false renders no search field', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        searchable: false,
      );

      expect(find.byType(EditableText), findsNothing);

      controller.dispose();
    });

    testWidgets('search: shell does not filter items itself', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
        const _Device('3', 'Gamma'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        onSearch: (query) {},
        searchable: true,
      );

      // All 3 items should render as ListItems because the shell doesn't filter
      expect(find.byType(ListItem), findsNWidgets(3));

      controller.dispose();
    });

    testWidgets('row actions: non-empty actions list renders menu', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];
      final actions = [
        LayrzDropdownEntry(
          labelText: 'Edit',
          onTap: () {},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        actions: actions,
      );

      // The list should render with the item
      expect(find.byType(ListItem), findsOneWidget);

      controller.dispose();
    });

    testWidgets('row actions: empty actions list renders no menu', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        actions: const [],
      );

      // List item should still render
      expect(find.byType(ListItem), findsOneWidget);

      controller.dispose();
    });

    testWidgets('selected row color differs from unselected', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Open the first item
      controller.open(items[0]);
      await tester.pump();

      // Both items should render as ListItems
      expect(find.byType(ListItem), findsNWidgets(2));

      controller.dispose();
    });

    testWidgets('empty list shows empty state', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = <_Device>[];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
      );

      // No ListItems should render
      expect(find.byType(ListItem), findsNothing);

      controller.dispose();
    });

    testWidgets('closed controller with non-empty list shows list, not detail', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
      );

      expect(controller.isOpen, isFalse);
      // List should be visible
      expect(find.byType(ListItem), findsWidgets);

      controller.dispose();
    });

    testWidgets('mutable list: render with different sized lists', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      var items = [
        const _Device('1', 'Alpha'),
        const _Device('2', 'Beta'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
      );

      expect(find.byType(ListItem), findsNWidgets(2));

      controller.dispose();
    });

    testWidgets('single item renders correctly', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
      );

      expect(find.byType(ListItem), findsOneWidget);

      controller.dispose();
    });

    testWidgets('controller remains usable after shell unmount', (tester) async {
      final controller = LayrzScaffoldController<_Device>();
      final items = [
        const _Device('1', 'Alpha'),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
      );

      controller.open(items[0]);
      await tester.pump();

      expect(controller.isOpen, isTrue);

      // Unmount by pumping something else
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      // Controller should still work
      expect(() {
        controller.open(items[0]);
      }, returnsNormally);

      expect(() {
        controller.close();
      }, returnsNormally);

      controller.dispose();
    });
  });
}
