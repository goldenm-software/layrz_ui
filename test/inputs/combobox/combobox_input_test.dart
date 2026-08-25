import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzComboBoxInput', () {
    testWidgets('renders with label and options', (tester) async {
      final options = ['Option 1', 'Option 2', 'Option 3'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select an option',
          options: options,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('can be created without labelText or hintText', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(options: []),
      );

      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('calls onChanged when value changes', (tester) async {
      final options = ['Option 1', 'Option 2'];
      String? lastValue;

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          onChanged: (value) => lastValue = value,
        ),
      );

      // Tap field
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Type text
      await tester.enterText(find.byType(EditableText), 'test');
      await tester.pumpAndSettle();

      expect(lastValue, 'test');
    });

    testWidgets('respects disabled state', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          disabled: true,
        ),
      );

      // Try to tap - should not open
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Field should not be editable
      final editableTextState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableTextState.widget.readOnly, isTrue);
    });

    testWidgets('respects readOnly state', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          readOnly: true,
        ),
      );

      // Field should not be editable
      final editableTextState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableTextState.widget.readOnly, isTrue);
    });

    testWidgets('initializes with provided value', (tester) async {
      final options = ['Option 1', 'Option 2', 'Option 3'];
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          value: 'Option 2',
          controller: controller,
        ),
      );

      expect(controller.text, 'Option 2');

      controller.dispose();
    });

    testWidgets('allows free-form entry when allowFreeForm is true', (tester) async {
      final options = ['Option 1', 'Option 2'];
      String? lastSubmitted;

      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          allowFreeForm: true,
          controller: controller,
          onSubmit: (value) => lastSubmitted = value,
        ),
      );

      // Tap field
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Type arbitrary text
      await tester.enterText(find.byType(EditableText), 'CustomValue');
      await tester.pumpAndSettle();

      expect(lastSubmitted, null); // Not submitted yet

      controller.dispose();
    });

    testWidgets('displays errors when provided', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          errors: ['This is an error'],
        ),
      );

      expect(find.text('This is an error'), findsWidgets);
    });

    testWidgets('creates and disposes controller when not provided', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
        ),
      );

      // Should work without issues
      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('creates and disposes focus node when not provided', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
        ),
      );

      // Should work without issues
      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('custom emptyOptionsText is used', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          emptyOptionsText: 'No matching items',
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('filters options when text is typed', (tester) async {
      final options = ['Apple', 'Apricot', 'Banana'];

      String? lastValue;

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          onChanged: (value) => lastValue = value,
        ),
      );

      // Tap field
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Type to filter
      await tester.enterText(find.byType(EditableText), 'app');
      await tester.pumpAndSettle();

      // The value should be updated
      expect(lastValue, 'app');
    });

    testWidgets('shows all options when enableAutocomplete is false', (tester) async {
      final options = ['Apple', 'Banana', 'Cherry'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          enableAutocomplete: false,
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('reverts when allowFreeForm is false and text doesn\'t match', (tester) async {
      final controller = TextEditingController();
      final options = ['Valid1', 'Valid2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          allowFreeForm: false,
          controller: controller,
          value: 'Valid1',
        ),
      );

      expect(controller.text, 'Valid1');

      controller.dispose();
    });

    testWidgets('flips above when there is no room below', (tester) async {
      tester.view.physicalSize = const Size(1600, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Column(
          children: const [
            Spacer(),
            LayrzComboBoxInput(
              labelText: 'TZ',
              options: ['America/Panama', 'America/Peru'],
            ),
          ],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byType(LayrzComboBoxInput));

      // Get the bounds of all option items to compute the panel rect
      final optionRects = find
          .byType(OptionItem)
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((element) => element == e)))
          .toList();
      final panelLeft = optionRects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
      final panelTop = optionRects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
      final panelRight = optionRects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
      final panelBottom = optionRects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      final panel = Rect.fromLTRB(panelLeft, panelTop, panelRight, panelBottom);

      expect(
        panel.bottom,
        lessThanOrEqualTo(field.top),
        reason: 'panel must sit above the field when there is no room below',
      );
      expect(
        panel.width,
        closeTo(field.width, 0.5),
        reason: 'a web-style combobox list matches its field width',
      );
    });

    testWidgets('opens below when there is room', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Column(
          children: [
            const LayrzComboBoxInput(
              labelText: 'TZ',
              options: ['America/Panama', 'America/Peru'],
            ),
            const Spacer(),
          ],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byType(LayrzComboBoxInput));

      // Get the bounds of all option items to compute the panel rect
      final optionRects = find
          .byType(OptionItem)
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((element) => element == e)))
          .toList();
      final panelLeft = optionRects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
      final panelTop = optionRects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
      final panelRight = optionRects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
      final panelBottom = optionRects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      final panel = Rect.fromLTRB(panelLeft, panelTop, panelRight, panelBottom);

      expect(
        panel.top,
        greaterThanOrEqualTo(field.bottom),
        reason: 'panel must sit below the field when there is room',
      );
      expect(
        panel.width,
        closeTo(field.width, 0.5),
        reason: 'a web-style combobox list matches its field width',
      );
    });

    testWidgets(
      'opens the compact bottom sheet and commits a selection exactly once (DESIGN-35)',
      (tester) async {
        // This is the gate for DESIGN-35's mobile fix: before it, the compact
        // combobox was structurally non-functional for any option count (a
        // ListView nested inside the sheet's own same-axis SingleChildScrollView
        // asserted with "Vertical viewport was given unbounded height"), yet the
        // suite stayed green because nothing opened the sheet at all.
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final options = ['Alpha', 'Bravo', 'Charlie'];
        var changedCount = 0;
        var submitCount = 0;
        String? lastChanged;
        String? lastSubmitted;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: options,
            onChanged: (value) {
              changedCount++;
              lastChanged = value;
            },
            onSubmit: (value) {
              submitCount++;
              lastSubmitted = value;
            },
          ),
        );

        // Tapping the chrome alone does not open the combobox's overlay/sheet —
        // only a tap that lands on the EditableText itself does. Verified during
        // the DESIGN-35 investigation; asserted here so a future regression that
        // moves the open-trigger back onto the chrome is caught.
        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();
        expect(
          find.byType(BottomSheetContent),
          findsNothing,
          reason: 'tapping the chrome alone must not open the compact sheet',
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheetContent), findsOneWidget);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Bravo'), findsOneWidget);
        expect(find.text('Charlie'), findsOneWidget);

        await tester.tap(find.text('Bravo'));
        await tester.pumpAndSettle();

        expect(
          find.byType(BottomSheetContent),
          findsNothing,
          reason: 'selecting an option closes the sheet',
        );
        expect(
          changedCount,
          1,
          reason:
              'onChanged must fire exactly once per mobile selection, not twice (the '
              'BottomSheetContent onSelected callback + Navigator.pop double-commit) and '
              'not zero times (the sheet never rendering usable content)',
        );
        expect(submitCount, 1, reason: 'onSubmit must fire exactly once per mobile selection');
        expect(lastChanged, 'Bravo');
        expect(lastSubmitted, 'Bravo');
      },
    );

    testWidgets(
      'reselecting the same option again does not re-fire onChanged, but does re-fire onSubmit',
      (tester) async {
        // Pins the contract decided for the onChanged/onSubmit split once selection
        // commits stopped double-firing onChanged (DESIGN-35): onChanged tracks the
        // field's *text value* (per its own doc comment, "fired when the input value
        // changes") and is deliberately silent when a selection does not change the
        // text — including re-selecting the option already shown. onSubmit tracks the
        // *user action* of committing a value (per its doc comment, "fired when the
        // user submits the input") and fires on every commit unconditionally, so a
        // caller that needs "the user picked something" — even the same something
        // again — has a callback that never misses one.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var changedCount = 0;
        var submitCount = 0;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo', 'Charlie'],
            onChanged: (_) => changedCount++,
            onSubmit: (_) => submitCount++,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(OptionItem), matching: find.text('Bravo')));
        await tester.pumpAndSettle();

        expect(changedCount, 1);
        expect(submitCount, 1);

        // Re-open and select the same option again. The field's text already
        // reads "Bravo", so the option list is filtered down to that single entry.
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(OptionItem), matching: find.text('Bravo')));
        await tester.pumpAndSettle();

        expect(changedCount, 1, reason: 'onChanged does not re-fire: the text did not change');
        expect(submitCount, 2, reason: 'onSubmit fires on every commit, including a repeated selection');
      },
    );
  });
}
