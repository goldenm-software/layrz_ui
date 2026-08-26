import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSearchInput', () {
    group('field mode', () {
      testWidgets('renders inline field with magnifier prefix', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        expect(find.byType(LayrzInputChrome), findsOneWidget);
        expect(find.byIcon(MdiIcons.magnify), findsWidgets);
        // Verify the text input is interactive
        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();
      });

      /// Per DESIGN-126, `dense` forwards to the chrome and resolves a smaller padding.
      testWidgets('dense: true resolves pd1 (6px) padding on a regular viewport', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 800);

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            dense: true,
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.dense, isTrue);
      });

      testWidgets('clear suffix is absent when field is empty', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        // The field is built, but the close icon should not be present initially
        final closeIconFinder = find.byIcon(MdiIcons.close);
        expect(closeIconFinder, findsNothing);
      });

      testWidgets('clear suffix appears when field has text', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            value: 'search',
          ),
        );

        expect(find.byIcon(MdiIcons.close), findsOneWidget);
      });

      testWidgets('tapping clear suffix clears field and fires onSearch', (tester) async {
        String? lastSearchValue;
        final controller = TextEditingController(text: 'flutter');

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
            onSearch: (value) => lastSearchValue = value,
            debounce: Duration.zero,
          ),
        );

        expect(find.byIcon(MdiIcons.close), findsOneWidget);

        // Tap the clear suffix
        await tester.tap(find.byIcon(MdiIcons.close));
        await tester.pumpAndSettle();

        // Field should be cleared
        expect(controller.text, isEmpty);
        // onSearch should have fired with empty string
        expect(lastSearchValue, '');
      });

      testWidgets('disabled field is not editable and clear suffix is disabled', (tester) async {
        final controller = TextEditingController(text: 'flutter');

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
            disabled: true,
          ),
        );

        // Try to type in the field (should be disabled)
        await tester.enterText(find.byType(LayrzInputChrome), 'new text');
        await tester.pumpAndSettle();

        // Field should still contain original text
        expect(controller.text, 'flutter');
      });

      testWidgets('clear icon appears while typing (D-I fix)', (tester) async {
        final controller = TextEditingController();

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
            debounce: Duration.zero,
          ),
        );

        // No initial value seeded — the clear icon must be absent at first.
        expect(find.byIcon(MdiIcons.close), findsNothing);

        // Type into the field: the icon must appear as a direct result of typing,
        // not merely after some unrelated rebuild.
        await tester.enterText(find.byType(LayrzInputChrome), 'flutter');
        await tester.pump();
        expect(find.byIcon(MdiIcons.close), findsOneWidget);

        // Clearing it back down to empty removes the icon again.
        await tester.enterText(find.byType(LayrzInputChrome), '');
        await tester.pump();
        expect(find.byIcon(MdiIcons.close), findsNothing);
      });
    });

    group('icon mode', () {
      testWidgets('renders button that opens panel with field', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Button should be present
        expect(find.byType(LayrzButton), findsOneWidget);

        // Chrome should not be visible initially
        expect(find.byType(LayrzInputChrome), findsNothing);

        // Tap the button to open the panel
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Now the chrome should be visible
        expect(find.byType(LayrzInputChrome), findsOneWidget);
      });

      /// Per DESIGN-126, `dense` forwards to the overlay panel's chrome (the second of the
      /// two `LayrzInputChrome` call sites in this widget) as well as the field-mode one.
      testWidgets('dense: true forwards to the overlay panel chrome', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            dense: true,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.dense, isTrue);
      });

      testWidgets('panel has sensible minimum width (not as narrow as button)', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Tap to open
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Find the chrome and check its constraints
        final chromeFinder = find.byType(LayrzInputChrome);
        expect(chromeFinder, findsOneWidget);

        // The anchored panel should have applied contentSized with widthBounds
        // The minimum width should be 280.0 as per the implementation
        final chromeSize = tester.getSize(chromeFinder);
        expect(chromeSize.width, greaterThanOrEqualTo(280.0)); // Minimum width constraint
      });

      testWidgets('panel width bounds work on wide surface', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Tap to open the panel
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // The chrome should still be present and usable on a wide surface
        // The contentSized policy ensures the panel width is appropriate (280-480px)
        // regardless of available viewport width
        final chromeFinder = find.byType(LayrzInputChrome);
        expect(chromeFinder, findsOneWidget);

        final chromeSize = tester.getSize(chromeFinder);
        // Width should be clamped to max 480 even on a 1600px wide surface
        expect(chromeSize.width, lessThanOrEqualTo(480.0));
        // Width should still be at least the minimum
        expect(chromeSize.width, greaterThanOrEqualTo(280.0));
      });

      testWidgets('escape key closes panel', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Open panel
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Verify panel is open
        expect(find.byType(LayrzInputChrome), findsOneWidget);

        // Press Escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Panel should be closed
        expect(find.byType(LayrzInputChrome), findsNothing);
      });

      testWidgets('disabled button does not open panel', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            disabled: true,
          ),
        );

        // Tap the button (should not open)
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Panel should not be open
        expect(find.byType(LayrzInputChrome), findsNothing);
      });
    });

    group('preferredSide', () {
      testWidgets('defaults to right and forwards to the anchored panel', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        final panel = tester.widget<LayrzAnchoredPanel>(find.byType(LayrzAnchoredPanel));
        expect(panel.preferredSide, LayrzPreferredSide.right);
      });

      testWidgets('a non-default value reaches the anchored panel', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            preferredSide: LayrzPreferredSide.top,
          ),
        );

        final panel = tester.widget<LayrzAnchoredPanel>(find.byType(LayrzAnchoredPanel));
        expect(panel.preferredSide, LayrzPreferredSide.top);
      });

      testWidgets('field mode ignores it and renders normally', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            preferredSide: LayrzPreferredSide.left,
          ),
        );

        expect(find.byType(LayrzAnchoredPanel), findsNothing);
        expect(find.byType(LayrzInputChrome), findsOneWidget);
      });
    });

    group('auto mode', () {
      testWidgets('auto renders the field on a wide surface', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.auto,
            onSearch: (_) {},
          ),
        );

        // Field mode should be active on wide surface (>= 960px)
        expect(find.byType(LayrzInputChrome), findsOneWidget);
        expect(find.byType(LayrzButton), findsNothing);
      });

      testWidgets('auto renders the icon button on a narrow surface', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.auto,
            onSearch: (_) {},
          ),
        );

        // Icon mode should be active on narrow surface (< 960px)
        expect(find.byType(LayrzButton), findsOneWidget);
        expect(find.byType(LayrzInputChrome), findsNothing);
      });
    });

    group('debouncing', () {
      testWidgets('debounce fires search callback once after delay', (tester) async {
        int callCount = 0;
        final duration = const Duration(milliseconds: 200);

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            debounce: duration,
            onSearch: (_) => callCount++,
          ),
        );

        // Type three characters quickly
        await tester.enterText(find.byType(LayrzInputChrome), 'abc');
        expect(callCount, 0); // Not called yet

        // Pump less than debounce duration
        await tester.pump(const Duration(milliseconds: 100));
        expect(callCount, 0); // Still not called

        // Pump past debounce duration
        await tester.pump(const Duration(milliseconds: 150));
        expect(callCount, 1); // Called once after the debounce
      });

      testWidgets('null debounce fires on every keystroke', (tester) async {
        int callCount = 0;

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            debounce: null,
            onSearch: (_) => callCount++,
          ),
        );

        // Type one character
        await tester.enterText(find.byType(LayrzInputChrome), 'a');
        expect(callCount, 1);

        // Type another character
        await tester.enterText(find.byType(LayrzInputChrome), 'ab');
        expect(callCount, 2);

        // Type another character
        await tester.enterText(find.byType(LayrzInputChrome), 'abc');
        expect(callCount, 3);
      });

      testWidgets('pending debounce timer does not fire after dispose', (tester) async {
        int callCount = 0;

        final widget = LayrzSearchInput(
          mode: LayrzSearchInputMode.field,
          debounce: const Duration(seconds: 10),
          onSearch: (_) => callCount++,
        );

        await pumpThemedApp(tester, widget);

        // Type something to start debounce
        await tester.enterText(find.byType(LayrzInputChrome), 'test');
        expect(callCount, 0);

        // Dispose the widget by pumping a different widget
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Wait for the debounce timer to elapse
        await tester.pump(const Duration(seconds: 15));

        // Callback should not have fired
        expect(callCount, 0);
        expect(tester.takeException(), isNull);
      });
    });

    group('disposal contract', () {
      testWidgets('disposes owned controller', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        // Type something to verify the controller works
        await tester.enterText(find.byType(LayrzInputChrome), 'test');
        await tester.pumpAndSettle();

        // Pump away - should dispose the owned controller
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Should not throw when accessing disposed widget
        expect(tester.takeException(), isNull);
      });

      testWidgets('does not dispose caller-supplied controller', (tester) async {
        final controller = TextEditingController();

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
          ),
        );

        // Pump away
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Controller should still be usable (no exception thrown)
        controller.text = 'test';
        expect(controller.text, 'test');
        controller.dispose();
      });

      testWidgets('disposes owned focus node', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        // Request focus to verify the focus node works
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Pump away - should dispose the owned focus node
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Should not throw when accessing disposed widget
        expect(tester.takeException(), isNull);
      });

      testWidgets('does not dispose caller-supplied focus node', (tester) async {
        final focusNode = FocusNode();

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            focusNode: focusNode,
          ),
        );

        // Pump away
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Focus node should still be usable
        expect(focusNode.canRequestFocus, isTrue);
        focusNode.dispose();
      });
    });

    group('hint and label text behavior', () {
      testWidgets('uses default localized hint when hintText is null', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        // The default hint should come from l10n
        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.hintText, isNotNull);
      });

      testWidgets('uses provided hintText when non-null', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            hintText: 'Custom hint',
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.hintText, equals('Custom hint'));
      });

      testWidgets('icon mode button gets labelText label', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            hintText: 'Find items',
          ),
        );

        // The button should have the labelText as its label
        expect(find.bySemanticsLabel('Find items'), findsOneWidget);
      });

      testWidgets('icon mode button uses l10n default when labelText is null', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // The button should have the localized default label
        expect(find.bySemanticsLabel('Search'), findsOneWidget);
      });
    });

    group('initial value', () {
      testWidgets('controller is initialized with value when provided', (tester) async {
        final controller = TextEditingController();

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            value: 'initial',
            controller: controller,
          ),
        );

        expect(controller.text, 'initial');
      });
    });

    group('new parameters', () {
      testWidgets('errors are forwarded to the chrome', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            errors: ['Too short'],
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.errors, equals(['Too short']));
        expect(find.text('Too short'), findsOneWidget);
      });

      testWidgets('helpTitleText and helpContentText are forwarded to the chrome', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            helpTitleText: 'About search',
            helpContentText: 'Searches across all records.',
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.helpTitleText, equals('About search'));
        expect(chrome.helpContentText, equals('Searches across all records.'));
        expect(find.byIcon(MdiIcons.helpCircleOutline), findsOneWidget);
      });

      testWidgets('readOnly is forwarded to the chrome and renders the lock icon', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            readOnly: true,
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.readOnly, isTrue);
        expect(find.byIcon(MdiIcons.lockOutline), findsOneWidget);
      });

      testWidgets('defaults are additive and non-breaking', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.errors, isEmpty);
        expect(chrome.helpTitleText, isNull);
        expect(chrome.helpContentText, isNull);
        expect(chrome.readOnly, isFalse);
      });
    });
  });
}
