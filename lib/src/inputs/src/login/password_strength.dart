import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// The "special character" class, matching `layrz_theme`'s exact character set:
/// `` !@#$%^&*()_-+=[]{};:'",.<>/?`~|\ ``.
///
/// Kept as its own named pattern (rather than inlined into [_requirementPatterns])
/// purely because the raw-string escaping for the embedded `'` and backslash pair is
/// easiest to get right, and easiest to audit against `layrz_theme`'s source, in
/// isolation. `RegExp`'s constructor is not `const` in Dart, so this — like every
/// other pattern in this file — is a `final` top-level, computed once at first use.
final RegExp _specialCharacterPattern = RegExp(
  r'[!@#$%^&*()_\-+=\[\]{};:'
  "'"
  r'",.<>/?`~|\\]',
);

/// The four character-class regular expressions a password is scored against,
/// matching `layrz_theme`'s `ThemedPasswordInput._ThemedPasswordInputState.requirements`
/// exactly: lowercase letter, uppercase letter, digit, and special character.
///
/// Exposed as a single list (rather than inlined at each call site) so
/// [LayrzPasswordRequirements.evaluate] stays derived from one source, instead of
/// hand-copied regex literals that could silently drift apart.
final List<RegExp> _requirementPatterns = [
  RegExp(r'[a-z]'),
  RegExp(r'[A-Z]'),
  RegExp(r'[0-9]'),
  _specialCharacterPattern,
];

/// The full "allowed characters" regex a candidate password must match in its
/// entirety for [LayrzPasswordRequirements.isValid] to hold: letters, digits, and the
/// same special-character class named in [_specialCharacterPattern].
///
/// Matches `layrz_theme`'s `ThemedPasswordInput._ThemedPasswordInputState.allowed`
/// exactly. A password containing any character outside this set (e.g. an emoji, a
/// stray whitespace character, or a Unicode letter outside `A-Za-z`) fails validity
/// regardless of how many of the four [_requirementPatterns] it otherwise satisfies —
/// this is a WHOLE-STRING anchor (`^...+$`), not a per-character allow-check.
final RegExp _allowedCharacters = RegExp(
  r'^[A-Za-z\d!@#$%^&*()_\-+=\[\]{};:'
  "'"
  r'",.<>/?`~|\\]+$',
);

/// The 0–4 strength bucket [LayrzPasswordRequirements.level] assigns to a password,
/// by length, once it has already passed every requirement in
/// [LayrzPasswordRequirements.isValid].
///
/// This enum exists purely so call sites can pattern-match on the bucket name instead
/// of a bare `int`; [LayrzPasswordRequirements.level] is still the canonical `0`–`4`
/// integer the rest of this module (and the meter) actually keys off of. See
/// [LayrzPasswordRequirements.level]'s own doc comment for the exact length
/// boundaries this mirrors.
enum LayrzPasswordStrengthLevel {
  /// Not a valid password (empty, missing a required character class, or containing
  /// a disallowed character) — always level 0 regardless of length.
  invalid,

  /// Valid, but shorter than 8 characters.
  veryWeak,

  /// Valid, 8–11 characters.
  weak,

  /// Valid, 12–15 characters.
  medium,

  /// Valid, 16–19 characters.
  strong,

  /// Valid, 20 characters or longer.
  veryStrong,
}

/// Per-requirement pass/fail flags plus the derived validity, 0–4 level, and semantic
/// color for one password value — computed by the EXACT rules `layrz_theme`'s
/// `ThemedPasswordInput` uses (see `password_input.dart` in the `layrz_theme` package,
/// `_ThemedPasswordInputState.requirements`/`.allowed`/`._isValid`/`._level`/`._color`),
/// so the two design systems' password-strength readings never disagree for the same
/// input.
///
/// This is a pure value class — no Flutter widget dependency beyond [Color]/[Icon]
/// import surface needed for [colorFor], so it is trivially unit-testable outside any
/// widget tree. Construct it via [LayrzPasswordRequirements.evaluate].
@immutable
class LayrzPasswordRequirements {
  /// Whether [password] contains at least one ASCII lowercase letter (`a`–`z`).
  final bool hasLowercase;

  /// Whether [password] contains at least one ASCII uppercase letter (`A`–`Z`).
  final bool hasUppercase;

  /// Whether [password] contains at least one ASCII digit (`0`–`9`).
  final bool hasDigit;

  /// Whether [password] contains at least one special character, from the exact set
  /// `` !@#$%^&*()_-+=[]{};:'",.<>/?`~|\ `` (matching `layrz_theme`'s special-character
  /// requirement).
  final bool hasSpecial;

  /// Whether every character in [password] belongs to one of the allowed classes
  /// (letters, digits, or the [hasSpecial] set) — the whole-string check
  /// `layrz_theme` calls `allowed`. A password with even one character outside this
  /// set (e.g. an emoji or a Unicode letter outside `A-Za-z`) fails this check
  /// regardless of [hasLowercase]/[hasUppercase]/[hasDigit]/[hasSpecial].
  final bool hasOnlyAllowedCharacters;

