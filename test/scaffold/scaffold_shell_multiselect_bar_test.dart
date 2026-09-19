import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/find_button_label.dart";
import "../helpers/pump_themed.dart";

/// Minimal domain object for the multiselect action bar tests.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// The two columns every test in this file renders.
List<LayrzColumn<_TestItem>> _columns() => [
  LayrzColumn<_TestItem>(
    key: const ValueKey("name"),
    headerText: "Name",
    valueBuilder: (item) => item.name,
    width: 200,
  ),
  LayrzColumn<_TestItem>(
    key: const ValueKey("id"),
    headerText: "ID",
    valueBuilder: (item) => item.id,
    width: 120,
  ),
];

const _items = [
  _TestItem("1", "Alpha"),
  _TestItem("2", "Bravo"),
];

/// Wraps [_items] into scaffold items.
List<LayrzScaffoldItem<_TestItem>> _scaffoldItems() => _items
    .map(
      (item) => LayrzScaffoldItem<_TestItem>(
        key: ValueKey(item.id),
        item: item,
        tile: SizedBox(child: Text(item.name)),
        searchableStrings: {item.name},
      ),
    )
    .toList();

/// Finds only the per-row [LayrzCheckboxInput] cells, excluding the header's
/// own select-all checkbox. Mirrors
/// `scaffold_shell_multiselect_test.dart`'s own helper.
Finder _rowCheckboxes() => find.descendant(of: find.byType(ListView), matching: find.byType(LayrzCheckboxInput));

