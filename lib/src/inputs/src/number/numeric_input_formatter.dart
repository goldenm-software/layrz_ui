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

  /// Whether the integer part is grouped in thousands with the separator opposite to
  /// [decimalSeparator] (see [groupSeparatorOf]), keeping the caret next to the same digit.
  final bool groupThousands;

  /// Creates a new [NumericInputFormatter] with the given configuration.
  NumericInputFormatter({
    required this.decimalSeparator,
    required this.maximumDecimalDigits,
    required this.allowNegative,
    this.groupThousands = false,
  });

  /// The thousands separator paired with [separator]: the opposite character.
  static String groupSeparatorOf(LayrzDecimalSeparator separator) {
    return separator == LayrzDecimalSeparator.dot ? ',' : '.';
  }

  /// Inserts [groupSeparator] every three digits of the leading integer run of [text]
  /// (after an optional minus); everything from the first non-digit on is left as is.
  static String groupIntegerPart(String text, String groupSeparator) {
    final start = text.startsWith('-') ? 1 : 0;
    var end = start;
    while (end < text.length && text.codeUnitAt(end) >= 48 && text.codeUnitAt(end) <= 57) {
      end++;
    }
    final digits = text.substring(start, end);
    final buffer = StringBuffer(text.substring(0, start));
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(groupSeparator);
      buffer.write(digits[i]);
    }
    buffer.write(text.substring(end));
    return buffer.toString();
  }

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
    final keptBefore = List<int>.filled(text.length + 1, 0);

    for (int i = 0; i < text.length; i++) {
      keptBefore[i] = buffer.length;
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

    keptBefore[text.length] = buffer.length;
    final formattedText = buffer.toString();

    if (groupThousands) {
      return _group(newValue, formattedText, keptBefore);
    }

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

  /// Drops redundant leading zeros from [filtered], groups its integer part and maps the
  /// selection and composing offsets of [newValue] onto the result.
  ///
  /// [keptBefore] holds, for every offset of `newValue.text`, how many characters of
  /// [filtered] come before it.
  TextEditingValue _group(TextEditingValue newValue, String filtered, List<int> keptBefore) {
    final sign = filtered.startsWith('-') ? 1 : 0;
    var zeros = 0;
    while (sign + zeros + 1 < filtered.length &&
        filtered[sign + zeros] == '0' &&
        _isDigit(filtered.codeUnitAt(sign + zeros + 1))) {
      zeros++;
    }

    final groupSeparator = groupSeparatorOf(decimalSeparator);
    final grouped = groupIntegerPart(filtered.substring(0, sign) + filtered.substring(sign + zeros), groupSeparator);
    if (grouped == newValue.text) {
      return newValue;
    }

    int map(int offset) {
      var kept = keptBefore[offset.clamp(0, newValue.text.length)];
      if (kept > sign) kept = sign + (kept - sign - zeros).clamp(0, kept);
      var mapped = 0;
      for (var seen = 0; mapped < grouped.length && seen < kept; mapped++) {
        if (grouped[mapped] != groupSeparator) seen++;
      }
      return mapped;
    }

    final selection = newValue.selection;
    final composing = newValue.composing;
    return TextEditingValue(
      text: grouped,
      selection: selection.isValid
          ? selection.copyWith(baseOffset: map(selection.baseOffset), extentOffset: map(selection.extentOffset))
          : TextSelection.collapsed(offset: grouped.length),
      composing: composing.isValid ? TextRange(start: map(composing.start), end: map(composing.end)) : TextRange.empty,
    );
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
