/// Required Fields namespace.
mixin LayrzUiL10nRequiredFieldsMixin {
///
/// **Status**: Scheduled for later milestone. Included in contract now for
/// forward compatibility — adding abstract members later would break existing
/// implementations.
  /// Localized text for "Add" action in required fields interface.
  String get requiredFieldsAdd => 'Add';
  /// Localized text for "Remove" action in required fields interface.
  String get requiredFieldsRemove => 'Remove';
  /// Localized label for "Field" column/input.
  String get requiredFieldsField => 'Field';
  /// Localized label for "Type" column/input.
  String get requiredFieldsType => 'Type';
  /// Localized label for "Action" column/input.
  String get requiredFieldsAction => 'Action';
  /// Localized label for minimum length constraint.
  String get requiredFieldsMinLength => 'Minimum length';
  /// Localized label for maximum length constraint.
  String get requiredFieldsMaxLength => 'Maximum length';
  /// Localized label for minimum value constraint.
  String get requiredFieldsMinValue => 'Minimum value';
  /// Localized label for maximum value constraint.
  String get requiredFieldsMaxValue => 'Maximum value';
  /// Localized label for "Only field" constraint.
  String get requiredFieldsOnlyField => 'Only field';
  /// Localized label for "Only choices" constraint.
  String get requiredFieldsOnlyChoices => 'Only choices';
  /// Localized label for "Choices" field type.
  String get requiredFieldsChoices => 'Choices';
  /// Localized text for "Filter choices" action.
  String get requiredFieldsChoicesFilter => 'Filter choices';
  /// Localized text for "Add option" action.
  String get requiredFieldsChoicesAddOption => 'Add option';
  /// Localized text for removing a choice option.
  String get requiredFieldsChoicesRemove => 'Remove';
  /// Localized text for editing a choice option.
  String get requiredFieldsChoicesEdit => 'Edit';
  /// Localized text for saving choice option edits.
  String get requiredFieldsChoicesSave => 'Save';
  /// Localized text for discarding choice option edits.
  String get requiredFieldsChoicesDiscard => 'Discard';
  /// Localized label for validators section.
  String get requiredFieldsSectionsValidators => 'Validators';
}
