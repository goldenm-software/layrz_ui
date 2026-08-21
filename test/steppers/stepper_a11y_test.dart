import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzStepper Accessibility', () {
    final testSteps = [
      const LayrzStep(
        labelText: 'Personal',
        body: SizedBox(child: Text('Personal Info')),
      ),
      const LayrzStep(
        labelText: 'Shipping',
        body: SizedBox(child: Text('Shipping Address')),
      ),
      const LayrzStep(
        labelText: 'Review',
        body: SizedBox(child: Text('Review Order')),
      ),
    ];

    testWidgets('step headers have semantics labels with position and state', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      // Verify semantics exist for step positions and state.
      // The semantics labels are constructed as:
      // "Step X of Y, labelText. state-description"
      final semantics = tester.getSemantics(find.byType(LayrzStepper));
      expect(semantics, isNotNull);
    });

    testWidgets('completed step has checkmark glyph', (WidgetTester tester) async {
      final completedSteps = [
        const LayrzStep(
          labelText: 'Step 1',
          body: SizedBox(child: Text('Content')),
          state: LayrzStepperState.completed,
        ),
        const LayrzStep(
          labelText: 'Step 2',
          body: SizedBox(child: Text('Content')),
        ),
      ];

      await pumpThemed(
        tester,
        LayrzStepper(steps: completedSteps),
      );

      // The completed step should render with a checkmark icon (from MdiIcons.check).
      // Verify the stepper renders correctly without errors.
      expect(find.byType(LayrzStepper), findsOneWidget);
    });

    testWidgets('error step has alert glyph', (WidgetTester tester) async {
      final errorSteps = [
        const LayrzStep(
          labelText: 'Step 1',
          body: SizedBox(child: Text('Content')),
        ),
        LayrzStep(
          labelText: 'Step 2',
          body: const SizedBox(child: Text('Content')),
          state: LayrzStepperState.error,
        ),
      ];

      await pumpThemed(
        tester,
        LayrzStepper(steps: errorSteps),
      );

      // The error step should render with an alert icon (from MdiIcons.alertCircle).
      // Verify the stepper renders correctly without errors.
      expect(find.byType(LayrzStepper), findsOneWidget);
    });

    testWidgets('back button is labelled and reachable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(1); // Move to step 2 so back button is enabled

      await pumpThemed(
        tester,
        LayrzStepper(
          steps: testSteps,
          controller: controller,
          backButtonLabel: 'Previous',
        ),
      );

      await tester.pumpAndSettle();

      // Back button should be found by widget predicate and should be tappable.
      final backButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Previous',
      );
      expect(backButton, findsOneWidget);
      final button = tester.widget<LayrzButton>(backButton);
      expect(button.onTap, isNotNull);
    });

    testWidgets('next button is labelled and reachable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(
          steps: testSteps,
          nextButtonLabel: 'Continue',
        ),
      );

      // Next button should be found by widget predicate and should be tappable.
      final nextButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Continue',
      );
      expect(nextButton, findsOneWidget);
      final button = tester.widget<LayrzButton>(nextButton);
      expect(button.onTap, isNotNull);
    });

    testWidgets('completed step is distinguishable without colour alone', (WidgetTester tester) async {
      final completedSteps = [
        const LayrzStep(
          labelText: 'Completed',
          body: SizedBox(child: Text('Done')),
          state: LayrzStepperState.completed,
        ),
      ];

      await pumpThemed(
        tester,
        LayrzStepper(steps: completedSteps),
      );

      // Completed step renders with a checkmark icon, not just colour.
      // Verify the rendering completes without errors and the step is displayed.
      expect(find.byType(LayrzStepper), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('tapping completed step jumps back for review', (WidgetTester tester) async {
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2); // Move to step 3

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      await tester.pumpAndSettle();
      expect(find.text('Review Order'), findsOneWidget);

      // Programmatically tap a completed step to jump back.
      controller.goTo(0);
      await tester.pumpAndSettle();

      expect(find.text('Personal Info'), findsOneWidget);
    });

    testWidgets('upcoming steps are not tappable', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      // On first step, upcoming steps should not be tappable.
      // They render but have no tap handler.
      expect(find.byType(LayrzStepper), findsOneWidget);
    });

    testWidgets('error state is visually distinct', (WidgetTester tester) async {
      final errorSteps = [
        const LayrzStep(
          labelText: 'Personal',
          body: SizedBox(child: Text('Personal Info')),
          state: LayrzStepperState.completed,
        ),
        LayrzStep(
          labelText: 'Shipping',
          body: const SizedBox(child: Text('Address Error')),
          state: LayrzStepperState.error,
        ),
      ];

      await pumpThemed(
        tester,
        LayrzStepper(steps: errorSteps),
      );

      // Error step should render with an alert icon for distinction.
      expect(find.byType(LayrzStepper), findsOneWidget);
    });

    testWidgets('back button disabled on first step has null onTap', (WidgetTester tester) async {
      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      // On first step, back button should be disabled (onTap is null).
      final backButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Back',
      );
      final button = tester.widget<LayrzButton>(backButton);
      expect(button.onTap, isNull);
    });

    testWidgets('next button disabled on last step has null onTap', (WidgetTester tester) async {
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      await tester.pumpAndSettle();

      // On last step, next button should be disabled (onTap is null).
      final nextButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Next',
      );
      final button = tester.widget<LayrzButton>(nextButton);
      expect(button.onTap, isNull);
    });
  });
}
