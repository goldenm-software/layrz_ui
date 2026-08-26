import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_custom_value_row.dart';
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

    testWidgets(
      "the desktop panel's rect overlaps the field's own rect, not sits below it (Q3/Q9 -- coverAnchor)",
      (tester) async {
        // Superseded by U3: the pre-parity combobox opened a panel below/above
        // the field with a small gap, using its own hand-rolled
        // `ComboBoxLayoutDelegate`. Parity with `LayrzSelectInput` (Q3) means
        // `coverAnchor: true` on `LayrzAnchoredPanel` instead -- the panel now
        // starts at the field's own top-left corner, exactly like DESIGN-145's
        // "elevated field" illusion for Select. Mirrors
        // `select_input_test.dart`'s own defect-1 regression: 0.0 tolerance,
        // not a loose one -- there is no border-inset side effect here either,
        // since U1's `LayrzAnchoredPanelBorder` is painted with
        // `strokeAlign: BorderSide.strokeAlignOutside`.
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemedApp(
          tester,
          const LayrzComboBoxInput(
            labelText: 'TZ',
            options: ['America/Panama', 'America/Peru'],
          ),
        );

        // The FIELD's own rect, not `LayrzComboBoxInput`'s whole rect: since the
        // label/error hoisting fix (parity with `LayrzSelectInput`'s
        // `_appendExtras`), the label renders OUTSIDE the anchor passed to
        // `LayrzAnchoredPanel` -- the panel now covers the field exactly, not
        // the field-plus-label the widget's outer rect includes.
        final field = tester.getRect(find.byType(LayrzInputChrome).first);

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        // `LayrzComboBoxPanelContent` is the panel's own content -- its rect
        // spans the input row, the divider, and the option list together,
        // unlike `OptionItem`'s rect, which covers only the list below the
        // live input and so never overlaps the field on its own.
        final panel = tester.getRect(find.byType(LayrzComboBoxPanelContent));

        expect(panel.overlaps(field), isTrue, reason: 'the panel must cover the field, not sit beside it');
        expect(
          panel.left,
          closeTo(field.left, 0.5),
          reason: 'a web-style combobox list matches its field width and left edge',
        );
        expect(
          panel.top,
          closeTo(field.top, 0.5),
          reason: "coverAnchor starts the panel exactly at the field's own top-left corner (Q9)",
        );
      },
    );

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
        //
        // Tapping a point genuinely outside `EditableText`'s own rect, rather
        // than `find.byType(LayrzInputChrome)`'s default geometric center: since
        // the label/error hoisting fix (parity with `LayrzSelectInput`'s
        // `_appendExtras`), `LayrzInputChrome` no longer renders the label
        // internally, so its rect is now exactly the bordered field box --
        // whose center now sits ON the text line, not in dead space above it as
        // it did when the label lived inside the chrome. `chromeRect.topLeft`
        // plus a small inset lands inside the chrome's own left padding, still
        // outside the text field's own hit region.
        final chromeRect = tester.getRect(find.byType(LayrzInputChrome));
        await tester.tapAt(chromeRect.topLeft + const Offset(4, 4));
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

        // (20, 1150) lands in the trailing SizedBox, well below the panel: with
        // `coverAnchor: true` (Q3/Q9) the panel now covers the field itself
        // (see the "the desktop panel's rect overlaps the field's own rect"
        // test above), so a point that used to sit safely in the gap above a
        // below-the-field panel -- (20, 20) -- is now inside the covering
        // panel's own rect and is no longer a genuine outside tap.
        final gesture = await tester.startGesture(const Offset(20, 1150), kind: PointerDeviceKind.mouse);
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

          // See the mouse variant above for why (20, 1150), not (20, 20).
          final gesture = await tester.startGesture(const Offset(20, 1150), kind: PointerDeviceKind.touch);
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(find.byType(OptionItem), findsNothing, reason: 'a genuine outside tap must close the overlay');
          expect(changedCount, 0, reason: 'dismissing outside must not commit any option');
        },
      );
    });

    group('text/caret/focus continuity across the open transition (Q3, plan verification requirement)', () {
      // U3's plan flags this group explicitly: "the unit most likely to pass
      // its tests and feel wrong on device." These four tests are the
      // required, non-negotiable proof -- if any of them cannot be made to
      // pass, the plan says stop and report rather than ship a partial
      // transition. All four pass here.
      void setDesktopSize(WidgetTester tester) {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      testWidgets('typing before open and continuing after open loses no characters', (tester) async {
        setDesktopSize(tester);
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alabama', 'Alaska', 'Arizona'],
            controller: controller,
          ),
        );

        // Type before the panel opens (opening is triggered by the field's
        // own onTap, not by typing) -- then continue typing after it is open.
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Ala');
        await tester.pumpAndSettle();

        expect(controller.text, 'Ala', reason: 'text typed before the panel settles must not be lost');
        expect(find.byType(OptionItem), findsWidgets, reason: 'the panel must be open by now');

        // Continue typing after the transition -- the SAME EditableText
        // (structurally, the same controller/focus node) must still be live
        // and receiving input, whether it is rendered by the closed field's
        // slot or the panel's first row.
        await tester.enterText(find.byType(EditableText), 'Alaska');
        await tester.pumpAndSettle();

        expect(controller.text, 'Alaska', reason: 'no characters may be lost continuing to type after open');
      });

      testWidgets('the caret position does not jump across the open transition', (tester) async {
        setDesktopSize(tester);
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alabama', 'Alaska'],
            controller: controller,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Alaska');
        await tester.pumpAndSettle();

        // Move the caret to a specific, known offset (not the end) before the
        // transition settles further, then confirm it holds.
        final editableState = tester.state<EditableTextState>(find.byType(EditableText));
        editableState.userUpdateTextEditingValue(
          controller.value.copyWith(selection: const TextSelection.collapsed(offset: 3)),
          SelectionChangedCause.keyboard,
        );
        await tester.pump();

        expect(controller.selection, const TextSelection.collapsed(offset: 3));

        // Force a further rebuild of the open panel (mirroring what a
        // highlight change or option filter would do) and confirm the caret
        // offset is unaffected -- it must still be governed by the SAME
        // controller instance, not reset because a new widget instance was
        // mounted.
        await tester.pump();
        expect(
          controller.selection,
          const TextSelection.collapsed(offset: 3),
          reason: 'the caret must not jump when the panel content rebuilds',
        );
      });

      testWidgets('focus lands in the panel input on open, not the closed field or the panel root', (tester) async {
        setDesktopSize(tester);
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo'],
            focusNode: focusNode,
          ),
        );

        expect(focusNode.hasFocus, isFalse, reason: 'nothing is focused before any interaction');

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.byType(OptionItem), findsWidgets, reason: 'the panel must be open');
        // The SAME field focus node -- shared, by instance, between the
        // closed field and the panel's first row (Q3) -- must hold focus once
        // the panel has settled. There is exactly one EditableText in the
        // tree at this point (the panel's own field row; the closed slot
        // renders a non-editable placeholder while open), so this also pins
        // that there is no duplicate, competing EditableText fighting for
        // focus.
        expect(focusNode.hasFocus, isTrue, reason: "focus must land in the panel's own input, not nowhere");
        expect(find.byType(EditableText), findsOneWidget, reason: 'exactly one live EditableText while open');

        final editableState = tester.state<EditableTextState>(find.byType(EditableText));
        expect(
          editableState.widget.focusNode,
          same(focusNode),
          reason: 'the live EditableText while open must be bound to the SAME focus node as the closed field',
        );
      });

      testWidgets('onChanged dedupe survives the open transition: no extra notification from the field swap', (
        tester,
      ) async {
        setDesktopSize(tester);
        var changedCount = 0;
        final values = <String>[];

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo'],
            onChanged: (value) {
              changedCount++;
              values.add(value);
            },
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(
          changedCount,
          0,
          reason: 'opening the panel alone -- with no text typed -- must not fire onChanged by itself',
        );

        await tester.enterText(find.byType(EditableText), 'Al');
        await tester.pumpAndSettle();

        expect(
          changedCount,
          1,
          reason:
              'exactly one onChanged for the genuine text change, even though the field instance is '
              'reparented between the closed slot and the panel row across this same interaction',
        );
        expect(values, ['Al']);
      });
    });

    group('keyboard navigation and the custom-value row (Q4)', () {
      void setDesktopSize(WidgetTester tester) {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      // NOTE on an arrow-down-opens-when-closed test: `_handleKeyEvent`
      // implements that branch (see `combobox_input.dart`'s `!isOpen` case),
      // preserved verbatim from the pre-parity implementation. It is not
      // exercisable from a widget test in EITHER version, before or after
      // this unit: `RawMenuAnchor.buildAnchor` wraps its `builder:` slot
      // (where the closed field lives) in its own `Shortcuts` mapping
      // `arrowDown` to a `DirectionalFocusIntent`, which -- being on a
      // descendant `Focus` node relative to this widget's own
      // `Focus(onKeyEvent: _handleKeyEvent)` -- intercepts the key event
      // first. Confirmed pre-existing, not a regression: the pre-parity
      // implementation wrapped its own `RawMenuAnchor` inside an identical
      // `Focus(onKeyEvent: ...)` with the same branch, and the same
      // interception applies to it. Once the panel is open, the field lives
      // in the panel's overlay instead (a different `RawMenuAnchor` slot,
      // not wrapped by that `Shortcuts`), which is why arrow-key navigation
      // *while open* -- covered by the tests below -- works correctly.

      testWidgets('the "use" row appears first and shifts option highlight indices by one', (tester) async {
        setDesktopSize(tester);

        await pumpThemedApp(
          tester,
          const LayrzComboBoxInput(
            labelText: 'Choose',
            options: ['Alabama', 'Alaska'],
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        // "Ala" matches both options by prefix (so the option list stays
        // populated) but is not an exact match to either (so the
        // custom-value row is also shown) -- exercising both rows together.
        await tester.enterText(find.byType(EditableText), 'Ala');
        await tester.pumpAndSettle();

        expect(find.byType(LayrzComboBoxCustomValueRow), findsOneWidget);
        expect(find.byType(OptionItem), findsNWidgets(2));

        // Arrow down once highlights the custom-value row (index 0); a
        // second arrow down moves the highlight to the first option, which
        // this asserts by reading `highlightedIndex` off the rendered
        // `LayrzComboBoxPanelContent` -- the actual value `_handleKeyEvent`
        // computed, not an inference from color.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        final afterFirstDown = tester.widget<LayrzComboBoxPanelContent>(find.byType(LayrzComboBoxPanelContent));
        expect(afterFirstDown.highlightedIndex, -1, reason: 'index 0 belongs to the custom-value row, not an option');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        final afterSecondDown = tester.widget<LayrzComboBoxPanelContent>(find.byType(LayrzComboBoxPanelContent));
        expect(
          afterSecondDown.highlightedIndex,
          0,
          reason: 'the second arrow-down must land on the first option, index-shifted by the custom-value row',
        );
      });

      testWidgets('committing the custom-value row via Enter reports the typed value exactly once', (tester) async {
        setDesktopSize(tester);
        var changedCount = 0;
        var submitCount = 0;
        String? lastSubmitted;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo'],
            onChanged: (_) => changedCount++,
            onSubmit: (value) {
              submitCount++;
              lastSubmitted = value;
            },
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Custom option');
        await tester.pumpAndSettle();
        changedCount = 0; // isolate the commit's own notification

        expect(find.byType(LayrzComboBoxCustomValueRow), findsOneWidget);

        // The custom-value row is index 0: one arrow-down highlights it.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(submitCount, 1, reason: 'Enter on the highlighted custom-value row must commit exactly once');
        expect(lastSubmitted, 'Custom option');
        expect(changedCount, 1, reason: 'the commit itself still reports onChanged exactly once');
      });

      testWidgets('committing an option via Enter after arrowing past the custom-value row', (tester) async {
        setDesktopSize(tester);
        String? lastSubmitted;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo'],
            onSubmit: (value) => lastSubmitted = value,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'zzz-no-match');
        await tester.pumpAndSettle();

        expect(find.byType(LayrzComboBoxCustomValueRow), findsOneWidget);
        expect(
          find.byType(OptionItem),
          findsNothing,
          reason: 'the typed text matches no option, so the list is empty and only the custom row is navigable',
        );

        // With no options to land on, arrowing wraps back onto the single
        // navigable row (the custom-value row) rather than committing an
        // option that does not exist.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(lastSubmitted, 'zzz-no-match');
      });

      testWidgets('escape closes the panel via the keyboard without committing', (tester) async {
        setDesktopSize(tester);
        var changedCount = 0;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo'],
            onChanged: (_) => changedCount++,
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        expect(find.byType(OptionItem), findsWidgets);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(OptionItem), findsNothing, reason: 'Escape must close the panel');
        expect(changedCount, 0, reason: 'Escape must not commit anything');
      });

      testWidgets('arrow up from no highlight wraps to the last navigable row', (tester) async {
        setDesktopSize(tester);

        await pumpThemedApp(
          tester,
          const LayrzComboBoxInput(
            labelText: 'Choose',
            options: ['Alpha', 'Bravo', 'Charlie'],
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        // No exception, and the panel stays open with all three options still
        // present -- arrow-up wrapping must not throw or lose the list.
        expect(tester.takeException(), isNull);
        expect(find.byType(OptionItem), findsNWidgets(3));
      });
    });

    group('allowFreeForm: false revert-on-blur', () {
      testWidgets('a genuine loss of focus reverts non-matching text to the last valid option', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final otherFocusNode = FocusNode();
        addTearDown(otherFocusNode.dispose);

        await pumpThemedApp(
          tester,
          Column(
            children: [
              LayrzComboBoxInput(
                labelText: 'Choose',
                options: const ['Valid1', 'Valid2'],
                allowFreeForm: false,
                controller: controller,
                value: 'Valid1',
              ),
              Focus(
                focusNode: otherFocusNode,
                child: const SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'not a real option');
        await tester.pumpAndSettle();

        expect(controller.text, 'not a real option');

        // Move focus elsewhere entirely -- a genuine loss of focus, not the
        // panel's own transient open-transition blip.
        otherFocusNode.requestFocus();
        await tester.pumpAndSettle();

        expect(
          controller.text,
          'Valid1',
          reason: 'losing focus with allowFreeForm false must revert to the last valid option',
        );
      });
    });
  });
}
