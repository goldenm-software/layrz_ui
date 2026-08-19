import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Date & Time Pickers namespace to the i18n engine.
mixin LayrzUiI18nDateTimePickersMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get dateTimePickerDate => i18n.t('dateTimePickers.date');

  @override
  String get dateTimePickerTime => i18n.t('dateTimePickers.time');

  @override
  String get timePickerHours => i18n.t('timePickers.hours');

  @override
  String get timePickerMinutes => i18n.t('timePickers.minutes');

  @override
  String get timePickerStart => i18n.t('timePickers.start');

  @override
  String get timePickerEnd => i18n.t('timePickers.end');

  @override
  String monthPickerYear(int year) =>
      i18n.t('monthPicker.year', {'year': year});

  @override
  String get monthPickerBack => i18n.t('monthPicker.back');

  @override
  String get monthPickerNext => i18n.t('monthPicker.next');
}
