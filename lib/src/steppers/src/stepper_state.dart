/// Enum representing the state of a single step in a [LayrzStepper].
///
/// Each step in a stepper can be in one of four mutually exclusive states:
/// - [upcoming]: The step has not been reached yet. Not tappable.
/// - [active]: The current step being processed. Its body is shown.
/// - [completed]: Successfully completed. Tappable to jump back; shows checkmark icon.
/// - [error]: Failed or requires attention. Shows error icon; can be jumped to for correction.
enum LayrzStepperState {
  /// The step has not been reached yet in the flow.
  ///
  /// Upcoming steps are visually greyed out and not tappable (not clickable).
  /// They cannot be selected until all preceding steps are completed.
  upcoming,

  /// The current active step in the flow.
  ///
  /// Only one step is active at a time. Its body widget is shown, and
  /// back/next buttons are displayed to navigate.
  active,

  /// The step was successfully completed.
  ///
  /// Completed steps are visually highlighted with a checkmark icon (not just colour).
  /// They are tappable; tapping jumps back to the completed step for review or editing.
  completed,

  /// The step encountered an error or validation failure.
  ///
  /// Error steps show an error icon. They can be jumped to for correction.
  /// The stepper does not automatically advance out of an error state.
  error,
}
