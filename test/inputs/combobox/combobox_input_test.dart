import 'package:flutter/gestures.dart';
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
      'reselecting the same option again fires onChanged and onSubmit again, once each',
      (tester) async {
        // Pins the contract restored for combobox-commit-notify: onChanged now
        // fires exactly once per genuine *commit* — tapping an option, pressing
        // Enter on a highlighted option, or picking from the bottom sheet —
        // regardless of whether the resulting text differs from what the field
        // already showed. onSubmit already fired unconditionally on every
        // commit; onChanged now carries the same guarantee for a real commit,
        // while still deduping the purely mechanical echo notifications that a
        // controller assignment and EditableText's post-assignment selection
        // resync produce underneath (see `_lastNotifiedText`).
        //
        // An earlier version of this test pinned the opposite: that onChanged
        // stayed silent on a same-value re-selection. That was the same defect
        // as "type the option's full text, then tap it" (both leave the field's
        // displayed text already equal to the committed value at the moment of
        // commit) — fixing one necessarily fixes the other, since the two are
        // mechanically indistinguishable at commit time.
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

        expect(changedCount, 1, reason: 'the first selection is a genuine text change, "" -> "Bravo"');
        expect(submitCount, 1);

        // Re-open and select the same option again. The field's text already
        // reads "Bravo", so the option list is filtered down to that single entry.
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(OptionItem), matching: find.text('Bravo')));
        await tester.pumpAndSettle();

        expect(
          changedCount,
          2,
          reason: 'onChanged fires again: a repeated selection is still a genuine commit',
        );
        expect(submitCount, 2, reason: 'onSubmit fires on every commit, including a repeated selection');
      },
    );

    testWidgets(
      'commits onChanged exactly once when the typed text already matches the tapped option (desktop)',
      (tester) async {
        // This is the exact defect reported for LayrzComboBoxInput: "clicking an
        // option does not select it". It only reproduces once the field's text
        // already equals the option being tapped — the ordinary way to reach
        // that is to type the option's full text and then click it in the still-
        // open overlay, which is what this test does.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var changedCount = 0;
        String? lastChanged;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Beta', 'Charlie'],
            onChanged: (value) {
              changedCount++;
              lastChanged = value;
            },
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        // Typing the option's full text is itself a genuine change and already
        // notifies once — isolate that from the tap's own notification below.
        await tester.enterText(find.byType(EditableText), 'Beta');
        await tester.pumpAndSettle();
        expect(changedCount, 1, reason: 'typing "Beta" from empty text is a genuine change');
        changedCount = 0;

        await tester.tap(find.descendant(of: find.byType(OptionItem), matching: find.text('Beta')));
        await tester.pumpAndSettle();

        expect(
          changedCount,
          1,
          reason:
              'tapping the option that exactly matches the already-typed text is still a '
              'genuine commit and must notify onChanged exactly once, not zero times',
        );
        expect(lastChanged, 'Beta');
      },
    );

    testWidgets(
      'commits onChanged exactly once when the typed text already matches the tapped option (compact)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var changedCount = 0;
        String? lastChanged;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Beta', 'Charlie'],
            onChanged: (value) {
              changedCount++;
              lastChanged = value;
            },
          ),
        );

        // Type first, without a real tap gesture, so the compact overlay's
        // onTap-triggered open does not fire yet: `LayrzComboBoxInput` opens the
        // bottom sheet with the filtered list computed once, at open time, so
        // typing after opening it would not be reflected in what is on screen.
        await tester.showKeyboard(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'Beta');
        await tester.pumpAndSettle();
        expect(changedCount, 1, reason: 'typing "Beta" from empty text is a genuine change');
        changedCount = 0;

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheetContent), findsOneWidget);
        final sheetOption = find.descendant(of: find.byType(BottomSheetContent), matching: find.text('Beta'));
        expect(sheetOption, findsOneWidget, reason: 'the sheet opens already filtered to "Beta"');

        await tester.tap(sheetOption);
        await tester.pumpAndSettle();

        expect(
          changedCount,
          1,
          reason:
              'tapping the option that exactly matches the already-typed text is still a '
              'genuine commit and must notify onChanged exactly once, not zero times',
        );
        expect(lastChanged, 'Beta');
      },
    );

    group('panel tap region (H1)', () {
      // Regression coverage for the reported defect: "tapping an option in
      // LayrzComboBoxInput's overlay does nothing." Root cause: the overlay
      // was not grouped with the field's own `TextFieldTapRegion`, so a
      // mouse-kind tap-down on an option counted as "outside" the field for
      // `EditableText`'s own (mouse-unconditional, touch-conditional) tap-
      // outside handling, unfocusing it; `_handleFocusChange` then called
      // `_handleBlur`, which closed the overlay mid-gesture via
      // `_menuController.close()` before the option's own `onTap` ever fired
      // on pointer-up. `flutter_test`'s default synthetic taps use
      // `PointerDeviceKind.touch`, which this SDK path never unfocuses for —
      // which is exactly why 2648 prior passing tests said nothing about a
      // widget the maintainer could not use with a mouse. These tests
      // exercise a real `PointerDeviceKind.mouse` gesture instead.
      void setDesktopSize(WidgetTester tester) {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      Future<void> openOverlay(WidgetTester tester) async {
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
      }

      testWidgets('a mouse tap on an option commits the selection', (tester) async {
        setDesktopSize(tester);
        var changedCount = 0;
        String? lastChanged;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo', 'Charlie'],
            onChanged: (value) {
              changedCount++;
              lastChanged = value;
            },
          ),
        );

        await openOverlay(tester);

        final optionFinder = find.descendant(of: find.byType(OptionItem), matching: find.text('Bravo'));
        expect(optionFinder, findsOneWidget, reason: 'option must be visible before tapping it');
        final optionCenter = tester.getCenter(optionFinder);

        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.mouse);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(
          changedCount,
          1,
          reason: 'a mouse tap on the option must commit the selection exactly once, not be destroyed',
        );
        expect(lastChanged, 'Bravo');
      });

      testWidgets('a touch tap on an option commits the selection, matching mouse behavior', (tester) async {
        setDesktopSize(tester);
        var changedCount = 0;
        String? lastChanged;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo', 'Charlie'],
            onChanged: (value) {
              changedCount++;
              lastChanged = value;
            },
          ),
        );

        await openOverlay(tester);

        final optionFinder = find.descendant(of: find.byType(OptionItem), matching: find.text('Bravo'));
        final optionCenter = tester.getCenter(optionFinder);

        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.touch);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(changedCount, 1, reason: 'touch must commit the selection exactly like a mouse tap does');
        expect(lastChanged, 'Bravo');
      });

      testWidgets('tapping an option with a mouse pointer keeps the field focused', (tester) async {
        setDesktopSize(tester);
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo', 'Charlie'],
            focusNode: focusNode,
          ),
        );

        await openOverlay(tester);
        expect(focusNode.hasFocus, isTrue, reason: 'opening the overlay must keep the field focused');

        final optionFinder = find.descendant(of: find.byType(OptionItem), matching: find.text('Bravo'));
        final optionCenter = tester.getCenter(optionFinder);

        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.mouse);
        await tester.pump();

        expect(
          focusNode.hasFocus,
          isTrue,
          reason: 'a tap landing inside the overlay must never unfocus the field mid-gesture',
        );

        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a genuine mouse tap outside the field and overlay closes it without committing', (tester) async {
        setDesktopSize(tester);
        var changedCount = 0;

        await pumpThemedApp(
          tester,
          Column(
            children: [
              LayrzComboBoxInput(
                labelText: 'Choose',
                options: const ['Alpha', 'Bravo', 'Charlie'],
                onChanged: (_) => changedCount++,
              ),
              const SizedBox(height: 400),
            ],
          ),
        );

        await openOverlay(tester);
        expect(find.byType(OptionItem), findsWidgets, reason: 'overlay must be open before the outside tap');

        final gesture = await tester.startGesture(const Offset(20, 20), kind: PointerDeviceKind.mouse);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(OptionItem), findsNothing, reason: 'a genuine outside tap must close the overlay');
        expect(changedCount, 0, reason: 'dismissing outside must not commit any option');
      });

      testWidgets(
        'a genuine touch tap outside the field and overlay closes it, matching mouse behavior',
        (tester) async {
          setDesktopSize(tester);
          var changedCount = 0;

          await pumpThemedApp(
            tester,
            Column(
              children: [
                LayrzComboBoxInput(
                  labelText: 'Choose',
                  options: const ['Alpha', 'Bravo', 'Charlie'],
                  onChanged: (_) => changedCount++,
                ),
                const SizedBox(height: 400),
              ],
            ),
          );

          await openOverlay(tester);
          expect(find.byType(OptionItem), findsWidgets, reason: 'overlay must be open before the outside tap');

          final gesture = await tester.startGesture(const Offset(20, 20), kind: PointerDeviceKind.touch);
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(find.byType(OptionItem), findsNothing, reason: 'a genuine outside tap must close the overlay');
          expect(changedCount, 0, reason: 'dismissing outside must not commit any option');
        },
      );
    });
  });
}
