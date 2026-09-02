import 'package:layrz_ui/src/l10n/l10n.dart';

import 'strftime_directive.dart';

/// Parses [pattern] into a flat list of [StrftimeToken]s.
///
/// Recognizes every directive in [StrftimeDirectiveKind]. An unrecognized
/// `%`-prefixed sequence (an unsupported directive letter, or a lone
/// trailing `%` with nothing after it) is **not** an error: it is emitted as
/// a literal token carrying its own original text, so [formatStrftime]
/// renders it back out unchanged rather than throwing. See [formatStrftime]'s
/// class doc for why this is a deliberate, documented compatibility
/// commitment rather than an implementation gap.
List<StrftimeToken> parseStrftimePattern(String pattern) {
  const directiveByChar = <String, StrftimeDirectiveKind>{
    'Y': StrftimeDirectiveKind.year4,
    'y': StrftimeDirectiveKind.year2,
    'm': StrftimeDirectiveKind.month2,
    'd': StrftimeDirectiveKind.day2,
    'H': StrftimeDirectiveKind.hour24,
    'I': StrftimeDirectiveKind.hour12,
    'M': StrftimeDirectiveKind.minute2,
    'S': StrftimeDirectiveKind.second2,
    'B': StrftimeDirectiveKind.monthNameFull,
    'b': StrftimeDirectiveKind.monthNameAbbreviated,
    'A': StrftimeDirectiveKind.weekdayNameFull,
    'a': StrftimeDirectiveKind.weekdayNameAbbreviated,
    'p': StrftimeDirectiveKind.meridiem,
    'j': StrftimeDirectiveKind.dayOfYear3,
    '%': StrftimeDirectiveKind.literalPercent,
  };

  final tokens = <StrftimeToken>[];
  final literalBuffer = StringBuffer();

  void flushLiteral() {
    if (literalBuffer.isNotEmpty) {
      tokens.add(StrftimeLiteralToken(literalBuffer.toString()));
      literalBuffer.clear();
    }
  }

  var i = 0;
  while (i < pattern.length) {
    final char = pattern[i];
    if (char != '%') {
      literalBuffer.write(char);
      i++;
      continue;
    }

    // `char == '%'` here. A trailing lone '%' (nothing follows it) and an
    // unrecognized directive letter both fall through to the same
    // pass-through behavior: the '%' (and the following char, if any) is
    // emitted as a literal rather than throwing.
    if (i + 1 >= pattern.length) {
      literalBuffer.write('%');
      i++;
      continue;
    }

    final directiveChar = pattern[i + 1];
    final kind = directiveByChar[directiveChar];
    if (kind == null) {
      literalBuffer
        ..write('%')
        ..write(directiveChar);
      i += 2;
      continue;
    }

    flushLiteral();
    tokens.add(StrftimeDirectiveToken(kind));
    i += 2;
  }

  flushLiteral();
  return tokens;
}

/// Formats [dateTime] according to [pattern], a strftime-style format string
/// using Python `datetime` directives (`%Y`, `%m`, `%d`, `%H`, `%I`, `%M`,
/// `%S`, `%y`, `%B`, `%b`, `%A`, `%a`, `%p`, `%j`, `%%`) — **not**
/// `intl`/Dart `DateFormat` patterns (`yyyy-MM-dd`). This mirrors the old
/// layrz_theme pickers' own `pattern: '%Y-%m-%d'` convention, so consumers
/// migrating from layrz_theme keep their existing format strings unchanged —
/// one of the few places this batch preserves the old API rather than
/// breaking it.
///
/// **Zero-padding is the directives' own semantics** (`%d`, `%H`, `%I`, `%M`,
/// `%S`, `%m`, `%y`, `%j` are all zero-padded by definition) — there is no
/// separate padding parameter.
///
/// **Name-producing directives resolve through [l10n], never hardcoded
/// English:** `%B`/`%b` read the month keys, `%A`/`%a` read the weekday
/// keys, `%p` reads `timeMeridiemAm`/`timeMeridiemPm`.
///
/// **Malformed or unsupported directives pass through literally and never
/// throw.** A format string is often authored by a consumer at runtime (a
/// caller-supplied `pattern` string, not a compile-time literal this library
/// controls), and a crash there is worse than a wrong-looking label. So
/// `%Q` in [pattern] renders as the literal text `%Q`, and a trailing lone
/// `%` renders as `%`. This is a documented compatibility commitment on
/// public API, not an implementation detail — see `strftime_malformed_test.dart`.
///
/// **Parsing (`strptime`) is deliberately not provided.** Every picker widget
/// in this batch has a read-only anchor and commits from a tap or an
/// in-panel Save — there is no text input to parse a typed date out of, so a
/// parser would have zero consumers in this batch.
String formatStrftime(DateTime dateTime, String pattern, LayrzUiL10n l10n) {
  final tokens = parseStrftimePattern(pattern);
  final buffer = StringBuffer();
  for (final token in tokens) {
    buffer.write(_renderToken(token, dateTime, l10n));
  }
  return buffer.toString();
}

