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

    testWidgets('non-empty actions renders a pinned-right actions cell with one button per action', (tester) async {
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
          .widgetList<DecoratedBox>(find.descendant(of: find.byType(LayrzTableRow<TableTestRow>), matching: find.byType(DecoratedBox)))
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
