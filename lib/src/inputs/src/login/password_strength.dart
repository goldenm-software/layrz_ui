/// Discrete strength levels a password can be scored into.
///
/// The scale is deliberately coarse (four buckets) so the meter reads as a quick,
/// glanceable signal rather than a precise measurement. This enum is pure — it has no
/// Flutter dependency and can be used, tested, and reasoned about outside any widget
/// tree.
///
/// **Login-field usage note:** on a login field the user is typically authenticating
/// with a password they already chose and cannot change from that screen. A strength
/// reading there is informational only, never a call to action — see
/// [LayrzPasswordStrengthMeter] (in `password_strength_meter.dart`) for the styling
/// rule this implies (never danger-red).
enum LayrzPasswordStrength {
  /// The input is empty. Distinct from [weak] so a meter can render "nothing typed
  /// yet" (e.g. an empty/neutral track) instead of implying the user already typed a
  /// bad password.
  empty,

  /// The password is short and/or draws from very few character classes.
  ///
  /// Easily guessed or brute-forced; the weakest non-empty bucket.
  weak,

  /// The password has moderate length and mixes some character classes.
  ///
  /// Better than [weak] but still missing either sufficient length or enough
  /// character-class variety to be considered strong.
  medium,

  /// The password is long and mixes multiple character classes.
  ///
  /// The strongest bucket this scale recognizes.
  strong,
}

/// Returns true if [character] is an ASCII lowercase letter (`a`–`z`).
bool _isLowercase(String character) => character.contains(RegExp(r'[a-z]'));

/// Returns true if [character] is an ASCII uppercase letter (`A`–`Z`).
bool _isUppercase(String character) => character.contains(RegExp(r'[A-Z]'));

/// Returns true if [character] is an ASCII digit (`0`–`9`).
bool _isDigit(String character) => character.contains(RegExp(r'[0-9]'));

/// Returns true if [character] is a special (non-alphanumeric, non-whitespace)
/// character, e.g. `!@#$%^&*`.
///
/// This mirrors the "special character" requirement named in
/// `LayrzUiL10nPasswordMixin.passwordRequirementsSpecialCharacter` — the same
/// criterion concept, reused here as a scoring signal instead of a pass/fail
/// validator message.
bool _isSpecial(String character) => character.contains(RegExp(r'[^a-zA-Z0-9\s]'));

/// Scores [password] into a [LayrzPasswordStrength] bucket using length and
/// character-class heuristics.
///
/// The heuristic is intentionally simple and pure (no async, no I/O, no Flutter
/// dependency) so it is trivially unit-testable and reusable outside a widget:
///
/// 1. An empty [password] always scores [LayrzPasswordStrength.empty].
/// 2. Otherwise, the function counts how many of the four character classes named in
///    `LayrzUiL10nPasswordMixin` are present at least once: lowercase letter, uppercase
///    letter, digit, and special character. This count (0–4) is the "variety" score.
/// 3. Length and variety are combined into a single 0–2 point scale:
///    - +1 point if [password] has at least 8 characters, +1 more if it has at least
///      12 characters (0, 1, or 2 length points).
///    - +1 point if variety is at least 2 classes, +1 more if variety is at least 3
///      classes (0, 1, or 2 variety points).
/// 4. The two 0–2 sub-scores are summed into a combined 0–4 score, which is then
///    mapped to a bucket: 0–1 → [LayrzPasswordStrength.weak], 2 →
///    [LayrzPasswordStrength.medium], 3–4 → [LayrzPasswordStrength.strong].
///
/// [password] is the raw candidate password text to score. Passing an empty string
/// always yields [LayrzPasswordStrength.empty] regardless of any other characteristic
/// (there is nothing to score).
///
/// Returns the [LayrzPasswordStrength] bucket the heuristic assigns to [password].
LayrzPasswordStrength evaluatePasswordStrength(String password) {
  if (password.isEmpty) {
    return LayrzPasswordStrength.empty;
  }

  var hasLowercase = false;
  var hasUppercase = false;
  var hasDigit = false;
  var hasSpecial = false;

  for (final rune in password.runes) {
    final character = String.fromCharCode(rune);
    if (!hasLowercase && _isLowercase(character)) {
      hasLowercase = true;
    } else if (!hasUppercase && _isUppercase(character)) {
      hasUppercase = true;
    } else if (!hasDigit && _isDigit(character)) {
      hasDigit = true;
    } else if (!hasSpecial && _isSpecial(character)) {
      hasSpecial = true;
    }
  }

  final variety = [hasLowercase, hasUppercase, hasDigit, hasSpecial].where((present) => present).length;

  var lengthScore = 0;
  if (password.length >= 8) {
    lengthScore++;
  }
  if (password.length >= 12) {
    lengthScore++;
  }

  var varietyScore = 0;
  if (variety >= 2) {
    varietyScore++;
  }
  if (variety >= 3) {
    varietyScore++;
  }

  final combinedScore = lengthScore + varietyScore;

  if (combinedScore <= 1) {
    return LayrzPasswordStrength.weak;
  }
  if (combinedScore == 2) {
    return LayrzPasswordStrength.medium;
  }
  return LayrzPasswordStrength.strong;
}
