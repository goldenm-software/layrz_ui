import 'strftime.dart';
import 'strftime_directive.dart';

/// Returns whether [pattern] uses a 24-hour clock, as opposed to a 12-hour
/// clock with an AM/PM meridiem.
///
/// A pattern is treated as 12-hour when it contains a
/// [StrftimeDirectiveKind.hour12] (`%I`) or [StrftimeDirectiveKind.meridiem]
/// (`%p`) directive; otherwise it is treated as 24-hour, including when
/// [pattern] contains no hour directive at all (e.g. a date-only pattern
/// like `'%Y-%m-%d'`).
///
/// [pattern] is parsed with [parseStrftimePattern] rather than scanned with
/// `String.contains`, so an escaped `%%I` or `%%p` (a literal `%` followed
/// by a literal `I`/`p`, not a directive) never misfires this check.
///
/// This is the single source of truth the picker inputs
/// (`LayrzTimeInput`, `LayrzTimeRangeInput`, `LayrzDateTimeInput`,
/// `LayrzDateTimeRangeInput`) use to decide whether their picker surface
/// renders a 12-hour AM/PM cluster or a 24-hour digit box, replacing the
/// deprecated `use24HourFormat` flag those widgets used to read directly.
bool strftimePatternUses24HourClock(String pattern) {
  final tokens = parseStrftimePattern(pattern);
  for (final token in tokens) {
    if (token is! StrftimeDirectiveToken) continue;
    if (token.kind == StrftimeDirectiveKind.hour12 || token.kind == StrftimeDirectiveKind.meridiem) {
      return false;
    }
  }
  return true;
}

/// Returns whether [pattern] includes a seconds directive
/// ([StrftimeDirectiveKind.second2], `%S`).
///
/// [pattern] is parsed with [parseStrftimePattern] rather than scanned with
/// `String.contains`, so an escaped `%%S` (a literal `%` followed by a
/// literal `S`, not a directive) never misfires this check.
///
/// This is the single source of truth the picker inputs
/// (`LayrzTimeInput`, `LayrzTimeRangeInput`, `LayrzDateTimeInput`,
/// `LayrzDateTimeRangeInput`) use to decide whether their picker surface
/// shows a seconds column, replacing the deprecated `showSeconds` flag those
/// widgets used to read directly.
bool strftimePatternShowsSeconds(String pattern) {
  final tokens = parseStrftimePattern(pattern);
  for (final token in tokens) {
    if (token is! StrftimeDirectiveToken) continue;
    if (token.kind == StrftimeDirectiveKind.second2) return true;
  }
  return false;
}
