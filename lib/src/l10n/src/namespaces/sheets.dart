/// Sheets namespace — localized strings for bottom sheet and modal components.
mixin LayrzUiL10nSheetsMixin {
  /// Semantic label for the modal barrier/scrim in screen readers and accessibility trees.
  ///
  /// Announced when the bottom sheet is presented in modal mode, describing the
  /// semi-transparent overlay that makes the page behind the sheet non-interactive.
  /// Screen readers use this label when the user focuses on the barrier area or
  /// when the modal is first presented.
  ///
  /// English default: "Dialog box"
  String get sheetsBarrierLabel => 'Dialog box';
}