/// Pumps a [LayrzScaffoldShell] at [size], wiring [multiselectActionsBuilder]
/// (capturing its argument into [capturedSelection] when supplied) and the
/// optional label overrides straight through.
///
/// A real [Navigator] ancestor is provided (mirrors
/// `scaffold_shell_table_default_test.dart`/`scaffold_shell_multiselect_test.dart`)
/// so a compact-viewport open never asserts, and `pumpThemed`'s own [Overlay]
/// ancestor is what the shell's `rootOverlay: true` insert resolves against —
/// the same harness shape `find_in_page_host_test.dart` relies on for its own
/// root-overlay widgets, just via `pumpThemed` instead of `LayrzApp` since no
/// keyboard-shortcut/router machinery is needed here.
Future<void> _pumpShell(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  required Size size,
  List<LayrzButton> Function(List<_TestItem> selected)? multiselectActionsBuilder,
  String Function(int count)? multiselectCountLabel,
  String? multiselectClearLabel,
}) async {
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  final shell = SizedBox.expand(
    child: LayrzScaffoldShell<_TestItem>(
      controller: controller,
      items: _scaffoldItems(),
      itemExtent: 56.0,
      title: const Text("Title"),
      tableColumns: _columns(),
      tableController: tableController,
      multiselectActionsBuilder: multiselectActionsBuilder,
      multiselectCountLabel: multiselectCountLabel,
      multiselectClearLabel: multiselectClearLabel,
      onItemTap: (item) => controller.open(key: item.key, builder: (_) => Text("detail:${item.item.name}")),
    ),
  );

  await pumpThemed(
    tester,
    Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) => shell,
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

const _kWideSize = Size(1600, 1200);

void main() {
  group("LayrzScaffoldShell multiselect action bar", () {
    testWidgets("absent while selection is empty", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        multiselectActionsBuilder: (selected) => [LayrzButton.delete(labelText: "Delete", onTap: () {})],
      );

      expect(find.byType(LayrzScaffoldMultiselectBar), findsNothing);

      controller.dispose();
    });

    testWidgets("appears on selection and disappears when cleared via the shell's clear button", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      List<_TestItem>? captured;

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        multiselectActionsBuilder: (selected) {
          captured = selected;
          return [LayrzButton.delete(labelText: "Delete", onTap: () {})];
        },
      );

      expect(find.byType(LayrzScaffoldMultiselectBar), findsNothing);

      await tester.tap(_rowCheckboxes().first);
      await tester.pumpAndSettle();

      expect(tableController.selection, hasLength(1));
      expect(find.byType(LayrzScaffoldMultiselectBar), findsOneWidget);
      expect(find.text("1 selected"), findsOneWidget);
      expect(findButtonLabel("Delete"), findsOneWidget);
      expect(captured, isNotNull);
      expect(captured!.map((e) => e.id), tableController.selection.map((e) => e.id));

      // Two-row layout: the count label (row 1) sits strictly above the
      // caller's action button (row 2) — never beside it.
      final countLabelDy = tester.getTopLeft(find.text("1 selected")).dy;
      final deleteButtonDy = tester.getTopLeft(findButtonLabel("Delete")).dy;
      expect(countLabelDy, lessThan(deleteButtonDy));

      // The shell's own Clear button stays on row 1, beside the count label
      // (same top edge), not pushed down alongside the caller's actions.
      final clearButtonDy = tester.getTopLeft(findButtonLabel("Clear")).dy;
      expect(clearButtonDy, closeTo(countLabelDy, 1.0));

      // Tap the shell's own clear button (not the caller's Delete button).
      await tester.tap(findButtonLabel("Clear"));
      await tester.pumpAndSettle();

      expect(tableController.selection, isEmpty);
      expect(find.byType(LayrzScaffoldMultiselectBar), findsNothing);

      controller.dispose();
    });

    testWidgets("null multiselectActionsBuilder shows neither the checkbox column nor the bar", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
      );

      // No checkbox column at all — there is nothing to tap to build a
      // selection with, since multiselectActionsBuilder is what enables it.
      expect(_rowCheckboxes(), findsNothing);
      expect(find.byType(LayrzCheckboxInput), findsNothing);

      // Selecting nothing (there is nothing to select) leaves the selection
      // empty, and the bar never appears.
      expect(tableController.selection, isEmpty);
      expect(find.byType(LayrzScaffoldMultiselectBar), findsNothing);

      controller.dispose();
    });

    testWidgets("multiselectCountLabel and multiselectClearLabel override the default copy", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        multiselectActionsBuilder: (selected) => [LayrzButton.delete(labelText: "Delete", onTap: () {})],
        multiselectCountLabel: (count) => "$count picked",
        multiselectClearLabel: "Deselect",
      );

      await tester.tap(_rowCheckboxes().first);
      await tester.pumpAndSettle();

      expect(find.text("1 picked"), findsOneWidget);
      expect(find.text("1 selected"), findsNothing);
      expect(findButtonLabel("Deselect"), findsOneWidget);
      expect(findButtonLabel("Clear"), findsNothing);

      controller.dispose();
    });

    testWidgets("reappears when a second row is selected after a clear", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        multiselectActionsBuilder: (selected) => [LayrzButton.delete(labelText: "Delete", onTap: () {})],
      );

      await tester.tap(_rowCheckboxes().first);
      await tester.pumpAndSettle();
      expect(find.byType(LayrzScaffoldMultiselectBar), findsOneWidget);

      tableController.clearSelection();
      await tester.pumpAndSettle();
      expect(find.byType(LayrzScaffoldMultiselectBar), findsNothing);

      await tester.tap(_rowCheckboxes().last);
      await tester.pumpAndSettle();
      expect(find.byType(LayrzScaffoldMultiselectBar), findsOneWidget);
      expect(find.text("1 selected"), findsOneWidget);

      controller.dispose();
    });
  });

  group("LayrzScaffoldShell multiselect action bar — accessibility", () {
    testWidgets("the bar exposes a live-region container announcing the count label", (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final controller = LayrzScaffoldController();
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await _pumpShell(
          tester,
          controller: controller,
          tableController: tableController,
          size: _kWideSize,
          multiselectActionsBuilder: (selected) => [LayrzButton.delete(labelText: "Delete", onTap: () {})],
        );

        await tester.tap(_rowCheckboxes().first);
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.byType(LayrzScaffoldMultiselectBar)),
          matchesSemantics(
            label: "1 selected",
            isLiveRegion: true,
            hasSelectedState: false,
          ),
        );

        controller.dispose();
      } finally {
        handle.dispose();
      }
    });
  });
}
