import 'package:layrz_ui/src/steppers/src/stepper_state.dart';

/// Steppers namespace.
mixin LayrzUiL10nSteppersMixin {
  /// Localized text for the "Previous" / back button in a stepper.
  ///
  /// Default: "Back"
  String get steppersPreviousButtonLabel => 'Back';

  /// Localized text for the "Next" / forward button in a stepper.
  ///
  /// Default: "Next"
  String get steppersNextButtonLabel => 'Next';

  /// Localized text for the persistent step-progress counter shown above the
  /// compact (vertical accordion) stepper layout.
  ///
  /// [current] is the 1-based index of the active step; [total] is the total
  /// number of steps. Default: "Step $current of $total"
  String steppersStepCounterLabel(int current, int total) => 'Step $current of $total';

  /// Localized text describing a step's [LayrzStepperState] for use inside a
  /// step's semantics label, shared by both the wide and compact layouts.
  ///
  /// The [LayrzStepperState.upcoming] case includes "locked" in the shared
  /// string, deliberately: the same state must announce identically
  /// regardless of which layout renders it, so a screen-reader user resizing
  /// a window does not hear a step's status change when nothing about the
  /// step did. "Locked" is also the word that tells the user *why* the row
  /// does not respond to a tap — omitting it is the WCAG 1.4.1 gap this
  /// affordance work exists to close; a locked row that gives no reason reads
  /// as a frozen app.
  String steppersStateLabel(LayrzStepperState state) {
    switch (state) {
      case LayrzStepperState.upcoming:
        return 'upcoming, not yet reached, locked';
      case LayrzStepperState.active:
        return 'currently active';
      case LayrzStepperState.completed:
        return 'completed';
      case LayrzStepperState.error:
        return 'error, needs attention';
    }
  }
}
