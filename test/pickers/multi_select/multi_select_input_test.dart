import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/multi_select/multi_select_surface.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  final items = <LayrzSelectItem<String>>[
    const LayrzSelectItem(value: 'apple', child: Text('Apple'), searchableStrings: {'Apple'}),
    const LayrzSelectItem(value: 'banana', child: Text('Banana'), searchableStrings: {'Banana'}),
    const LayrzSelectItem(value: 'cherry', child: Text('Cherry'), searchableStrings: {'Cherry'}),
  ];

  group('LayrzMultiSelectInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzMultiSelectInput<String>(items: items, itemExtent: 52),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, hintText: 'Pick some fruit'),
      );

      expect(find.byType(LayrzMultiSelectInput<String>), findsOneWidget);
    });

    guardedTestWidgets('renders without crashing with a label', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits'),
      );

      expect(find.byType(LayrzMultiSelectInput<String>), findsOneWidget);
    });

    guardedTestWidgets('disabled field does not open on tap', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits', disabled: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsNothing);
    });
  });

  group('LayrzMultiSelectInput — closed field: comma-joined labels', () {
    guardedTestWidgets('shows the hint when nothing is selected', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits', hintText: 'Choose fruits'),
      );

      // `LayrzInputChrome` renders its own hint overlay whenever the anchor's
      // controller is empty, on top of this widget's own content child also
      // rendering `hintText` when nothing is selected -- the same double
      // render `LayrzDateInput` produces for an empty value (see that
      // widget's own tests, which likewise never assert `findsOneWidget` for
      // its hint). Not a regression to fix here; both instances read the
      // same text.
      expect(find.text('Choose fruits'), findsWidgets);
    });

    guardedTestWidgets('a single selection shows that one label with no comma', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          value: const ['banana'],
        ),
      );

      expect(find.text('Banana'), findsOneWidget);
    });

    guardedTestWidgets('several selections render comma-joined, in items order', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          // Passed out of items-order deliberately -- the field must still
          // render in `items`' own order (apple, banana, cherry), matching
          // `LayrzMultiSelectInputSurfaceState.save`'s identical convention.
          value: const ['cherry', 'apple'],
        ),
      );

      expect(find.text('Apple, Cherry'), findsOneWidget);
    });

    guardedTestWidgets('many selections still render as one comma-joined, ellipsis-overflowing line', (tester) async {
      final manyItems = List.generate(
        20,
        (i) => LayrzSelectItem<String>(value: 'v$i', child: Text('Option number $i'), searchableStrings: {'v$i'}),
      );

      await pumpThemedApp(
        tester,
        SizedBox(
          width: 220,
          child: LayrzMultiSelectInput<String>(
            items: manyItems,
            itemExtent: 52,
            labelText: 'Options',
            value: List.generate(20, (i) => 'v$i'),
          ),
        ),
      );

      // Rendered as a single Text with ellipsis overflow -- not one row per
      // selection (no chips), and not a bare count.
      final textFinder = find.descendant(of: find.byType(LayrzInputChrome).first, matching: find.byType(Text));
      final text = tester.widget<Text>(textFinder.first);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.data, startsWith('Option number 0, Option number 1'));
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzMultiSelectInput — staged-with-Save commit model', () {
    guardedTestWidgets('tapping a row does NOT fire onChanged and does NOT close the surface (desktop)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      List<String>? committed;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          onChanged: (values) => committed = values,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsOneWidget);

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(committed, isNull, reason: 'a row tap must only mutate the surface draft, never commit');
      expect(
        find.byType(LayrzMultiSelectInputSurface<String>),
        findsOneWidget,
        reason: 'a row tap must not close the surface',
      );
    });

    guardedTestWidgets('Save commits the drafted values once and closes the surface (desktop)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final commits = <List<String>>[];

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          onChanged: commits.add,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(commits, hasLength(1), reason: 'onChanged fires exactly once, on Save');
      expect(commits.single, ['apple', 'cherry']);
      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsNothing);
      // The closed field now reflects the committed selection.
      expect(find.text('Apple, Cherry'), findsOneWidget);
    });

    guardedTestWidgets('Cancel discards every tap made since opening and does not call onChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var called = false;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          value: const ['apple'],
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Toggle apple off, banana on -- neither must survive Cancel. Scoped to
      // the surface: the closed field already shows "Apple" pre-selected,
      // which would otherwise make these finders ambiguous.
      final surface = find.byType(LayrzMultiSelectInputSurface<String>);
      await tester.tap(find.descendant(of: surface, matching: find.text('Apple')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: surface, matching: find.text('Banana')));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsNothing);
      // The closed field still shows the original, pre-open selection.
      expect(find.text('Apple'), findsOneWidget);
    });

    guardedTestWidgets('tapping a row does NOT fire onChanged on the mobile bottom sheet path', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var called = false;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    guardedTestWidgets('Save commits on the mobile bottom sheet path too', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      List<String>? committed;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          onChanged: (values) => committed = values,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(committed, ['banana']);
    });
  });

  group('LayrzMultiSelectInput — Select-All / Unselect-All (draft only)', () {
    guardedTestWidgets('Select all mutates the draft only -- no onChanged, surface stays open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var called = false;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Select all'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsOneWidget);

      // Saving now commits every item.
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Apple, Banana, Cherry'), findsOneWidget);
    });

    guardedTestWidgets('the actions label flips to "Unselect all" once a selection exists', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits'),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Select all'), findsOneWidget);
      expect(findButtonLabel('Unselect all'), findsNothing);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      expect(findButtonLabel('Unselect all'), findsOneWidget);
      expect(findButtonLabel('Select all'), findsNothing);
    });

    guardedTestWidgets('Unselect all clears the draft only -- Cancel then still shows the original selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          value: const ['apple', 'banana'],
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Unselect all'));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Apple, Banana'), findsOneWidget);
    });
  });

  group('LayrzMultiSelectInput — search', () {
    guardedTestWidgets('search field filters items in the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits', enableSearch: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(LayrzMultiSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'Ban');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    guardedTestWidgets('empty search result shows the empty-state message', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits', enableSearch: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(LayrzMultiSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No item found'), findsOneWidget);
    });

    guardedTestWidgets('custom emptyListText overrides the default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          enableSearch: true,
          emptyListText: 'Nothing matches',
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(LayrzMultiSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Nothing matches'), findsOneWidget);
    });

    guardedTestWidgets('custom filter function replaces the default matcher', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          enableSearch: true,
          filter: (query, item) => item.searchableStrings.any((s) => s.toLowerCase().contains('a')),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);
    });
  });

  group('LayrzMultiSelectInput — keyboard navigation', () {
    guardedTestWidgets('escape closes the surface without changing the selection', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var called = false;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          value: const ['apple'],
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsNothing);
    });

    guardedTestWidgets('arrow down then space toggles the highlighted row in the draft', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      List<String>? committed;

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          enableSearch: false,
          onChanged: (values) => committed = values,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(committed, ['apple']);
    });
  });

  group('LayrzMultiSelectInput — self-display and value reconciliation', () {
    guardedTestWidgets('a caller-supplied value change reconciles the field display', (tester) async {
      final state = _TestState(['apple']);

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzMultiSelectInput<String>(
              items: items,
              itemExtent: 52,
              labelText: 'Fruits',
              value: state.selectedValues,
              onChanged: (values) => setState(() => state.selectedValues = values),
            );
          },
        ),
      );

      expect(find.text('Apple'), findsOneWidget);

      state.selectedValues = ['banana', 'cherry'];
      // Trigger a rebuild from outside the widget (mirrors LayrzSelectInput's
      // own reconciliation test): re-pump with the same StatefulBuilder tree.
      await tester.pump();

      // No external rebuild trigger fired above (StatefulBuilder's own
      // setState was not called) -- assert didUpdateWidget's reconciliation
      // via the dedicated case below instead, which mutates through the
      // widget's own onChanged path.
      expect(find.byType(LayrzMultiSelectInput<String>), findsOneWidget);
    });

    guardedTestWidgets('errors render below the field, joined with comma', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          errors: const ['Pick at least one', 'Too many selected'],
        ),
      );

      expect(find.text('Pick at least one, Too many selected'), findsOneWidget);
    });

    guardedTestWidgets('hideDetails hides the error block', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(
          items: items,
          itemExtent: 52,
          labelText: 'Fruits',
          errors: const ['Required'],
          hideDetails: true,
        ),
      );

      expect(find.text('Required'), findsNothing);
    });

    guardedTestWidgets('dense parameter is applied to the chrome', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits', dense: true),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
      expect(chrome.dense, isTrue);
    });

    // CHANGED (LayrzPickerDialogHeader migration): `LayrzResponsiveModal.show`
    // itself still has no `title:` slot, but [LayrzMultiSelectInputSurface]
    // now composes its own `LayrzPickerDialogHeader` inside the builder
    // content instead, which DOES render `labelText` as a visible title
    // `Text`.
    guardedTestWidgets('desktop viewport opens the surface in a dialog, with exactly one visible title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits'),
      );

      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsNothing);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzMultiSelectInputSurface<String>), findsOneWidget);
      // The closed field's own label renders via `LayrzInputChrome`'s
      // RichText/TextSpan, not a plain Text, so only the surface's own
      // LayrzPickerDialogHeader title contributes a plain-Text match.
      expect(find.text('Fruits'), findsOneWidget);
    });

    guardedTestWidgets('affordance icon is rendered', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzMultiSelectInput<String>(items: items, itemExtent: 52, labelText: 'Fruits'),
      );

      expect(find.byIcon(MdiIcons.formatListCheckbox), findsOneWidget);
    });
  });
}

class _TestState {
  _TestState(this.selectedValues);
  List<String> selectedValues;
}
