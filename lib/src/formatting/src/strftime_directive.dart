/// One parsed token of a strftime-style format string.
///
/// A format string is parsed into a flat list of [StrftimeToken]s before
/// rendering — either a [StrftimeLiteralToken] (plain text copied through
/// unchanged) or a [StrftimeDirectiveToken] (a `%`-prefixed directive that
/// resolves against a [DateTime] and, for name-producing directives, an
/// `LayrzUiL10n` instance). Splitting parsing from rendering keeps the
/// malformed-directive pass-through rule (see `strftime.dart`) in one place:
/// an unrecognized directive is simply parsed as a [StrftimeLiteralToken]
/// carrying its own source text, so rendering never needs a special case for
/// "unknown directive" — it already reads as literal text by the time
/// rendering sees it.
sealed class StrftimeToken {
  /// Creates a new [StrftimeToken].
  const StrftimeToken();
}

/// A run of plain text copied verbatim into the formatted output.
final class StrftimeLiteralToken extends StrftimeToken {
  /// The literal text this token contributes to the output.
  final String text;

  /// Creates a new [StrftimeLiteralToken].
  const StrftimeLiteralToken(this.text);

  @override
  bool operator ==(Object other) => identical(this, other) || (other is StrftimeLiteralToken && other.text == text);

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'StrftimeLiteralToken($text)';
}

/// A single supported strftime directive, e.g. `%Y` or `%B`.
///
/// The enum name matches the directive letter for readability; the actual
/// character consumed from the format string is not stored here because
/// resolution never needs it — only the parser (`strftime.dart`) maps a
/// character to a member of this enum.
enum StrftimeDirectiveKind {
  /// `%Y` — four-digit year, e.g. `2026`.
  year4,

  /// `%y` — two-digit year, zero-padded, e.g. `26`.
  year2,

  /// `%m` — month number, zero-padded, `01`–`12`.
  month2,

  /// `%d` — day of month, zero-padded, `01`–`31`.
  day2,

  /// `%H` — hour in 24-hour form, zero-padded, `00`–`23`.
  hour24,

  /// `%I` — hour in 12-hour form, zero-padded, `01`–`12`.
  hour12,

  /// `%M` — minute, zero-padded, `00`–`59`.
  minute2,

  /// `%S` — second, zero-padded, `00`–`59`.
  second2,

  /// `%B` — full, localized month name, e.g. `September`.
  monthNameFull,

  /// `%b` — abbreviated, localized month name, e.g. `Sep`.
  monthNameAbbreviated,

  /// `%A` — full, localized weekday name, e.g. `Wednesday`.
  weekdayNameFull,

  /// `%a` — abbreviated, localized weekday name, e.g. `Wed`.
  weekdayNameAbbreviated,

  /// `%p` — localized meridiem marker (AM/PM).
  meridiem,

  /// `%j` — day of year, zero-padded, `001`–`366`.
  dayOfYear3,

  /// `%%` — a literal `%` character.
  literalPercent,
}

/// A parsed `%`-directive, resolved against a [DateTime] and, for
/// name-producing directives, localized strings at render time.
final class StrftimeDirectiveToken extends StrftimeToken {
  /// Which directive this token represents.
  final StrftimeDirectiveKind kind;

  /// Creates a new [StrftimeDirectiveToken].
  const StrftimeDirectiveToken(this.kind);

  @override
  bool operator ==(Object other) => identical(this, other) || (other is StrftimeDirectiveToken && other.kind == kind);

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'StrftimeDirectiveToken($kind)';
}
