import 'package:flutter/widgets.dart';

import 'stepper_state.dart';

/// An immutable data class representing a single step in a [LayrzStepper].
///
/// Each step carries a labelText, a body widget, and an optional state override.
/// The stepper drives the state automatically; pass a state here only to override
/// the default progression logic (e.g. to mark a step as error after validation).
///
/// **Equality and hashing caveat**: [LayrzStep] equality and [hashCode] depend on
/// [body], which is a [Widget]. Widget instances are compared by identity, not by
/// structure. Two [LayrzStep] instances are only equal if their [body] fields are
/// the exact same widget instance (e.g. both reference `const MyWidget()` or the
/// same variable). Creating two structurally identical widgets will produce unequal
/// steps: `LayrzStep(..., body: const Text('x'))` != `LayrzStep(..., body: const Text('x'))`.
@immutable
class LayrzStep {
  /// Creates a [LayrzStep].
  const LayrzStep({
    required this.labelText,
    required this.body,
    this.state,
  });

  /// The step's display label.
  ///
  /// Shown in the step header/circle. Short and descriptive, e.g. "Shipping", "Review".
  final String labelText;

  /// The widget body displayed when this step is active.
  ///
  /// Can be any widget — a form, a summary, a confirmation screen. The stepper
  /// renders only the active step's body.
  final Widget body;

  /// Optional state override for this step.
  ///
  /// If null, the stepper's controller determines the state based on progression
  /// (upcoming, active, completed, or error). Set explicitly to force a step into
  /// error state after validation fails, for example.
  ///
  /// The stepper always enforces [LayrzStepperState.active] for the current step,
  /// overriding this field if set.
  final LayrzStepperState? state;

  /// Creates a copy of this step with the given fields replaced.
  ///
  /// All parameters are optional; omitted fields retain their original values.
  LayrzStep copyWith({
    String? labelText,
    Widget? body,
    LayrzStepperState? state,
  }) {
    return LayrzStep(
      labelText: labelText ?? this.labelText,
      body: body ?? this.body,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzStep &&
          runtimeType == other.runtimeType &&
          labelText == other.labelText &&
          body == other.body &&
          state == other.state;

  @override
  int get hashCode => Object.hash(labelText, body, state);
}
