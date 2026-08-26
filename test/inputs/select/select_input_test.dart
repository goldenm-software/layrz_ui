import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/layrz_ui.dart';
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
      // REWRITE: the search box this test originally typed into lived inside the
      // panel and is gone. The field itself is the searcher now -- typing into it
      // filters live, and that only works with the surface open, which requires
      // the desktop path (see select_input.dart's focus-race handling).
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

      // Tap the field to open the surface and focus it.
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Type into the field itself -- there is no separate search box anymore.
      await tester.enterText(find.byType(EditableText), 'B');
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
      // REWRITE: typed into the field itself now, not a separate search box.
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

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'nonexistent');
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

    testWidgets('desktop viewport uses anchored panel', (tester) async {
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

      // Desktop should use LayrzAnchoredPanel
      expect(find.byType(LayrzAnchoredPanel), findsOneWidget);
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
      // REWRITE: typed into the field itself now, not a separate search box.
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

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Type uppercase search
      await tester.enterText(find.byType(EditableText), 'A');
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
      // REWRITE: typed into the field itself now, not a separate search box.
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

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'zzz');
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

    testWidgets('padding parameter is applied', (tester) async {
      const customPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          labelText: 'Choose one',
          padding: customPadding,
        ),
      );

      // Widget should accept padding parameter
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
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
      // REWRITE, with a caveat: the old panel search box's inline clear (close)
      // icon is gone, and there is no equivalent built-in "clear" affordance on
      // the field itself -- that specific UI capability disappeared with the
      // search box (flagged to the maintainer separately). What survives is the
      // underlying behavior: erasing the query restores the full list. Proven
      // here by clearing the field's text directly, the same way a user would by
      // backspacing, rather than by tapping a control that no longer exists.
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

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'A');
      await tester.pumpAndSettle();

      // Only one option visible
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsNothing);
      expect(find.text('Option C'), findsNothing);

      await tester.enterText(find.byType(EditableText), '');
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
  // scroll past 300 -- enforced by `LayrzAnchoredPanel.maxHeight` alone.
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
      final panelSize = tester.getSize(find.byType(SingleChildScrollView));
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

      final panelSize = tester.getSize(find.byType(SingleChildScrollView));
      expect(panelSize.height, equals(300.0));

      // The cap must be scrollable, not merely clipped: all 30 items are
      // built (this is a plain `Column`, not a lazy `ListView`), so presence
      // alone proves nothing -- assert that dragging actually moves content,
      // i.e. the viewport genuinely scrolls rather than being pinned.
      final topBefore = tester.getTopLeft(find.text('Option 29')).dy;
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
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
  });

  // DESIGN-40/144: the field-as-searcher redesign. Neither this widget nor
  // `LayrzComboBoxInput` had this mode logic before -- combobox's displayed text
  // *is* its value, so it never needed to distinguish "idle" from "typing". Each
  // of the four modes gets its own test; mode 3 (blur-revert) is the one people
  // forget, so it is asserted explicitly rather than folded into another test.
  group('LayrzSelectInput field-as-searcher mode logic (DESIGN-40/144)', () {
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

    testWidgets('mode 2: typing shows the query and filters the opened list', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, labelText: 'Choose one'),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'B');
      await tester.pumpAndSettle();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, 'B');
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option A'), findsNothing);
      expect(find.text('Option C'), findsNothing);
    });

    testWidgets(
      'the field keeps focus after the desktop panel opens (not the panel itself)',
      (tester) async {
        // Asserts the OUTCOME, not the timing that produces it:
        // `LayrzAnchoredPanel._handlePanelOpenRequested` unconditionally moves
        // focus to its own internal panel-focus-node one frame after opening, which
        // would otherwise defocus the field the instant it's tapped -- breaking
        // "the field is the searcher" on desktop before the user types a single
        // character. `LayrzSelectInput._handlePanelOpened` (wired via the panel's
        // own `onOpen` hook) wins that race back for the field. If the race ever
        // flips -- an SDK change, a change to the panel's own open-focus timing --
        // this must fail rather than let the regression pass silently.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemedApp(
          tester,
          LayrzSelectInput<String>(itemExtent: 40, items: items, labelText: 'Choose one', focusNode: focusNode),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);
      },
    );

    testWidgets("mode 3: blur with nothing picked reverts to the selected item's child", (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          itemExtent: 40,
          items: items,
          value: 'b',
          labelText: 'Choose one',
          focusNode: focusNode,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'zzz-no-match');
      await tester.pumpAndSettle();

      var editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, 'zzz-no-match');

      // Blur without picking anything -- the field must revert to rendering the
      // selected item's child, not stay showing the abandoned query.
      focusNode.unfocus();
      await tester.pumpAndSettle();

      editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, isNot('zzz-no-match'));
      expect(
        find.descendant(of: find.byType(LayrzInputChrome), matching: find.byKey(const ValueKey('flag-Option B'))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(LayrzInputChrome), matching: find.text('Option B')),
        findsOneWidget,
      );
    });

    testWidgets(
      'mode 4: a caller-supplied value change mid-query reconciles without clobbering the typed text',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        String? currentValue = 'a';
        late StateSetter setOuterState;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              setOuterState = setState;
              return LayrzSelectInput<String>(
                itemExtent: 40,
                items: items,
                value: currentValue,
                labelText: 'Choose one',
                focusNode: focusNode,
              );
            },
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(EditableText), 'typing...');
        await tester.pumpAndSettle();

        // The caller changes `value` externally while the user is mid-query.
        setOuterState(() => currentValue = 'c');
        await tester.pump();

        // The typed text must survive the external change -- it is reconciled
        // silently, not applied immediately over what the user is typing.
        var editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.controller.text, 'typing...');

        // Once the query resolves (blur, nothing picked), the *new* external
        // value's child renders -- proving the change was reconciled, not
        // dropped.
        focusNode.unfocus();
        await tester.pumpAndSettle();

        editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.controller.text, isNot('typing...'));
        expect(
          find.descendant(of: find.byType(LayrzInputChrome), matching: find.byKey(const ValueKey('flag-Option C'))),
          findsOneWidget,
        );
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

    testWidgets('tapping directly on the text still places the caret', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, value: 'b', labelText: 'Choose one'),
      );

      // The field's own idle text is intentionally empty now (mode 1 renders the
      // selected item's `child` instead, see select_input.dart) -- so a caret has
      // nothing to be "placed" within until there is a live query to place it in.
      // Focus and type first (`enterText` focuses directly, no hit-testing involved),
      // then tap again to reposition the caret within that typed text, which is what
      // this test actually pins.
      await tester.enterText(find.byType(EditableText), 'Selectable query text');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final editableState = tester.state<EditableTextState>(find.byType(EditableText));
      expect(editableState.textEditingValue.selection.isCollapsed, isTrue);
    });

    testWidgets('dragging across the text still selects a range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, value: 'b', labelText: 'Choose one'),
      );

      // Same reasoning as the caret test above: there must be real text present
      // to drag across before a range selection is even possible.
      await tester.enterText(find.byType(EditableText), 'Selectable query text');
      await tester.pumpAndSettle();

      final editableRect = tester.getRect(find.byType(EditableText));
      final start = Offset(editableRect.left + 4, editableRect.center.dy);
      final end = Offset(editableRect.right - 4, editableRect.center.dy);

      final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
      for (var i = 1; i <= 10; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await gesture.moveTo(Offset.lerp(start, end, i / 10)!);
      }
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pumpAndSettle();

      final editableState = tester.state<EditableTextState>(find.byType(EditableText));
      expect(editableState.textEditingValue.selection.isCollapsed, isFalse);
    });

    testWidgets('long-pressing the text still shows touch selection handles', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(itemExtent: 40, items: items, value: 'b', labelText: 'Choose one'),
      );

      // Same reasoning again: long-press-to-select needs real text under the field.
      // `enterText` focuses the field directly (it does not hit-test), unlike a real
      // `tap` -- deliberately avoided here, since on this mobile viewport a real tap
      // opens the bottom sheet (a separate modal route) instead of just focusing the
      // inline field, which would leave nothing left to long-press against afterward.
      await tester.enterText(find.byType(EditableText), 'Selectable query text');
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();

      final editableState = tester.state<EditableTextState>(find.byType(EditableText));
      expect(editableState.widget.showSelectionHandles, isTrue);
    });
  });
}

class _TestState {
  String? selectedValue;
}
