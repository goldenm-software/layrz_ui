import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// Pumps a widget with Navigator support for narrow layout sheet tests.
///
/// Wraps the child in a Localizations + LayrzTheme + Overlay + Navigator hierarchy
/// so that sheets can be shown on narrow layouts.
Future<void> _pumpThemedWithNavigator(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Navigator(
                onGenerateRoute: (settings) {
                  return PageRouteBuilder<void>(
                    pageBuilder: (context, animation, secondaryAnimation) => Center(child: child),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  Size size = const Size(1500, 950),
  bool searchable = true,
  Widget? footer,
  bool narrowWithNavigator = false,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  final shell = SizedBox.expand(
    child: LayrzScaffoldShell<_TestItem>(
      controller: controller,
      items: items,
      searchable: searchable,
      footer: footer,
      onDetailsBuild: (item) => Text("detail:${item.name}"),
      itemExtent: 56.0,
    ),
  );

  if (narrowWithNavigator) {
    await _pumpThemedWithNavigator(tester, shell);
  } else {
    await pumpThemed(tester, shell);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  group("LayrzScaffoldShell rendering", () {
    testWidgets("sanity check: two items at 1500x950 renders list items", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
        const LayrzScaffoldItem(
          key: ValueKey("2"),
          item: _TestItem("2", "Beta"),
          tile: SizedBox(child: Text("Beta")),
          searchableStrings: {"Beta"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Verify the list panel renders by finding the Text widgets in tiles
      expect(find.byType(Text), findsWidgets);

      controller.dispose();
    });

    testWidgets("two-pane wide layout at 1500x950 shows list and detail side-by-side", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
        const LayrzScaffoldItem(
          key: ValueKey("2"),
          item: _TestItem("2", "Beta"),
          tile: SizedBox(child: Text("Beta")),
          searchableStrings: {"Beta"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Open an item
      controller.open(const ValueKey("1"));
      await tester.pump();

      // Both the list and detail should render
      expect(find.byType(Text), findsWidgets);
      expect(find.text("detail:Alpha"), findsOneWidget);

      controller.dispose();
    });

    testWidgets("single-pane narrow at 520x900 shows list when closed", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
        const LayrzScaffoldItem(
          key: ValueKey("2"),
          item: _TestItem("2", "Beta"),
          tile: SizedBox(child: Text("Beta")),
          searchableStrings: {"Beta"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
      );

      // List should be visible, detail should not
      expect(controller.isOpen, isFalse);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("detail:Alpha"), findsNothing);

      controller.dispose();
    });

    testWidgets("narrow layout with sheet: list still visible and sheet presents detail", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
        const LayrzScaffoldItem(
          key: ValueKey("2"),
          item: _TestItem("2", "Beta"),
          tile: SizedBox(child: Text("Beta")),
          searchableStrings: {"Beta"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(520, 900),
        narrowWithNavigator: true,
      );

      controller.open(const ValueKey("1"));
      await tester.pump();
      await tester.pumpAndSettle();

      // Detail should be shown in the sheet
      expect(controller.isOpen, isTrue);
      expect(find.text("detail:Alpha"), findsOneWidget);

      // List should still be visible (behind the sheet)
      expect(find.text("Alpha"), findsWidgets);

      controller.dispose();
    });

    testWidgets("tapping a row opens it", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Initially closed
      expect(controller.isOpen, isFalse);

      // Tap the row
      await tester.tap(find.byType(LayrzTappable));
      await tester.pump();

      // Now should be open with the selected item
      expect(controller.openedKey, equals(const ValueKey("1")));

      controller.dispose();
    });

    testWidgets("controller open/close methods work correctly", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      // Open programmatically
      controller.open(const ValueKey("1"));
      await tester.pump();
      expect(controller.isOpen, isTrue);
      expect(find.text("detail:Alpha"), findsOneWidget);

      // Close programmatically
      controller.close();
      await tester.pump();
      expect(controller.isOpen, isFalse);
      expect(find.text("detail:Alpha"), findsNothing);

      controller.dispose();
    });

    testWidgets("wide layout with item open: detail pane shows correctly", (tester) async {
      final controller = LayrzScaffoldController();
      final items = [
        const LayrzScaffoldItem(
          key: ValueKey("1"),
          item: _TestItem("1", "Alpha"),
          tile: SizedBox(child: Text("Alpha")),
          searchableStrings: {"Alpha"},
        ),
      ];

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        size: const Size(1500, 950),
      );

      controller.open(const ValueKey("1"));
      await tester.pump();

      // Wide layout should show both list and detail side-by-side
      expect(find.text("Alpha"), findsWidgets);
      expect(find.text("detail:Alpha"), findsOneWidget);

      controller.dispose();
    });
  });
}