/// Renders a single parsed [token] against [dateTime] and [l10n].
String _renderToken(StrftimeToken token, DateTime dateTime, LayrzUiL10n l10n) {
  if (token is StrftimeLiteralToken) return token.text;

  final directive = token as StrftimeDirectiveToken;
  switch (directive.kind) {
    case StrftimeDirectiveKind.year4:
      return dateTime.year.toString().padLeft(4, '0');
    case StrftimeDirectiveKind.year2:
      return (dateTime.year % 100).toString().padLeft(2, '0');
    case StrftimeDirectiveKind.month2:
      return dateTime.month.toString().padLeft(2, '0');
    case StrftimeDirectiveKind.day2:
      return dateTime.day.toString().padLeft(2, '0');
    case StrftimeDirectiveKind.hour24:
      return dateTime.hour.toString().padLeft(2, '0');
    case StrftimeDirectiveKind.hour12:
      return _hour12(dateTime.hour).toString().padLeft(2, '0');
    case StrftimeDirectiveKind.minute2:
      return dateTime.minute.toString().padLeft(2, '0');
    case StrftimeDirectiveKind.second2:
      return dateTime.second.toString().padLeft(2, '0');
    case StrftimeDirectiveKind.monthNameFull:
      return _fullMonthName(dateTime.month, l10n);
    case StrftimeDirectiveKind.monthNameAbbreviated:
      return _abbreviatedMonthName(dateTime.month, l10n);
    case StrftimeDirectiveKind.weekdayNameFull:
      return _fullWeekdayName(dateTime.weekday, l10n);
    case StrftimeDirectiveKind.weekdayNameAbbreviated:
      return _abbreviatedWeekdayName(dateTime.weekday, l10n);
    case StrftimeDirectiveKind.meridiem:
      return dateTime.hour >= 12 ? l10n.timeMeridiemPm : l10n.timeMeridiemAm;
    case StrftimeDirectiveKind.dayOfYear3:
      return _dayOfYear(dateTime).toString().padLeft(3, '0');
    case StrftimeDirectiveKind.literalPercent:
      return '%';
  }
}

/// Converts a 24-hour [hour] (`0`–`23`) to its 12-hour form (`1`–`12`).
int _hour12(int hour) {
  final h = hour % 12;
  return h == 0 ? 12 : h;
}

/// Returns the 1-indexed day-of-year for [dateTime] (`1`–`366`).
int _dayOfYear(DateTime dateTime) {
  final startOfYear = DateTime(dateTime.year, 1, 1);
  return dateTime.difference(startOfYear).inDays + 1;
}

/// Returns the full, localized month name for [month] (`1`–`12`).
String _fullMonthName(int month, LayrzUiL10n l10n) {
  switch (month) {
    case 1:
      return l10n.monthJanuary;
    case 2:
      return l10n.monthFebruary;
    case 3:
      return l10n.monthMarch;
    case 4:
      return l10n.monthApril;
    case 5:
      return l10n.monthMay;
    case 6:
      return l10n.monthJune;
    case 7:
      return l10n.monthJuly;
    case 8:
      return l10n.monthAugust;
    case 9:
      return l10n.monthSeptember;
    case 10:
      return l10n.monthOctober;
    case 11:
      return l10n.monthNovember;
    default:
      return l10n.monthDecember;
  }
}

/// Returns the abbreviated, localized month name for [month] (`1`–`12`).
String _abbreviatedMonthName(int month, LayrzUiL10n l10n) {
  switch (month) {
    case 1:
      return l10n.monthAbbreviatedJanuary;
    case 2:
      return l10n.monthAbbreviatedFebruary;
    case 3:
      return l10n.monthAbbreviatedMarch;
    case 4:
      return l10n.monthAbbreviatedApril;
    case 5:
      return l10n.monthAbbreviatedMay;
    case 6:
      return l10n.monthAbbreviatedJune;
    case 7:
      return l10n.monthAbbreviatedJuly;
    case 8:
      return l10n.monthAbbreviatedAugust;
    case 9:
      return l10n.monthAbbreviatedSeptember;
    case 10:
      return l10n.monthAbbreviatedOctober;
    case 11:
      return l10n.monthAbbreviatedNovember;
    default:
      return l10n.monthAbbreviatedDecember;
  }
}

/// Returns the full, localized weekday name for [weekday]
/// (`DateTime.monday`..`DateTime.sunday`, i.e. `1`–`7`).
String _fullWeekdayName(int weekday, LayrzUiL10n l10n) {
  switch (weekday) {
    case DateTime.monday:
      return l10n.dateTimeMonday;
    case DateTime.tuesday:
      return l10n.dateTuesday;
    case DateTime.wednesday:
      return l10n.dateWednesday;
    case DateTime.thursday:
      return l10n.dateThursday;
    case DateTime.friday:
      return l10n.dateFriday;
    case DateTime.saturday:
      return l10n.dateSaturday;
    default:
      return l10n.dateSunday;
  }
}

/// Returns the abbreviated, localized weekday name for [weekday]
/// (`DateTime.monday`..`DateTime.sunday`, i.e. `1`–`7`).
String _abbreviatedWeekdayName(int weekday, LayrzUiL10n l10n) {
  switch (weekday) {
    case DateTime.monday:
      return l10n.weekdayAbbreviatedMonday;
    case DateTime.tuesday:
      return l10n.weekdayAbbreviatedTuesday;
    case DateTime.wednesday:
      return l10n.weekdayAbbreviatedWednesday;
    case DateTime.thursday:
      return l10n.weekdayAbbreviatedThursday;
    case DateTime.friday:
      return l10n.weekdayAbbreviatedFriday;
    case DateTime.saturday:
      return l10n.weekdayAbbreviatedSaturday;
    default:
      return l10n.weekdayAbbreviatedSunday;
  }
}
