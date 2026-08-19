import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the DateTime Helpers — Weekday & Month Names namespace to the i18n engine.
mixin LayrzUiI18nWeekdaysMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get dateTimeMonday => i18n.t('dateTime.monday');

  @override
  String get dateTuesday => i18n.t('dateTime.tuesday');

  @override
  String get dateWednesday => i18n.t('dateTime.wednesday');

  @override
  String get dateThursday => i18n.t('dateTime.thursday');

  @override
  String get dateFriday => i18n.t('dateTime.friday');

  @override
  String get dateSaturday => i18n.t('dateTime.saturday');

  @override
  String get dateSunday => i18n.t('dateTime.sunday');
}
