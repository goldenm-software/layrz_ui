import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Calendar Navigation namespace to the i18n engine.
mixin LayrzUiI18nCalendarMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get calendarYearBack => i18n.t('calendar.yearBack');

  @override
  String get calendarYearNext => i18n.t('calendar.yearNext');

  @override
  String get calendarMonthBack => i18n.t('calendar.monthBack');

  @override
  String get calendarMonthNext => i18n.t('calendar.monthNext');

  @override
  String get calendarWeekBack => i18n.t('calendar.weekBack');

  @override
  String get calendarWeekNext => i18n.t('calendar.weekNext');

  @override
  String get calendarDayBack => i18n.t('calendar.dayBack');

  @override
  String get calendarDayNext => i18n.t('calendar.dayNext');

  @override
  String get calendarToday => i18n.t('calendar.today');

  @override
  String get calendarViewYear => i18n.t('calendar.viewYear');

  @override
  String get calendarViewMonth => i18n.t('calendar.viewMonth');

  @override
  String get calendarViewWeek => i18n.t('calendar.viewWeek');

  @override
  String get calendarViewDay => i18n.t('calendar.viewDay');

  @override
  String get calendarViewAs => i18n.t('calendar.viewAs');

  @override
  String get calendarPickMonth => i18n.t('calendar.pickMonth');
}
