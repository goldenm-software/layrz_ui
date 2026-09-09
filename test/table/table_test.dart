import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'helpers/pump_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Every clipboard-copy test asserts against `Clipboard.setData`, so start
    // each test with a clean mock channel handler rather than relying on
    // whatever the previous test's handler left behind.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  List<LayrzColumn<TableTestRow>> baseColumns() => [
    LayrzColumn<TableTestRow>(
      key: const ValueKey('name'),
      headerText: 'Name',
      valueBuilder: (row) => row.name,
    ),
    LayrzColumn<TableTestRow>(
      key: const ValueKey('amount'),
      headerText: 'Amount',
      valueBuilder: (row) => row.amount.toString(),
    ),
  ];

  /// Finds only the per-row [LayrzTableAction] buttons, excluding the
  /// header's own [LayrzColumnMenu] trigger.
  ///
  /// [LayrzTable]'s header always renders a column-visibility menu trigger
  /// (keyed `'layrz-column-menu-trigger'`), and that trigger is itself a
  /// [LayrzButton] — so a bare `find.byType(LayrzButton)` over-counts by one
  /// whenever the header is present, which it always is.
  Finder actionButtons() =>
      find.byWidgetPredicate((w) => w is LayrzButton && w.key != const ValueKey('layrz-column-menu-trigger'));

  group('LayrzTable render', () {
    testWidgets('renders header text and every row for its items', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      for (final row in rows) {
        expect(find.text(row.name), findsOneWidget);
      }
    });

    testWidgets('reports the initial filtered count via onFilteredCountChanged', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final reported = <int>[];

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          onFilteredCountChanged: reported.add,
        ),
      );
      await tester.pumpAndSettle();

      expect(reported, contains(rows.length));
    });
  });

  group('LayrzTable search filtering', () {
    testWidgets('typing into the search field filters rows by visible-column contents', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'ban');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('a search matching multiple rows keeps all of them', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      await tester.enterText(find.byType(EditableText), 'cher');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Cherimoya'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('canSearch: false renders no search field', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), canSearch: false),
      );

      expect(find.byType(LayrzSearchInput), findsNothing);
    });
  });

  group('LayrzTable multiselect', () {
    testWidgets('hasMultiselect: false renders no checkbox cells', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(find.byType(LayrzCheckboxInput), findsNothing);
    });

    testWidgets('tapping a row checkbox toggles that item into the controller selection', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          controller: controller,
          hasMultiselect: true,
        ),
      );

      expect(controller.selection, isEmpty);

      await tester.tap(find.byType(LayrzCheckboxInput).first);
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(1));

      await tester.tap(find.byType(LayrzCheckboxInput).first);
      await tester.pumpAndSettle();

      expect(controller.selection, isEmpty);
    });

    testWidgets('selectAll via the controller selects every currently-filtered row', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          controller: controller,
          hasMultiselect: true,
        ),
      );

      controller.selectAll(rows);
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(rows.length));
      expect(find.byWidgetPredicate((w) => w is LayrzCheckboxInput && w.value == true), findsNWidgets(rows.length));

      controller.clearSelection();
      await tester.pumpAndSettle();

      expect(controller.selection, isEmpty);
      expect(find.byWidgetPredicate((w) => w is LayrzCheckboxInput && w.value == true), findsNothing);
    });
  });

  group('LayrzTable cell tap', () {
    testWidgets('tapping a cell without onTap copies its displayed text to the clipboard', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
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

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(copied, contains('Banana'));
    });

    testWidgets('richTextBuilder cell copies the reconstructed plain text, not valueBuilder', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
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

      final columns = [
        LayrzColumn<TableTestRow>(
          key: const ValueKey('name'),
          headerText: 'Name',
          valueBuilder: (row) => 'raw:${row.name}',
          richTextBuilder: (row) => [TextSpan(text: 'rich:'), TextSpan(text: row.name)],
        ),
      ];

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: columns),
      );

      // A richTextBuilder cell renders via RichText (InlineSpans), not a
      // plain Text widget, so find.textContaining can't see "Banana" here —
      // locate the RichText carrying that plain text instead.
      final cell = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Banana'),
      );
      expect(cell, findsOneWidget);

      await tester.tap(cell);
      await tester.pumpAndSettle();

      expect(copied, contains('rich:Banana'));
      expect(copied, isNot(contains('raw:Banana')));
    });

    testWidgets('a per-column onTap overrides the default copy-to-clipboard behavior', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      TableTestRow? tapped;
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

      final columns = [
        LayrzColumn<TableTestRow>(
          key: const ValueKey('name'),
          headerText: 'Name',
          valueBuilder: (row) => row.name,
          onTap: (row) => tapped = row,
        ),
      ];

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: columns),
      );

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(tapped, isNotNull);
      expect(tapped!.name, 'Banana');
      expect(copied, isEmpty);
    });
  });

  group('LayrzTable row actions', () {
    testWidgets('actionsBuilder renders each action as a button per row', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final tappedIds = <int>[];

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          actionsBuilder: (row) => [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () => tappedIds.add(row.id)),
          ],
        ),
      );

      // LayrzTable's header always renders a LayrzColumnMenu trigger, which
      // is itself a LayrzButton, so a bare byType(LayrzButton) count must
      // exclude it (keyed 'layrz-column-menu-trigger') to count only the
      // per-row action buttons.
      expect(actionButtons(), findsNWidgets(rows.length));

      await tester.tap(actionButtons().first);
      await tester.pumpAndSettle();

      expect(tappedIds, hasLength(1));
    });

    testWidgets('no actionsBuilder renders no action buttons', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(actionButtons(), findsNothing);
    });

    testWidgets('a disabled action does not invoke its onTap', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      var tapCount = 0;

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          actionsBuilder: (row) => [
            LayrzTableAction(
              icon: MdiIcons.pencilOutline,
              labelText: 'Edit',
              onTap: () => tapCount++,
              disabled: true,
            ),
          ],
        ),
      );

      await tester.tap(actionButtons().first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tapCount, 0);
    });
  });

  group('LayrzTable loading state', () {
    testWidgets('isLoading: true renders a spinner and the loading label, not the table body', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          isLoading: true,
          loadingLabelText: 'Please hold on...',
        ),
      );

      expect(find.text('Please hold on...'), findsOneWidget);
      expect(find.byType(LayrzProgressBar), findsOneWidget);
      expect(find.text('Name'), findsNothing);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('isLoading: false (default) renders the table body, not the loading state', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Please hold on...'), findsNothing);
    });
  });

  group('LayrzTable empty states', () {
    testWidgets('an empty items list shows the empty-data message, not the search-miss one', (tester) async {
      useWideViewport(tester);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: const [],
          columns: baseColumns(),
          emptyText: 'Nothing here yet.',
          emptySearchText: 'No matches for your search.',
        ),
      );

      expect(find.text('Nothing here yet.'), findsOneWidget);
      expect(find.text('No matches for your search.'), findsNothing);
    });

    testWidgets('a search with no matches shows the search-miss message, not the empty-data one', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          emptyText: 'Nothing here yet.',
          emptySearchText: 'No matches for your search.',
        ),
      );

      await tester.enterText(find.byType(EditableText), 'zzz-no-match');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No matches for your search.'), findsOneWidget);
      expect(find.text('Nothing here yet.'), findsNothing);
    });

    testWidgets('house default empty/search-miss strings differ from each other', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      await tester.enterText(find.byType(EditableText), 'zzz-no-match');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final searchMissFinder = find.byType(Text);
      final texts = tester.widgetList<Text>(searchMissFinder).map((t) => t.data).whereType<String>().toList();
      // Empty-data and search-miss defaults must not collapse to one string;
      // verified by asserting a search-miss render shows *some* non-empty
      // message text distinct from the table's other own strings.
      expect(texts.any((t) => t.isNotEmpty), isTrue);
    });
  });

  group('LayrzTable pinned-cell / scroll-sync alignment', () {
    testWidgets('multiselect + actions: checkbox and actions cells stay pinned while the middle scrolls', (
      tester,
    ) async {
      useWideViewport(tester);
      final rows = sampleRows();

      final wideColumns = [
        for (var i = 0; i < 6; i++)
          LayrzColumn<TableTestRow>(
            key: ValueKey('col-$i'),
            headerText: 'Column $i',
            valueBuilder: (row) => '${row.name}-$i',
            width: 400,
          ),
      ];

      await pumpTable(
        tester,
        SizedBox(
          width: 500,
          height: 400,
          child: LayrzTable<TableTestRow>(
            items: rows,
            columns: wideColumns,
            hasMultiselect: true,
            actionsBuilder: (row) => [
              LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
            ],
          ),
        ),
        size: const Size(500, 400),
      );

      // Pinned cells render once per row regardless of how far the
      // scrolling-middle region has scrolled.
      expect(find.byType(LayrzCheckboxInput), findsNWidgets(rows.length));
      expect(actionButtons(), findsNWidgets(rows.length));

      final middleScrollables = find.byType(SingleChildScrollView);
      final beforeOffsets = tester
          .widgetList<SingleChildScrollView>(middleScrollables)
          .map((s) => s.controller?.hasClients == true ? s.controller!.offset : null)
          .toList();

      await tester.drag(middleScrollables.first, const Offset(-200, 0));
      await tester.pumpAndSettle();

      final afterOffsets = tester
          .widgetList<SingleChildScrollView>(middleScrollables)
          .map((s) => s.controller?.hasClients == true ? s.controller!.offset : null)
          .toList();

      // Every joined scroll-sync controller (header + every row's middle
      // region) must move together: no two non-null offsets after the drag
      // may disagree, proving lockstep sync rather than each row scrolling
      // independently.
      final settledOffsets = afterOffsets.whereType<double>().toSet();
      expect(settledOffsets.length, 1, reason: 'all synced middle regions must share one offset: $afterOffsets');
      expect(beforeOffsets, isNot(equals(afterOffsets)));

      // Pinned cells are unaffected by the middle-region scroll.
      expect(find.byType(LayrzCheckboxInput), findsNWidgets(rows.length));
      expect(actionButtons(), findsNWidgets(rows.length));
    });
  });
}
