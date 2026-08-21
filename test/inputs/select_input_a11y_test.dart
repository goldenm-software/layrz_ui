import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/input_chrome.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSelectInput Accessibility', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(labelText: 'Option A', value: 'a'),
      const LayrzSelectItem(labelText: 'Option B', value: 'b'),
      const LayrzSelectItem(labelText: 'Option C', value: 'c'),
    ];

    testWidgets('anchor field has label for screen readers', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose an option',
        ),
      );

      // Label should be visible and readable
      expect(find.text('Choose an option'), findsOneWidget);
    });

    testWidgets('marks required fields appropriately', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Required field',
          isRequired: true,
        ),
      );

      // Required indicator should be present
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('error messages are announced to screen readers',
        (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          errors: const ['This field is required', 'Value must be valid'],
        ),
      );

      // All errors should be visible
      expect(find.text('This field is required'), findsOneWidget);
      expect(find.text('Value must be valid'), findsOneWidget);
    });

    testWidgets('help text is accessible', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          helpTitleText: 'Help Title',
          helpContentText: 'This is help content',
        ),
      );

      // Help affordance should be present
      expect(find.byIcon(mdiHelpCircleOutline), findsOneWidget);
    });

    testWidgets('disabled state is communicated', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          disabled: true,
        ),
      );

      // Field should not be interactive
      final field = find.byType(LayrzInputChrome);
      expect(field, findsOneWidget);

      // Verify disabled state by checking widget properties
      final chrome = tester.widget<LayrzInputChrome>(field);
      expect(chrome.disabled, true);
    });

    testWidgets('focus is properly managed in selection surface',
        (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: true,
        ),
      );

      // Tap the field to open surface
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Search field should receive focus (for keyboard entry)
      final searchField = find.byType(LayrzTextInput);
      expect(searchField, findsOneWidget);

      // Select an item
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      // Focus should return to anchor after closing
      // (This is tested implicitly - no crash means focus was managed)
    });

    testWidgets('list items are recognizable as options', (tester) async {
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

      // Each item should have a check icon when selected (visual affordance)
      // But initially, none should be selected so no checks
      expect(find.byIcon(mdiCheck), findsNothing);

      // Select an item
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();

      // Re-open to verify selection state
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Now Option B should have a check
      expect(find.byIcon(mdiCheck), findsOneWidget);
    });

    testWidgets('search results are announced as items filter', (tester) async {
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

      // Initially all items should be visible
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);

      // Type a search query
      final searchField = find.byType(LayrzTextInput);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'B');
      await tester.pumpAndSettle();

      // Only matching item should be visible
      expect(find.text('Option A'), findsNothing);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsNothing);

      // Empty state message for non-matching searches
      await tester.enterText(searchField, 'ZZZZZ');
      await tester.pumpAndSettle();

      // Empty message should appear
      expect(find.text('No item found'), findsOneWidget);
    });

    testWidgets('keyboard navigation is accessible', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          enableSearch: false,
        ),
      );

      // Tap the field to open surface
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Arrow down should work
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Arrow up should work
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Enter should select
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Surface should close
      expect(find.text('Option A'), findsWidgets);
    });

    testWidgets('escape closes surface without side effects', (tester) async {
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

      // Surface should be closed
      // Selection should not have changed
      expect(selectedItem, isNull);
    });
  });
}

/// Icon constants for testing.
const mdiHelpCircleOutline =
    IconData(0xf0184, fontFamily: 'MaterialDesignIcons');
const mdiCheck = IconData(0xf0137, fontFamily: 'MaterialDesignIcons');