  /// The exact password value this result was computed from.
  ///
  /// Kept only so [level] can re-read its length; not otherwise consulted by any
  /// getter on this class.
  final String password;

  /// Creates a [LayrzPasswordRequirements] snapshot. Use [LayrzPasswordRequirements.evaluate]
  /// rather than calling this directly, unless constructing a value for a test.
  const LayrzPasswordRequirements({
    required this.hasLowercase,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSpecial,
    required this.hasOnlyAllowedCharacters,
    required this.password,
  });

  /// Evaluates [password] against every requirement and the allowed-character check,
  /// matching `layrz_theme`'s `_matches`/`allowed` computation exactly.
  factory LayrzPasswordRequirements.evaluate(String password) {
    return LayrzPasswordRequirements(
      hasLowercase: _requirementPatterns[0].hasMatch(password),
      hasUppercase: _requirementPatterns[1].hasMatch(password),
      hasDigit: _requirementPatterns[2].hasMatch(password),
      hasSpecial: _requirementPatterns[3].hasMatch(password),
      hasOnlyAllowedCharacters: _allowedCharacters.hasMatch(password),
      password: password,
    );
  }

  /// Whether [password] is a fully valid password: non-empty, matches
  /// [hasOnlyAllowedCharacters] (every character belongs to an allowed class), AND
  /// satisfies all four requirements ([hasLowercase], [hasUppercase], [hasDigit],
  /// [hasSpecial]).
  ///
  /// Matches `layrz_theme`'s `_isValid` exactly: an empty password, one containing a
  /// disallowed character, or one missing even a single required class is invalid —
  /// there is no partial-credit "mostly valid" state.
  bool get isValid {
    if (password.isEmpty) return false;
    if (!hasOnlyAllowedCharacters) return false;
    return hasLowercase && hasUppercase && hasDigit && hasSpecial;
  }

  /// The 0–4 strength level, matching `layrz_theme`'s `_level` exactly.
  ///
  /// An invalid password (per [isValid]) is always level 0, regardless of length.
  /// Otherwise the level is determined purely by [password]'s length:
  ///
  /// | Length | Level |
  /// |---|---|
  /// | < 8 | 0 |
  /// | 8–11 | 1 |
  /// | 12–15 | 2 |
  /// | 16–19 | 3 |
  /// | ≥ 20 | 4 |
  int get level {
    if (!isValid) return 0;
    final length = password.length;
    if (length < 8) return 0;
    if (length < 12) return 1;
    if (length < 16) return 2;
    if (length < 20) return 3;
    return 4;
  }

  /// The [LayrzPasswordStrengthLevel] bucket name for [level], for callers that
  /// prefer to pattern-match on a named bucket instead of a bare integer.
  LayrzPasswordStrengthLevel get strengthLevel {
    switch (level) {
      case 0:
        return isValid ? LayrzPasswordStrengthLevel.veryWeak : LayrzPasswordStrengthLevel.invalid;
      case 1:
        return LayrzPasswordStrengthLevel.weak;
      case 2:
        return LayrzPasswordStrengthLevel.medium;
      case 3:
        return LayrzPasswordStrengthLevel.strong;
      default:
        return LayrzPasswordStrengthLevel.veryStrong;
    }
  }

  /// Resolves the semantic color for [level] from [colors], matching `layrz_theme`'s
  /// `_color` mapping exactly (level 0 → danger/red, 1–2 → warning/orange, 3–4 →
  /// success/green) but sourced from layrz_ui's own [LayrzColorTokens] instead of
  /// Material's `Colors.red`/`Colors.orange`/`Colors.green` — `layrz_theme` hardcodes
  /// Material colors because it is built on Material; layrz_ui has no Material
  /// dependency, so the equivalent semantic tokens are used instead. `.shade500` is
  /// each swatch's canonical, undiluted tone (matching the plain `Colors.red` etc.
  /// `layrz_theme` uses, which is also each Material color's 500 shade).
  Color colorFor(LayrzColorTokens colors) {
    switch (level) {
      case 0:
        return colors.danger.shade500;
      case 1:
      case 2:
        return colors.warning.shade500;
      default:
        return colors.success.shade500;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzPasswordRequirements &&
          runtimeType == other.runtimeType &&
          hasLowercase == other.hasLowercase &&
          hasUppercase == other.hasUppercase &&
          hasDigit == other.hasDigit &&
          hasSpecial == other.hasSpecial &&
          hasOnlyAllowedCharacters == other.hasOnlyAllowedCharacters &&
          password == other.password;

  @override
  int get hashCode => Object.hash(
    hasLowercase,
    hasUppercase,
    hasDigit,
    hasSpecial,
    hasOnlyAllowedCharacters,
    password,
  );
}
