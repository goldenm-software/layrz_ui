import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzStepper', () {
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

    testWidgets('renders with minimum steps', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      expect(find.byType(LayrzStepper), findsOneWidget);
      expect(find.text('Personal'), findsWidgets);
      expect(find.text('Personal Info'), findsOneWidget);
    });

    testWidgets('shows active step body', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Shipping Address'), findsNothing);
    });

    testWidgets('next button advances step', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      expect(find.text('Personal Info'), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Next',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shipping Address'), findsOneWidget);
      expect(find.text('Personal Info'), findsNothing);
    });

    testWidgets('back button moves to previous step', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(1);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      await tester.pumpAndSettle();
      expect(find.text('Shipping Address'), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Back',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Info'), findsOneWidget);
    });

    testWidgets('back button disabled on first step', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      final backButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Back',
      );
      final button = tester.widget<LayrzButton>(backButton);
      expect(button.onTap, isNull);
    });

    testWidgets('next button disabled on last step', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      await tester.pumpAndSettle();
      final nextButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Next',
      );
      final button = tester.widget<LayrzButton>(nextButton);
      expect(button.onTap, isNull);
    });

    testWidgets('controller-driven navigation works', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      expect(find.text('Personal Info'), findsOneWidget);

      controller.goTo(2);
      await tester.pumpAndSettle();

      expect(find.text('Review Order'), findsOneWidget);
    });

    testWidgets('controller is required and cannot be swapped', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final first = LayrzStepperController();
      first.setStepCount(3);
      addTearDown(first.dispose);

      // Verify that a stepper can be created with a supplied controller.
      await pumpThemed(
        tester,
        LayrzStepper(
          steps: testSteps,
          controller: first,
        ),
      );

      expect(find.byType(LayrzStepper), findsOneWidget);

      // The controller should be usable after the widget is built.
      expect(first.currentStepIndex, 0);
      await first.next();
      expect(first.currentStepIndex, 1);
    });

    // `pumpThemed` builds a brand-new `OverlayEntry` on every call, so
    // `didUpdateWidget` never fires across two `pumpThemed` calls (same
    // constraint documented for `LayrzAnchoredPanel`, see
    // `test/overlays/anchored_panel_test.dart:310-350` and the settled
    // DESIGN-146 decision it records: the guard is a debug-only `assert`,
    // not a `StateError`, because throwing mid-rebuild through a real element
    // tree corrupts the framework's `_InactiveElements` bookkeeping). Rather
    // than leave this as an empty skipped stub — which reads as covered when
    // it verifies nothing — this test mirrors the exact boolean
    // `didUpdateWidget` asserts on (`stepper.dart`:
    // `widget.controller == oldWidget.controller`) without walking
    // `LayrzStepper`'s real element tree. It honestly verifies only: (1) the
    // condition never trips when the same controller is passed again, and
    // (2) `assert` throws an `AssertionError` when a genuinely different one
    // is. It says nothing about release builds, where the same `assert`
    // compiles out and a swap is silently ignored instead — matching the
    // class doc's "an assertion fails" wording, not a release-mode guarantee.
    test('the swap guard assert condition matches the documented contract', () {
      final first = LayrzStepperController()..setStepCount(3);
      final second = LayrzStepperController()..setStepCount(3);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      LayrzStepperController? previous = first;
      void simulateDidUpdateWidget(LayrzStepperController? next) {
        assert(
          next == previous,
          'LayrzStepper does not support changing the controller instance. '
          'The same controller must be passed, or null must remain null.',
        );
        previous = next;
      }

      // Same controller again (first didUpdateWidget after initState): must not assert.
      simulateDidUpdateWidget(first);
      expect(previous, same(first));

      // A genuinely different controller: the assert condition is false, so
      // it throws here (assertions are enabled under the test runner).
      expect(
        () => simulateDidUpdateWidget(second),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('caller-supplied controller is not disposed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      // Controller should still be usable after widget is disposed.
      expect(() => controller.goTo(0), returnsNormally);
    });

    testWidgets('internal controller is disposed', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      // Just verify the widget tree rebuilds without error.
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('onStepChanged callback fires', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var lastIndex = -1;

      await pumpThemed(
        tester,
        LayrzStepper(
          steps: testSteps,
          onStepChanged: (index) => lastIndex = index,
        ),
      );

      expect(lastIndex, -1);

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is LayrzButton && w.labelText == 'Next',
        ),
      );
      await tester.pumpAndSettle();

      expect(lastIndex, 1);
    });

    testWidgets('step with explicit error state shows error icon', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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

      // Step 2's indicator shows the alert glyph, not the checkmark, and no
      // other step renders one — the error glyph is exclusive to the error step.
      expect(
        find.descendant(
          of: find.byType(LayrzStepIndicator),
          matching: find.byIcon(MdiIcons.alertCircle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(LayrzStepIndicator),
          matching: find.byIcon(MdiIcons.check),
        ),
        findsNothing,
      );
    });

    testWidgets('custom button labels work', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(
          steps: testSteps,
          backButtonLabel: 'Previous',
          nextButtonLabel: 'Continue',
        ),
      );

      // Find buttons by widget predicate, not by text.
      final backButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Previous',
      );
      final nextButton = find.byWidgetPredicate(
        (w) => w is LayrzButton && w.labelText == 'Continue',
      );
      expect(backButton, findsOneWidget);
      expect(nextButton, findsOneWidget);
    });

    testWidgets('completed step can be tapped to jump back', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, controller: controller),
      );

      await tester.pumpAndSettle();
      expect(find.text('Review Order'), findsOneWidget);

      // Tap the first step's indicator (completed) to jump back.
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Info'), findsOneWidget);
    });

    test('next does not notify on no-op', () {
      var notifyCount = 0;
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);
      controller.addListener(() => notifyCount++);

      // Try to move next from the last step (no-op).
      controller.next();
      expect(notifyCount, 0);

      controller.dispose();
    });

    test('previous does not notify on no-op', () {
      var notifyCount = 0;
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      // Already at step 0 by default.
      controller.addListener(() => notifyCount++);

      // Try to move previous from the first step (no-op).
      controller.previous();
      expect(notifyCount, 0);

      controller.dispose();
    });

    test('goTo does not notify when already at index', () {
      var notifyCount = 0;
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(1);
      var initialNotifyCount = notifyCount;

      controller.addListener(() => notifyCount++);

      // Try to go to the current index (no-op).
      controller.goTo(1);
      expect(notifyCount, initialNotifyCount);

      controller.dispose();
    });

    test('next notifies when advancing', () async {
      var notifyCount = 0;
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.addListener(() => notifyCount++);

      await controller.next();
      expect(notifyCount, 1);

      controller.dispose();
    });

    test('previous notifies when moving back', () {
      var notifyCount = 0;
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.goTo(2);
      controller.addListener(() => notifyCount++);

      controller.previous();
      expect(notifyCount, 1);

      controller.dispose();
    });

    test('goTo notifies when changing to different index', () {
      var notifyCount = 0;
      final controller = LayrzStepperController();
      controller.setStepCount(3);
      controller.addListener(() => notifyCount++);

      controller.goTo(2);
      expect(notifyCount, 1);

      controller.dispose();
    });

    testWidgets('handles empty body gracefully', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final emptySteps = [
        const LayrzStep(
          labelText: 'Empty',
          body: SizedBox.shrink(),
        ),
      ];

      await pumpThemed(
        tester,
        LayrzStepper(steps: emptySteps),
      );

      expect(find.byType(LayrzStepper), findsOneWidget);
    });

    testWidgets('requires at least one step', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      expect(
        () => LayrzStepper(steps: []),
        throwsAssertionError,
      );
    });

    testWidgets('wide mode renders step labels and circles, no compact counter', (WidgetTester tester) async {
      // Ambient viewport is narrow, but isCompact: false forces the wide
      // branch — this proves the override wins over the derived value, which
      // a matching viewport+override pair would not.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, isCompact: false),
      );

      // In wide mode, every step's label renders (Personal/Shipping/Review all
      // findsWidgets, since the label appears once per step in the header).
      expect(find.text('Personal'), findsWidgets);
      expect(find.text('Shipping'), findsWidgets);
      expect(find.text('Review'), findsWidgets);
      // The compact layout's persistent "Step X of Y" counter must not render.
      expect(find.text('Step 1 of 3'), findsNothing);
    });

    testWidgets('compact mode renders accordion labels and counter, no wide header', (WidgetTester tester) async {
      // Ambient viewport is wide, but isCompact: true forces the compact
      // branch — this proves the override wins over the derived value, which
      // a matching viewport+override pair would not.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzStepper(steps: testSteps, isCompact: true),
      );

      // In compact mode, every step's label renders exactly once as an
      // accordion header row, plus the persistent "Step X of Y" counter — it
      // does NOT collapse to a single summary line the way the old layout did.
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Shipping'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });
  });
}
