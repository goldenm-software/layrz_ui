import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nDefault — picker namespace additions', () {
    const l10n = LayrzUiL10nDefault();

    test('weekday single-letter initials all have English defaults', () {
      expect(l10n.weekdayInitialMonday, isNotEmpty);
      expect(l10n.weekdayInitialTuesday, isNotEmpty);
      expect(l10n.weekdayInitialWednesday, isNotEmpty);
      expect(l10n.weekdayInitialThursday, isNotEmpty);
      expect(l10n.weekdayInitialFriday, isNotEmpty);
      expect(l10n.weekdayInitialSaturday, isNotEmpty);
      expect(l10n.weekdayInitialSunday, isNotEmpty);
    });

    test('weekday abbreviated names all have English defaults', () {
      expect(l10n.weekdayAbbreviatedMonday, 'Mon');
      expect(l10n.weekdayAbbreviatedTuesday, 'Tue');
      expect(l10n.weekdayAbbreviatedWednesday, 'Wed');
      expect(l10n.weekdayAbbreviatedThursday, 'Thu');
      expect(l10n.weekdayAbbreviatedFriday, 'Fri');
      expect(l10n.weekdayAbbreviatedSaturday, 'Sat');
      expect(l10n.weekdayAbbreviatedSunday, 'Sun');
    });

    test('month abbreviated names all have English defaults', () {
      expect(l10n.monthAbbreviatedJanuary, 'Jan');
      expect(l10n.monthAbbreviatedFebruary, 'Feb');
      expect(l10n.monthAbbreviatedMarch, 'Mar');
      expect(l10n.monthAbbreviatedApril, 'Apr');
      expect(l10n.monthAbbreviatedMay, 'May');
      expect(l10n.monthAbbreviatedJune, 'Jun');
      expect(l10n.monthAbbreviatedJuly, 'Jul');
      expect(l10n.monthAbbreviatedAugust, 'Aug');
      expect(l10n.monthAbbreviatedSeptember, 'Sep');
      expect(l10n.monthAbbreviatedOctober, 'Oct');
      expect(l10n.monthAbbreviatedNovember, 'Nov');
      expect(l10n.monthAbbreviatedDecember, 'Dec');
    });

    test('the seconds label has an English default distinct from hours/minutes', () {
      expect(l10n.timePickerSeconds, isNotEmpty);
      expect(l10n.timePickerSeconds, isNot(equals(l10n.timePickerHours)));
      expect(l10n.timePickerSeconds, isNot(equals(l10n.timePickerMinutes)));
    });

    test('the range separator has a non-empty English default', () {
      expect(l10n.dateTimePickerRangeSeparator, isNotEmpty);
    });

    test('the week-number gutter label has a non-empty English default', () {
      expect(l10n.dateTimePickerWeekNumberLabel, isNotEmpty);
    });

    test('the pickers namespace strings all have non-empty English defaults', () {
      expect(l10n.pickerRangeReset, isNotEmpty);
      expect(l10n.pickerTodayLabel, isNotEmpty);
      expect(l10n.pickerSelectedLabel, isNotEmpty);
      expect(l10n.pickerRangeInteriorLabel, isNotEmpty);
      expect(l10n.pickerDisabledLabel, isNotEmpty);
    });
  });

  group('LayrzUiL10n subclass overrides — adapters can override without breaking', () {
    test('a subclass overriding only one picker key inherits the rest', () {
      final l10n = _PartialOverrideL10n();
      expect(l10n.pickerRangeReset, 'CUSTOM_RESET');
      expect(l10n.pickerTodayLabel, const LayrzUiL10nDefault().pickerTodayLabel);
      expect(l10n.weekdayInitialMonday, const LayrzUiL10nDefault().weekdayInitialMonday);
    });
  });
}

class _PartialOverrideL10n extends LayrzUiL10n {
  @override
  String get pickerRangeReset => 'CUSTOM_RESET';
}
