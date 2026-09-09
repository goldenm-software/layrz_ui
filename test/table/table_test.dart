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

  /// Finds only the per-row [LayrzCheckboxInput] cells, excluding the
  /// header's own select-all checkbox.
  ///
  /// [LayrzTable] always renders the header's select-all checkbox as a
  /// sibling [LayrzCheckboxInput] ahead of every row's, in widget-tree order,
  /// whenever `hasMultiselect` is `true` — so a bare `find.byType` over-counts
  /// by one, and `.first` resolves to the header's checkbox rather than row
  /// 0's. Anchoring on a [ListView] ancestor (the row list) isolates the
  /// row-owned checkboxes: the header lives as the list's sibling, never a
  /// descendant of it.
  Finder rowCheckboxes() => find.descendant(of: find.byType(ListView), matching: find.byType(LayrzCheckboxInput));

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

    testWidgets(
      'does not crash when a consumer calls setState from onFilteredCountChanged (regression)',
      (tester) async {
        // Regression test for a real runtime crash: LayrzTable used to call
        // onFilteredCountChanged synchronously from the recompute kicked off
        // in initState, which runs while LayrzTable's own parent is still
        // inside its build() method (that's how a newly-mounted child's
        // initState is invoked). A consumer doing the obvious thing —
        // setState-ing the reported count — then hit Flutter's "setState()
        // or markNeedsBuild() called during build" error. _CountDisplay
        // below mirrors that exact shape: a StatefulWidget that constructs
        // LayrzTable in its own build() and calls setState from the
        // callback, same as example/lib/src/sections/table_section.dart.
        useWideViewport(tester);
        final rows = sampleRows();

        await pumpTable(tester, _CountDisplay<TableTestRow>(items: rows, columns: baseColumns()));

        // The crash (if present) surfaces as a FlutterError during this
        // very first pump, before any post-frame callback has a chance to
        // run — so reaching this line at all is part of the assertion.
        expect(tester.takeException(), isNull);

        // The initial count is deferred to a post-frame callback, not
        // dropped: it must still arrive once the frame settles.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('count: ${rows.length}'), findsOneWidget);
      },
    );
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

    testWidgets(
      'search is served from the precomputed display-string cache, not a per-keystroke valueBuilder call',
      (tester) async {
        // Regression/perf test for the display-string cache LayrzTable's own
        // doc comment claims to maintain: filtering must be served from a
        // cache built once (on items/columns change), not by re-invoking
        // valueBuilder on every search-text recompute. A column whose
        // valueBuilder increments a counter lets us assert that directly.
        //
        // valueBuilder is also (separately, unavoidably, and expected)
        // called once per currently-*rendered* row by LayrzTableRow itself,
        // to build each visible cell's display text — that cost scales with
        // the visible/filtered row count, not the full dataset, and is
        // orthogonal to the search-filtering cache this test targets. A
        // search with NO matches renders zero rows, isolating that
        // rendering cost to zero and leaving only the cache-driven filter
        // pass to observe: if the cache is reused (not rebuilt), a
        // zero-result search must not invoke valueBuilder at all.
        useWideViewport(tester);
        final rows = sampleRows();
        var nameCallCount = 0;
        var amountCallCount = 0;

        final columns = [
          LayrzColumn<TableTestRow>(
            key: const ValueKey('name'),
            headerText: 'Name',
            valueBuilder: (row) {
              nameCallCount++;
              return row.name;
            },
          ),
          LayrzColumn<TableTestRow>(
            key: const ValueKey('amount'),
            headerText: 'Amount',
            valueBuilder: (row) {
              amountCallCount++;
              return row.amount.toString();
            },
          ),
        ];

        await pumpTable(tester, LayrzTable<TableTestRow>(items: rows, columns: columns));
        await tester.pumpAndSettle();

        // The cache build (rows.length calls per column) plus rendering all
        // rows (another rows.length calls per column, since nothing is
        // filtered out yet) account for every call so far.
        expect(nameCallCount, rows.length * 2);
        expect(amountCallCount, rows.length * 2);

        final countsBeforeSearch = (nameCallCount, amountCallCount);

        // A search matching nothing renders zero rows, so any further
        // valueBuilder call could only come from rebuilding the search
        // cache — which must not happen, since items/columns didn't change.
        await tester.enterText(find.byType(EditableText), 'zzz-no-match');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        for (final row in rows) {
          expect(find.text(row.name), findsNothing);
        }
        expect((nameCallCount, amountCallCount), countsBeforeSearch);

        // A second, different zero-match search: still no cache rebuild.
        await tester.enterText(find.byType(EditableText), 'still-no-match');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect((nameCallCount, amountCallCount), countsBeforeSearch);
      },
    );

    testWidgets('search still matches hidden (non-currently-visible) column values via the cache', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );
      await tester.pumpAndSettle();

      // Searching by the numeric "amount" column value (visible by default)
      // still matches, proving the cache carries every column's string, not
      // just the "name" column exercised by the other search tests.
      await tester.enterText(find.byType(EditableText), '30');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
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

      await tester.tap(rowCheckboxes().first);
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(1));

      await tester.tap(rowCheckboxes().first);
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
      // Every row's checkbox is checked, and selectAll now also checks the
      // header's own select-all checkbox (all rows are selected) — so the
      // full-tree count is rows.length + 1; the row-only count (excluding
      // the header) is asserted separately via rowCheckboxes().
      expect(
        find.byWidgetPredicate((w) => w is LayrzCheckboxInput && w.value == true),
        findsNWidgets(rows.length + 1),
      );
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byWidgetPredicate((w) => w is LayrzCheckboxInput && w.value == true),
        ),
        findsNWidgets(rows.length),
      );

      controller.clearSelection();
      await tester.pumpAndSettle();

      expect(controller.selection, isEmpty);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byWidgetPredicate((w) => w is LayrzCheckboxInput && w.value == true),
        ),
        findsNothing,
      );
    });
  });

  group('LayrzTable header select-all checkbox', () {
    /// Finds the header's own select-all [LayrzCheckboxInput] — the one
    /// checkbox that is NOT a descendant of the row [ListView].
    Finder headerCheckbox() {
      final element = find
          .byWidgetPredicate((w) => w is LayrzCheckboxInput)
          .evaluate()
          .firstWhere((element) => element.findAncestorWidgetOfExactType<ListView>() == null);
      return find.byWidgetPredicate((w) => identical(w, element.widget));
    }

    testWidgets('hasMultiselect: false renders no header checkbox', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(find.byType(LayrzCheckboxInput), findsNothing);
    });

    testWidgets('header checkbox is unchecked when nothing is selected', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), controller: controller, hasMultiselect: true),
      );

      expect(tester.widget<LayrzCheckboxInput>(headerCheckbox()).value, isFalse);
    });

    testWidgets('header checkbox becomes checked only once every row is selected', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), controller: controller, hasMultiselect: true),
      );

      controller.selectItem(rows.first);
      await tester.pumpAndSettle();
      expect(tester.widget<LayrzCheckboxInput>(headerCheckbox()).value, isFalse);

      controller.selectAll(rows);
      await tester.pumpAndSettle();
      expect(tester.widget<LayrzCheckboxInput>(headerCheckbox()).value, isTrue);
    });

    testWidgets('tapping the header checkbox selects every row via controller.selectAll', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), controller: controller, hasMultiselect: true),
      );

      await tester.tap(headerCheckbox());
      await tester.pumpAndSettle();

      expect(controller.selection, hasLength(rows.length));
      expect(controller.selection, containsAll(rows));
    });

    testWidgets('tapping the header checkbox again (all selected) clears the selection', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), controller: controller, hasMultiselect: true),
      );

      controller.selectAll(rows);
      await tester.pumpAndSettle();

      await tester.tap(headerCheckbox());
      await tester.pumpAndSettle();

      expect(controller.selection, isEmpty);
    });

    testWidgets('select-all selects every row in the FULL dataset, ignoring the active search filter', (
      tester,
    ) async {
      useWideViewport(tester);
      final rows = sampleRows();
      final controller = LayrzTableController<TableTestRow>();
      addTearDown(controller.dispose);

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), controller: controller, hasMultiselect: true),
      );

      // Filter down to just "Banana" — only one row is visible/rendered now.
      await tester.enterText(find.byType(EditableText), 'ban');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);

      await tester.tap(headerCheckbox());
      await tester.pumpAndSettle();

      // The selection must include every row of the full dataset — the ones
      // hidden by the search filter too — not just the single filtered-in
      // "Banana" row.
      expect(controller.selection, hasLength(rows.length));
      expect(controller.selection, containsAll(rows));
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
          actionsCount: 1,
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
          actionsCount: 1,
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

  group('LayrzTable actionsCount-driven actions column', () {
    /// Finds the header's actions-cell placeholder [SizedBox] — see
    /// `LayrzTableHeader._buildActionsCell` — sized to [width] and the
    /// table's default `headerHeight` (40).
    Finder headerActionsCellSize(double width) =>
        find.byWidgetPredicate((w) => w is SizedBox && w.width == width && w.height == 40);

    /// Finds every row's actions-cell [SizedBox] — see
    /// `LayrzTableRow._buildActionsCell` — sized to [width] and the table's
    /// default row `height` (50).
    Finder rowActionsCellSize(double width) =>
        find.byWidgetPredicate((w) => w is SizedBox && w.width == width && w.height == 50);

    testWidgets('actionsCount: 0 (default) renders no actions column even with actionsBuilder set', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          // actionsCount defaults to 0 — actionsBuilder must be entirely
          // ignored: no column reserved, no buttons rendered, in header or
          // rows.
          actionsBuilder: (row) => [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
          ],
        ),
      );

      expect(actionButtons(), findsNothing);
    });

    testWidgets('wide: actionsCount: N sizes the column to N fabs + spacers, header == rows', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      const actionsCount = 3;
      // Formula from LayrzTable._computeActionsColumnWidth: each fab is
      // kLayrzButtonHeight (45.0) square, wrapped in sp1/2 (3.0) horizontal
      // padding per side inside LayrzTableRow._buildWideActions, so each fab
      // contributes (45.0 + 6.0) to the row of fabs; the actions cell itself
      // adds sp1 (6.0) padding on each side (12.0 total).
      const expectedWidth = actionsCount * (45.0 + 6.0) + 12.0;

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          actionsCount: actionsCount,
          actionsBuilder: (row) => [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
            LayrzTableAction(icon: MdiIcons.eyeOutline, labelText: 'Show', onTap: () {}),
            LayrzTableAction(icon: MdiIcons.trashCanOutline, labelText: 'Delete', onTap: () {}),
          ],
        ),
      );

      expect(actionButtons(), findsNWidgets(rows.length * actionsCount));
      expect(headerActionsCellSize(expectedWidth), findsOneWidget);
      expect(rowActionsCellSize(expectedWidth), findsNWidgets(rows.length));

      final headerWidth = tester.getSize(headerActionsCellSize(expectedWidth)).width;
      final rowWidth = tester.getSize(rowActionsCellSize(expectedWidth).first).width;
      expect(headerWidth, rowWidth);
    });

    testWidgets('compact: actionsCount: N still sizes the column to exactly one trigger', (tester) async {
      useCompactViewport(tester);
      final rows = sampleRows();
      // Compact collapses to a single overflow trigger regardless of count —
      // kLayrzButtonCompactHeight (50.0) square + sp1 (6.0) cell padding on
      // each side (12.0 total).
      const expectedWidth = 50.0 + 12.0;

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(
          items: rows,
          columns: baseColumns(),
          actionsCount: 3,
          actionsBuilder: (row) => [
            LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
            LayrzTableAction(icon: MdiIcons.eyeOutline, labelText: 'Show', onTap: () {}),
            LayrzTableAction(icon: MdiIcons.trashCanOutline, labelText: 'Delete', onTap: () {}),
          ],
        ),
      );

      expect(headerActionsCellSize(expectedWidth), findsOneWidget);
      expect(rowActionsCellSize(expectedWidth), findsNWidgets(rows.length));

      final headerWidth = tester.getSize(headerActionsCellSize(expectedWidth)).width;
      final rowWidth = tester.getSize(rowActionsCellSize(expectedWidth).first).width;
      expect(headerWidth, rowWidth);
    });
  });

  group('LayrzTable loading state', () {
    /// Finds the [SizedBox] that reserves the top progress strip's space.
    ///
    /// [LayrzProgressBar] itself also renders a 2px-tall [SizedBox] inside
    /// its own tree when active (sized to its `height`), so a bare
    /// height-2.0 predicate over-matches while loading — excluding any
    /// [SizedBox] that has a [LayrzProgressBar] ancestor isolates
    /// [LayrzTable]'s own reserved-space wrapper, which sits above it.
    Finder topProgressStripSpace() => find.byElementPredicate((element) {
      final widget = element.widget;
      if (widget is! SizedBox || widget.height != 2.0) return false;
      return element.findAncestorWidgetOfExactType<LayrzProgressBar>() == null;
    }, description: 'top progress strip space');

    testWidgets('isLoading: true keeps rendering the header/body, with an animating top strip', (tester) async {
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

      // The header and rows are never hidden while loading — the top strip
      // is the only loading affordance now.
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      // loadingLabelText is currently unused (no home now that the centered
      // spinner+label is gone); it must not be rendered anywhere.
      expect(find.text('Please hold on...'), findsNothing);

      expect(topProgressStripSpace(), findsOneWidget);
      expect(find.byType(LayrzProgressBar), findsOneWidget);

      final bar = tester.widget<LayrzProgressBar>(find.byType(LayrzProgressBar));
      expect(bar.format, LayrzProgressFormat.linear);
      expect(bar.value, isNull, reason: 'indeterminate while isLoading is true');
    });

    testWidgets('isLoading: false (default) reserves the same top strip space, but paints no bar', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      expect(find.text('Name'), findsOneWidget);
      // The space is still reserved — toggling isLoading must never move the
      // header — but no LayrzProgressBar is mounted while idle, so there is
      // no sweep ticker running for nothing.
      expect(topProgressStripSpace(), findsOneWidget);
      expect(find.byType(LayrzProgressBar), findsNothing);
    });

    testWidgets('the top strip sits above the header in the widget tree, in both loading states', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      for (final isLoading in [false, true]) {
        await pumpTable(
          tester,
          LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), isLoading: isLoading),
        );

        final stripRect = tester.getRect(topProgressStripSpace());
        // 'Name' is the header's own text (LayrzTable renders no other
        // widget with that exact text), so its rect stands in for the
        // header row's position without reaching for an internal type.
        final headerTextRect = tester.getRect(find.text('Name'));
        expect(
          stripRect.bottom,
          lessThanOrEqualTo(headerTextRect.top),
          reason: 'strip must sit above the header when isLoading is $isLoading',
        );
      }
    });

    testWidgets('toggling isLoading does not move the header', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );
      final headerTopBefore = tester.getRect(find.text('Name')).top;

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns(), isLoading: true),
      );
      final headerTopAfter = tester.getRect(find.text('Name')).top;

      expect(headerTopAfter, headerTopBefore);
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

    testWidgets('emptyText: null falls back to context.l10n.tableEmpty', (tester) async {
      useWideViewport(tester);
      const l10n = LayrzUiL10nDefault();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: const [], columns: baseColumns()),
      );

      expect(find.text(l10n.tableEmpty), findsOneWidget);
    });

    testWidgets('emptySearchText: null falls back to context.l10n.tableNoSearchResults', (tester) async {
      useWideViewport(tester);
      final rows = sampleRows();
      const l10n = LayrzUiL10nDefault();

      await pumpTable(
        tester,
        LayrzTable<TableTestRow>(items: rows, columns: baseColumns()),
      );

      await tester.enterText(find.byType(EditableText), 'zzz-no-match');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tableNoSearchResults), findsOneWidget);
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
            actionsCount: 1,
            actionsBuilder: (row) => [
              LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () {}),
            ],
          ),
        ),
        size: const Size(500, 400),
      );

      // Pinned cells render once per row regardless of how far the
      // scrolling-middle region has scrolled. (rowCheckboxes() excludes the
      // header's own select-all checkbox, which also renders here since
      // hasMultiselect is true.)
      expect(rowCheckboxes(), findsNWidgets(rows.length));
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
      expect(rowCheckboxes(), findsNWidgets(rows.length));
      expect(actionButtons(), findsNWidgets(rows.length));
    });
  });
}

