import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// Pumps [surface] inside a fixed-height [SizedBox], matching how
/// [LayrzMultiSelectInputSurface] is actually hosted in production —
/// [LayrzMultiSelectInput._openPicker] always gives it a bounded height (a
/// bigger [LayrzDialogConfig] on the dialog branch, `scrollable: false` on
/// the sheet branch) — see this surface's own class doc, "Pinned header +
/// search, scrolling list only". The surface's own `Expanded(child:
/// listOrEmptyState)` requires a bounded ancestor to resolve at all;
/// `pumpThemed` alone gives its child unbounded height via `Center`, which
/// this layout cannot resolve without a bound.
Future<void> _pumpBoundedSurface(WidgetTester tester, Widget surface) {
  return pumpThemed(tester, SizedBox(height: 600, width: 700, child: surface));
}

void main() {
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
  ];

  group('LayrzMultiSelectInputSurface — rendering', () {
    guardedTestWidgets('renders every item', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('seeds the draft from initialValues -- those rows render selected', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(surfaceKey.currentState!.hasSelection, isTrue);

      // Maintainer review: each row now reflects selection via a real
      // LayrzCheckboxInput (not a check/blank icon pair), wrapped in an
      // IgnorePointer -- the row's own LayrzTappable.onTap already toggles
      // selection for a tap anywhere in the row, so the checkbox's own value
      // is purely a reflection of draft membership, never itself a trigger.
      // Each row is scoped by its own LayrzTappable (the IgnorePointer wraps
      // only the checkbox, as a sibling of the row's label, not an ancestor
      // of the label text).
      final bananaRow = find.ancestor(
        of: find.text('Banana'),
        matching: find.byType(LayrzTappable),
      );
      // Banana is selected (in initialValues); Apple/Cherry are not.
      final selectedCheckbox = tester.widget<LayrzCheckboxInput>(
        find.descendant(of: bananaRow, matching: find.byType(LayrzCheckboxInput)).first,
      );
      expect(selectedCheckbox.value, isTrue);

      final appleRow = find.ancestor(
        of: find.text('Apple'),
        matching: find.byType(LayrzTappable),
      );
      final unselectedCheckbox = tester.widget<LayrzCheckboxInput>(
        find.descendant(of: appleRow, matching: find.byType(LayrzCheckboxInput)).first,
      );
      expect(unselectedCheckbox.value, isFalse);
    });

    guardedTestWidgets('the row checkbox flips its value as the draft is toggled by a row tap', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      Finder checkboxFor(String label) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(LayrzTappable)),
        matching: find.byType(LayrzCheckboxInput),
      );

      expect(tester.widget<LayrzCheckboxInput>(checkboxFor('Apple').first).value, isFalse);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(tester.widget<LayrzCheckboxInput>(checkboxFor('Apple').first).value, isTrue);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(tester.widget<LayrzCheckboxInput>(checkboxFor('Apple').first).value, isFalse);
    });

    guardedTestWidgets('with no search field, all items still render (enableSearch: false)', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
    });

    // Maintainer review: "Pinned header + search, scrolling list only" --
    // the header row (title | dense search | X) is a fixed, non-scrolling
    // sibling of an Expanded ListView, not part of one shared scrollable
    // column the way the pre-review layout stacked them (see this surface's
    // own class doc). This proves the structural split, not merely that a
    // ListView exists somewhere.
    guardedTestWidgets('the header (with its inline search) is pinned outside the scrolling list region', (
      tester,
    ) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      // The header (carrying the search EditableText) must NOT be a
      // descendant of the ListView -- it is a fixed sibling above it.
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);
      expect(
        find.descendant(of: listView, matching: find.byType(EditableText)),
        findsNothing,
        reason: 'the search field must live in the pinned header, not inside the scrolling ListView',
      );
      // The search field is reachable in the tree at all (outside the list).
      expect(find.byType(EditableText), findsOneWidget);

      // The ListView itself is the sole child of an Expanded -- the only
      // part of this surface that claims flexible/scrolling height.
      expect(
        find.ancestor(of: listView, matching: find.byType(Expanded)),
        findsOneWidget,
      );
    });

    guardedTestWidgets(
      'a row at the minimum itemExtent floor renders with no vertical overflow on a narrow viewport',
      (tester) async {
        // Regression test for the checkbox-row overflow this floor exists to
        // prevent (see kLayrzPickerMinItemExtent's own doc): a full
        // LayrzCheckboxInput indicator is 40px tall on its own, plus this
        // row's own vertical padding, floors the safe itemExtent at 52. A
        // narrow (360x640) viewport with itemExtent set exactly to that floor
        // must render every row with no RenderFlex (or other) overflow --
        // guardedTestWidgets fails the test on any uncaught exception,
        // including an overflow, so no explicit assertion is needed beyond
        // pumping and settling.
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            height: 600,
            width: 360,
            child: LayrzMultiSelectInputSurface<String>(
              items: items,
              initialValues: const [],
              enableSearch: true,
              itemExtent: 52,
              onDraftCommitted: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsOneWidget);
      },
    );

    guardedTestWidgets('empty items list shows the empty-state text', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: const [],
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('No item found'), findsOneWidget);
    });
  });

  group('LayrzMultiSelectInputSurfaceState — draft mutation surface', () {
    guardedTestWidgets('canSave is always true, even with an empty draft', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(surfaceKey.currentState!.canSave, isTrue);
      expect(surfaceKey.currentState!.hasSelection, isFalse);
    });

    guardedTestWidgets('tapping a row toggles it on, then off, without calling onDraftCommitted', (tester) async {
      var draftChanges = 0;
      var committed = false;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftChanged: () => draftChanges++,
          onDraftCommitted: (_) => committed = true,
        ),
      );

      final beforeTap = draftChanges;

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(draftChanges, greaterThan(beforeTap));
      expect(committed, isFalse);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(committed, isFalse, reason: 'a second tap toggling the row back off must also not commit');
    });

    guardedTestWidgets('selectAll mutates the draft to every item, in order, without committing', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      surfaceKey.currentState!.selectAll();
      await tester.pumpAndSettle();

      expect(committed, isNull);
      expect(surfaceKey.currentState!.hasSelection, isTrue);

      surfaceKey.currentState!.save();
      expect(committed, ['apple', 'banana', 'cherry']);
    });

    guardedTestWidgets('unselectAll clears the draft without committing', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['apple', 'cherry'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      surfaceKey.currentState!.unselectAll();
      await tester.pumpAndSettle();

      expect(committed, isNull);
      expect(surfaceKey.currentState!.hasSelection, isFalse);

      surfaceKey.currentState!.save();
      expect(committed, isEmpty);
    });

    guardedTestWidgets('save() reports the draft in items order, regardless of tap order', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      // Tap cherry, then apple -- reverse of items order.
      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();

      expect(committed, ['apple', 'cherry'], reason: 'save() must report items in the surface\'s own item order');
    });
  });

  group('LayrzMultiSelectInputSurface — search', () {
    guardedTestWidgets('typing narrows the visible items', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Ban');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('clearing the query restores the full list', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Ban');
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('a custom filter replaces the default matcher', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          filter: (query, item) => item.searchableStrings.any((s) => s.toLowerCase().contains('a')),
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('a selected row toggled while search-filtered still updates the draft', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Ban');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();
      expect(committed, ['banana']);
    });
  });

  group('LayrzMultiSelectInputSurface — keyboard navigation', () {
    guardedTestWidgets('arrow down highlights, space toggles the highlighted row', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();
      expect(committed, ['apple']);
    });

    guardedTestWidgets('arrow down wraps to the first item at the end of the list', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      for (var i = 0; i < items.length + 1; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('arrow up wraps to the last item at the beginning of the list', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('enter with no highlight does nothing', (tester) async {
      var committed = false;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (_) => committed = true,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(committed, isFalse);
    });
  });

  group('LayrzMultiSelectInputSurface — All/Selected tabs (DESIGN-43)', () {
    guardedTestWidgets('defaults to the All tab, showing every item with the full count', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Selected (1)'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('switching to Selected shows only drafted items, All shows every item again', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);

      await tester.tap(find.text('All (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    guardedTestWidgets('the Selected count updates live as rows are toggled', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      expect(find.text('Selected (0)'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Selected (1)'), findsOneWidget);

      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();
      expect(find.text('Selected (2)'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Selected (1)'), findsOneWidget);
    });

    guardedTestWidgets('toggling a row while on the Selected tab removes it from view immediately', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['apple', 'banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsOneWidget);
    });

    guardedTestWidgets('search narrows both the All count and the visible rows within the active tab', (
      tester,
    ) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      // "an" matches Banana only.
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('search still filters within the Selected tab', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const ['apple', 'banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (2)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    guardedTestWidgets('the empty state renders on the Selected tab when the draft is empty', (tester) async {
      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          items: items,
          initialValues: const [],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (_) {},
        ),
      );

      await tester.tap(find.text('Selected (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No item found'), findsOneWidget);
    });

    guardedTestWidgets('keyboard navigation on the Selected tab only cycles through drafted rows', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['cherry'],
          enableSearch: false,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.tap(find.text('Selected (1)'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Only "cherry" is visible on the Selected tab -- arrow-down highlights
      // it, and space toggles it OFF (it was already in the draft).
      surfaceKey.currentState!.save();
      expect(committed, isEmpty);
    });

    guardedTestWidgets('save() still commits from the full items set regardless of the active tab', (tester) async {
      final surfaceKey = GlobalKey<LayrzMultiSelectInputSurfaceState<String>>();
      List<String>? committed;

      await _pumpBoundedSurface(
        tester,
        LayrzMultiSelectInputSurface<String>(
          key: surfaceKey,
          items: items,
          initialValues: const ['apple', 'banana'],
          enableSearch: true,
          itemExtent: 52,
          onDraftCommitted: (values) => committed = values,
        ),
      );

      await tester.tap(find.text('Selected (2)'));
      await tester.pumpAndSettle();

      surfaceKey.currentState!.save();
      expect(committed, ['apple', 'banana']);
    });
  });
}
