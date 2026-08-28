import 'package:layrz_ui/src/l10n/l10n.dart';

/// The clock convention a [LayrzCalendar]'s week and day surfaces render
/// hour-axis labels and timed-event times in.
///
/// **Month view is unaffected by this enum entirely** — month cells render
/// event titles only, never times, so [LayrzTimeFormat] only threads into the
/// week and day surfaces' hour axis and timed-event blocks.
///
/// **Naming is final — do not "tidy" these values.** Two names were
/// considered and rejected before this spelling: `twentyFourHour` (too long
/// to type at the call site) and `standard` (rejected because 12-hour time
/// *is* standard in the US, so the name would rank rather than describe,
/// reading wrong to exactly the callers who would pick [amPm]). [h24] matches
/// ICU/CLDR convention and carries no value judgment; Dart accepts it as an
/// identifier because it starts with a letter. The value-order asymmetry
/// ([amPm] listed first) is intentional — each name is simply the
/// conventional name for its own format, not a ranking.
///
/// This is a [LayrzCalendar] constructor parameter, not a [LayrzTokens]
/// value — no existing token category carries formatting or behaviour, and
/// adding one here would be a new category solely for this enum.
enum LayrzTimeFormat {
  /// Renders times with an AM/PM marker, e.g. `8 AM`, `2:30 PM`.
  ///
  /// The marker text comes from [LayrzUiL10nMonthsMixin.timeMeridiemAm] /
  /// [LayrzUiL10nMonthsMixin.timeMeridiemPm], never a string literal.
  amPm,

  /// Renders times on a 24-hour clock, e.g. `08:00`, `14:30`.
  ///
  /// The default for [LayrzCalendar.timeFormat] — 24-hour time needs no
  /// localized markers to render correctly and matches the fixed
  /// `00:00`–`23:00` hour axis already used by the week and day surfaces.
  h24,
}

/// Formats [hour] (0–23) as an hour-axis label under [format].
///
/// [l10n] supplies the localized AM/PM markers for [LayrzTimeFormat.amPm];
/// unused for [LayrzTimeFormat.h24].
///
/// [hour] is asserted to be in `0..23` — a DST-transition day still has 23 or
/// 25 elapsed hours, but its hour-of-day axis is always the ordinary 24 rows;
/// see `calendar_day_surface.dart` and `calendar_week_surface.dart` for how
/// the axis is built without stepping by `Duration(hours: 1)`.
String formatHourLabel(int hour, LayrzTimeFormat format, LayrzUiL10n l10n) {
  assert(hour >= 0 && hour <= 23, 'hour must be between 0 and 23, got $hour.');

  switch (format) {
    case LayrzTimeFormat.h24:
      return '${hour.toString().padLeft(2, '0')}:00';
    case LayrzTimeFormat.amPm:
      final meridiem = hour < 12 ? l10n.timeMeridiemAm : l10n.timeMeridiemPm;
      final displayHour = switch (hour % 12) {
        0 => 12,
        final h => h,
      };
      return '$displayHour $meridiem';
  }
}

/// The widest hour-axis label rendered across both [LayrzTimeFormat] values,
/// used to size the shared hour-axis label column so switching format never
/// reflows or clips it.
///
/// `08:00` (five characters) and `12 AM`/`12 PM` (five characters) are the
/// widest labels either format produces; both are used here (rather than
/// picking one) so the sizing is correct regardless of which format a caller
/// measures with, and so a future locale with a wider meridiem marker than
/// `AM`/`PM` still measures its own real width rather than an assumed one.
const List<String> kLayrzCalendarWidestHourLabels = ['08:00', '12 AM', '12 PM'];
