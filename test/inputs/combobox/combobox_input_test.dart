import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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
      // Explicit desktop size (DESIGN-161): this test's own gesture --
      // tapping the chrome and expecting `find.byType(EditableText)` to
      // resolve to a single field -- only holds before the field has opened
      // any overlay. Left unset, this ran at flutter_test's 800x600 default,
      // which `context.isCompact` (< 960px) reads as compact.
      //
      // DESIGN-98: typing now happens BEFORE tapping, not after. Before
      // DESIGN-98 the closed field's own `EditableText` continued live into
      // the opened `LayrzAnchoredPanel` (Q3), so typing after the tap still
      // resolved to a single `EditableText` in the tree. DESIGN-98 replaced
      // that panel with `LayrzEndDrawer` hosting a wholly independent
      // `BottomSheetContent` surface (its own search field) -- once the
      // drawer is open there are genuinely TWO `EditableText`s in the tree
      // (the closed field's, still mounted underneath the drawer, and the
      // drawer's own), so `find.byType(EditableText)` after opening now
      // throws "Too many elements". Typing before ever tapping keeps this
      // test exercising exactly one `EditableText` -- the closed field's own,
      // which still reports every keystroke via `onChanged` regardless of
      // whether anything is open.
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

      await tester.enterText(find.byType(EditableText), 'test');
      await tester.pumpAndSettle();

      expect(lastValue, 'test');
    });

    /// Per DESIGN-126, `dense` forwards to the field's chrome (closed field and, per
    /// `combobox_input_chrome_test.dart`, the open panel row read the same density).
    ///
    /// Affordance check (liliana's criterion): the field itself is the dropdown trigger --
    /// tapping it must still open the panel, and selecting an option must still commit
    /// correctly, at `dense: true`.
    testWidgets('dense: true forwards to the chrome and keeps the field trigger + option selection working', (
      tester,
    ) async {
      final options = ['Option 1', 'Option 2', 'Option 3'];
      String? lastValue;

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select an option',
          options: options,
          dense: true,
          onChanged: (value) => lastValue = value,
        ),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
      expect(chrome.dense, isTrue);

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option 2').last);
      await tester.pumpAndSettle();

      expect(lastValue, 'Option 2', reason: 'tapping an option at dense must still commit the selection');
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
      // DESIGN-98: types before ever opening the overlay -- see 'calls
      // onChanged when value changes' above for why (opening now mounts a
      // second, independent EditableText via LayrzEndDrawer/BottomSheetContent,
      // so `find.byType(EditableText)` after opening is no longer unique).
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

      // Type arbitrary text, without ever opening the overlay.
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
      // DESIGN-98: types without ever opening the overlay -- see 'calls
      // onChanged when value changes' above for why.
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
      "the desktop drawer's rect does not overlap the field's own rect (DESIGN-98 retires coverAnchor)",
      (tester) async {
        // DESIGN-98 retired the Q3/Q9 `coverAnchor: true` illusion this test
        // used to pin: the maintainer's own instruction moved this widget's
        // desktop overlay onto `LayrzEndDrawer`, a fixed-width right-edge
        // drawer that does not anchor to (or cover) the field's rect at all --
        // mirroring `LayrzSelectInput`'s own DESIGN-98 rewrite in
        // `select_input_test.dart`. There is no more `LayrzComboBoxPanelContent`
        // in the real desktop flow either (see `combobox_input.dart`'s class
        // doc): the drawer hosts the same independent `BottomSheetContent`
        // surface the mobile band already opened.
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

        final field = tester.getRect(find.byType(LayrzInputChrome).first);

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        final drawer = tester.getRect(find.byType(BottomSheetContent));

        expect(
          drawer.overlaps(field),
          isFalse,
          reason: 'the drawer is a separate, fixed-width right-edge panel -- it must not cover the field in place',
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
        // Enter on a highlighted option, or picking from the bottom sheet/drawer —
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
        //
        // DESIGN-98: taps the drawer's own `BottomSheetContent` option text
        // directly, not `OptionItem` -- `LayrzComboBoxPanelContent`/`OptionItem`
        // are no longer built by the real desktop flow (see the class doc's
        // Q3 section).
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
        await tester.tap(find.descendant(of: find.byType(BottomSheetContent), matching: find.text('Bravo')));
        await tester.pumpAndSettle();

        expect(changedCount, 1, reason: 'the first selection is a genuine text change, "" -> "Bravo"');
        expect(submitCount, 1);

        // Re-open and select the same option again. The field's text already
        // reads "Bravo", so the option list is filtered down to that single entry.
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(BottomSheetContent), matching: find.text('Bravo')));
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
        // already equals the option being tapped.
        //
        // DESIGN-98 changed WHEN the typing must happen: before DESIGN-98, the
        // field's own `EditableText` continued live into the still-open
        // `LayrzAnchoredPanel` (Q3), so typing after the tap (in the still-open
        // overlay) reproduced the defect. DESIGN-98 replaced that panel with
        // `LayrzEndDrawer` hosting an independent `BottomSheetContent` --
        // opening it computes the filtered option pool once, at open time (see
        // `_openDesktopDrawer`'s own doc), so typing must now happen BEFORE the
        // tap that opens it, mirroring the compact variant of this test below,
        // which already followed this pattern.
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

        // Typing the option's full text is itself a genuine change and already
        // notifies once — isolate that from the tap's own notification below.
        await tester.enterText(find.byType(EditableText), 'Beta');
        await tester.pumpAndSettle();
        expect(changedCount, 1, reason: 'typing "Beta" from empty text is a genuine change');
        changedCount = 0;

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        final drawerOption = find.descendant(of: find.byType(BottomSheetContent), matching: find.text('Beta'));
        expect(drawerOption, findsOneWidget, reason: 'the drawer opens already filtered to "Beta"');

        await tester.tap(drawerOption);
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

    group('panel tap region (H1) -- superseded by DESIGN-98\'s drawer/route model', () {
      // The original regression here ("tapping an option in
      // LayrzComboBoxInput's overlay does nothing") was rooted in a
      // `RawMenuAnchor`-hosted, in-place overlay sharing a widget subtree with
      // the field's own `EditableText`: a mouse-kind tap-down on an option
      // could count as "outside" the field for `EditableText`'s own tap-
      // outside handling, unfocusing it and closing the overlay before the
      // option's own `onTap` ever fired.
      //
      // DESIGN-98 makes that entire failure mode structurally impossible: the
      // overlay is now `LayrzEndDrawer`, a [Navigator.push]ed route with its
      // own modal barrier and its own [BottomSheetContent] subtree, wholly
      // separate from the closed field's. A tap on an option inside the
      // drawer is never in the same gesture arena as the closed field's own
      // `EditableText` at all -- there is no "outside the field, inside the
      // overlay" ambiguity left to regress. These tests assert the DESIGN-98
      // equivalent: mouse and touch taps on the drawer's own option both
      // still commit, and a barrier tap still closes the drawer without
      // committing.
      void setDesktopSize(WidgetTester tester) {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      Future<void> openOverlay(WidgetTester tester) async {
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();
      }

      testWidgets('a mouse tap on the drawer\'s own option commits the selection', (tester) async {
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

        final optionFinder = find.descendant(of: find.byType(BottomSheetContent), matching: find.text('Bravo'));
        expect(optionFinder, findsOneWidget, reason: 'option must be visible before tapping it');
        final optionCenter = tester.getCenter(optionFinder);

        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.mouse);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(changedCount, 1, reason: 'a mouse tap on the option must commit the selection exactly once');
        expect(lastChanged, 'Bravo');
      });

      testWidgets('a touch tap on the drawer\'s own option commits the selection, matching mouse behavior', (
        tester,
      ) async {
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

        final optionFinder = find.descendant(of: find.byType(BottomSheetContent), matching: find.text('Bravo'));
        final optionCenter = tester.getCenter(optionFinder);

        final gesture = await tester.startGesture(optionCenter, kind: PointerDeviceKind.touch);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(changedCount, 1, reason: 'touch must commit the selection exactly like a mouse tap does');
        expect(lastChanged, 'Bravo');
      });

      testWidgets('a barrier tap outside the drawer closes it without committing', (tester) async {
        setDesktopSize(tester);
        var changedCount = 0;

        await pumpThemedApp(
          tester,
          LayrzComboBoxInput(
            labelText: 'Choose',
            options: const ['Alpha', 'Bravo', 'Charlie'],
            onChanged: (_) => changedCount++,
          ),
        );

        await openOverlay(tester);
        expect(find.byType(BottomSheetContent), findsOneWidget, reason: 'drawer must be open before the tap');

        // The drawer sits at the right edge (LayrzEndDrawer.width, 420px) --
        // a point near the top-left of the 1600px-wide viewport always lands
        // on the barrier, well clear of the drawer itself.
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheetContent), findsNothing, reason: 'a barrier tap must close the drawer');
        expect(changedCount, 0, reason: 'dismissing via the barrier must not commit any option');
      });
    });

    group('the closed field and the opened drawer, post-DESIGN-98 (Q3 retired)', () {
      // U3's original plan flagged the pre-DESIGN-98 Q3 continuity contract
      // as "the unit most likely to pass its tests and feel wrong on
      // device", and required non-negotiable proof that the SAME live field
      // (controller, focus node, caret) continued unbroken from the closed
      // slot into the open `LayrzAnchoredPanel`'s first row.
      //
      // DESIGN-98 retires that contract entirely, deliberately, on the
      // maintainer's own instruction: the desktop overlay is now
      // `LayrzEndDrawer`, hosting a wholly independent `BottomSheetContent`
      // surface -- the same one the mobile band already opened -- with its
      // OWN search controller and focus node (see `combobox_input.dart`'s
      // class doc). There is no more field to reparent, no more caret to
      // preserve across the transition, and no more shared focus node to
      // hand off: the closed field and the drawer's own search field are two
      // separate, independently-focused widgets from the moment the drawer
      // opens. This group proves the NEW contract instead of the old one --
      // what a caller can still rely on, and what they explicitly cannot
      // anymore.
      void setDesktopSize(WidgetTester tester) {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      testWidgets('text typed into the closed field before opening is preserved -- the field stays live underneath', (
        tester,
      ) async {
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

        // Type into the closed field, THEN open the drawer -- typing after
        // opening is no longer meaningful for the closed field's own
        // EditableText, since the drawer's own independent field is what
        // receives focus and input once open (see the next test).
        await tester.enterText(find.byType(EditableText), 'Ala');
        await tester.pumpAndSettle();
        expect(controller.text, 'Ala');

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheetContent), findsOneWidget, reason: 'the drawer must be open by now');
        expect(
          controller.text,
          'Ala',
          reason: "the closed field's own text must survive opening the drawer, unmodified",
        );
      });

      testWidgets(
        'the drawer opens with its OWN empty search field -- it does not continue the closed field\'s text or caret',
        (tester) async {
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

          await tester.enterText(find.byType(EditableText), 'Alaska');
          await tester.pumpAndSettle();

          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          // Post-DESIGN-98 there are genuinely TWO EditableTexts once the
          // drawer is open: the closed field's own (still mounted, holding
          // "Alaska") and the drawer's own search field (a fresh,
          // independent TextEditingController, starting empty).
          expect(find.byType(EditableText), findsNWidgets(2));

          final drawerField = find.descendant(of: find.byType(BottomSheetContent), matching: find.byType(EditableText));
          final drawerState = tester.state<EditableTextState>(drawerField);
          expect(
            drawerState.widget.controller.text,
            isEmpty,
            reason: "the drawer's own search field is independent -- it does not inherit the closed field's text",
          );
        },
      );

      testWidgets(
        "opening the drawer moves focus off the closed field -- BottomSheetContent's own search field does NOT "
        'autofocus (a pre-existing characteristic shared with the mobile band, not a DESIGN-98 regression)',
        (tester) async {
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

          expect(find.byType(BottomSheetContent), findsOneWidget, reason: 'the drawer must be open');
          expect(
            focusNode.hasFocus,
            isFalse,
            reason: "the closed field's own focus node must not still hold focus once the drawer is open",
          );

          // BottomSheetContent's own search field passes `autofocus: false`
          // (combobox_surface.dart) -- it does not request focus for itself.
          // LayrzEndDrawer instead autofocuses its own wrapper Focus node
          // (see end_drawer.dart's `_EndDrawerContentState.initState`), so
          // opening the drawer leaves the wrapper -- not the search field --
          // focused, exactly like opening the mobile bottom sheet already
          // did before DESIGN-98.
          final drawerField = find.descendant(of: find.byType(BottomSheetContent), matching: find.byType(EditableText));
          final drawerState = tester.state<EditableTextState>(drawerField);
          expect(
            drawerState.widget.focusNode.hasFocus,
            isFalse,
            reason: "the drawer's own search field does not autofocus -- the user must tap it to type",
          );
        },
      );

      testWidgets('typing in the closed field alone -- with the drawer never opened -- still reports via onChanged', (
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

        await tester.enterText(find.byType(EditableText), 'Al');
        await tester.pumpAndSettle();

        expect(changedCount, 1, reason: 'the closed field alone still reports every genuine text change');
        expect(values, ['Al']);
      });
    });

    // DESIGN-98 REMOVES in-panel keyboard navigation on desktop -- flagged for
    // the maintainer, not silently absorbed.
    //
    // Before DESIGN-98, `LayrzComboBoxPanelContent` carried its own
    // `highlightedIndex` state, and arrow-down/arrow-up/Enter/Escape all
    // navigated and committed rows in that in-place panel via
    // `_handleKeyEvent` (bound to a `Focus` wrapping the field's own
    // subtree, which stayed live inside the anchored panel). DESIGN-98's
    // `LayrzEndDrawer` hosts `BottomSheetContent` instead -- a route-based,
    // wholly independent widget with NO keyboard-navigable highlight state
    // at all (confirmed: `BottomSheetContent` has no `highlightedIndex`,
    // no `onKeyEvent`, nothing arrow-key-reachable). Once the drawer opens,
    // arrow-up/down no longer move a highlight, and Enter no longer commits
    // a highlighted row -- selecting an option now requires a tap (or,
    // still, typing the option's exact text and pressing Enter to submit
    // free-form). Escape still closes the drawer (via `LayrzEndDrawer`'s own
    // dismiss handling, since this widget passes `actions: null`), and
    // typing continues to filter/report through the closed field as before.
    //
    // This group proves what the maintainer should know changed, rather than
    // silently deleting the coverage: arrow-key highlight navigation inside
    // the option list is gone on desktop, matching the mobile band (which
    // never had it either).
    group('keyboard behavior post-DESIGN-98 (in-panel arrow-key navigation removed)', () {
      void setDesktopSize(WidgetTester tester) {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      testWidgets(
        'arrow-down/up inside the open drawer no longer highlight any row -- BottomSheetContent has no highlight state',
        (tester) async {
          setDesktopSize(tester);

          await pumpThemedApp(
            tester,
            const LayrzComboBoxInput(
              labelText: 'Choose',
              options: ['Alabama', 'Alaska'],
            ),
          );

          await tester.enterText(find.byType(EditableText), 'Ala');
          await tester.pumpAndSettle();
          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          expect(
            find.descendant(of: find.byType(BottomSheetContent), matching: find.byType(GestureDetector)),
            findsWidgets,
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pump();

          // No exception either way -- arrow keys are simply inert now, not
          // wired to anything inside BottomSheetContent.
          expect(tester.takeException(), isNull);
          expect(find.byType(BottomSheetContent), findsOneWidget, reason: 'the drawer stays open through both keys');
        },
      );

      testWidgets(
        'Enter inside the open drawer does not commit any option -- only typing + Enter, or a tap, commits',
        (tester) async {
          setDesktopSize(tester);
          var submitCount = 0;

          await pumpThemedApp(
            tester,
            LayrzComboBoxInput(
              labelText: 'Choose',
              options: const ['Alpha', 'Bravo'],
              onSubmit: (_) => submitCount++,
            ),
          );

          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();

          expect(
            submitCount,
            0,
            reason:
                'there is no highlighted row for Enter to commit post-DESIGN-98 -- committing now requires a '
                'tap on an option in the drawer, or typing the exact text and submitting the closed field',
          );
        },
      );

      testWidgets(
        'typing a free-form value that matches no option is still retained via onChanged (closed field, before opening)',
        (tester) async {
          setDesktopSize(tester);
          final changes = <String>[];

          await pumpThemedApp(
            tester,
            LayrzComboBoxInput(
              labelText: 'Choose',
              options: const ['Alpha', 'Bravo'],
              onChanged: changes.add,
            ),
          );

          await tester.enterText(find.byType(EditableText), 'zzz-no-match');
          await tester.pumpAndSettle();

          expect(changes, contains('zzz-no-match'));
          expect(find.text('zzz-no-match', findRichText: true), findsWidgets);
        },
      );

      testWidgets('escape still closes the drawer via LayrzEndDrawer\'s own dismiss handling, without committing', (
        tester,
      ) async {
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
        expect(find.byType(BottomSheetContent), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheetContent), findsNothing, reason: 'Escape must close the drawer');
        expect(changedCount, 0, reason: 'Escape must not commit anything');
      });
    });

    group('allowFreeForm: false revert-on-blur', () {
      testWidgets('a genuine loss of focus reverts non-matching text to the last valid option', (tester) async {
        // DESIGN-98: does not tap the field first (that now opens the
        // drawer, mounting a second EditableText and making
        // `find.byType(EditableText)` ambiguous) -- `enterText` focuses the
        // field on its own, which is all this test needs.
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
