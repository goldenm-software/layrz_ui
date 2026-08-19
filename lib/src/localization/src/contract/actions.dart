/// Actions & Confirmations namespace.
abstract mixin class LayrzActionsLocalizations {
  /// Localized text for "Cancel" action.
  String get actionCancel;

  /// Localized text for "Save" action.
  String get actionSave;

  /// Localized text for "Reset" action.
  String get actionReset;

  /// Localized text for "Search..." action.
  String get actionSearch;

  /// Localized text for "Lint" action.
  String get actionLint;

  /// Localized text for "Run" action.
  String get actionRun;

  /// Localized title for single-item deletion confirmation.
  ///
  /// Default: "Are you sure that you want to delete this item?"
  String get confirmationTitle;

  /// Localized content for single-item deletion confirmation.
  ///
  /// Default: "Once deleted, you will not be able to recover it."
  String get confirmationContent;

  /// Localized text for affirmative confirmation button.
  ///
  /// Default: "Do it!"
  String get confirmationConfirm;

  /// Localized text for dismissal confirmation button.
  ///
  /// Default: "Nevermind"
  String get confirmationDismiss;

  /// Localized title for multi-item deletion confirmation.
  ///
  /// Default: "Are you sure that you want to delete these items?"
  String get confirmationMultipleTitle;

  /// Localized content for multi-item deletion confirmation.
  ///
  /// Default: "Once deleted, you will not be able to recover them."
  String get confirmationMultipleContent;
}
