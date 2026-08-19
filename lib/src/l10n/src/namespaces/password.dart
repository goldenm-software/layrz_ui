/// Password Requirements namespace.
mixin LayrzUiL10nPasswordMixin {
  /// Localized validator message for lowercase letter requirement.
  String get passwordRequirementsLowercaseLetter => 'At least one lowercase letter';

  /// Localized validator message for uppercase letter requirement.
  String get passwordRequirementsUppercaseLetter => 'At least one uppercase letter';

  /// Localized validator message for digit requirement.
  String get passwordRequirementsDigit => 'At least one digit';

  /// Localized validator message for special character requirement.
  String get passwordRequirementsSpecialCharacter => 'At least one special character';

  /// Localized label for password strength indicator.
  String get passwordStrengthLevel => 'Password Length';
}
