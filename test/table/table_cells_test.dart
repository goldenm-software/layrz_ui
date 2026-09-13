import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/table/src/table_cells.dart';

import 'helpers/pump_table.dart';

/// Tests for the three column-major cell widgets that replaced the old
/// per-row `LayrzTableRow`: [LayrzTableCheckboxCell] (pinned-left),
/// [LayrzTableDataRowCell] (scrollable-middle), and [LayrzTableActionsCell]
/// (pinned-right). Each is now the item of its column region's own vertical
/// list; this file preserves the coverage the old `table_row_test.dart` had
/// over the same visuals and behaviors.
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

  group('LayrzTableCheckboxCell', () {
    testWidgets('reflects isSelected and invokes onSelectedChanged on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool? changed;
      await pumpTable(
        tester,
        LayrzTableCheckboxCell(
          rowIndex: 0,
          height: 50,
          isSelected: false,
          onSelectedChanged: (v) => changed = v,
        ),
      );

      expect(find.byType(LayrzCheckboxInput), findsOneWidget);
      await tester.tap(find.byType(LayrzCheckboxInput));
      await tester.pumpAndSettle();
      expect(changed, isTrue);
    });

    testWidgets('background equals the row stripe color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpTable(
        tester,
        Builder(
          builder: (context) {
            final expected = layrzTableRowStripe(context, 1);
            return _ProbeStripe(
              expected: expected,
              child: const LayrzTableCheckboxCell(rowIndex: 1, height: 50, isSelected: false, onSelectedChanged: null),
            );
          },
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(of: find.byType(LayrzTableCheckboxCell), matching: find.byType(DecoratedBox))
            .first,
      );
      final probe = tester.widget<_ProbeStripe>(find.byType(_ProbeStripe));
      expect((decorated.decoration as BoxDecoration).color, probe.expected);
    });
  });

  group('LayrzTableDataRowCell', () {
    testWidgets('renders one data cell per visible column', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final cols = columns();
      await pumpTable(
        tester,
        LayrzTableDataRowCell<TableTestRow>(
          item: const TableTestRow(id: 1, name: 'Alpha', amount: 10),
          rowIndex: 0,
          visibleColumns: cols,
          columnWidths: const [150, 150],
          height: 50,
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('even and odd rows plumb distinct stripe colors into their cell tappables', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final cols = [
        LayrzColumn<TableTestRow>(key: const ValueKey('name'), headerText: 'Name', valueBuilder: (r) => r.name),
      ];
      await pumpTable(
        tester,
        SizedBox(
          width: 150,
          child: Column(
            children: [
              LayrzTableDataRowCell<TableTestRow>(
                item: const TableTestRow(id: 1, name: 'RowEven', amount: 1),
                rowIndex: 0,
                visibleColumns: cols,
                columnWidths: const [150],
                height: 50,
              ),
              LayrzTableDataRowCell<TableTestRow>(
                item: const TableTestRow(id: 2, name: 'RowOdd', amount: 2),
                rowIndex: 1,
                visibleColumns: cols,
                columnWidths: const [150],
                height: 50,
              ),
            ],
          ),
        ),
      );

      final evenTappable = tester.widget<LayrzTappable>(
        find.ancestor(of: find.text('RowEven'), matching: find.byType(LayrzTappable)).first,
      );
      final oddTappable = tester.widget<LayrzTappable>(
        find.ancestor(of: find.text('RowOdd'), matching: find.byType(LayrzTappable)).first,
      );
      expect(evenTappable.color, isNot(oddTappable.color));
    });

    testWidgets('a data cell paints right + bottom dividers on the foreground layer', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final cols = columns();
      await pumpTable(
        tester,
        LayrzTableDataRowCell<TableTestRow>(
          item: const TableTestRow(id: 1, name: 'Alpha', amount: 10),
          rowIndex: 0,
          visibleColumns: cols,
          columnWidths: const [150, 150],
          height: 50,
        ),
      );

      final foregroundBorders = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((d) => d.position == DecorationPosition.foreground && d.decoration is BoxDecoration)
          .where((d) {
            final border = (d.decoration as BoxDecoration).border;
            return border is Border && border.right != BorderSide.none && border.bottom != BorderSide.none;
          });
      expect(foregroundBorders, isNotEmpty);
    });

    testWidgets('tapping a cell without onTap copies displayed text to clipboard', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final messages = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          messages.add(call);
          return null;
        },
      );

      final cols = columns();
      await pumpTable(
        tester,
        LayrzTableDataRowCell<TableTestRow>(
          item: const TableTestRow(id: 1, name: 'Alpha', amount: 10),
          rowIndex: 0,
          visibleColumns: cols,
          columnWidths: const [150, 150],
          height: 50,
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      final clipboardCall = messages.where((m) => m.method == 'Clipboard.setData').firstOrNull;
      expect(clipboardCall, isNotNull);
      expect((clipboardCall!.arguments as Map)['text'], 'Alpha');
    });

    testWidgets('a column onTap runs instead of the clipboard copy', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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
        LayrzTableDataRowCell<TableTestRow>(
          item: const TableTestRow(id: 1, name: 'Alpha', amount: 10),
          rowIndex: 0,
          visibleColumns: cols,
          columnWidths: const [150],
          height: 50,
        ),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'Alpha');
    });
  });

  group('LayrzTableActionsCell', () {
    List<LayrzTableAction> actions() => [
      LayrzTableAction(labelText: 'Edit', icon: MdiIcons.pencil, onTap: () {}),
      LayrzTableAction(labelText: 'Delete', icon: MdiIcons.delete, onTap: () {}),
    ];

    testWidgets('wide viewport renders one fab per action, no ButtonGroup', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpTable(
        tester,
        LayrzTableActionsCell<TableTestRow>(rowIndex: 0, height: 50, width: 150, actions: actions()),
      );

      expect(find.byType(LayrzButton), findsNWidgets(2));
      expect(find.byType(LayrzButtonGroup), findsNothing);
    });

    testWidgets('compact viewport collapses actions into a single ButtonGroup', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpTable(
        tester,
        LayrzTableActionsCell<TableTestRow>(rowIndex: 0, height: 50, width: 80, actions: actions()),
      );

      expect(find.byType(LayrzButtonGroup), findsOneWidget);
    });

    testWidgets('paints a bottom divider matching the data cells', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpTable(
        tester,
        SizedBox(
          width: 150,
          child: LayrzTableActionsCell<TableTestRow>(rowIndex: 0, height: 50, width: 150, actions: actions()),
        ),
      );

      final hasBottomBorder = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((d) => d.decoration is BoxDecoration)
          .any((d) {
            final border = (d.decoration as BoxDecoration).border;
            return border is Border && border.bottom != BorderSide.none;
          });
      expect(hasBottomBorder, isTrue);
    });
  });
}

/// Test-only probe that just carries an [expected] color so a test body can
/// read it back out of the tree after pumping.
class _ProbeStripe extends StatelessWidget {
  const _ProbeStripe({required this.expected, required this.child});
  final Color expected;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
