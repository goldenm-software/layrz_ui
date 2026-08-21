import 'package:flutter/widgets.dart';

import 'stepper_state.dart';

/// An immutable data class representing a single step in a [LayrzStepper].
///
/// Each step carries a label, a body widget, and an optional state override.
/// The stepper drives the state automatically; pass a state here only to override
/// the default progression logic (e.g. to mark a step as error after validation).
@immutable
class LayrzStep {
  /// Creates a [LayrzStep].
  const LayrzStep({
    required this.label,
    required this.body,
    this.state,
  });

  /// The step's display label.
  ///
  /// Shown in the step header/circle. Short and descriptive, e.g. "Shipping", "Review".
  final String label;

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
    String? label,
    Widget? body,
    LayrzStepperState? state,
  }) {
    return LayrzStep(
      label: label ?? this.label,
      body: body ?? this.body,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzStep &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          body == other.body &&
          state == other.state;

  @override
  int get hashCode => Object.hash(label, body, state);
}
