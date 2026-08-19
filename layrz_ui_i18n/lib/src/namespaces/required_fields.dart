import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Required Fields namespace to the i18n engine.
mixin LayrzUiI18nRequiredFieldsMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get requiredFieldsAdd => i18n.t('requiredFields.add');

  @override
  String get requiredFieldsRemove => i18n.t('requiredFields.remove');

  @override
  String get requiredFieldsField => i18n.t('requiredFields.field');

  @override
  String get requiredFieldsType => i18n.t('requiredFields.type');

  @override
  String get requiredFieldsAction => i18n.t('requiredFields.action');

  @override
  String get requiredFieldsMinLength => i18n.t('requiredFields.minLength');

  @override
  String get requiredFieldsMaxLength => i18n.t('requiredFields.maxLength');

  @override
  String get requiredFieldsMinValue => i18n.t('requiredFields.minValue');

  @override
  String get requiredFieldsMaxValue => i18n.t('requiredFields.maxValue');

  @override
  String get requiredFieldsOnlyField => i18n.t('requiredFields.onlyField');

  @override
  String get requiredFieldsOnlyChoices => i18n.t('requiredFields.onlyChoices');

  @override
  String get requiredFieldsChoices => i18n.t('requiredFields.choices');

  @override
  String get requiredFieldsChoicesFilter =>
      i18n.t('requiredFields.choices.filter');

  @override
  String get requiredFieldsChoicesAddOption =>
      i18n.t('requiredFields.choices.addOption');

  @override
  String get requiredFieldsChoicesRemove =>
      i18n.t('requiredFields.choices.remove');

  @override
  String get requiredFieldsChoicesEdit => i18n.t('requiredFields.choices.edit');

  @override
  String get requiredFieldsChoicesSave => i18n.t('requiredFields.choices.save');

  @override
  String get requiredFieldsChoicesDiscard =>
      i18n.t('requiredFields.choices.discard');

  @override
  String get requiredFieldsSectionsValidators =>
      i18n.t('requiredFields.sections.validators');
}
