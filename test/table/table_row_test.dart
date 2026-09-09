import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/table/src/table_row.dart';

import 'helpers/pump_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  List<LayrzColumn<TableTestRow>> columns() => [
    LayrzColumn<TableTestRow>(key: const ValueKey('name'), headerText: 'Name', valueBuilder: (r) => r.name),
    LayrzColumn<TableTestRow>(key: const ValueKey('amount'), headerText: 'Amount', valueBuilder: (r) => '${r.amount}'),
  ];

  Widget buildRow({
    required TableTestRow item,
    required int rowIndex,
    required LayrzTableRowScrollSync scrollSync,
    bool hasMultiselect = false,
    bool isSelected = false,
    ValueChanged<bool>? onSelectedChanged,
    List<LayrzTableAction> actions = const [],
  }) {
    final cols = columns();
    return LayrzTableRow<TableTestRow>(
      item: item,
      rowIndex: rowIndex,
      visibleColumns: cols,
      columnWidths: [for (final _ in cols) 150.0],
      height: 50,
      scrollSync: scrollSync,
      hasMultiselect: hasMultiselect,
      isSelected: isSelected,
      onSelectedChanged: onSelectedChanged,
      actions: actions,
    );
  }

  group('LayrzTableRow three regions', () {
    testWidgets('hasMultiselect: false renders no checkbox cell', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      await pumpTable(
        tester,
        buildRow(item: sampleRows().first, rowIndex: 0, scrollSync: scrollSync),
      );

      expect(find.byType(LayrzCheckboxInput), findsNothing);
    });

    testWidgets('hasMultiselect: true renders a pinned checkbox cell', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      await pumpTable(
        tester,
        buildRow(item: sampleRows().first, rowIndex: 0, scrollSync: scrollSync, hasMultiselect: true),
      );

      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
    });

    testWidgets('checkbox reflects isSelected and invokes onSelectedChanged on tap', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      bool? changedTo;

      await pumpTable(
        tester,
        buildRow(
          item: sampleRows().first,
          rowIndex: 0,
          scrollSync: scrollSync,
          hasMultiselect: true,
          isSelected: false,
          onSelectedChanged: (v) => changedTo = v,
        ),
      );

      final checkbox = tester.widget<LayrzCheckboxInput>(find.byType(LayrzCheckboxInput));
      expect(checkbox.value, isFalse);

      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();

      expect(changedTo, isTrue);
    });

    testWidgets('empty actions renders no pinned-right actions cell', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      await pumpTable(
        tester,
        buildRow(item: sampleRows().first, rowIndex: 0, scrollSync: scrollSync),
      );

      expect(find.byType(LayrzButton), findsNothing);
    });

    testWidgets('wide viewport renders one individual fab button per action, no ButtonGroup', (tester) async {
      useWideViewport(tester);
      final scrollSync = LayrzTableRowScrollSync();
      await pumpTable(
        tester,
        buildRow(
          item: sampleRows().first,
          rowIndex: 0,
          scrollSync: scrollSync,
          actions: [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
            LayrzTableAction(icon: MdiIcons.trashCanOutline, labelText: 'Delete', onTap: () {}),
          ],
        ),
      );

      expect(find.byType(LayrzButton), findsNWidgets(2));
      expect(find.byType(LayrzButtonGroup), findsNothing);
    });

    testWidgets('compact viewport collapses actions into a single ButtonGroup, not individual buttons', (
      tester,
    ) async {
      useCompactViewport(tester);
      final scrollSync = LayrzTableRowScrollSync();
      await pumpTable(
        tester,
        buildRow(
          item: sampleRows().first,
          rowIndex: 0,
          scrollSync: scrollSync,
          actions: [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
            LayrzTableAction(icon: MdiIcons.trashCanOutline, labelText: 'Delete', onTap: () {}),
          ],
        ),
      );

      expect(find.byType(LayrzButtonGroup), findsOneWidget);
      // The collapsed group renders only its own single trigger button, not
      // one LayrzButton per action.
      expect(find.byType(LayrzButton), findsOneWidget);
    });

    testWidgets('compact ButtonGroup opens a dropdown listing every action, mapped from LayrzTableAction', (
      tester,
    ) async {
      useCompactViewport(tester);
      final scrollSync = LayrzTableRowScrollSync();
      bool editTapped = false;

      await pumpTable(
        tester,
        buildRow(
          item: sampleRows().first,
          rowIndex: 0,
          scrollSync: scrollSync,
          actions: [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () => editTapped = true),
            LayrzTableAction(icon: MdiIcons.trashCanOutline, labelText: 'Delete', onTap: () {}, disabled: true),
          ],
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });

    testWidgets('the scrolling-middle region renders one data cell per visible column', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync),
      );

      expect(find.text(row.name), findsOneWidget);
      expect(find.text('${row.amount}'), findsOneWidget);
    });
  });

  group('LayrzTableRow cell idle color (hover-blink fix)', () {
    testWidgets('a data cell tappable idles at the row stripe color, not transparent', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync),
      );

      final tappable = tester.widget<LayrzTappable>(
        find.ancestor(of: find.text(row.name), matching: find.byType(LayrzTappable)).first,
      );

      // Previously this was `const Color(0x00000000)` (transparent), which
      // made the hover transition ramp transparent -> hover instead of
      // stripe -> hover, producing a visible blink the instant the pointer
      // entered. The idle color must now equal the row's own stripe color.
      expect(tappable.color, isNot(const Color(0x00000000)));
    });

    testWidgets('even and odd rows plumb their own distinct stripe color into their cell tappables', (tester) async {
      final row = sampleRows().first;

      await pumpTable(
        tester,
        Column(
          children: [
            buildRow(item: row, rowIndex: 0, scrollSync: LayrzTableRowScrollSync()),
            buildRow(item: row, rowIndex: 1, scrollSync: LayrzTableRowScrollSync()),
          ],
        ),
      );

      final tappables = tester
          .widgetList<LayrzTappable>(find.ancestor(of: find.text(row.name), matching: find.byType(LayrzTappable)))
          .toList();

      expect(tappables, hasLength(2));
      // Row 0 (even, sf1) and row 1 (odd, sf2) must plumb different idle
      // colors into their tappables, mirroring LayrzTableRow's own striping.
      expect(tappables[0].color, isNot(tappables[1].color));
    });

    testWidgets('the checkbox cell background also equals the row stripe color', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync, hasMultiselect: true),
      );

      final rowBackground =
          (tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration as BoxDecoration).color;

      // The checkbox cell's own DecoratedBox is the one wrapping the
      // LayrzCheckboxInput directly — anchor on that ancestry rather than a
      // border shape, which every bordered cell in the row shares.
      final checkboxCellBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(LayrzCheckboxInput), matching: find.byType(DecoratedBox)).first,
      );
      final checkboxCellBackground = (checkboxCellBox.decoration as BoxDecoration).color;

      expect(checkboxCellBackground, rowBackground);
    });

    testWidgets('a data cell still paints its right-side divider border, on top of the tappable fill', (
      tester,
    ) async {
      // Regression test: giving each data cell's LayrzTappable an opaque
      // idle color (the stripe fix above) covers a background-positioned
      // divider border painted behind it. The border must be moved to a
      // DecoratedBox with DecorationPosition.foreground so it is painted
      // AFTER (visually on top of) the tappable's fill, and this must stay
      // true regardless of the tappable's current idle/hover color.
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync),
      );

      final dividerBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(LayrzTappable), matching: find.byType(DecoratedBox)).first,
      );

      expect(dividerBox.position, DecorationPosition.foreground);
      final decoration = dividerBox.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).right.width, greaterThan(0));
    });

    testWidgets('a data cell also paints a bottom-side row divider, on the same foreground layer', (tester) async {
      // Regression test: the actions cell drew a horizontal row divider but
      // data cells did not, so rows blurred together in the scrolling-middle
      // region. The bottom border must live on the same foreground
      // DecoratedBox as the right-side divider, so it is painted on top of
      // the tappable's opaque fill for the same reason the right border is.
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync),
      );

      final dividerBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(LayrzTappable), matching: find.byType(DecoratedBox)).first,
      );

      expect(dividerBox.position, DecorationPosition.foreground);
      final decoration = dividerBox.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.bottom.width, greaterThan(0));
      expect(border.bottom.color, border.right.color);
      expect(border.bottom.width, border.right.width);
    });

    testWidgets('the checkbox cell also paints a bottom-side row divider matching the data cell', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync, hasMultiselect: true),
      );

      final checkboxCellBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(LayrzCheckboxInput), matching: find.byType(DecoratedBox)).first,
      );
      final checkboxDecoration = checkboxCellBox.decoration as BoxDecoration;
      final checkboxBorder = checkboxDecoration.border as Border;
      expect(checkboxBorder.bottom.width, greaterThan(0));

      final dataDividerBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(LayrzTappable), matching: find.byType(DecoratedBox)).first,
      );
      final dataBorder = (dataDividerBox.decoration as BoxDecoration).border as Border;

      expect(checkboxBorder.bottom.color, dataBorder.bottom.color);
      expect(checkboxBorder.bottom.width, dataBorder.bottom.width);
    });
  });

  group('LayrzTableRow striping', () {
    testWidgets('even and odd rowIndex paint different backgrounds', (tester) async {
      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        Column(
          children: [
            buildRow(item: row, rowIndex: 0, scrollSync: LayrzTableRowScrollSync()),
            buildRow(item: row, rowIndex: 1, scrollSync: scrollSync),
          ],
        ),
      );

      final decoratedBoxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: find.byType(LayrzTableRow<TableTestRow>), matching: find.byType(DecoratedBox)),
          )
          .where((box) => box.decoration is BoxDecoration && (box.decoration as BoxDecoration).color != null)
          .toList();

      final colors = decoratedBoxes.map((box) => (box.decoration as BoxDecoration).color).toSet();
      // Even (sf1) and odd (sf2) striping must differ; both rows contribute a
      // color-bearing DecoratedBox, so at least two distinct colors appear
      // across the pumped pair when the tokens' sf1/sf2 differ (the default
      // light theme's do).
      expect(colors.length, greaterThanOrEqualTo(2));
    });
  });

  group('LayrzTableRow cell tap', () {
    testWidgets('tapping a cell without onTap copies displayed text to clipboard', (tester) async {
      final copied = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );

      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;

      await pumpTable(
        tester,
        buildRow(item: row, rowIndex: 0, scrollSync: scrollSync),
      );

      await tester.tap(find.text(row.name));
      await tester.pumpAndSettle();

      expect(copied, contains(row.name));
    });

    testWidgets('a column onTap runs instead of the clipboard copy', (tester) async {
      final copied = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );

      final scrollSync = LayrzTableRowScrollSync();
      final row = sampleRows().first;
      TableTestRow? tapped;

      final cols = [
        LayrzColumn<TableTestRow>(
          key: const ValueKey('name'),
          headerText: 'Name',
          valueBuilder: (r) => r.name,
          onTap: (r) => tapped = r,
        ),
      ];

      await pumpTable(
        tester,
        LayrzTableRow<TableTestRow>(
          item: row,
          rowIndex: 0,
          visibleColumns: cols,
          columnWidths: const [150.0],
          height: 50,
          scrollSync: scrollSync,
        ),
      );

      await tester.tap(find.text(row.name));
      await tester.pumpAndSettle();

      expect(tapped, row);
      expect(copied, isEmpty);
    });
  });
}
