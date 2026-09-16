import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'helpers/pump_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Every clipboard-copy path a LayrzTable cell might exercise asserts
    // against `Clipboard.setData`, so start each test with a clean mock
    // channel handler rather than relying on whatever the previous test's
    // handler left behind.
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
      width: 150,
    ),
    LayrzColumn<TableTestRow>(
      key: const ValueKey('amount'),
      headerText: 'Amount',
      valueBuilder: (row) => row.amount.toString(),
      width: 150,
    ),
  ];

  group('LayrzTable onFilteredCountChanged after an items change', () {
    testWidgets(
      'does not crash when items change via LayoutBuilder-driven didUpdateWidget (regression)',
      (tester) async {
        // Regression test for the "setState() called during build" crash
        // reported against LayrzScaffoldShell: LayrzTable's didUpdateWidget
        // calls _recompute() synchronously whenever widget.items changes
        // identity, and _recompute() (when it has no sort column active, so
        // it never reaches an `await`) reports through
        // onFilteredCountChanged synchronously in the same call stack. When
        // the items swap is itself triggered from inside an ancestor's
        // performLayout (exactly what _ItemsHost/LayoutBuilder below does),
        // that synchronous report — and any setState a consumer's callback
        // makes in response, the obvious thing to do with a "count changed"
        // notification — lands mid-layout, which is still inside the
        // framework's build/layout/paint phase. Flutter's assertion then
        // throws "setState() or markNeedsBuild() called during build".
        //
        // This exact chain matches the reported stack trace:
        // _RenderLayoutBuilder.performLayout -> didUpdateWidget -> _recompute
        // -> _notifyFilteredCountChanged -> the external callback's setState.
        useWideViewport(tester);
        final firstRows = sampleRows();
        final secondRows = [
          ...sampleRows(),
          const TableTestRow(id: 6, name: 'Elderberry', amount: 50),
        ];

        final key = GlobalKey<_ItemsHostState<TableTestRow>>();
        final reported = <int>[];

        await pumpTable(
          tester,
          _ItemsHost<TableTestRow>(
            key: key,
            initialItems: firstRows,
            columns: baseColumns(),
            onFilteredCountChanged: reported.add,
          ),
        );
        await tester.pumpAndSettle();
        reported.clear();

        // Swap the items list from inside the host's own build() — this is
        // what makes the resulting LayrzTable.didUpdateWidget call land
        // during the ancestor LayoutBuilder's performLayout, matching the
        // reported crash's exact call stack rather than a synthetic one.
        key.currentState!.swapItems(secondRows);
        await tester.pump();

        // The crash (if present) surfaces as a FlutterError during this very
        // pump — before any post-frame callback runs — so reaching this line
        // at all, with no exception recorded, is part of the assertion.
        expect(tester.takeException(), isNull);

        // The new, larger count must still be delivered once the frame
        // settles rather than silently dropped by the deferral.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(reported, contains(secondRows.length));
      },
    );

    testWidgets(
      'delivers the latest count when a consumer setState-s from the callback after an items change (regression)',
      (tester) async {
        // Same reproduction as above, but through a callback that itself
        // calls setState (mirroring _CountDisplay's shape in table_test.dart)
        // so the regression is exercised end-to-end: no crash, and the
        // final on-screen count matches the new items list.
        useWideViewport(tester);
        final firstRows = sampleRows();
        final secondRows = [
          ...sampleRows(),
          const TableTestRow(id: 6, name: 'Elderberry', amount: 50),
          const TableTestRow(id: 7, name: 'Fig', amount: 60),
        ];

        final key = GlobalKey<_CountDisplayHostState<TableTestRow>>();

        await pumpTable(
          tester,
          _CountDisplayHost<TableTestRow>(key: key, initialItems: firstRows, columns: baseColumns()),
        );
        await tester.pumpAndSettle();
        expect(find.text('count: ${firstRows.length}'), findsOneWidget);

        key.currentState!.swapItems(secondRows);
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('count: ${secondRows.length}'), findsOneWidget);
      },
    );
  });
}

/// Hosts a [LayrzTable] behind a [LayoutBuilder] and exposes [swapItems] so a
/// test can change [LayrzTable.items] identity from inside this widget's own
/// `build()` — the call path that makes the resulting
/// `LayrzTable.didUpdateWidget` run from inside the ancestor
/// [LayoutBuilder]'s `performLayout`, matching the reported crash's stack
/// trace (`_RenderLayoutBuilder.performLayout` -> `didUpdateWidget`) rather
/// than a synthetic reproduction.
class _ItemsHost<T> extends StatefulWidget {
  /// Creates an [_ItemsHost].
  const _ItemsHost({super.key, required this.initialItems, required this.columns, this.onFilteredCountChanged});

  /// The items [LayrzTable.items] is first built with.
  final List<T> initialItems;

  /// The columns handed straight through to the wrapped [LayrzTable.columns].
  final List<LayrzColumn<T>> columns;

  /// Forwarded to the wrapped [LayrzTable.onFilteredCountChanged].
  final void Function(int count)? onFilteredCountChanged;

  @override
  State<_ItemsHost<T>> createState() => _ItemsHostState<T>();
}

class _ItemsHostState<T> extends State<_ItemsHost<T>> {
  late List<T> _items = widget.initialItems;

  /// Replaces [_items] with [newItems] and rebuilds, so the wrapped
  /// [LayrzTable] receives a new, non-identical `items` list on its next
  /// build — the condition [LayrzTable.didUpdateWidget] checks to decide
  /// whether to re-run `_recompute()`.
  void swapItems(List<T> newItems) => setState(() => _items = newItems);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return LayrzTable<T>(
          items: _items,
          columns: widget.columns,
          onFilteredCountChanged: widget.onFilteredCountChanged,
        );
      },
    );
  }
}

/// Combines [_ItemsHost]'s items-swap shape with `_CountDisplay`'s
/// setState-from-callback shape (see `table_test.dart`), so the callback
/// itself does the obvious, expected thing with a "count changed"
/// notification while the items swap is in flight.
class _CountDisplayHost<T> extends StatefulWidget {
  /// Creates a [_CountDisplayHost].
  const _CountDisplayHost({super.key, required this.initialItems, required this.columns});

  /// The items [LayrzTable.items] is first built with.
  final List<T> initialItems;

  /// The columns handed straight through to the wrapped [LayrzTable.columns].
  final List<LayrzColumn<T>> columns;

  @override
  State<_CountDisplayHost<T>> createState() => _CountDisplayHostState<T>();
}

class _CountDisplayHostState<T> extends State<_CountDisplayHost<T>> {
  late List<T> _items = widget.initialItems;
  int _count = 0;

  /// Replaces [_items] with [newItems] and rebuilds, mirroring
  /// [_ItemsHostState.swapItems].
  void swapItems(List<T> newItems) => setState(() => _items = newItems);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count: $_count'),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return LayrzTable<T>(
                items: _items,
                columns: widget.columns,
                onFilteredCountChanged: (count) => setState(() => _count = count),
              );
            },
          ),
        ),
      ],
    );
  }
}
