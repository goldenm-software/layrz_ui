/// Dialogs namespace — localized strings for the modal dialog component.
mixin LayrzUiL10nDialogsMixin {
  /// Semantic label for the modal barrier/scrim in screen readers and accessibility trees.
  ///
  /// Announced when [LayrzDialog] is presented, describing the semi-transparent
  /// overlay that makes the page behind the dialog non-interactive. Screen readers
  /// use this label when the user focuses on the barrier area or when the dialog
  /// is first presented.
  ///
  /// Kept distinct from [LayrzUiL10nSheetsMixin.sheetsBarrierLabel]: the two
  /// surfaces are presented independently (a dialog is not a bottom sheet), and
  /// each may need its own translation in the future even though both default
  /// to the same English text today.
  ///
  /// English default: "Dialog box"
  String get dialogsBarrierLabel => 'Dialog box';
}
