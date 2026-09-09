import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Sets the test surface to a wide (desktop-class) viewport, well above the
/// `960px` compact/wide threshold read by `context.isCompact`.
///
/// Registers `tester.view.reset` via [addTearDown] so the override never
/// leaks into a later test in the same file.
void useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Sets the test surface to a narrow (mobile-class) viewport, well below the
/// `960px` compact/wide threshold read by `context.isCompact`.
///
/// Registers `tester.view.reset` via [addTearDown] so the override never
/// leaks into a later test in the same file.
void useCompactViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps [child] into the minimal themed tree a `LayrzTable<T>` (or one of
/// its constituent widgets: row, header, column menu) needs to render.
///
/// Mirrors `test/helpers/pump_themed.dart`'s tree shape (`Localizations` +
/// `LayrzTheme` + `Overlay`) but is kept local to `test/table/` per U11's
/// file list, since the table suite needs a couple of table-specific
/// defaults ([size] to bound the table's `Expanded`/`LayoutBuilder` region,
/// which — unlike most themed widgets — has no intrinsic size of its own).
///
/// [tester] is the active [WidgetTester]. [size] bounds [child] inside a
/// [SizedBox] so [LayrzTable]'s internal `LayoutBuilder` and `ListView`
/// receive finite constraints; defaults to a generous `900x600` desktop-ish
/// box that comfortably fits a header, a search field, and several rows.
/// [theme] optionally overrides the default light [LayrzThemeData].
Future<void> pumpTable(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(900, 600),
  LayrzThemeData? theme,
}) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: theme ?? LayrzThemeData.light(),
        child: LayrzSnackbarMessenger(
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Center(
                  child: SizedBox(width: size.width, height: size.height, child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A minimal row model used across the U11 table widget/a11y suites.
///
/// Kept intentionally small — an `id` for identity/equality (so
/// [LayrzTableController]'s `Set<T>`-based selection behaves predictably in
/// tests), a sortable [name] string, and a numeric [amount] for exercising
/// the numeric branch of the default sort comparator.
@immutable
class TableTestRow {
  /// This row's stable identity, also used for `==`/`hashCode`.
  final int id;

  /// A display name, sorted/searched as a case-insensitive string.
  final String name;

  /// A numeric value, sorted via the default comparator's numeric branch.
  final int amount;

  /// Creates a [TableTestRow].
  const TableTestRow({required this.id, required this.name, required this.amount});

  @override
  bool operator ==(Object other) => identical(this, other) || (other is TableTestRow && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TableTestRow($id, $name, $amount)';
}

/// A small, deterministic fixture list of [TableTestRow]s for the U11 suites.
///
/// Deliberately unsorted by [TableTestRow.name] and [TableTestRow.amount] so
/// sort tests have real work to do, and includes distinct substrings for
/// search-filter tests (only "Banana" contains "ban", only "Cherry" and
/// "Cherimoya" contain "cher").
List<TableTestRow> sampleRows() => const [
  TableTestRow(id: 1, name: 'Banana', amount: 30),
  TableTestRow(id: 2, name: 'Apple', amount: 10),
  TableTestRow(id: 3, name: 'Cherry', amount: 20),
  TableTestRow(id: 4, name: 'Date', amount: 40),
  TableTestRow(id: 5, name: 'Cherimoya', amount: 15),
];
