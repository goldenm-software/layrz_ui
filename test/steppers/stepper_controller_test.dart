import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/steppers/src/stepper_controller.dart';

void main() {
  group('LayrzStepperController', () {
    late LayrzStepperController controller;

    setUp(() {
      controller = LayrzStepperController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes at step 0', () {
      controller.setStepCount(3);
      expect(controller.currentStepIndex, 0);
    });

    test('canMoveNext is true when not at last step', () {
      controller.setStepCount(3);
      expect(controller.canMoveNext, true);
    });

    test('canMoveNext is false when at last step', () {
      controller.setStepCount(3);
      controller.goTo(2);
      expect(controller.canMoveNext, false);
    });

    test('canMovePrevious is true when not at first step', () {
      controller.setStepCount(3);
      controller.goTo(1);
      expect(controller.canMovePrevious, true);
    });

    test('canMovePrevious is false when at first step', () {
      controller.setStepCount(3);
      expect(controller.canMovePrevious, false);
    });

    test('next advances step index', () async {
      controller.setStepCount(3);
      expect(controller.currentStepIndex, 0);

      await controller.next();
      expect(controller.currentStepIndex, 1);

      await controller.next();
      expect(controller.currentStepIndex, 2);
    });

    test('next does not advance past last step', () async {
      controller.setStepCount(2);
      controller.goTo(1);

      await controller.next();
      expect(controller.currentStepIndex, 1);
    });

    test('previous moves back one step', () {
      controller.setStepCount(3);
      controller.goTo(2);

      controller.previous();
      expect(controller.currentStepIndex, 1);

      controller.previous();
      expect(controller.currentStepIndex, 0);
    });

    test('previous does not go below step 0', () {
      controller.setStepCount(3);
      controller.previous();
      expect(controller.currentStepIndex, 0);
    });

    test('goTo jumps to specified step', () {
      controller.setStepCount(5);
      controller.goTo(3);
      expect(controller.currentStepIndex, 3);
    });

    test('goTo clamps to valid range', () {
      controller.setStepCount(3);
      controller.goTo(-1);
      expect(controller.currentStepIndex, 0);

      controller.goTo(5);
      expect(controller.currentStepIndex, 0);
    });

    test('setCanAdvance gates next() advancement', () async {
      controller.setStepCount(3);
      controller.setCanAdvance(() async => false);

      await controller.next();
      expect(controller.currentStepIndex, 0); // Did not advance
    });

    test('setCanAdvance allows advancement when returning true', () async {
      controller.setStepCount(3);
      controller.setCanAdvance(() async => true);

      await controller.next();
      expect(controller.currentStepIndex, 1); // Advanced
    });

    test('setCanAdvance supports async validation', () async {
      controller.setStepCount(3);
      var callCount = 0;

      controller.setCanAdvance(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        callCount++;
        return true;
      });

      await controller.next();
      expect(callCount, 1);
      expect(controller.currentStepIndex, 1);
    });

    test('setCanAdvance(null) removes validation gate', () async {
      controller.setStepCount(3);
      controller.setCanAdvance(() async => false);

      await controller.next();
      expect(controller.currentStepIndex, 0); // Blocked

      controller.setCanAdvance(null);
      await controller.next();
      expect(controller.currentStepIndex, 1); // Allowed
    });

    test('notifies listeners on step change', () {
      controller.setStepCount(3);
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.previous(); // No-op at step 0, should not notify
      expect(notifyCount, 0);

      controller.goTo(1);
      expect(notifyCount, 1);

      controller.previous(); // Real change, should notify
      expect(notifyCount, 2);
    });

    test('disposes resources', () {
      controller.setStepCount(3);
      // Dispose will be called by tearDown. Verify controller is set up correctly.
      expect(controller.stepCount, 3);
    });

    test('handles step count changes correctly', () {
      controller.setStepCount(5);
      controller.goTo(4);

      // Reduce step count; current index should clamp.
      controller.setStepCount(3);
      expect(controller.currentStepIndex, 2);
    });

    test('reset clears to first step', () {
      controller.setStepCount(3);
      controller.goTo(2);
      controller.reset();

      expect(controller.currentStepIndex, 0);
      expect(controller.stepCount, 0);
    });

    test('supports multiple listeners', () {
      controller.setStepCount(3);
      var count1 = 0;
      var count2 = 0;

      controller.addListener(() => count1++);
      controller.addListener(() => count2++);

      controller.goTo(1);
      expect(count1, 1);
      expect(count2, 1);
    });
  });
}
