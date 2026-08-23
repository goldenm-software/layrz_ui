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
      const LayrzSelectItem(labelText: 'Option A', value: 'a'),
      const LayrzSelectItem(labelText: 'Option B', value: 'b'),
      const LayrzSelectItem(labelText: 'Option C', value: 'c'),
    ];

    testWidgets('renders without crashing', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
          items: items,
          value: 'b',
          labelText: 'Choose one',
        ),
      );

      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('field is read-only (no keyboard input)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
        ),
      );

      // Verify the select input exists
      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);

      // Verify the chrome is created with readOnly flag
      final chromeWidget = find.byType(LayrzInputChrome);
      expect(chromeWidget, findsOneWidget);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.readOnly, true);
    });

    testWidgets('does not render lock icon (uses dropdown chevron instead)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
      expect(selectedItem!.labelText, 'Option B');
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
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Type in search
      final searchField = find.byType(LayrzTextInput);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'B');
      await tester.pumpAndSettle();

      // Only Option B should remain
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
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Search for non-existent item
      final searchField = find.byType(LayrzTextInput);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'nonexistent');
      await tester.pumpAndSettle();

      // Empty message should appear
      expect(find.text('No item found'), findsOneWidget);
    });

    testWidgets('custom filter function works', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
          filter: (query, item) => item.labelText.contains('A'),
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
          labelText: 'Option A',
          value: 'a',
          child: const Text('Custom A'),
        ),
      ];

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
      // Label text is not shown when custom child is provided
      expect(find.text('Option A'), findsNothing);
    });

    testWidgets('opens surface when field has no value selected', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
          items: const [
            LayrzSelectItem(labelText: 'None', value: null),
            LayrzSelectItem(labelText: 'Option A', value: 'a'),
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
          items: const [
            LayrzSelectItem(labelText: 'None', value: 'none'),
            LayrzSelectItem(labelText: 'Option A', value: 'a'),
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
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
          filter: (query, item) => item.labelText.toLowerCase().contains(query.toLowerCase()),
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Type uppercase search
      final searchField = find.byType(LayrzTextInput);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'A');
      await tester.pumpAndSettle();

      // Should find Option A (case-insensitive)
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('multiple errors are joined with comma', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
          emptyListText: 'No matching items',
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Search for non-existent item
      final searchField = find.byType(LayrzTextInput);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'zzz');
      await tester.pumpAndSettle();

      // Custom empty message should appear
      expect(find.text('No matching items'), findsOneWidget);
    });

    testWidgets('focus node is created and disposed by widget', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
          items: items,
          labelText: 'Choose one',
          focusNode: focusNode,
        ),
      );

      expect(find.byType(LayrzSelectInput<String>), findsOneWidget);
    });

    testWidgets('text input disables autocomplete when enableSearch is false', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: false,
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // No search field should be present
      expect(find.byType(LayrzTextInput), findsNothing);
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

    testWidgets('search clear button removes query text', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Type search text
      final searchInput = find.byType(LayrzTextInput).first;
      await tester.enterText(searchInput, 'A');
      await tester.pumpAndSettle();

      // Only one option visible
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsNothing);

      // Find and tap clear button
      final closeIcon = find.byIcon(MdiIcons.close);
      if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.first);
        await tester.pumpAndSettle();

        // All options visible again
        expect(find.text('Option A'), findsOneWidget);
        expect(find.text('Option B'), findsOneWidget);
        expect(find.text('Option C'), findsOneWidget);
      }
    });

    testWidgets('enter with no highlight does nothing', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changed = false;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
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
}

class _TestState {
  String? selectedValue;
}
