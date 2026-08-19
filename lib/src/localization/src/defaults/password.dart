import '../contract/password.dart';

/// English default implementations for Password Requirements namespace.
mixin LayrzDefaultPasswordLocalizations implements LayrzPasswordLocalizations {
  @override
  String get passwordRequirementsLowercaseLetter => 'At least one lowercase letter';

  @override
  String get passwordRequirementsUppercaseLetter => 'At least one uppercase letter';

  @override
  String get passwordRequirementsDigit => 'At least one digit';

  @override
  String get passwordRequirementsSpecialCharacter => 'At least one special character';

  @override
  String get passwordStrengthLevel => 'Password Length';
}
