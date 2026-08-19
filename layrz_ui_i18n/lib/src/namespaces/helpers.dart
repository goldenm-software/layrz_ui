import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Helpers namespace to the i18n engine.
mixin LayrzUiI18nHelpersMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers — General Utilities (13 members)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String get helperSearch => i18n.t('helpers.search');

  @override
  String get helperButtonsShow => i18n.t('helpers.buttons.show');

  @override
  String get helperButtonsEdit => i18n.t('helpers.buttons.edit');

  @override
  String get helperButtonsDelete => i18n.t('helpers.buttons.delete');

  @override
  String get helperMultipleSelectionTitle =>
      i18n.t('helpers.multipleSelection.title');

  @override
  String get helperMultipleSelectionCaption =>
      i18n.t('helpers.multipleSelection.caption');

  @override
  String get helperMultipleSelectionActionsCancel =>
      i18n.t('helpers.multipleSelection.actions.cancel');

  @override
  String get helperMultipleSelectionActionsDelete =>
      i18n.t('helpers.multipleSelection.actions.delete');

  @override
  String get helperCopiedToClipboard => i18n.t('helpers.copiedToClipboard');

  @override
  String get helperCopyToClipboardPost =>
      i18n.t('helpers.copyToClipboard.post');

  @override
  String get helperAnd => i18n.t('helpers.and');

  @override
  String get helperTrue => i18n.t('helpers.true');

  @override
  String get helperFalse => i18n.t('helpers.false');

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers — Time Units (8 members)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String get helperYear => i18n.t('helpers.timeUnits.year');

  @override
  String get helperMonth => i18n.t('helpers.timeUnits.month');

  @override
  String get helperDays => i18n.t('helpers.timeUnits.days');

  @override
  String get helperWeeks => i18n.t('helpers.timeUnits.weeks');

  @override
  String get helperHours => i18n.t('helpers.timeUnits.hours');

  @override
  String get helperMinutes => i18n.t('helpers.timeUnits.minutes');

  @override
  String get helperSeconds => i18n.t('helpers.timeUnits.seconds');

  @override
  String get helperMilliseconds => i18n.t('helpers.timeUnits.milliseconds');

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers — Duration (8 count-aware methods)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String helperDurationDays(int count) =>
      i18n.tc('helpers.duration.days', count);

  @override
  String helperDurationHours(int count) =>
      i18n.tc('helpers.duration.hours', count);

  @override
  String helperDurationMinutes(int count) =>
      i18n.tc('helpers.duration.minutes', count);

  @override
  String helperDurationSeconds(int count) =>
      i18n.tc('helpers.duration.seconds', count);

  @override
  String helperDurationWeeks(int count) =>
      i18n.tc('helpers.duration.weeks', count);

  @override
  String helperDurationMonths(int count) =>
      i18n.tc('helpers.duration.months', count);

  @override
  String helperDurationYears(int count) =>
      i18n.tc('helpers.duration.years', count);

  @override
  String helperDurationMilliseconds(int count) =>
      i18n.tc('helpers.duration.milliseconds', count);
}
