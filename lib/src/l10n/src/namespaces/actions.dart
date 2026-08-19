/// Actions & Confirmations namespace.
mixin LayrzUiL10nActionsMixin {
  /// Localized text for "Cancel" action.
  String get actionCancel => 'Cancel';

  /// Localized text for "Save" action.
  String get actionSave => 'Save';

  /// Localized text for "Reset" action.
  String get actionReset => 'Reset';

  /// Localized text for "Search..." action.
  String get actionSearch => 'Search...';

  /// Localized text for "Lint" action.
  String get actionLint => 'Lint';

  /// Localized text for "Run" action.
  String get actionRun => 'Run';

  /// Localized title for single-item deletion confirmation.
  ///
  /// Default: "Are you sure that you want to delete this item?"
  String get confirmationTitle => 'Are you sure that you want to delete this item?';

  /// Localized content for single-item deletion confirmation.
  ///
  /// Default: "Once deleted, you will not be able to recover it."
  String get confirmationContent => 'Once deleted, you will not be able to recover it.';

  /// Localized text for affirmative confirmation button.
  ///
  /// Default: "Do it!"
  String get confirmationConfirm => 'Do it!';

  /// Localized text for dismissal confirmation button.
  ///
  /// Default: "Nevermind"
  String get confirmationDismiss => 'Nevermind';

  /// Localized title for multi-item deletion confirmation.
  ///
  /// Default: "Are you sure that you want to delete these items?"
  String get confirmationMultipleTitle => 'Are you sure that you want to delete these items?';

  /// Localized content for multi-item deletion confirmation.
  ///
  /// Default: "Once deleted, you will not be able to recover them."
  String get confirmationMultipleContent => 'Once deleted, you will not be able to recover them.';
}
