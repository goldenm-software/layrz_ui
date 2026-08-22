import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/duration_picker_panel.dart';
import 'package:layrz_ui/src/inputs/src/input_chrome.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed_app.dart';

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

    testWidgets('asserts at least one of labelText or hintText is non-null', (WidgetTester tester) async {
      expect(
        () => LayrzDurationInput(),
        throwsAssertionError,
      );
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
}
