import 'package:flutter/services.dart';

import 'decimal_separator.dart';

/// A custom [TextInputFormatter] that enforces numeric input based on configuration.
///
/// Restricts input to digits, the configured decimal separator, and (optionally) a leading minus sign.
/// Enforces [maximumDecimalDigits] limit on the fractional part. Invalid characters are filtered out,
/// allowing intermediate typing states (empty, lone minus, trailing separator) to work smoothly.
///
/// Extracted from `number_input.dart` into its own file because Dart privacy is per-file: a
/// package-internal (not barrel-exported) type must live outside the widget file if it is to keep
/// its own concern separate, matching the precedent set by `NumberFieldControl` in
/// `number_field_edge.dart`.
class NumericInputFormatter extends TextInputFormatter {
  /// The decimal separator to accept (`.` or `,`).
  final LayrzDecimalSeparator decimalSeparator;

  /// The maximum number of decimal digits allowed.
  final int maximumDecimalDigits;

  /// Whether negative values are allowed (true if minimum is null or < 0).
  final bool allowNegative;

  /// Creates a new [NumericInputFormatter] with the given configuration.
  NumericInputFormatter({
    required this.decimalSeparator,
    required this.maximumDecimalDigits,
    required this.allowNegative,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Empty input is always allowed
    if (text.isEmpty) {
      return newValue;
    }

    // Build the separator character
    final separator = decimalSeparator == LayrzDecimalSeparator.dot ? '.' : ',';

    // Filter the text, keeping only valid characters
    final buffer = StringBuffer();
    var hasLeadingMinus = false;
    var hasSeparator = false;
    var decimalDigitCount = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Minus is allowed only at the start and only if negatives are allowed
      if (char == '-') {
        if (i == 0 && allowNegative && !hasLeadingMinus) {
          buffer.write(char);
          hasLeadingMinus = true;
          continue;
        } else {
          // Reject any other minus (not at start, or duplicates, or not allowed)
          continue;
        }
      }

      // Digits are always allowed
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        if (hasSeparator) {
          // We're in the fractional part
          if (decimalDigitCount < maximumDecimalDigits) {
            buffer.write(char);
            decimalDigitCount++;
          }
          // Skip if we exceed the decimal digit limit
        } else {
          // Before the separator
          buffer.write(char);
        }
        continue;
      }

      // The separator is allowed (once, and not if we don't allow decimals)
      if (char == separator && !hasSeparator && maximumDecimalDigits > 0) {
        buffer.write(char);
        hasSeparator = true;
        decimalDigitCount = 0;
        continue;
      }

      // Any other character is skipped (filtered out)
    }

    final formattedText = buffer.toString();

    // If the formatted text differs from the input, the user tried to enter invalid characters
    // But we still accept the valid part, so return the formatted text
    if (formattedText == text) {
      return newValue;
    } else {
      // Return the filtered text with the same selection position (or adjusted if text was shortened)
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
  }
}
