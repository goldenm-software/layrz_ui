import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/steppers/src/step.dart';
import 'package:layrz_ui/src/steppers/src/stepper_state.dart';

void main() {
  group('LayrzStep', () {
    test('creates with all fields', () {
      const step = LayrzStep(
        label: 'Personal Info',
        body: Text('content'),
        state: LayrzStepperState.completed,
      );

      expect(step.label, 'Personal Info');
      expect(step.state, LayrzStepperState.completed);
    });

    test('creates with null state', () {
      const step = LayrzStep(
        label: 'Shipping',
        body: Text('content'),
      );

      expect(step.label, 'Shipping');
      expect(step.state, isNull);
    });

    test('copyWith replaces all fields', () {
      const original = LayrzStep(
        label: 'Step 1',
        body: Text('original'),
        state: LayrzStepperState.upcoming,
      );

      final updated = original.copyWith(
        label: 'Step 1 Modified',
        body: const Text('modified'),
        state: LayrzStepperState.completed,
      );

      expect(updated.label, 'Step 1 Modified');
      expect(updated.state, LayrzStepperState.completed);
      expect(original.label, 'Step 1');
    });

    test('copyWith preserves omitted fields', () {
      const original = LayrzStep(
        label: 'Step 1',
        body: Text('content'),
        state: LayrzStepperState.active,
      );

      final updated = original.copyWith(label: 'Modified');

      expect(updated.label, 'Modified');
      expect(updated.state, LayrzStepperState.active);
    });

    test('== operator works correctly', () {
      final widget1 = const Text('address');

      final step1 = LayrzStep(
        label: 'Shipping',
        body: widget1,
        state: LayrzStepperState.completed,
      );

      final step2 = LayrzStep(
        label: 'Shipping',
        body: widget1, // Same instance
        state: LayrzStepperState.completed,
      );

      final step3 = LayrzStep(
        label: 'Shipping',
        body: widget1,
        state: LayrzStepperState.upcoming,
      );

      expect(step1, step2);
      expect(step1, isNot(step3));
    });

    test('hashCode is consistent', () {
      final widget = const Text('address');

      final step1 = LayrzStep(
        label: 'Shipping',
        body: widget,
        state: LayrzStepperState.completed,
      );

      final step2 = LayrzStep(
        label: 'Shipping',
        body: widget, // Same instance
        state: LayrzStepperState.completed,
      );

      expect(step1.hashCode, step2.hashCode);
    });

    test('hashCode differs for different steps', () {
      const step1 = LayrzStep(
        label: 'Shipping',
        body: Text('address'),
      );

      const step2 = LayrzStep(
        label: 'Billing',
        body: Text('address'),
      );

      expect(step1.hashCode, isNot(step2.hashCode));
    });
  });
}