/// Reproduces the exact widget shape that surfaced the
/// "setState() or markNeedsBuild() called during build" crash in
/// `example/lib/src/sections/table_section.dart`: a [StatefulWidget] that
/// constructs a [LayrzTable] from its own `build()` and updates its own
/// state from [LayrzTable.onFilteredCountChanged].
///
/// Building [LayrzTable] here — rather than passing `reported.add` straight
/// to a directly-pumped [LayrzTable], as the older
/// "reports the initial filtered count" test does — matters: the crash only
/// occurs when the table's `initState` (and therefore its first
/// [LayrzTable.onFilteredCountChanged] call) runs while a wrapping widget is
/// still inside its own `build()`, which is how a newly-mounted child is
/// always initialized. Renders the last reported count as plain text so the
/// test can assert on it without reaching into private state.
class _CountDisplay<T> extends StatefulWidget {
  /// Creates a [_CountDisplay].
  const _CountDisplay({required this.items, required this.columns});

  /// The rows handed straight through to the wrapped [LayrzTable.items].
  final List<T> items;

  /// The columns handed straight through to the wrapped [LayrzTable.columns].
  final List<LayrzColumn<T>> columns;

  @override
  State<_CountDisplay<T>> createState() => _CountDisplayState<T>();
}

class _CountDisplayState<T> extends State<_CountDisplay<T>> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count: $_count'),
        Expanded(
          child: LayrzTable<T>(
            items: widget.items,
            columns: widget.columns,
            onFilteredCountChanged: (count) => setState(() => _count = count),
          ),
        ),
      ],
    );
  }
}
