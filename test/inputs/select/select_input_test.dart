import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/select/select_input_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';
import '../../helpers/find_button_label.dart';

void main() {
  group('LayrzSelectInput', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
      const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
      const LayrzSelectItem(value: 'c', child: Text('Option C'), searchableStrings: {'Option C'}),
    ];

    testWidgets('renders without crashing', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('displays label text', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'My Label',
        ),
      );

      expect(findButtonLabel('My Label'), findsOneWidget);
    });

    testWidgets('displays selected item text in field', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'b',
          labelText: 'Choose one',
        ),
      );

      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('chrome readOnly flag is false (field-as-searcher redesign)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Verify the select input exists
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);

      // Chrome's own `readOnly` was always inert (its only consequence was the lock
      // icon, suppressed via `suppressReadOnlyLock`); non-editability came from the
      // old `Text` content child, not this flag. Now that the field is genuinely
      // editable (the field is the searcher), the flag is `false` -- see the
      // BREAKING changelog entry for the redesign this pins.
      final chromeWidget = find.byType(LayrzInputChrome);
      expect(chromeWidget, findsOneWidget);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.readOnly, false);
    });

    testWidgets('does not render lock icon (uses dropdown chevron instead)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Should have a chevron icon (dropdown)
      expect(find.byIcon(MdiIcons.chevronDown), findsOneWidget);
    });

    testWidgets('disabled field does not open on tap', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          disabled: true,
        ),
      );

      // Disabled field shouldn't respond to taps
      final field = find.byType(LayrzSelectInput<String>);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Should still be disabled
      expect(find.byIcon(MdiIcons.chevronDown), findsOneWidget);
    });

    testWidgets('opens surface on tap (mobile viewport)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Items should appear in the surface
      expect(find.text('Option A'), findsWidgets);
      expect(find.text('Option B'), findsWidgets);
      expect(find.text('Option C'), findsWidgets);
    });

    testWidgets('selecting item calls onChanged with correct item', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzSelectItem<String>? selectedItem;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          onChanged: (item) {
            selectedItem = item;
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Tap an item
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      expect(selectedItem, isNotNull);
      expect(selectedItem!.value, 'b');
      expect(selectedItem!.searchableStrings, {'Option B'});
    });

    testWidgets('field updates after selection', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final state = _TestState();

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              value: state.selectedValue,
              labelText: 'Choose one',
              onChanged: (item) {
                setState(() {
                  state.selectedValue = item?.value;
                });
              },
            );
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Options should appear in the opened surface
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);

      // Tap an item
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      // Field should now show selected value
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('search field filters items', (tester) async {
      // REWRITE (DESIGN-145): search moved back into the opened surface's own
      // internal search field (see select_input_surface.dart) -- the closed field
      // itself is always read-only and never hosts a query. Typing narrows the
      // list live from there instead.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      // Tap the field to open the surface.
      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Type into the surface's own internal search field, not the closed field.
      final searchField = find.descendant(
        of: find.byType(LayrzSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'B');
      await tester.pumpAndSettle();

      // Assert the narrowing: the right item remains, the wrong ones are gone.
      expect(find.text('Option B'), findsWidgets);
      expect(find.text('Option A'), findsNothing);
      expect(find.text('Option C'), findsNothing);
    });

    testWidgets('keyboard arrow navigation works', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final state = _TestState();

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              value: state.selectedValue,
              labelText: 'Choose one',
              enableSearch: false,
              onChanged: (item) {
                setState(() {
                  state.selectedValue = item?.value;
                });
              },
            );
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Focus the list (simulate keyboard focus on list)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Press Enter to select
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Surface should close after selection and field should show selected value
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('escape key closes surface without changing value', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzSelectItem<String>? selectedItem;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'a',
          labelText: 'Choose one',
          onChanged: (item) {
            selectedItem = item;
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Press Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Surface should be closed (field still shows Option A)
      expect(find.text('Option A'), findsOneWidget);
      // onChanged should not have been called
      expect(selectedItem, isNull);
    });

    testWidgets('empty list shows empty state message', (tester) async {
      // REWRITE (DESIGN-145): typed into the surface's own internal search field,
      // not the closed field itself -- see the class doc.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(LayrzSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'nonexistent');
      await tester.pumpAndSettle();

      // Empty message should appear, and no items should remain.
      expect(find.text('No item found'), findsOneWidget);
      expect(find.text('Option A'), findsNothing);
      expect(find.text('Option B'), findsNothing);
      expect(find.text('Option C'), findsNothing);
    });

    testWidgets('custom filter function works', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
          filter: (query, item) => item.searchableStrings.any((s) => s.contains('A')),
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Only Option A should appear
      expect(find.text('Option A'), findsWidgets);
      expect(find.text('Option B'), findsNothing);
      expect(find.text('Option C'), findsNothing);
    });

    testWidgets('error messages display correctly', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          errors: const ['This field is required'],
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('custom item rendering works', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final customItems = <LayrzSelectItem<String>>[
        LayrzSelectItem(
          value: 'a',
          child: const Text('Custom A'),
          searchableStrings: const {'Option A'},
        ),
      ];

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: customItems,
          labelText: 'Choose one',
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Custom rendering should appear in surface
      expect(find.text('Custom A'), findsOneWidget);
    });

    testWidgets('opens surface when field has no value selected', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Field should be empty initially
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);

      // Tap the field to open surface
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Surface should be open with items visible
      expect(find.text('Option A'), findsWidgets);
      expect(find.text('Option B'), findsWidgets);
      expect(find.text('Option C'), findsWidgets);
    });

    testWidgets('handles null value correctly', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String?>(
          itemExtent: 40,
          items: const [
            LayrzSelectItem(value: null, child: Text('None'), searchableStrings: {'None'}),
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          labelText: 'Choose one',
          canUnselect: true,
        ),
      );

      // Field should be empty initially
      // (no selected item text shown)
      expect(find.byType(LayrzSelectInput<String?>), findsOneWidget);

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Both options should appear in the surface
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('desktop viewport opens the selection surface in LayrzEndDrawer (DESIGN-98)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      expect(find.byType(LayrzSelectInputSurface<String>), findsNothing);

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Desktop opens the selection surface via LayrzEndDrawer (DESIGN-98),
      // replacing the previous LayrzAnchoredPanel hosting.
      expect(find.byType(LayrzSelectInputSurface<String>), findsOneWidget);
    });

    testWidgets('desktop viewport opens panel on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Items should appear in the anchored panel
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('desktop selection closes panel', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var selectedValue = '';

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              labelText: 'Choose one',
              onChanged: (item) {
                if (item != null) {
                  selectedValue = item.value ?? '';
                }
              },
            );
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Select an item
      await tester.tap(find.text('Option C'));
      await tester.pumpAndSettle();

      // Callback should have been invoked
      expect(selectedValue, equals('c'));
    });

    testWidgets('prefix slot is rendered correctly', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          prefixIcon: MdiIcons.magnify,
        ),
      );

      // Prefix icon should be visible
      expect(find.byIcon(MdiIcons.magnify), findsOneWidget);
    });

    testWidgets('suffix slot is overridden by dropdown chevron when no suffix provided', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Should have a chevron icon (dropdown)
      expect(find.byIcon(MdiIcons.chevronDown), findsOneWidget);
    });

    testWidgets('can unselect when canUnselect is true', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      LayrzSelectItem<String>? selectedItem;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: const [
            LayrzSelectItem(value: 'none', child: Text('None'), searchableStrings: {'None'}),
            LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
          ],
          value: 'a',
          labelText: 'Choose one',
          canUnselect: true,
          onChanged: (item) {
            selectedItem = item;
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Select 'None' to unselect
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      // onChanged should have been called
      expect(selectedItem, isNotNull);
    });

    testWidgets('custom filter respects case sensitivity', (tester) async {
      // REWRITE (DESIGN-145): typed into the surface's own internal search field.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
          filter: (query, item) => item.searchableStrings.any((s) => s.toLowerCase().contains(query.toLowerCase())),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // Type uppercase search into the surface's own search field.
      final searchField = find.descendant(
        of: find.byType(LayrzSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'A');
      await tester.pumpAndSettle();

      // Should find Option A (case-insensitive) and narrow out B and C, neither
      // of which contains an "a".
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsNothing);
      expect(find.text('Option C'), findsNothing);
    });

    testWidgets('multiple errors are joined with comma', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          errors: const ['Error 1', 'Error 2'],
        ),
      );

      // Errors should be joined
      expect(find.text('Error 1, Error 2'), findsOneWidget);
    });

    testWidgets('hideDetails hides error block', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          errors: const ['This field is required'],
          hideDetails: true,
        ),
      );

      // Error should not be visible
      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('selection callback is invoked with correct item', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changedValue = '';

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          onChanged: (item) {
            if (item != null) {
              changedValue = item.value ?? '';
            }
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Select an item
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      // onChanged should have been called with correct value
      expect(changedValue, equals('b'));
    });

    testWidgets('empty search result shows custom empty text', (tester) async {
      // REWRITE (DESIGN-145): typed into the surface's own internal search field.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
          emptyListText: 'No matching items',
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(LayrzSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'zzz');
      await tester.pumpAndSettle();

      // Custom empty message should appear, and no items should remain.
      expect(find.text('No matching items'), findsOneWidget);
      expect(find.text('Option A'), findsNothing);
      expect(find.text('Option B'), findsNothing);
      expect(find.text('Option C'), findsNothing);
    });

    testWidgets('focus node is created and disposed by widget', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          // No focusNode provided, so widget creates one
        ),
      );

      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('provided focus node is used', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          focusNode: focusNode,
        ),
      );

      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('selected item is preserved when value changes', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final state = _TestState();

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzSelectInput<String>(
              itemExtent: 40,
              items: items,
              value: state.selectedValue,
              labelText: 'Choose one',
              onChanged: (item) {
                setState(() {
                  state.selectedValue = item?.value;
                });
              },
            );
          },
        ),
      );

      // First selection
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(state.selectedValue, equals('a'));
    });

    /// Per DESIGN-126, the public `padding` escape hatch was removed; density is now
    /// expressible only via `dense`, forwarded to the field's chrome.
    testWidgets('dense parameter is applied', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          dense: true,
        ),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
      expect(chrome.dense, isTrue);
    });

    /// Affordance check (liliana's criterion): the dropdown chevron is a second, smaller tap
    /// target beside the chrome. At `dense: true` it must still be independently hittable and
    /// open the picker -- the failure mode to guard against is the tap missing the chevron and
    /// landing on the field instead, not merely "harder to tap".
    testWidgets('dense: true keeps the dropdown chevron hittable and it opens the picker', (tester) async {
      String? selected;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          dense: true,
          onChanged: (item) => selected = item?.value,
        ),
      );

      final chevron = find.byIcon(MdiIcons.chevronDown);
      expect(chevron, findsOneWidget);

      await tester.tap(chevron);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(selected, equals('a'), reason: 'tapping the chevron at dense must open the picker and commit a choice');
    });

    testWidgets('arrow down navigates through items', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'c',
          labelText: 'Choose one',
          enableSearch: false,
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Press arrow down to trigger navigation code path
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Test passes if no error occurred (navigation code executed)
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('arrow up navigates through items', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'b',
          labelText: 'Choose one',
          enableSearch: false,
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Test passes if no error occurred
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('arrow up wrapping at beginning', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'a',
          labelText: 'Choose one',
          enableSearch: false,
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Press arrow up multiple times to test wrapping
      for (int i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
      }

      // Test passes if no error occurred (wrapping code executed)
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('clearing the typed query restores the full list', (tester) async {
      // REWRITE (DESIGN-145): the surface owns its own search field again, so
      // erasing the query happens there, not on the closed field.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final searchField = find.descendant(
        of: find.byType(LayrzSelectInputSurface<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchField, 'A');
      await tester.pumpAndSettle();

      // Only one option visible
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsNothing);
      expect(find.text('Option C'), findsNothing);

      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // All options visible again
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('enter with no highlight does nothing', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changed = false;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          enableSearch: false,
          onChanged: (item) {
            changed = true;
          },
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Press enter without any keyboard navigation (no highlight)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Surface should still be open since nothing was selected
      expect(find.text('Option A'), findsOneWidget);
      expect(changed, isFalse);
    });
  });

  // DESIGN-40: the desktop surface previously stacked two disagreeing height
  // caps (a fixed `SizedBox(height: 300)` around a `LimitedBox(maxHeight:
  // 300)`-capped list), which both pinned the panel to exactly 300px
  // regardless of content AND overflowed by the search field's height once
  // enough items were added. The rule is now: `height = min(content, 300)`,
  // scroll past 300.
  //
  // DESIGN-98 moved the desktop cap's enforcement from `LayrzAnchoredPanel.maxHeight`
  // to a `ConstrainedBox`+`SingleChildScrollView` pair `_openDesktopDrawer` wraps
  // around `LayrzSelectInputSurface` (see that method's own doc comment) --
  // `LayrzEndDrawer` offers no height-cap parameter of its own. That
  // `SingleChildScrollView` now sits nested inside `LayrzEndDrawer`'s own
  // outer one, so `find.byType(SingleChildScrollView)` below matches TWO
  // widgets on desktop; [_panelScrollView] disambiguates to the inner one --
  // the immediate ancestor of the surface -- which is the one this group's
  // measurements are actually about.
  //
  // These assertions are measured geometry, not widget presence: presence
  // assertions are exactly what let the original overflow ship behind a
  // green suite (only 3-item fixtures existed before this).
  group('LayrzSelectInput height rule (DESIGN-40)', () {
    List<LayrzSelectItem<String>> buildItems(int count) => List.generate(
      count,
      (i) => LayrzSelectItem(value: 'v$i', child: Text('Option $i'), searchableStrings: {'Option $i'}),
    );

    testWidgets('desktop panel shrinks to content with 2 items', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: buildItems(2), labelText: 'Choose one'),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Before the fix this measured Size(1580.0, 300.0) -- a fixed height
      // regardless of content. With 2 items the panel must shrink well
      // below the 300px cap.
      final panelSize = tester.getSize(_panelScrollView());
      expect(panelSize.height, lessThan(300.0));
    });

    testWidgets('desktop panel caps at 300 and scrolls past it with 30 items', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: buildItems(30), labelText: 'Choose one'),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final panelSize = tester.getSize(_panelScrollView());
      expect(panelSize.height, equals(300.0));

      // The cap must be scrollable, not merely clipped: all 30 items are
      // built (this is a plain `Column`, not a lazy `ListView`), so presence
      // alone proves nothing -- assert that dragging actually moves content,
      // i.e. the viewport genuinely scrolls rather than being pinned.
      final topBefore = tester.getTopLeft(find.text('Option 29')).dy;
      await tester.drag(_panelScrollView(), const Offset(0, -3000));
      await tester.pumpAndSettle();
      final topAfter = tester.getTopLeft(find.text('Option 29')).dy;
      expect(topAfter, lessThan(topBefore));
    });

    testWidgets('8 items renders with no overflow exception (below the old threshold)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: buildItems(8), labelText: 'Choose one'),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('12 items renders with no overflow exception (the original repro threshold)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: buildItems(12), labelText: 'Choose one'),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Before the fix this threw `A RenderFlex overflowed by 68 pixels`.
      expect(tester.takeException(), isNull);
    });

    // Regression for a second, later DESIGN-40 defect: `ff58cd7` swapped the
    // surface's item rendering from a `Column` to a `ListView.builder`. A
    // `Column` tolerates being handed unbounded height by an ancestor
    // `SingleChildScrollView` -- its own height is just the sum of its
    // children's -- but a lazy, non-shrinkWrap `ListView` cannot, and throws
    // (`Vertical viewport was given unbounded height`) the instant either host
    // (the desktop panel or the mobile sheet) tries to lay it out, before the
    // 300px cap this group is named for ever gets a chance to apply. Presence
    // assertions (`findsOneWidget`, `tester.takeException() is null`) alone do
    // not catch this: an exception thrown mid-frame during `pumpAndSettle` can
    // leave enough of the tree built for a text finder to still succeed. These
    // assert measured geometry instead, on both hosts, so a regression here
    // fails on the numbers even if presence checks would not have caught it.
    testWidgets('desktop panel and mobile sheet both stay bounded and scrollable with 30 items', (tester) async {
      // Desktop first.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: buildItems(30), labelText: 'Choose one'),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // The panel's own scroll viewport must be strictly shorter than the
      // full, uncapped content height (30 * 40 = 1200) -- proof the panel is
      // actually constraining the list, not merely failing to crash.
      final desktopViewport = tester.getSize(_panelScrollView());
      expect(desktopViewport.height, lessThan(1200.0));

      final desktopTopBefore = tester.getTopLeft(find.text('Option 0')).dy;
      await tester.drag(_panelScrollView(), const Offset(0, -3000));
      await tester.pumpAndSettle();
      final desktopTopAfter = tester.getTopLeft(find.text('Option 0')).dy;
      expect(desktopTopAfter, lessThan(desktopTopBefore));

      // Close the panel, then switch to the mobile viewport and repeat through
      // the bottom sheet path -- a separate host with its own
      // `SingleChildScrollView`, so the desktop assertions above prove nothing
      // about it on their own.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final mobileViewport = tester.getSize(find.byType(SingleChildScrollView));
      expect(mobileViewport.height, lessThan(1200.0));

      final mobileTopBefore = tester.getTopLeft(find.text('Option 0')).dy;
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      final mobileTopAfter = tester.getTopLeft(find.text('Option 0')).dy;
      expect(mobileTopAfter, lessThan(mobileTopBefore));
    });

    // Promoted from the context dossier's measured probe (context-dossier.md
    // §2.3): before the fix, `select_input.dart` drew its "elevated field"
    // border as a `ClipRRect`+`Container` passed as `LayrzAnchoredPanel.child`,
    // which lands *inside* `SingleChildScrollView`. A `SingleChildScrollView`
    // relaxes its child's height constraint to unbounded along the scroll
    // axis, so that bordered box sized itself to the full, uncapped content
    // height (measured: 1260px for 30 items @ itemExtent 40) instead of the
    // panel's own 300px cap -- the border was painted ~960px past the visible
    // panel edge. This must fail before the fix and pass after.
    //
    // The invariant checked is scoped to *decorated boxes carrying a border*,
    // not to every descendant: the panel's actual scrollable content (the
    // item list) is SUPPOSED to be taller than the 300px viewport -- that is
    // what makes it scroll. What must never happen is a `Container`/
    // `DecoratedBox` painting a border sizing itself to that full content
    // height instead of the panel's own capped box.
    testWidgets(
      'no bordered decoration inside the panel scroll viewport exceeds the viewport height (border-scoping regression)',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          LayrzSelectInput<String>(itemExtent: 40, items: buildItems(30), labelText: 'Choose one'),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        final scrollViewFinder = _panelScrollView();
        final viewportHeight = tester.getSize(scrollViewFinder).height;
        final viewportElement = tester.element(scrollViewFinder);

        final offenders = <String>[];
        viewportElement.visitChildElements((child) {
          void visit(Element element) {
            final widget = element.widget;
            BoxDecoration? decoration;
            if (widget is Container && widget.decoration is BoxDecoration) {
              decoration = widget.decoration as BoxDecoration;
            } else if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
              decoration = widget.decoration as BoxDecoration;
            }

            if (decoration?.border != null) {
              final renderObject = element.renderObject;
              if (renderObject is RenderBox && renderObject.hasSize) {
                final height = renderObject.size.height;
                if (height > viewportHeight + 0.5) {
                  offenders.add('${widget.runtimeType} height=$height > viewport=$viewportHeight');
                }
              }
            }

            element.visitChildElements(visit);
          }

          visit(child);
        });

        expect(
          offenders,
          isEmpty,
          reason:
              'Bordered decorations inside the panel scroll viewport must never exceed its height:\n'
              '${offenders.join('\n')}',
        );
      },
    );
  });

  // DESIGN-145 superseded DESIGN-40/144's "field is the searcher" design: typing
  // now happens in the opened surface's own internal search field (see
  // select_input_surface.dart), never in this closed field. That collapses the
  // old four-mode logic (idle / typing / blur-revert / external-change-mid-query)
  // down to one: the field always shows the selected item's child, full stop --
  // it is always read-only and never diverges by focus. The obsolete
  // mode-2/3/4 tests and the "field keeps focus" test this group used to carry
  // are retired below in favor of the group that actually pins the new contract.
  group('LayrzSelectInput field self-display (DESIGN-145)', () {
    // Each item's child pairs an Icon with Text -- a widget shape no string-based
    // check could produce by coincidence, so finding both inside the field (mode 1)
    // is real proof the field renders the actual `LayrzSelectItem.child` widget,
    // not merely a string that happens to match.
    Widget itemChild(String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(MdiIcons.flag, key: ValueKey('flag-$label')),
        Text(label),
      ],
    );

    final items = <LayrzSelectItem<String>>[
      LayrzSelectItem(value: 'a', child: itemChild('Option A'), searchableStrings: const {'Option A'}),
      LayrzSelectItem(value: 'b', child: itemChild('Option B'), searchableStrings: const {'Option B'}),
      LayrzSelectItem(value: 'c', child: itemChild('Option C'), searchableStrings: const {'Option C'}),
    ];

    testWidgets("mode 1: idle renders the selected item's child widget", (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, value: 'b', labelText: 'Choose one'),
      );

      // Scoped to LayrzInputChrome (the field itself) -- the surface, when open,
      // lives in a completely separate subtree (the anchored panel's overlay), so
      // this can never accidentally pass because of the surface's own list.
      final field = find.descendant(
        of: find.byType(LayrzInputChrome),
        matching: find.byKey(const ValueKey('flag-Option B')),
      );
      expect(field, findsOneWidget);
      expect(
        find.descendant(of: find.byType(LayrzInputChrome), matching: find.text('Option B')),
        findsOneWidget,
      );

      // And the EditableText itself -- still mounted for focus continuity -- carries
      // no display text of its own; the child overlay is what's actually shown.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, isNot('Option B'));
    });

    testWidgets('the field never accepts typed input, on any enableSearch value', (tester) async {
      // Regression guard for defect 2's actual root cause (DESIGN-145): the field
      // used to stay focused-and-editable post-tap whenever `enableSearch` was
      // true, which is what left it rendering an empty `EditableText` instead of
      // the selected item's child right after a pick. It is now always read-only,
      // so there is no focus-dependent display path left to regress.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, labelText: 'Choose one', enableSearch: true),
      );

      final field = find.descendant(of: find.byType(LayrzInputChrome).first, matching: find.byType(EditableText));
      final editable = tester.widget<EditableText>(field);
      expect(editable.readOnly, isTrue);

      // Tapping still opens the surface (the tap callback fires regardless of
      // read-only), but typing into the field itself is a no-op: `readOnly`
      // routes `onUserTap` straight to `onTap` without ever calling
      // `_focusNode.requestFocus()`, so there is nothing to type into.
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(editable.controller.text, isEmpty);
    });

    testWidgets(
      'opening the desktop panel does not require the field to hold focus',
      (tester) async {
        // Supersedes the old "field keeps focus after the desktop panel opens"
        // test: DESIGN-145 covers the field with the panel instead of keeping it
        // focused as the searcher, so the field losing focus on open is no longer
        // a regression -- it is expected. Typing now happens in the surface's own
        // internal search field instead (see select_input_surface.dart).
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemedApp(
          tester,
          LayrzSelectInput<String>(itemExtent: 40, items: items, labelText: 'Choose one', focusNode: focusNode),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        // The surface's own search field is what ends up focused, not the
        // (always read-only) outer field.
        final searchField = find.descendant(
          of: find.byType(LayrzSelectInputSurface<String>),
          matching: find.byType(EditableText),
        );
        final searchEditable = tester.widget<EditableText>(searchField);
        expect(searchEditable.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'enableSearch: false self-displays a local pick without the caller feeding value back',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Deliberately no `onChanged`/`value` wiring -- the caller never feeds a
        // new value back. Under the old spec the field would never update; under
        // the redesign it self-displays from internal state regardless.
        await pumpThemedApp(
          tester,
          LayrzSelectInput<String>(
            itemExtent: 40,
            items: items,
            labelText: 'Choose one',
            enableSearch: false,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Option B'));
        await tester.pumpAndSettle();

        final editable = tester.widget<EditableText>(find.byType(EditableText));
        // Still not editable: the false path needs no mode logic of its own.
        expect(editable.readOnly, isTrue);
        // enableSearch: false never diverges from the selected item's child --
        // it shows every time, focused or not (unlike the searchable path).
        expect(
          find.descendant(of: find.byType(LayrzInputChrome), matching: find.byKey(const ValueKey('flag-Option B'))),
          findsOneWidget,
        );
      },
    );

    testWidgets('a caller-supplied suffix and the dropdown caret render together', (tester) async {
      // Before the caret moved to an external sibling, the widget's own chevron
      // occupied `suffixSlot` whenever the caller left it empty -- a caller that
      // *did* supply a suffix lost the chevron entirely. This is what proves that
      // is no longer true.
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          suffixIcon: MdiIcons.star,
        ),
      );

      expect(find.byIcon(MdiIcons.star), findsOneWidget);
      expect(find.byIcon(MdiIcons.chevronDown), findsOneWidget);
    });
  });

  // The chrome region outside the field's own text (its floating label, its
  // padding) has a `LayrzTappable` fallback so the whole chrome opens the
  // surface, matching pre-redesign behavior. These assert the four outcomes
  // that fallback must not break, not the widget tree -- a `find.byType`
  // assertion on the wrapper would pass whether or not the tap actually
  // reaches anything underneath it.
  group('LayrzSelectInput chrome-region tap fallback does not break text interaction', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
      const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
    ];

    testWidgets('tapping the chrome outside the text (e.g. the floating label) opens the surface', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, labelText: 'Choose one'),
      );

      final chromeRect = tester.getRect(find.byType(LayrzInputChrome));
      final editableRect = tester.getRect(find.byType(EditableText));
      final labelAreaPoint = Offset(chromeRect.left + 20, chromeRect.top + 10);
      // Sanity-check the point actually sits outside the editable text's own
      // hit region -- otherwise this would not be testing the fallback at all.
      expect(editableRect.contains(labelAreaPoint), isFalse);

      await tester.tapAt(labelAreaPoint);
      await tester.pumpAndSettle();

      expect(find.text('Option A'), findsWidgets);
    });

    // The three tests this group used to carry here (caret placement, drag-to-select,
    // long-press handles) pinned text-selection mechanics on the field itself, back
    // when the field was genuinely editable (it was the searcher). DESIGN-145 makes
    // the field permanently read-only -- see the class doc -- so there is no longer
    // any selection state to place a caret in, drag across, or show handles for.
    // Replaced with the tests below, which pin that non-editability directly instead
    // of retrofitting selection assertions onto a field that no longer supports them.
    testWidgets('tapping directly on the text opens the surface instead of placing a caret', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, value: 'b', labelText: 'Choose one'),
      );

      final field = find.descendant(of: find.byType(LayrzInputChrome).first, matching: find.byType(EditableText));
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Tapping directly on the (read-only) text still triggers the field's own
      // `onTap` -- opening the surface -- rather than focusing it for editing. The
      // surface's own search field is what actually gets focus (see the
      // "opening the desktop panel does not require the field to hold focus" test
      // above), never this one.
      final editableState = tester.state<EditableTextState>(field);
      expect(editableState.widget.focusNode.hasFocus, isFalse);
      expect(find.byType(LayrzSelectInputSurface<String>), findsOneWidget);
    });

    testWidgets('the field never shows selection handles, since it is always read-only', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, value: 'b', labelText: 'Choose one'),
      );

      final field = find.descendant(of: find.byType(LayrzInputChrome).first, matching: find.byType(EditableText));
      // A real `tap` here would open the bottom sheet (a separate modal route) on
      // this mobile viewport; `longPress` on the same finder exercises the same
      // gesture-detector wiring without leaving the field for a route that no
      // longer contains it.
      await tester.longPress(field);
      await tester.pumpAndSettle();

      final editableState = tester.state<EditableTextState>(field);
      expect(editableState.widget.showSelectionHandles, isFalse);
    });
  });

  // DESIGN-145 regressions: geometry and behavior, not mere presence -- see the
  // four defects fixed in this change. A widget being findable somewhere in the
  // tree proves nothing about where it is or what it does; these pin the actual
  // outcomes the maintainer reported as broken.
  group('LayrzSelectInput DESIGN-145 regressions', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(value: 'a', child: Text('Option A'), searchableStrings: {'Option A'}),
      const LayrzSelectItem(value: 'b', child: Text('Option B'), searchableStrings: {'Option B'}),
    ];

    // DESIGN-98 retired the DESIGN-145 "elevated field" illusion this defect-1
    // regression used to pin: the maintainer reported that overlay "kinda
    // weird" after live usage, so the desktop selection surface no longer
    // covers the field in place -- it opens in `LayrzEndDrawer`, a fixed-width
    // right-edge drawer that does NOT overlap the field's own rect. This
    // replaces the old overlap assertion with the new, intentionally
    // non-overlapping one.
    testWidgets("the desktop drawer's rect does not overlap the field's own rect (DESIGN-98 retires DESIGN-145)", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, labelText: 'Choose one'),
      );

      final fieldRect = tester.getRect(find.byType(LayrzInputChrome).first);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final surfaceRect = tester.getRect(find.byType(LayrzSelectInputSurface<String>));

      expect(
        surfaceRect.overlaps(fieldRect),
        isFalse,
        reason: 'the drawer is a separate, fixed-width right-edge panel -- it must not cover the field in place',
      );
    });

    testWidgets(
      "defect 2: the selected item's child is visible immediately after picking it, with no focus change",
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzSelectItem<String>? selected;

        await pumpThemedApp(
          tester,
          LayrzSelectInput<String>(
            itemExtent: 40,
            items: items,
            labelText: 'Choose one',
            onChanged: (item) => selected = item,
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome).first);
        await tester.pumpAndSettle();

        // Tap the option WITHOUT any subsequent focus manipulation (no `unfocus()`,
        // no tapping elsewhere first) -- the old bug was that the field stayed
        // focused right after a pick and kept showing its (empty) `EditableText`
        // instead of the picked item's child until focus moved away.
        await tester.tap(find.text('Option B').last);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(selected?.value, equals('b'));
        expect(
          find.descendant(of: find.byType(LayrzInputChrome).first, matching: find.text('Option B')),
          findsOneWidget,
        );
      },
    );

    testWidgets('defect 3: the clear affordance actually clears the selection', (tester) async {
      LayrzSelectItem<String>? changedTo;
      var callbackFired = false;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'a',
          labelText: 'Choose one',
          canUnselect: true,
          onChanged: (item) {
            callbackFired = true;
            changedTo = item;
          },
        ),
      );

      // The field shows the selection to start, and no items in `items` carry a
      // null value -- so the only way to clear is the dedicated affordance itself,
      // not the pre-existing "select a null-value item" mechanism.
      expect(find.text('Option A'), findsOneWidget);

      await tester.tap(find.byIcon(MdiIcons.close));
      await tester.pumpAndSettle();

      expect(callbackFired, isTrue);
      expect(changedTo, isNull);
      expect(find.text('Option A'), findsNothing);
    });
  });
}

/// Locates the `SingleChildScrollView` [_LayrzSelectInputState._openDesktopDrawer]
/// wraps directly around [LayrzSelectInputSurface] -- the one carrying the
/// DESIGN-40 300px cap -- disambiguated from [LayrzEndDrawer]'s own outer
/// `SingleChildScrollView` (its `builder(context)` content, one level further
/// out) by walking up from the surface itself and taking the closest match.
Finder _panelScrollView() {
  return find
      .ancestor(
        of: find.byType(LayrzSelectInputSurface<String>),
        matching: find.byType(SingleChildScrollView),
      )
      .first;
}

class _TestState {
  String? selectedValue;
}
