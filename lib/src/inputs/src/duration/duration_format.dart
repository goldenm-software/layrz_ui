import 'duration_input.dart';

/// The display format for a [LayrzDurationInput]'s summary text.
///
/// Controls how a picked [Duration] is rendered inside the anchor field once
/// decomposed into its visible units. Both values read their unit tokens
/// from `LayrzUiL10n` (the `durationUnit*` getters) — no abbreviation or word
/// literal is ever hardcoded in the widget itself, so both formats translate
/// correctly under any locale.
///
/// Exactly two values exist, deliberately: this repository trims enums to
/// what is actually asked for (see decisions D27/D28), and no third format —
/// nor a caller-supplied `valueFormatter` callback — was requested.
enum LayrzDurationFormat {
  /// Abbreviated summary, e.g. `"2h 30m"`.
  ///
  /// Each visible, non-zero unit is rendered as its numeric value directly
  /// followed by its localized abbreviation (no space between them), and the
  /// resulting parts are joined with a single space. The abbreviation for
  /// each unit comes from the `durationUnit*Short{Singular,Plural}` getters
  /// on `LayrzUiL10n`.
  short,

  /// Fully spelled-out summary, e.g. `"2 hours, 30 minutes"`.
  ///
  /// Each visible, non-zero unit is rendered as its numeric value followed
  /// by a space and its localized singular/plural word, and the resulting
  /// parts are joined with `", "`. This is the format [LayrzDurationInput]
  /// rendered before [LayrzDurationFormat] existed, preserved unchanged and
  /// kept as the default so existing callers see no behavior change.
  long,
}
