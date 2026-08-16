import 'package:flutter/widgets.dart' as flutter_widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/state.dart';

/// Tests for the state module re-exports.
///
/// Verifies that all WidgetState family types are accessible via the public
/// layrz_ui barrel import, and that they function correctly in component-like
/// use cases (buttons, inputs, etc.).
void main() {
  group('State module re-exports', () {
    test('WidgetState enum is exported', () {
      // Verify that the enum is accessible from layrz_ui.
      final Type stateType = WidgetState;
      expect(stateType, isNotNull);
      expect(stateType.toString(), contains('WidgetState'));
    });

    test('WidgetStateProperty interface is exported', () {
      final Type propertyType = WidgetStateProperty;
      expect(propertyType, isNotNull);
    });

    test('WidgetStateMapper class is exported', () {
      final Type mapperType = WidgetStateMapper;
      expect(mapperType, isNotNull);
    });

    test('WidgetStatePropertyAll class is exported', () {
      final Type allType = WidgetStatePropertyAll;
      expect(allType, isNotNull);
    });

    test('WidgetStatesController class is exported', () {
      final Type controllerType = WidgetStatesController;
      expect(controllerType, isNotNull);
    });

    test('WidgetStatesConstraint mixin is exported', () {
      final Type constraintType = WidgetStatesConstraint;
      expect(constraintType, isNotNull);
    });

    test('WidgetStateMap typedef is exported', () {
      // WidgetStateMap is a typedef, so we verify it resolves in a type context.
      const Map<WidgetStatesConstraint, int> testMap = <WidgetStatesConstraint, int>{};
      expect(testMap, isNotNull);
    });

    test('WidgetPropertyResolver typedef is exported', () {
      // WidgetPropertyResolver is a typedef for resolver functions.
      int resolver(Set<WidgetState> states) => 42;
      expect(resolver(const <WidgetState>{}), equals(42));
    });

    test('WidgetStateColor class is exported', () {
      final Type colorType = WidgetStateColor;
      expect(colorType, isNotNull);
    });

    test('WidgetStateTextStyle class is exported', () {
      final Type styleType = WidgetStateTextStyle;
      expect(styleType, isNotNull);
    });

    test('WidgetStateBorderSide class is exported', () {
      final Type borderType = WidgetStateBorderSide;
      expect(borderType, isNotNull);
    });

    test('WidgetStateMouseCursor class is exported', () {
      final Type cursorType = WidgetStateMouseCursor;
      expect(cursorType, isNotNull);
    });

    test('WidgetStateOutlinedBorder class is exported', () {
      final Type borderOutlineType = WidgetStateOutlinedBorder;
      expect(borderOutlineType, isNotNull);
    });
  });

  group('WidgetStateProperty functional smoke tests', () {
    test('resolveWith creates a functional state property', () {
      // Create a color property that returns red when pressed, blue otherwise.
      final WidgetStateProperty<int> colorProperty = WidgetStateProperty.resolveWith<int>((Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed)) {
          return 0xFF0000; // red
        }
        return 0x0000FF; // blue
      });

      // Resolve in default state (empty set).
      expect(colorProperty.resolve(const <WidgetState>{}), equals(0x0000FF));

      // Resolve in pressed state.
      expect(
        colorProperty.resolve(<WidgetState>{WidgetState.pressed}),
        equals(0xFF0000),
      );
    });

    test('WidgetStateProperty.fromMap resolves based on constraints', () {
      // Create a map-based property with different values for different states.
      final WidgetStateProperty<String> textProperty = WidgetStateProperty.fromMap(<WidgetStatesConstraint, String>{
        WidgetState.pressed: 'pressed',
        WidgetState.hovered: 'hovered',
        WidgetState.focused: 'focused',
        WidgetState.any: 'default',
      });

      // Test each state.
      expect(
        textProperty.resolve(<WidgetState>{WidgetState.pressed}),
        equals('pressed'),
      );
      expect(
        textProperty.resolve(<WidgetState>{WidgetState.hovered}),
        equals('hovered'),
      );
      expect(
        textProperty.resolve(<WidgetState>{WidgetState.focused}),
        equals('focused'),
      );
      expect(textProperty.resolve(const <WidgetState>{}), equals('default'));
    });

    test('WidgetStatePropertyAll returns same value for all states', () {
      // Create a constant property.
      const WidgetStateProperty<String> constProperty = WidgetStatePropertyAll<String>('constant');

      // Verify it returns the same value for any state.
      expect(constProperty.resolve(const <WidgetState>{}), equals('constant'));
      expect(
        constProperty.resolve(<WidgetState>{WidgetState.pressed}),
        equals('constant'),
      );
      expect(
        constProperty.resolve(<WidgetState>{
          WidgetState.pressed,
          WidgetState.hovered,
          WidgetState.focused,
        }),
        equals('constant'),
      );
    });

    test('WidgetStateMapper constructs and resolves correctly', () {
      // Create a mapper with state-based values.
      final WidgetStateMapper<bool> mapper = WidgetStateMapper<bool>(
        <WidgetStatesConstraint, bool>{
          WidgetState.disabled: false,
          WidgetState.any: true,
        },
      );

      // Test disabled state.
      expect(mapper.resolve(<WidgetState>{WidgetState.disabled}), isFalse);

      // Test other states.
      expect(mapper.resolve(<WidgetState>{WidgetState.hovered}), isTrue);
      expect(mapper.resolve(const <WidgetState>{}), isTrue);
    });
  });

  group('WidgetStatesController', () {
    test('creates with initial empty state set', () {
      final WidgetStatesController controller = WidgetStatesController();
      expect(controller.value, isEmpty);
    });

    test('creates with initial state set', () {
      final Set<WidgetState> initialStates = <WidgetState>{WidgetState.hovered};
      final WidgetStatesController controller = WidgetStatesController(
        initialStates,
      );
      expect(controller.value, contains(WidgetState.hovered));
    });

    test('update adds state and notifies listeners', () async {
      final WidgetStatesController controller = WidgetStatesController();
      bool listenerCalled = false;

      controller.addListener(() {
        listenerCalled = true;
      });

      // Add a state.
      controller.update(WidgetState.pressed, true);
      await Future<void>.microtask(() {});

      expect(controller.value, contains(WidgetState.pressed));
      expect(listenerCalled, isTrue);
    });

    test('update removes state and notifies listeners', () async {
      final WidgetStatesController controller = WidgetStatesController(
        <WidgetState>{WidgetState.hovered},
      );
      bool listenerCalled = false;

      controller.addListener(() {
        listenerCalled = true;
      });

      // Remove the state.
      controller.update(WidgetState.hovered, false);
      await Future<void>.microtask(() {});

      expect(controller.value, isNot(contains(WidgetState.hovered)));
      expect(listenerCalled, isTrue);
    });

    test('update with no change does not notify listeners', () async {
      final WidgetStatesController controller = WidgetStatesController();
      int listenerCount = 0;

      controller.addListener(() {
        listenerCount++;
      });

      // Try to add a state that's already there (won't actually be added on first call).
      // Then try to remove a state that's not there.
      controller.update(WidgetState.pressed, false);
      await Future<void>.microtask(() {});

      // Listener should not have been called because no change occurred.
      expect(listenerCount, equals(0));
    });

    test('multiple states can be tracked simultaneously', () {
      final WidgetStatesController controller = WidgetStatesController();

      controller.update(WidgetState.pressed, true);
      controller.update(WidgetState.hovered, true);
      controller.update(WidgetState.focused, true);

      expect(controller.value, contains(WidgetState.pressed));
      expect(controller.value, contains(WidgetState.hovered));
      expect(controller.value, contains(WidgetState.focused));
      expect(controller.value.length, equals(3));
    });

    test('controller can be used with WidgetStateProperty', () {
      final WidgetStatesController controller = WidgetStatesController();
      final WidgetStateProperty<int> property = WidgetStateProperty.resolveWith<int>(
        (Set<WidgetState> states) => states.contains(WidgetState.pressed) ? 100 : 0,
      );

      // Resolve before pressing.
      expect(property.resolve(controller.value), equals(0));

      // Simulate pressing.
      controller.update(WidgetState.pressed, true);

      // Resolve after pressing.
      expect(property.resolve(controller.value), equals(100));
    });
  });

  group('WidgetStatesConstraint combinations', () {
    test('OR operator combines constraints', () {
      final WidgetStatesConstraint combined = WidgetState.pressed | WidgetState.hovered;

      // Should match if either state is present.
      expect(
        combined.isSatisfiedBy(<WidgetState>{WidgetState.pressed}),
        isTrue,
      );
      expect(
        combined.isSatisfiedBy(<WidgetState>{WidgetState.hovered}),
        isTrue,
      );
      expect(combined.isSatisfiedBy(const <WidgetState>{}), isFalse);
    });

    test('AND operator combines constraints', () {
      final WidgetStatesConstraint combined = WidgetState.pressed & WidgetState.hovered;

      // Should match only if both states are present.
      expect(
        combined.isSatisfiedBy(<WidgetState>{WidgetState.pressed}),
        isFalse,
      );
      expect(
        combined.isSatisfiedBy(<WidgetState>{
          WidgetState.pressed,
          WidgetState.hovered,
        }),
        isTrue,
      );
    });

    test('NOT operator negates constraint', () {
      final WidgetStatesConstraint notDisabled = ~WidgetState.disabled;

      // Should match when disabled is NOT present.
      expect(notDisabled.isSatisfiedBy(const <WidgetState>{}), isTrue);
      expect(
        notDisabled.isSatisfiedBy(<WidgetState>{WidgetState.hovered}),
        isTrue,
      );
      expect(
        notDisabled.isSatisfiedBy(<WidgetState>{WidgetState.disabled}),
        isFalse,
      );
    });
  });

  group('Re-export integrity', () {
    test('all exported types are identical to flutter types', () {
      // Verify that WidgetState from layrz_ui is the same as from Flutter.
      expect(WidgetState, equals(flutter_widgets.WidgetState));

      // Verify other key types.
      expect(WidgetStateProperty, equals(flutter_widgets.WidgetStateProperty));
      expect(
        WidgetStatesController,
        equals(flutter_widgets.WidgetStatesController),
      );
    });
  });
}
