import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Actions & Confirmations namespace to the i18n engine.
mixin LayrzUiI18nActionsMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get actionCancel => i18n.t('actions.cancel');

  @override
  String get actionSave => i18n.t('actions.save');

  @override
  String get actionReset => i18n.t('actions.reset');

  @override
  String get actionSearch => i18n.t('actions.search');

  @override
  String get actionLint => i18n.t('actions.lint');

  @override
  String get actionRun => i18n.t('actions.run');

  @override
  String get confirmationTitle => i18n.t('confirmations.title');

  @override
  String get confirmationContent => i18n.t('confirmations.content');

  @override
  String get confirmationConfirm => i18n.t('confirmations.confirm');

  @override
  String get confirmationDismiss => i18n.t('confirmations.dismiss');

  @override
  String get confirmationMultipleTitle => i18n.t('confirmations.multipleTitle');

  @override
  String get confirmationMultipleContent =>
      i18n.t('confirmations.multipleContent');
}
