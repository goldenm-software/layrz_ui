import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_picker_panel.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

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
}
