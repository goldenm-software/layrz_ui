/// Required Fields namespace.
///
/// **Status**: Scheduled for later milestone. Included in contract now for
/// forward compatibility — adding abstract members later would break existing
/// implementations.
abstract mixin class LayrzRequiredFieldsLocalizations {
  /// Localized text for "Add" action in required fields interface.
  String get requiredFieldsAdd;

  /// Localized text for "Remove" action in required fields interface.
  String get requiredFieldsRemove;

  /// Localized label for "Field" column/input.
  String get requiredFieldsField;

  /// Localized label for "Type" column/input.
  String get requiredFieldsType;

  /// Localized label for "Action" column/input.
  String get requiredFieldsAction;

  /// Localized label for minimum length constraint.
  String get requiredFieldsMinLength;

  /// Localized label for maximum length constraint.
  String get requiredFieldsMaxLength;

  /// Localized label for minimum value constraint.
  String get requiredFieldsMinValue;

  /// Localized label for maximum value constraint.
  String get requiredFieldsMaxValue;

  /// Localized label for "Only field" constraint.
  String get requiredFieldsOnlyField;

  /// Localized label for "Only choices" constraint.
  String get requiredFieldsOnlyChoices;

  /// Localized label for "Choices" field type.
  String get requiredFieldsChoices;

  /// Localized text for "Filter choices" action.
  String get requiredFieldsChoicesFilter;

  /// Localized text for "Add option" action.
  String get requiredFieldsChoicesAddOption;

  /// Localized text for removing a choice option.
  String get requiredFieldsChoicesRemove;

  /// Localized text for editing a choice option.
  String get requiredFieldsChoicesEdit;

  /// Localized text for saving choice option edits.
  String get requiredFieldsChoicesSave;

  /// Localized text for discarding choice option edits.
  String get requiredFieldsChoicesDiscard;

  /// Localized label for validators section.
  String get requiredFieldsSectionsValidators;
}
