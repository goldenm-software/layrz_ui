import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_picker_panel.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzDurationInput', () {
    guardedTestWidgets('renders with label and hint text', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          hintText: 'Select a duration',
        ),
      );

      expect(findButtonLabel('Duration'), findsOneWidget);
      expect(find.text('Select a duration'), findsWidgets);
    });

    guardedTestWidgets('displays empty text when value is null', (WidgetTester tester) async {
      late final TextEditingController controller;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              controller: controller,
            );
          },
        ),
      );

      expect(controller.text, isEmpty);
    });

    guardedTestWidgets('displays summary text for a complete duration', (WidgetTester tester) async {
      const duration = Duration(days: 2, hours: 3, minutes: 4, seconds: 5);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: duration,
        ),
      );

      // Asserted on rendered output, not `controller.text` -- see the geometry
      // regression above for why a controller-only assertion cannot catch a
      // visually blank field.
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('3'), findsWidgets);
      expect(find.textContaining('4'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);
    });

    // Regression for a device-reported CRITICAL bug: every closed LayrzDurationInput field
    // with a non-null value rendered visibly blank, even though `controller.text` held the
    // correct summary string the whole time. Asserting `controller.text` (as the test above
    // does) cannot catch this class of bug -- the controller was always right. Root cause was
    // `_buildInteractiveField`'s `contentChild` wrapping its `Text` in an extra
    // `Padding(tokens.spacing.pd2)` (20px vertical) that `LayrzInputChrome` never budgets for:
    // the chrome constrains its child to a fixed-height box sized by
    // `_InputComfortableSpec.contentHeight` (~24px, just the text line height), so the added
    // padding squeezed the actual paintable height for the text down to ~4px -- too small to
    // render any glyphs, even though the `Text` widget's `data` (and so `controller.text`,
    // and even `find.text`, which matches by widget data, not by paint) was always correct.
    // This asserts the rendered box is actually tall enough to show a real line of body text,
    // which the 4px-clipped bug fails and a correctly-painted summary passes.
    guardedTestWidgets('renders the summary text tall enough to actually be visible, not clipped to a sliver', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
        ),
      );

      final textFinder = find.text('2 hours, 30 minutes');
      expect(textFinder, findsOneWidget, reason: 'the Text widget must exist with the correct summary data');

      final renderedHeight = tester.getSize(textFinder).height;
      expect(
        renderedHeight,
        greaterThan(13.0),
        reason:
            'a real line of 14px body text (LayrzTextTheme.body, DESIGN-105) needs at least '
            '~14px of rendered height; the reported bug clipped this to ~4px, which is '
            'invisible even though the text data itself was correct',
      );
    });

    guardedTestWidgets('omits zero-valued units from summary', (WidgetTester tester) async {
      const duration = Duration(days: 2, minutes: 4);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: duration,
        ),
      );

      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('4'), findsWidgets);
    });

    guardedTestWidgets('respects visibleUnits in summary', (WidgetTester tester) async {
      const duration = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: duration,
          visibleUnits: {LayrzDurationUnit.day, LayrzDurationUnit.minute},
        ),
      );

      expect(find.textContaining('1'), findsWidgets);
      expect(find.textContaining('3'), findsWidgets);
    });

    guardedTestWidgets('opens bottom sheet on compact viewport', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 1),
        ),
      );

      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);
    });

    guardedTestWidgets('closes picker and fires onChanged when bottom sheet returns value', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 1),
          onChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      // Verify the bottom sheet is visible with number inputs
      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);
      expect(find.byType(LayrzNumberInput), findsWidgets);
    });

    // Regression for DESIGN-170 (parent DESIGN-44): on a compact viewport, interacting
    // with the picker inside the mobile bottom sheet dismissed the sheet instead of
    // registering the edit. Root cause was `_openMobileSurface` wiring
    // `LayrzDurationPickerPanel.onChanged` -- which fires on every field edit, not just a
    // deliberate reset -- straight to `Navigator.pop(context, duration)`, so the very
    // first +/- tap or keystroke inside the sheet popped it. This is the bottom-sheet
    // counterpart of the bug `28c9680` already fixed for the desktop anchored panel (see
    // the "tapping a field's increment control updates the value and keeps the panel
    // open" test above and `duration_input.dart`'s `onChanged`/`onReset` split) -- that
    // split was never carried over to the mobile branch, so the same failure mode
    // regressed here. Asserts BOTH that the sheet is still present after the interaction
    // AND that the value actually changed -- either alone would miss half of the bug: a
    // sheet that silently ignored every tap (never popping, but never registering the
    // edit either) would also leave the sheet present.
    guardedTestWidgets(
      'tapping a field\'s increment control inside the mobile bottom sheet updates the '
      'value and keeps the sheet open',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        Duration? changedValue;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              return LayrzDurationInput(
                labelText: 'Duration',
                value: changedValue,
                onChanged: (value) => setState(() => changedValue = value),
              );
            },
          ),
        );

        await tester.tap(find.byType(LayrzInputChrome));
        await tester.pumpAndSettle();

        expect(find.byType(LayrzDurationPickerPanel), findsWidgets);

        final dayIncrement = find.descendant(
          of: find.byKey(const ValueKey('layrz_duration_field_day')),
          matching: find.bySemanticsLabel('Increase value'),
        );
        expect(dayIncrement, findsOneWidget);

        await tester.tap(dayIncrement);
        await tester.pumpAndSettle();

        expect(
          changedValue,
          const Duration(days: 1),
          reason: 'the field edit must actually be registered, not silently swallowed',
        );
        expect(
          find.byType(LayrzDurationPickerPanel),
          findsWidgets,
          reason: 'a field edit inside the mobile bottom sheet must not close it -- only Reset does',
        );

        // The sheet must still be interactive after the edit -- a second increment
        // proves the sheet did not just fail to pop while silently losing focus/input.
        await tester.tap(dayIncrement);
        await tester.pumpAndSettle();

        expect(changedValue, const Duration(days: 2));
        expect(find.byType(LayrzDurationPickerPanel), findsWidgets);
      },
    );

    // Companion to the increment-control regression above: Reset is the one action in
    // the mobile picker meant to close the sheet (mirroring the desktop panel's
    // `onReset` contract) -- this proves that contract still holds after the fix, i.e.
    // the fix did not accidentally make the sheet un-closeable altogether.
    guardedTestWidgets('pressing reset inside the mobile bottom sheet closes it and reports zero', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue ?? const Duration(hours: 5),
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);

      await tester.tap(findButtonLabel('Reset'));
      await tester.pumpAndSettle();

      expect(changedValue, Duration.zero);
      expect(
        find.byType(LayrzDurationPickerPanel),
        findsNothing,
        reason: 'Reset is the one action meant to close the mobile sheet',
      );
    });

    guardedTestWidgets('applies disabled state correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          disabled: true,
        ),
      );

      final inputFinder = find.byType(LayrzInputChrome);
      expect(inputFinder, findsOneWidget);

      await tester.tap(inputFinder);
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
    });

    guardedTestWidgets('displays errors when provided', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          errors: ['Invalid duration'],
        ),
      );

      expect(find.text('Invalid duration'), findsOneWidget);
    });

    guardedTestWidgets('hides error block when hideDetails is true', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          errors: ['Invalid duration'],
          hideDetails: true,
        ),
      );

      expect(find.text('Invalid duration'), findsNothing);
    });

    guardedTestWidgets('disposes self-created controller on dispose', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('does not dispose caller-provided controller', (WidgetTester tester) async {
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          controller: controller,
        ),
      );

      await tester.pumpWidget(const SizedBox());
      expect(() => controller.dispose(), returnsNormally);
    });

    guardedTestWidgets('does not dispose caller-provided focus node', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          focusNode: focusNode,
        ),
      );

      await tester.pumpWidget(const SizedBox());
      expect(() => focusNode.dispose(), returnsNormally);
    });

    guardedTestWidgets('can be created without labelText or hintText', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(),
      );

      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    guardedTestWidgets('asserts visibleUnits is non-empty', (WidgetTester tester) async {
      expect(
        () => LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: const {},
        ),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('updates summary when value changes', (WidgetTester tester) async {
      Duration? currentValue = const Duration(hours: 1);

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                LayrzButton(
                  labelText: 'Change',
                  onTap: () => setState(() => currentValue = const Duration(hours: 2)),
                ),
                LayrzDurationInput(
                  labelText: 'Duration',
                  value: currentValue,
                ),
              ],
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
    });

    guardedTestWidgets('clears the summary back to empty text when value transitions from set to null', (
      WidgetTester tester,
    ) async {
      Duration? currentValue = const Duration(hours: 1);
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                LayrzButton(
                  labelText: 'Clear',
                  onTap: () => setState(() => currentValue = null),
                ),
                LayrzDurationInput(
                  labelText: 'Duration',
                  value: currentValue,
                  controller: controller,
                ),
              ],
            );
          },
        ),
      );

      expect(controller.text, isNotEmpty);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    guardedTestWidgets('handles null onChanged callback', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('respects required flag', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          isRequired: true,
        ),
      );

      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    guardedTestWidgets('provides help affordance when helpContentText is non-null', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          helpTitleText: 'Help',
          helpContentText: 'Enter a duration',
        ),
      );

      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    guardedTestWidgets('round-trip: duration in, same duration out (day,hour,minute,second)', (
      WidgetTester tester,
    ) async {
      const testDuration = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: testDuration,
        ),
      );

      expect(find.text('1 day, 2 hours, 3 minutes, 4 seconds'), findsOneWidget);
    });

    guardedTestWidgets('clamping: hour 0-23 displays correctly', (WidgetTester tester) async {
      final duration = Duration(hours: 47);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: duration,
          visibleUnits: {LayrzDurationUnit.hour},
        ),
      );

      expect(find.textContaining('23'), findsWidgets);
    });

    guardedTestWidgets('clamping: minute 0-59 displays correctly', (WidgetTester tester) async {
      final duration = Duration(minutes: 125);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: duration,
          visibleUnits: {LayrzDurationUnit.minute},
        ),
      );

      expect(find.textContaining('5'), findsWidgets);
    });

    guardedTestWidgets('clamping: second 0-59 displays correctly', (WidgetTester tester) async {
      final duration = Duration(seconds: 125);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: duration,
          visibleUnits: {LayrzDurationUnit.second},
        ),
      );

      expect(find.textContaining('5'), findsWidgets);
    });

    guardedTestWidgets('picker panel has all four number input fields visible by default', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzNumberInput), findsNWidgets(4));
    });

    guardedTestWidgets('picker panel respects visibleUnits restriction', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzNumberInput), findsNWidgets(2));
    });

    guardedTestWidgets('does not render read-only lock icon', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      expect(find.byIcon(MdiIcons.lockOutline), findsNothing);
    });
  });

  group('LayrzDurationInput format', () {
    guardedTestWidgets('defaults to LayrzDurationFormat.long, matching pre-format behavior exactly', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
        ),
      );

      // Asserts what is actually ON SCREEN, not `controller.text` -- a
      // `Text` widget with the right `data` can still render invisibly (see
      // the geometry regression above), so only `find.text` proves the
      // summary is something a user can actually read.
      expect(find.text('2 hours, 30 minutes'), findsOneWidget);
    });

    guardedTestWidgets('LayrzDurationFormat.long renders exactly "2 hours, 30 minutes"', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
          format: LayrzDurationFormat.long,
        ),
      );

      expect(find.text('2 hours, 30 minutes'), findsOneWidget);
    });

    guardedTestWidgets('LayrzDurationFormat.short renders exactly "2h 30m" — abbreviated, space-joined', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
          format: LayrzDurationFormat.short,
        ),
      );

      expect(find.text('2h 30m'), findsOneWidget);
    });

    guardedTestWidgets('short format reads day abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(days: 1),
          visibleUnits: const {LayrzDurationUnit.day},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('1d'), findsOneWidget);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(days: 3),
          visibleUnits: const {LayrzDurationUnit.day},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('3d'), findsOneWidget);
    });

    guardedTestWidgets('short format reads hour abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 1),
          visibleUnits: const {LayrzDurationUnit.hour},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('1h'), findsOneWidget);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 5),
          visibleUnits: const {LayrzDurationUnit.hour},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('5h'), findsOneWidget);
    });

    guardedTestWidgets('short format reads minute abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(minutes: 1),
          visibleUnits: const {LayrzDurationUnit.minute},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('1m'), findsOneWidget);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(minutes: 45),
          visibleUnits: const {LayrzDurationUnit.minute},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('45m'), findsOneWidget);
    });

    guardedTestWidgets('short format reads second abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(seconds: 1),
          visibleUnits: const {LayrzDurationUnit.second},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('1s'), findsOneWidget);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(seconds: 45),
          visibleUnits: const {LayrzDurationUnit.second},
          format: LayrzDurationFormat.short,
        ),
      );
      expect(find.text('45s'), findsOneWidget);
    });

    guardedTestWidgets(
      'Duration.zero renders the smallest visible unit instead of empty text, '
      'with visibleUnits declared out of enum order',
      (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
            // Declared out of enum order (day, hour, minute, second) on
            // purpose: a set-iteration implementation of "smallest visible
            // unit" would see `second` first here and might get lucky, but
            // would fail the {hour, day} case below. Computing by enum
            // index instead is order-independent by construction.
            visibleUnits: const {LayrzDurationUnit.second, LayrzDurationUnit.day},
            value: Duration.zero,
          ),
        );

        expect(find.text('0 seconds'), findsOneWidget);
      },
    );

    guardedTestWidgets('Duration.zero in short format renders "0s" when seconds are visible, out-of-order set', (
      WidgetTester tester,
    ) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: const {LayrzDurationUnit.second, LayrzDurationUnit.day},
          value: Duration.zero,
          format: LayrzDurationFormat.short,
        ),
      );

      expect(find.text('0s'), findsOneWidget);
    });

    guardedTestWidgets(
      'Duration.zero renders "0h" when only day and hour are visible (seconds hidden), out-of-order set',
      (WidgetTester tester) async {
        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
            // Out of enum order: hour before day.
            visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.day},
            value: Duration.zero,
            format: LayrzDurationFormat.short,
          ),
        );

        expect(find.text('0h'), findsOneWidget);
      },
    );

    guardedTestWidgets('null value still renders empty text, distinct from an explicit Duration.zero', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          controller: controller,
        ),
      );

      expect(controller.text, isEmpty);
    });

    guardedTestWidgets(
      'a null value shows the hint text on screen, while Duration.zero shows the smallest-unit '
      'zero reading instead of the hint',
      (WidgetTester tester) async {
        // `_buildInteractiveField`'s `displayText` falls back to `hintText` only
        // when the controller's own text is empty -- `value: null` is the one
        // case that leaves it empty (see `_updateSummary`). `Duration.zero`
        // deliberately renders a non-empty "0s" (with `visibleUnits: {second}`
        // here, so the smallest -- and only -- visible unit is unambiguous), so
        // the hint must NOT be what is shown once a duration, even a zero one,
        // has actually been chosen.
        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
            hintText: 'Select a duration',
            visibleUnits: const {LayrzDurationUnit.second},
            format: LayrzDurationFormat.short,
          ),
        );

        expect(find.text('Select a duration'), findsWidgets);
        expect(find.text('0s'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
            hintText: 'Select a duration',
            visibleUnits: const {LayrzDurationUnit.second},
            format: LayrzDurationFormat.short,
            value: Duration.zero,
          ),
        );

        expect(find.text('0s'), findsWidgets);
        expect(find.text('Select a duration'), findsNothing);
      },
    );

    guardedTestWidgets('resetting the picker fires onChanged with an all-zero duration and updates the summary', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;
      final controller = TextEditingController();

      // A controlled component: onChanged feeds the new value back into
      // `value`, exactly as a real caller would. Asserting against
      // `widget.value` without this would only prove `_updateSummary` ran
      // against the *old* value, not that the round trip actually works.
      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue ?? const Duration(hours: 1),
              format: LayrzDurationFormat.short,
              controller: controller,
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Reset'));
      await tester.pumpAndSettle();

      expect(changedValue, const Duration());
      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
      expect(controller.text, '0s');
      expect(find.text('0s'), findsOneWidget, reason: 'the reset summary must actually be visible, not just correct');
    });
  });

  group('LayrzDurationInput desktop anchored panel', () {
    guardedTestWidgets('renders the anchored panel (not the bottom sheet) at a wide viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          hintText: 'Select a duration',
        ),
      );

      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
      expect(find.text('Select a duration'), findsWidgets);

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);
    });

    guardedTestWidgets('disabled anchor does not open the panel on tap at a wide viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          disabled: true,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
    });

    guardedTestWidgets('resetting the panel fires onChanged, updates the summary, and closes the panel', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;
      final controller = TextEditingController();

      // A controlled component: onChanged feeds the new value back into
      // `value`, exactly as a real caller would. Asserting against
      // `widget.value` without this would only prove `_updateSummary` ran
      // against the *old* value, not that the round trip actually works.
      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue ?? const Duration(hours: 2, minutes: 30),
              format: LayrzDurationFormat.long,
              controller: controller,
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);

      await tester.tap(findButtonLabel('Reset'));
      await tester.pumpAndSettle();

      expect(changedValue, const Duration());
      expect(controller.text, '0 seconds');
      expect(
        find.text('0 seconds'),
        findsOneWidget,
        reason: 'the reset summary must actually be visible, not just correct',
      );
      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
    });

    // Regression for a device-reported bug: tapping a field's +/- stepper (or
    // editing its text) used to close the panel, because `onChanged` -- fired
    // for every field edit, not just Reset -- was wired straight to
    // `_panelController.close()`. See `duration_input.dart`'s `onChanged` vs
    // `onReset` wiring on `LayrzDurationPickerPanel` for the fix: only a
    // genuine reset closes the panel now.
    guardedTestWidgets('tapping a field\'s increment control updates the value and keeps the panel open', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue,
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);

      final dayIncrement = find.descendant(
        of: find.byKey(const ValueKey('layrz_duration_field_day')),
        matching: find.bySemanticsLabel('Increase value'),
      );
      expect(dayIncrement, findsOneWidget);

      await tester.tap(dayIncrement);
      await tester.pumpAndSettle();

      expect(changedValue, const Duration(days: 1));
      expect(
        find.byType(LayrzDurationPickerPanel),
        findsWidgets,
        reason: 'a field edit must not close the panel -- only Reset does',
      );
    });

    guardedTestWidgets('tapping a field\'s decrement control updates the value and keeps the panel open', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue ?? const Duration(hours: 5),
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);

      final hourDecrement = find.descendant(
        of: find.byKey(const ValueKey('layrz_duration_field_hour')),
        matching: find.bySemanticsLabel('Decrease value'),
      );
      expect(hourDecrement, findsOneWidget);

      await tester.tap(hourDecrement);
      await tester.pumpAndSettle();

      expect(changedValue, const Duration(hours: 4));
      expect(
        find.byType(LayrzDurationPickerPanel),
        findsWidgets,
        reason: 'a field edit must not close the panel -- only Reset does',
      );
    });

    guardedTestWidgets('typing directly into a field\'s text box updates the value and keeps the panel open', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue,
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);

      final minuteField = find.descendant(
        of: find.byKey(const ValueKey('layrz_duration_field_minute')),
        matching: find.byType(EditableText),
      );
      expect(minuteField, findsOneWidget);

      await tester.enterText(minuteField, '15');
      await tester.pumpAndSettle();

      expect(changedValue, const Duration(minutes: 15));
      expect(
        find.byType(LayrzDurationPickerPanel),
        findsWidgets,
        reason: 'typing into a field must not close the panel -- only Reset does',
      );
    });

    // DESIGN-98: `LayrzDurationInput` moved off `LayrzAnchoredPanel` onto
    // `LayrzEndDrawer` -- see the class doc on `_LayrzDurationInputState.build`.
    // The old `matchAnchor`/`coverAnchor` rect-tracking, primary/danger
    // `LayrzAnchoredPanelBorder`, and width-follows-the-field behavior these
    // tests used to assert are gone: the drawer is a fixed-width
    // (`LayrzEndDrawer.width`, 420px) right-edge panel independent of the
    // anchor field's own rect or width. This is a container change only --
    // the only functional move is Reset, relocated from the panel's own
    // inline footer into the drawer's `actions` slot; no Cancel/Save added.
    guardedTestWidgets('the drawer opens with a fixed 420px width, independent of the anchor field\'s own width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Center(
          child: SizedBox(
            width: 320.0,
            child: LayrzDurationInput(labelText: 'Duration'),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final drawerWidth = tester.getSize(find.byType(LayrzDurationPickerPanel)).width;
      expect(drawerWidth, closeTo(LayrzEndDrawer.width, 1.0));
    });

    guardedTestWidgets('the drawer carries a single Reset action, relocated from the panel\'s own inline footer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(labelText: 'Duration'),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Reset'), findsOneWidget, reason: 'Reset now lives in the drawer actions slot');
      expect(
        findButtonLabel('Cancel'),
        findsNothing,
        reason: 'this widget never buffered a draft -- no Cancel is added',
      );
      expect(
        findButtonLabel('Save'),
        findsNothing,
        reason: 'every field edit already reports live -- no Save is added',
      );
    });

    guardedTestWidgets('field edits inside the drawer still report live, exactly as before DESIGN-98', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Duration? changedValue;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzDurationInput(
              labelText: 'Duration',
              value: changedValue ?? const Duration(hours: 1),
              onChanged: (value) => setState(() => changedValue = value),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      final dayIncrement = find.descendant(
        of: find.byKey(const ValueKey('layrz_duration_field_day')),
        matching: find.bySemanticsLabel('Increase value'),
      );
      await tester.tap(dayIncrement);
      await tester.pumpAndSettle();

      expect(changedValue, const Duration(hours: 1, days: 1), reason: 'the live edit must still report immediately');
      expect(find.byType(LayrzDurationPickerPanel), findsWidgets, reason: 'a field edit must not close the drawer');
    });

    // Note: Reset's full zero-and-close-and-report behavior is already
    // covered above by "resetting the panel fires onChanged, updates the
    // summary, and closes the panel" -- that test needed no change here,
    // since `findButtonLabel('Reset')` finds the button in the drawer's
    // `actions` slot exactly as it found it inline before DESIGN-98.
  });

  group('LayrzDurationInput controller/focusNode lifecycle updates', () {
    guardedTestWidgets('adopts a newly-supplied controller and disposes the self-created one it replaces', (
      WidgetTester tester,
    ) async {
      final suppliedController = TextEditingController();
      addTearDown(suppliedController.dispose);
      TextEditingController? activeController;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                LayrzButton(
                  labelText: 'Swap controller',
                  onTap: () => setState(() => activeController = suppliedController),
                ),
                LayrzDurationInput(
                  labelText: 'Duration',
                  controller: activeController,
                ),
              ],
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    guardedTestWidgets('adopts a newly-supplied focus node and disposes the self-created one it replaces', (
      WidgetTester tester,
    ) async {
      final suppliedFocusNode = FocusNode();
      addTearDown(suppliedFocusNode.dispose);
      FocusNode? activeFocusNode;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                LayrzButton(
                  labelText: 'Swap focus node',
                  onTap: () => setState(() => activeFocusNode = suppliedFocusNode),
                ),
                LayrzDurationInput(
                  labelText: 'Duration',
                  focusNode: activeFocusNode,
                ),
              ],
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });
  });

  group('LayrzDurationInput affordance icon', () {
    guardedTestWidgets('renders the clock affordance icon on the desktop band', (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      final iconFinder = find.byIcon(MdiIcons.clockOutline);
      expect(iconFinder, findsOneWidget);

      final tokens = LayrzTokens.light();
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, tokens.colors.fg1);
      expect(icon.size, tokens.typography.body.fontSize);
    });

    guardedTestWidgets('renders the clock affordance icon on the compact band', (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      final iconFinder = find.byIcon(MdiIcons.clockOutline);
      expect(iconFinder, findsOneWidget);

      final tokens = LayrzTokens.light();
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, tokens.colors.fg1);
      expect(icon.size, tokens.typography.body.fontSize);
    });

    /// Per DESIGN-126, `dense` forwards to the field's inner chrome and shrinks its padding.
    /// The clock affordance icon lives *outside* the chrome (an external sibling in the row,
    /// per the class doc above), so this also serves as the affordance check: the icon must
    /// stay visible and correctly sized, and tapping the field row -- including the area right
    /// beside the icon -- must still open the picker rather than silently doing nothing.
    guardedTestWidgets('dense: true forwards to the inner chrome and keeps the clock affordance hittable', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          dense: true,
        ),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
      expect(chrome.dense, isTrue);

      final iconFinder = find.byIcon(MdiIcons.clockOutline);
      expect(iconFinder, findsOneWidget);

      final tokens = LayrzTokens.light();
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.size, tokens.typography.body.fontSize, reason: 'dense must not change icon size (padding-only)');

      // Tapping the field row (anywhere, including near the affordance icon) must still open
      // the picker -- the icon has no tap target of its own, it is decorative.
      await tester.tap(find.byType(LayrzInputChrome));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzDurationPickerPanel), findsWidgets);
    });

    guardedTestWidgets('dims the affordance icon to fg4 when disabled, matching the chrome text color', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          disabled: true,
        ),
      );

      final tokens = LayrzTokens.light();
      final icon = tester.widget<Icon>(find.byIcon(MdiIcons.clockOutline));
      expect(icon.color, tokens.colors.fg4);
    });

    guardedTestWidgets('recolors the affordance icon to the danger color when errors are present', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          errors: const ['Invalid duration'],
        ),
      );

      final tokens = LayrzTokens.light();
      final icon = tester.widget<Icon>(find.byIcon(MdiIcons.clockOutline));
      // DESIGN-106 follow-up: the icon derives its color from `spec.textColor`, which now
      // resolves to `colors.danger` in the error state (previously left at plain fg1).
      expect(icon.color, tokens.colors.danger);
      expect(icon.color, isNot(tokens.colors.fg1));
      expect(icon.color, isNot(tokens.colors.fg4));
    });

    guardedTestWidgets(
      'keeps both prefix and suffix slots empty and available on the inner chrome (desktop band)',
      (WidgetTester tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));

        expect(chrome.prefixSlot, isA<LayrzInputPrefixSlot>());
        expect(chrome.prefixSlot.hasContent, isFalse);
        expect(chrome.prefixSlot.icon, isNull);
        expect(chrome.prefixSlot.widget, isNull);
        expect(chrome.prefixSlot.text, isNull);

        expect(chrome.suffixSlot, isA<LayrzInputSuffixSlot>());
        expect(chrome.suffixSlot.hasContent, isFalse);
        expect(chrome.suffixSlot.icon, isNull);
        expect(chrome.suffixSlot.widget, isNull);
        expect(chrome.suffixSlot.text, isNull);
      },
    );

    guardedTestWidgets(
      'keeps both prefix and suffix slots empty and available on the inner chrome (compact band)',
      (WidgetTester tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));

        expect(chrome.prefixSlot.hasContent, isFalse);
        expect(chrome.suffixSlot.hasContent, isFalse);
      },
    );

    guardedTestWidgets('the affordance icon is excluded from the semantics tree (decorative)', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      final excludeSemanticsAboveIcon = find.ancestor(
        of: find.byIcon(MdiIcons.clockOutline),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludeSemanticsAboveIcon, findsOneWidget);
    });

    guardedTestWidgets(
      'the inner chrome renders with no border of its own, and rounds only its left (outer-edge) corners',
      (WidgetTester tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        late LayrzTokens tokens;

        await pumpThemedApp(
          tester,
          Builder(
            builder: (context) {
              tokens = context.tokens;
              return LayrzDurationInput(labelText: 'Duration');
            },
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));

        expect(chrome.showBorder, isFalse);

        // The chrome sits flush against the field row's physical LEFT edge and
        // paints its own opaque fill there -- `BorderRadius.zero` on both sides
        // (the value this test pinned before the corner-crop fix) left that
        // fill square, so it painted over the outer container's own rounded
        // left corner instead of matching it. The RIGHT side stays square: it
        // is the internal seam facing `_buildAffordanceIcon`, not a physical
        // corner, and rounding it would open a visible gap against that
        // neighbor. Mirrors `NumberFieldControl`'s and `_SelectFieldCaret`'s
        // identical outer-corners-only treatment.
        final expectedInnerR = Radius.circular(
          tokens.radius.innerRadiusValue(
            outerRadius: tokens.radius.r2,
            spacer: tokens.border.base,
          ),
        );
        expect(
          chrome.borderRadius,
          BorderRadius.only(topLeft: expectedInnerR, bottomLeft: expectedInnerR),
        );
      },
    );
  });
}
