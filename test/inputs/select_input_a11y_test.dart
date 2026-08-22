import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/input_chrome.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSelectInput Accessibility - Semantics', () {
    final items = <LayrzSelectItem<String>>[
      const LayrzSelectItem(labelText: 'Option A', value: 'a'),
      const LayrzSelectItem(labelText: 'Option B', value: 'b'),
      const LayrzSelectItem(labelText: 'Option C', value: 'c'),
    ];

    testWidgets('anchor renders with proper label attribute', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose an option',
        ),
      );

      // Chrome should exist with the label
      final chromeWidget = find.byType(LayrzInputChrome);
      expect(chromeWidget, findsOneWidget);

      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.labelText, equals('Choose an option'));
    });

    testWidgets('disabled field prevents interaction', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          disabled: true,
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Surface should not open (verify no options visible beyond the anchor)
      expect(find.text('Option A'), findsNothing);
    });

    testWidgets('enabled field allows interaction', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          disabled: false,
        ),
      );

      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Surface should open
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('search field is accessible in surface', (tester) async {
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

      // Tap the field to open surface
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Search field should be present and accessible
      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('anchor stores label and hint properly', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Select',
          hintText: 'Choose from list',
        ),
      );

      final chromeWidget = find.byType(LayrzInputChrome);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.labelText, equals('Select'));
      expect(chrome.hintText, equals('Choose from list'));
    });

    testWidgets('required field attribute is set', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Required field',
          isRequired: true,
        ),
      );

      final chromeWidget = find.byType(LayrzInputChrome);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.isRequired, isTrue);
    });

    testWidgets('errors are accessible in the field', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          errors: const ['Field is required'],
        ),
      );

      // Error text should be visible
      expect(find.text('Field is required'), findsOneWidget);

      // Chrome should still have label
      final chromeWidget = find.byType(LayrzInputChrome);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.labelText, equals('Choose one'));
    });

    testWidgets('help affordance is present with accessible anchor', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Choose one',
          helpTitleText: 'Help',
          helpContentText: 'Select an option',
        ),
      );

      final chromeWidget = find.byType(LayrzInputChrome);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.helpTitleText, equals('Help'));
      expect(chrome.helpContentText, equals('Select an option'));
    });

    testWidgets('multiple items are independently accessible', (tester) async {
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

      // Open surface
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // All items should be present and accessible
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('selected item shows visual indication for screen readers', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          value: 'b',
          labelText: 'Choose one',
        ),
      );

      // Open surface
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Option B is selected and should show checkmark
      expect(find.byIcon(MdiIcons.check), findsOneWidget);
    });

    testWidgets('disabled field widget attribute is set', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Disabled Field',
          disabled: true,
        ),
      );

      final chromeWidget = find.byType(LayrzInputChrome);
      final chrome = tester.widget<LayrzInputChrome>(chromeWidget);
      expect(chrome.disabled, isTrue);
    });

    testWidgets('anchor is button-like and responds to clicks', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapped = false;

      await pumpThemedApp(
        tester,
        LayrzSelectInput<String>(
          items: items,
          labelText: 'Clickable Field',
          onChanged: (item) {
            if (item != null) {
              tapped = true;
            }
          },
        ),
      );

      // Tap the field
      final field = find.byType(LayrzInputChrome);
      await tester.tap(field);
      await tester.pumpAndSettle();

      // Select an item
      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('field shows dropdown chevron for affordance', (tester) async {
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
  });
}
