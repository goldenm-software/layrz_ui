import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzScaffoldShell', () {
    final items = [
      LayrzScaffoldItem(
        id: 'item-1',
        title: 'First Item',
        subtitle: 'First Subtitle',
        group: 'Group A',
      ),
      LayrzScaffoldItem(
        id: 'item-2',
        title: 'Second Item',
        subtitle: 'Second Subtitle',
        group: 'Group A',
      ),
      LayrzScaffoldItem(
        id: 'item-3',
        title: 'Third Item',
        subtitle: 'Third Subtitle',
        group: 'Group B',
      ),
      LayrzScaffoldItem(
        id: 'item-4',
        title: 'Ungrouped Item',
      ),
    ];

    testWidgets('renders with items list', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
        ),
      );

      expect(find.byType(LayrzScaffoldShell), findsOneWidget);
    });

    testWidgets('renders empty list with empty items', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: const [],
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
        ),
      );

      expect(find.byType(LayrzScaffoldShell), findsOneWidget);
    });

    testWidgets('renders list title when provided', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          listTitle: 'My Items',
        ),
      );

      expect(find.text('My Items'), findsOneWidget);
    });

    testWidgets('renders item count in list header', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          listTitle: 'Items',
        ),
      );

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('hides filter field when searchable is false', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          searchable: false,
        ),
      );

      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('renders detail actions', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: 'item-1',
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          detailActions: [
            GestureDetector(
              onTap: () {},
              child: const Text('Action Button'),
            ),
          ],
        ),
      );

      expect(find.text('Action Button'), findsOneWidget);
    });

    testWidgets('uses provided detailTitle instead of item title', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: 'item-1',
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          detailTitle: 'Custom Title',
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
    });

    testWidgets('renders detail subtitle when provided', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: 'item-1',
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          detailSubtitle: 'Custom Subtitle',
        ),
      );

      expect(find.text('Custom Subtitle'), findsOneWidget);
    });

    testWidgets('renders footer when provided', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          footer: const Text('Footer Text'),
        ),
      );

      expect(find.text('Footer Text'), findsOneWidget);
    });

    testWidgets('shows empty state with null selectedId', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => Text('Detail: ${item.title}'),
        ),
      );

      expect(find.text('No item selected'), findsOneWidget);
    });

    testWidgets('shows empty state when selectedId matches no item', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: 'nonexistent-id',
          onSelected: (_) {},
          contentBuilder: (context, item) => Text('Detail: ${item.title}'),
        ),
      );

      expect(find.text('No item selected'), findsOneWidget);
    });

    testWidgets('renders grouped mode by default', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
        ),
      );

      expect(find.byType(LayrzScaffoldShell), findsOneWidget);
    });

    testWidgets('renders with flat mode when specified', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
          initialGroupMode: LayrzScaffoldGroupMode.flat,
        ),
      );

      expect(find.byType(LayrzScaffoldShell), findsOneWidget);
    });

    testWidgets('builds content with selected item', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: 'item-1',
          onSelected: (_) {},
          contentBuilder: (context, item) => Text('Item: ${item.id}'),
        ),
      );

      expect(find.text('Item: item-1'), findsOneWidget);
    });

    testWidgets('item with null subtitle renders without subtitle', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 800);

      final itemWithoutSubtitle = LayrzScaffoldItem(
        id: 'item-x',
        title: 'Item Without Subtitle',
      );

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: [itemWithoutSubtitle],
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => const SizedBox(),
        ),
      );

      expect(find.byType(LayrzScaffoldShell), findsOneWidget);
    });

    testWidgets('renders single-pane layout on narrow width with no selection', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: null,
          onSelected: (_) {},
          contentBuilder: (context, item) => Text('Detail: ${item.title}'),
        ),
      );

      expect(find.text('First Item'), findsOneWidget);
      expect(find.text('No item selected'), findsNothing);
    });

    testWidgets('shows detail on narrow width when item is pre-selected (deep link)', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 800);

      await pumpThemedApp(
        tester,
        LayrzScaffoldShell(
          items: items,
          selectedId: 'item-1',
          onSelected: (_) {},
          contentBuilder: (context, item) => Text('Detail: ${item.title}'),
        ),
      );

      expect(find.text('Detail: First Item'), findsOneWidget);
    });
  });
}
