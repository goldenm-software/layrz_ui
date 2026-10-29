import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/number/numeric_input_formatter.dart';

TextEditingValue _edit(NumericInputFormatter formatter, String text, int caret) {
  return formatter.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    ),
  );
}

void main() {
  group('NumericInputFormatter', () {
    test('without groupThousands the integer part is left ungrouped', () {
      final formatter = NumericInputFormatter(
        decimalSeparator: LayrzDecimalSeparator.comma,
        maximumDecimalDigits: 4,
        allowNegative: true,
      );

      final result = _edit(formatter, '12000,5', 7);

      expect(result.text, '12000,5');
      expect(result.selection, const TextSelection.collapsed(offset: 7));
    });

    group('groupThousands', () {
      NumericInputFormatter formatterFor(LayrzDecimalSeparator separator) => NumericInputFormatter(
        decimalSeparator: separator,
        maximumDecimalDigits: 4,
        allowNegative: true,
        groupThousands: true,
      );

      test('comma separator groups with dots: 12000,5 -> 12.000,5', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.comma), '12000,5', 7);

        expect(result.text, '12.000,5');
        expect(result.selection, const TextSelection.collapsed(offset: 8));
      });

      test('dot separator groups with commas: 12000.5 -> 12,000.5', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.dot), '12000.5', 7);

        expect(result.text, '12,000.5');
        expect(result.selection, const TextSelection.collapsed(offset: 8));
      });

      test('typing a digit at the end regroups and keeps the caret at the end', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.comma), '1.2345', 6);

        expect(result.text, '12.345');
        expect(result.selection, const TextSelection.collapsed(offset: 6));
      });

      test('deleting in the middle keeps the caret after the same digit', () {
        // "1.234.567" with the "2" deleted, caret right after the "1."
        final result = _edit(formatterFor(LayrzDecimalSeparator.comma), '1.34.567', 2);

        expect(result.text, '134.567');
        expect(result.selection, const TextSelection.collapsed(offset: 1));
      });

      test('the fractional part is never grouped', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.dot), '1234.5678', 9);

        expect(result.text, '1,234.5678');
      });

      test('a leading minus stays outside the groups', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.comma), '-1234', 5);

        expect(result.text, '-1.234');
        expect(result.selection, const TextSelection.collapsed(offset: 6));
      });

      test('a trailing decimal separator is kept while typing', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.comma), '12.000,', 7);

        expect(result.text, '12.000,');
        expect(result.selection, const TextSelection.collapsed(offset: 7));
      });

      test('pasting an already grouped value keeps its grouping', () {
        final result = _edit(formatterFor(LayrzDecimalSeparator.comma), '1.234.567,89', 12);

        expect(result.text, '1.234.567,89');
      });
    });
  });
}
