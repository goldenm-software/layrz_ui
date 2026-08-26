/// Specifies the decimal separator used when parsing and formatting numbers.
///
/// This enum allows callers to control how numbers are parsed and displayed,
/// independent of device locale. The choice is explicit and does not change
/// when the app's locale changes, avoiding silent parsing bugs.
enum LayrzDecimalSeparator {
  /// Uses a dot (.) as the decimal separator, e.g., "3.14".
  dot,

  /// Uses a comma (,) as the decimal separator, e.g., "3,14".
  comma,
}
