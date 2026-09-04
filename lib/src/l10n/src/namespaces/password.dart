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

  /// Accessible name for the show-password toggle when the field is
  /// currently obscured.
  ///
  /// Announces the affordance that reveals the password's plain-text value.
  /// Used as the toggle's semantic label while `obscureText` is `true`.
  ///
  /// English default: "Show password"
  String get passwordShow => 'Show password';

  /// Accessible name for the show-password toggle when the field is
  /// currently revealed.
  ///
  /// Announces the affordance that re-obscures the password's value. Used as
  /// the toggle's semantic label while `obscureText` is `false`.
  ///
  /// English default: "Hide password"
  String get passwordHide => 'Hide password';

  /// Live-region announcement made after the show-password toggle reveals
  /// the password.
  ///
  /// Assistive tech announces this string right after the field transitions
  /// from obscured to plain-text, so a screen-reader user learns the state
  /// changed without needing to re-inspect the toggle.
  ///
  /// English default: "Password shown"
  String get passwordShownAnnouncement => 'Password shown';

  /// Live-region announcement made after the show-password toggle re-obscures
  /// the password.
  ///
  /// Assistive tech announces this string right after the field transitions
  /// from plain-text back to obscured, so a screen-reader user learns the
  /// state changed without needing to re-inspect the toggle.
  ///
  /// English default: "Password hidden"
  String get passwordHiddenAnnouncement => 'Password hidden';

  /// Default label for the username/identifier field in a login form.
  ///
  /// Used by login-oriented username inputs as the fallback `labelText` when
  /// the caller does not supply one.
  ///
  /// English default: "Username"
  String get loginUsernameLabel => 'Username';

  /// Default label for the password field in a login form.
  ///
  /// Used by login-oriented password inputs as the fallback `labelText` when
  /// the caller does not supply one.
  ///
  /// English default: "Password"
  String get loginPasswordLabel => 'Password';
}
