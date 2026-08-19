import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Password Requirements namespace to the i18n engine.
mixin LayrzUiI18nPasswordMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get passwordRequirementsLowercaseLetter =>
      i18n.t('password.requirements.lowercaseLetter');

  @override
  String get passwordRequirementsUppercaseLetter =>
      i18n.t('password.requirements.uppercaseLetter');

  @override
  String get passwordRequirementsDigit => i18n.t('password.requirements.digit');

  @override
  String get passwordRequirementsSpecialCharacter =>
      i18n.t('password.requirements.specialCharacter');

  @override
  String get passwordStrengthLevel => i18n.t('password.strengthLevel');
}
