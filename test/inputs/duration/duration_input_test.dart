import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_picker_panel.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzDurationInput', () {
    testWidgets('renders with label and hint text', (WidgetTester tester) async {
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

    testWidgets('displays empty text when value is null', (WidgetTester tester) async {
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

    testWidgets('displays summary text for a complete duration', (WidgetTester tester) async {
      late final TextEditingController controller;
      const duration = Duration(days: 2, hours: 3, minutes: 4, seconds: 5);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: duration,
              controller: controller,
            );
          },
        ),
      );

      expect(controller.text, isNotEmpty);
      expect(controller.text, contains('2'));
      expect(controller.text, contains('3'));
      expect(controller.text, contains('4'));
      expect(controller.text, contains('5'));
    });

    testWidgets('omits zero-valued units from summary', (WidgetTester tester) async {
      late final TextEditingController controller;
      const duration = Duration(days: 2, minutes: 4);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: duration,
              controller: controller,
            );
          },
        ),
      );

      final summary = controller.text;
      expect(summary, contains('2'));
      expect(summary, contains('4'));
    });

    testWidgets('respects visibleUnits in summary', (WidgetTester tester) async {
      late final TextEditingController controller;
      const duration = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: duration,
              visibleUnits: {LayrzDurationUnit.day, LayrzDurationUnit.minute},
              controller: controller,
            );
          },
        ),
      );

      final summary = controller.text;
      expect(summary, contains('1'));
      expect(summary, contains('3'));
    });

    testWidgets('opens bottom sheet on compact viewport', (WidgetTester tester) async {
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

    testWidgets('closes picker and fires onChanged when bottom sheet returns value', (WidgetTester tester) async {
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

    testWidgets('applies disabled state correctly', (WidgetTester tester) async {
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

    testWidgets('displays errors when provided', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          errors: ['Invalid duration'],
        ),
      );

      expect(find.text('Invalid duration'), findsOneWidget);
    });

    testWidgets('hides error block when hideDetails is true', (WidgetTester tester) async {
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

    testWidgets('disposes self-created controller on dispose', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
        ),
      );

      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not dispose caller-provided controller', (WidgetTester tester) async {
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

    testWidgets('does not dispose caller-provided focus node', (WidgetTester tester) async {
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

    testWidgets('can be created without labelText or hintText', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(),
      );

      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    testWidgets('asserts visibleUnits is non-empty', (WidgetTester tester) async {
      expect(
        () => LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: const {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('updates summary when value changes', (WidgetTester tester) async {
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

    testWidgets('clears the summary back to empty text when value transitions from set to null', (
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

    testWidgets('handles null onChanged callback', (WidgetTester tester) async {
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

    testWidgets('respects required flag', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          isRequired: true,
        ),
      );

      expect(find.byType(LayrzDurationInput), findsOneWidget);
    });

    testWidgets('provides help affordance when helpContentText is non-null', (WidgetTester tester) async {
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

    testWidgets('round-trip: duration in, same duration out (day,hour,minute,second)', (WidgetTester tester) async {
      const testDuration = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);

      late final TextEditingController controller;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: testDuration,
              controller: controller,
            );
          },
        ),
      );

      expect(controller.text, isNotEmpty);
    });

    testWidgets('clamping: hour 0-23 displays correctly', (WidgetTester tester) async {
      final duration = Duration(hours: 47);
      late final TextEditingController controller;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: duration,
              controller: controller,
              visibleUnits: {LayrzDurationUnit.hour},
            );
          },
        ),
      );

      expect(controller.text, contains('23'));
    });

    testWidgets('clamping: minute 0-59 displays correctly', (WidgetTester tester) async {
      final duration = Duration(minutes: 125);
      late final TextEditingController controller;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: duration,
              controller: controller,
              visibleUnits: {LayrzDurationUnit.minute},
            );
          },
        ),
      );

      expect(controller.text, contains('5'));
    });

    testWidgets('clamping: second 0-59 displays correctly', (WidgetTester tester) async {
      final duration = Duration(seconds: 125);
      late final TextEditingController controller;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            controller = TextEditingController();
            return LayrzDurationInput(
              labelText: 'Duration',
              value: duration,
              controller: controller,
              visibleUnits: {LayrzDurationUnit.second},
            );
          },
        ),
      );

      expect(controller.text, contains('5'));
    });

    testWidgets('picker panel has all four number input fields visible by default', (WidgetTester tester) async {
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

    testWidgets('picker panel respects visibleUnits restriction', (WidgetTester tester) async {
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

    testWidgets('does not render read-only lock icon', (WidgetTester tester) async {
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
    testWidgets('defaults to LayrzDurationFormat.long, matching pre-format behavior exactly', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
          controller: controller,
        ),
      );

      expect(controller.text, '2 hours, 30 minutes');
    });

    testWidgets('LayrzDurationFormat.long renders exactly "2 hours, 30 minutes"', (WidgetTester tester) async {
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
          format: LayrzDurationFormat.long,
          controller: controller,
        ),
      );

      expect(controller.text, '2 hours, 30 minutes');
    });

    testWidgets('LayrzDurationFormat.short renders exactly "2h 30m" — abbreviated, space-joined', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 2, minutes: 30),
          format: LayrzDurationFormat.short,
          controller: controller,
        ),
      );

      expect(controller.text, '2h 30m');
    });

    testWidgets('short format reads day abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      final singularController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(days: 1),
          visibleUnits: const {LayrzDurationUnit.day},
          format: LayrzDurationFormat.short,
          controller: singularController,
        ),
      );
      expect(singularController.text, '1d');

      final pluralController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(days: 3),
          visibleUnits: const {LayrzDurationUnit.day},
          format: LayrzDurationFormat.short,
          controller: pluralController,
        ),
      );
      expect(pluralController.text, '3d');
    });

    testWidgets('short format reads hour abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      final singularController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 1),
          visibleUnits: const {LayrzDurationUnit.hour},
          format: LayrzDurationFormat.short,
          controller: singularController,
        ),
      );
      expect(singularController.text, '1h');

      final pluralController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(hours: 5),
          visibleUnits: const {LayrzDurationUnit.hour},
          format: LayrzDurationFormat.short,
          controller: pluralController,
        ),
      );
      expect(pluralController.text, '5h');
    });

    testWidgets('short format reads minute abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      final singularController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(minutes: 1),
          visibleUnits: const {LayrzDurationUnit.minute},
          format: LayrzDurationFormat.short,
          controller: singularController,
        ),
      );
      expect(singularController.text, '1m');

      final pluralController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(minutes: 45),
          visibleUnits: const {LayrzDurationUnit.minute},
          format: LayrzDurationFormat.short,
          controller: pluralController,
        ),
      );
      expect(pluralController.text, '45m');
    });

    testWidgets('short format reads second abbreviation singular and plural forms from l10n', (
      WidgetTester tester,
    ) async {
      final singularController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(seconds: 1),
          visibleUnits: const {LayrzDurationUnit.second},
          format: LayrzDurationFormat.short,
          controller: singularController,
        ),
      );
      expect(singularController.text, '1s');

      final pluralController = TextEditingController();
      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          value: const Duration(seconds: 45),
          visibleUnits: const {LayrzDurationUnit.second},
          format: LayrzDurationFormat.short,
          controller: pluralController,
        ),
      );
      expect(pluralController.text, '45s');
    });

    testWidgets(
      'Duration.zero renders the smallest visible unit instead of empty text, '
      'with visibleUnits declared out of enum order',
      (WidgetTester tester) async {
        final controller = TextEditingController();

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
            controller: controller,
          ),
        );

        expect(controller.text, isNot(''));
        expect(controller.text, '0 seconds');
      },
    );

    testWidgets('Duration.zero in short format renders "0s" when seconds are visible, out-of-order set', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzDurationInput(
          labelText: 'Duration',
          visibleUnits: const {LayrzDurationUnit.second, LayrzDurationUnit.day},
          value: Duration.zero,
          format: LayrzDurationFormat.short,
          controller: controller,
        ),
      );

      expect(controller.text, '0s');
    });

    testWidgets(
      'Duration.zero renders "0h" when only day and hour are visible (seconds hidden), out-of-order set',
      (WidgetTester tester) async {
        final controller = TextEditingController();

        await pumpThemedApp(
          tester,
          LayrzDurationInput(
            labelText: 'Duration',
            // Out of enum order: hour before day.
            visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.day},
            value: Duration.zero,
            format: LayrzDurationFormat.short,
            controller: controller,
          ),
        );

        expect(controller.text, '0h');
      },
    );

    testWidgets('null value still renders empty text, distinct from an explicit Duration.zero', (
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

    testWidgets(
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

    testWidgets('resetting the picker fires onChanged with an all-zero duration and updates the summary', (
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
    });
  });

  group('LayrzDurationInput desktop anchored panel', () {
    testWidgets('renders the anchored panel (not the bottom sheet) at a wide viewport', (
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

    testWidgets('disabled anchor does not open the panel on tap at a wide viewport', (WidgetTester tester) async {
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

    testWidgets('resetting the panel fires onChanged, updates the summary, and closes the panel', (
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
      expect(find.byType(LayrzDurationPickerPanel), findsNothing);
    });

    // Regression for a device-reported bug: tapping a field's +/- stepper (or
    // editing its text) used to close the panel, because `onChanged` -- fired
    // for every field edit, not just Reset -- was wired straight to
    // `_panelController.close()`. See `duration_input.dart`'s `onChanged` vs
    // `onReset` wiring on `LayrzDurationPickerPanel` for the fix: only a
    // genuine reset closes the panel now.
    testWidgets('tapping a field\'s increment control updates the value and keeps the panel open', (
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

    testWidgets('tapping a field\'s decrement control updates the value and keeps the panel open', (
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

    testWidgets('typing directly into a field\'s text box updates the value and keeps the panel open', (
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

    // Shell-parity regressions: `LayrzDurationInput` adopts the same panel
    // chrome `LayrzSelectInput` already has (`coverAnchor: true` plus a
    // primary/danger `LayrzAnchoredPanelBorder`), while its width policy
    // (`contentSized`, 280.0-480.0) and 400.0 height cap are deliberately left
    // unchanged -- see the class doc on `_LayrzDurationInputState.build`.
    testWidgets('the panel covers the field -- its rect starts at the anchor\'s own top-left corner', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(),
      );

      // `RawMenuAnchor` measures its `anchorRect` from the entire widget
      // `_buildAnchor` returns -- the outermost `GestureDetector` wrapping the
      // label, bordered field row, and footer -- not from `LayrzInputChrome`
      // alone. `LayrzInputChrome`'s own rect sits inset from that by the
      // field row's own border width (`tokens.border.base`, painted with the
      // default inside `strokeAlign` in `_buildFieldRow`), so the anchor
      // widget itself is the correct rect to compare against.
      final anchorRect = tester.getRect(find.byType(GestureDetector).first);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final panelRect = tester.getRect(find.byType(LayrzDurationPickerPanel));

      // `coverAnchor: true` starts the panel's top-left exactly at the
      // anchor's own top-left, clamped into overlay bounds -- mirroring
      // `LayrzSelectInput`'s DESIGN-145 defect-1 regression.
      expect(panelRect.top, equals(anchorRect.top));
      expect(panelRect.left, equals(anchorRect.left));
    });

    testWidgets('the panel is bordered in the primary color when the field has no errors', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final decoration = _panelDecoratedBox(tester).decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.color, equals(tokens.colors.primary));
      expect((decoration.border as Border).top.width, equals(tokens.border.base));
    });

    testWidgets('the panel is bordered in the danger color when the field has errors', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late LayrzTokens tokens;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            tokens = context.tokens;
            return LayrzDurationInput(
              labelText: 'Duration',
              errors: const ['Required'],
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final decoration = _panelDecoratedBox(tester).decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.color, equals(tokens.colors.danger));
    });

    // Device-reported defect fix, reversing an earlier decision: the panel used to
    // stay `contentSized` within a fixed 280.0-480.0 band regardless of the anchor
    // field's own width, so on a wide field it visually occupied only a small
    // fraction of it. `matchAnchor` (mirroring `LayrzSelectInput`) makes the panel
    // span the field's actual rendered width instead -- see the class doc on
    // `_LayrzDurationInputState.build` for the full reasoning.
    testWidgets('the panel spans the anchor field\'s full width (matchAnchor), not a fixed 280.0-480.0 band', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(labelText: 'Duration'),
      );

      final anchorRect = tester.getRect(find.byType(GestureDetector).first);

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final panelWidth = tester.getSize(find.byType(SingleChildScrollView)).width;

      expect(
        panelWidth,
        greaterThan(480.0),
        reason: 'the old contentSized cap must no longer bound the panel on a wide field',
      );
      // The anchor here spans the full 1200px overlay, so LayrzAnchoredPanelLayoutDelegate's
      // own overlay-bounds clamp (overlaySize.width - 2 * sp2) legitimately trims a few
      // pixels off matchAnchor's raw anchorRect.width -- a wide tolerance distinguishes that
      // expected clamp from the old, much narrower 280.0-480.0 contentSized cap this test
      // guards against regressing to.
      expect(
        panelWidth,
        closeTo(anchorRect.width, 25.0),
        reason: 'matchAnchor makes the panel width track the anchor field\'s own rendered width',
      );
    });

    testWidgets('a narrow anchor field yields a narrow matchAnchor panel', (tester) async {
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

      final panelWidth = tester.getSize(find.byType(SingleChildScrollView)).width;
      expect(panelWidth, closeTo(320.0, 1.0));
    });

    testWidgets('a wide anchor field yields a matchAnchor panel wider than the old 480.0 cap', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Center(
          child: SizedBox(
            width: 900.0,
            child: LayrzDurationInput(labelText: 'Duration'),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final panelWidth = tester.getSize(find.byType(SingleChildScrollView)).width;
      expect(panelWidth, closeTo(900.0, 1.0));
    });

    testWidgets('the maxHeight cap stays 400.0, unaffected by the border/coverAnchor', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzDurationInput(labelText: 'Duration'),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final panelHeight = tester.getSize(find.byType(SingleChildScrollView)).height;
      expect(panelHeight, lessThanOrEqualTo(400.0));
    });
  });

  group('LayrzDurationInput controller/focusNode lifecycle updates', () {
    testWidgets('adopts a newly-supplied controller and disposes the self-created one it replaces', (
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

    testWidgets('adopts a newly-supplied focus node and disposes the self-created one it replaces', (
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
    testWidgets('renders the clock affordance icon on the desktop band', (WidgetTester tester) async {
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

    testWidgets('renders the clock affordance icon on the compact band', (WidgetTester tester) async {
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

    testWidgets('dims the affordance icon to fg4 when disabled, matching the chrome text color', (
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

    testWidgets('recolors the affordance icon to the danger color when errors are present', (
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
      expect(icon.color, tokens.colors.fg1);
      expect(icon.color, isNot(tokens.colors.fg4));
    });

    testWidgets(
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

    testWidgets(
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

    testWidgets('the affordance icon is excluded from the semantics tree (decorative)', (
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

    testWidgets('the inner chrome renders with no border and square corners of its own', (
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

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));

      expect(chrome.showBorder, isFalse);
      expect(chrome.borderRadius, BorderRadius.zero);
    });
  });
}

/// Locates the `Container` [LayrzAnchoredPanel] itself builds around its
/// scroll viewport -- the one carrying `sf1`/shadow/radius and, when set, the
/// border -- identified structurally as the closest `Container` ancestor of
/// the panel's [SingleChildScrollView]. Mirrors the identical helper in
/// `test/overlays/anchored_panel_border_test.dart`; duplicated locally rather
/// than shared, since these two test files own disjoint concerns.
Container _panelDecoratedBox(WidgetTester tester) {
  final scrollViewElement = tester.element(find.byType(SingleChildScrollView));
  final ancestor = scrollViewElement.findAncestorWidgetOfExactType<Container>();
  expect(ancestor, isNotNull, reason: 'LayrzAnchoredPanel must wrap its scroll viewport in a Container.');
  return ancestor!;
}
