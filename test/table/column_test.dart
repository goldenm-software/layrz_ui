import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/table/src/column.dart';

void main() {
  group('LayrzColumn', () {
    test('constructor assigns required fields and documented defaults', () {
      final column = LayrzColumn<int>(
        key: const ValueKey('col'),
        headerText: 'Amount',
        valueBuilder: (item) => '$item',
      );

      expect(column.key, const ValueKey('col'));
      expect(column.headerText, 'Amount');
      expect(column.valueBuilder(42), '42');
      expect(column.richTextBuilder, isNull);
      expect(column.alignment, Alignment.centerLeft);
      expect(column.isSortable, isTrue);
      expect(column.width, isNull);
      expect(column.onTap, isNull);
      expect(column.customSort, isNull);
    });

    test('constructor honors every explicit override', () {
      void onTap(int item) {}
      int customSort(int a, int b, bool ascending) => 0;
      List<InlineSpan> richText(int item) => [TextSpan(text: '$item')];

      final column = LayrzColumn<int>(
        key: const ValueKey('col'),
        headerText: 'Amount',
        valueBuilder: (item) => '$item',
        richTextBuilder: richText,
        alignment: Alignment.centerRight,
        isSortable: false,
        width: 120,
        onTap: onTap,
        customSort: customSort,
      );

      expect(column.richTextBuilder, richText);
      expect(column.alignment, Alignment.centerRight);
      expect(column.isSortable, isFalse);
      expect(column.width, 120);
      expect(column.onTap, onTap);
      expect(column.customSort, customSort);
    });

    group('copyWith', () {
      test('replaces only the given fields, keeping the rest', () {
        final original = LayrzColumn<int>(
          key: const ValueKey('col'),
          headerText: 'Amount',
          valueBuilder: (item) => '$item',
        );

        final copy = original.copyWith(headerText: 'Total', isSortable: false);

        expect(copy.headerText, 'Total');
        expect(copy.isSortable, isFalse);
        expect(copy.key, original.key);
        expect(copy.valueBuilder, original.valueBuilder);
        expect(copy.alignment, original.alignment);
        expect(copy.width, original.width);
      });

      test('with no arguments preserves every field', () {
        String valueBuilder(int item) => '$item';
        final original = LayrzColumn<int>(
          key: const ValueKey('col'),
          headerText: 'Amount',
          valueBuilder: valueBuilder,
          alignment: Alignment.centerRight,
          isSortable: false,
          width: 80,
        );

        final copy = original.copyWith();

        expect(copy.key, original.key);
        expect(copy.headerText, original.headerText);
        expect(copy.valueBuilder, original.valueBuilder);
        expect(copy.alignment, original.alignment);
        expect(copy.isSortable, original.isSortable);
        expect(copy.width, original.width);
      });

      test('can replace the key itself', () {
        final original = LayrzColumn<int>(
          key: const ValueKey('col-a'),
          headerText: 'Amount',
          valueBuilder: (item) => '$item',
        );

        final copy = original.copyWith(key: const ValueKey('col-b'));

        expect(copy.key, const ValueKey('col-b'));
        expect(copy, isNot(original));
      });
    });

    group('equality', () {
      test('two columns of the same type with the same key are equal', () {
        final a = LayrzColumn<int>(key: const ValueKey('col'), headerText: 'A', valueBuilder: (item) => '$item');
        final b = LayrzColumn<int>(key: const ValueKey('col'), headerText: 'B', valueBuilder: (item) => 'different');

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('columns of the same type with different keys are unequal', () {
        final a = LayrzColumn<int>(key: const ValueKey('col-a'), headerText: 'A', valueBuilder: (item) => '$item');
        final b = LayrzColumn<int>(key: const ValueKey('col-b'), headerText: 'A', valueBuilder: (item) => '$item');

        expect(a == b, isFalse);
      });

      test('LayrzColumn<int> and LayrzColumn<String> with the same Key are UNEQUAL', () {
        final intColumn = LayrzColumn<int>(
          key: const ValueKey('shared'),
          headerText: 'A',
          valueBuilder: (item) => '$item',
        );
        final stringColumn = LayrzColumn<String>(
          key: const ValueKey('shared'),
          headerText: 'A',
          valueBuilder: (item) => item,
        );

        // ignore: unrelated_type_equality_checks
        expect(intColumn == stringColumn, isFalse);
        expect(intColumn.runtimeType == stringColumn.runtimeType, isFalse);
      });

      test('a column is equal to itself (identical)', () {
        final a = LayrzColumn<int>(key: const ValueKey('col'), headerText: 'A', valueBuilder: (item) => '$item');

        expect(a == a, isTrue);
      });

      test('a column is not equal to an unrelated object', () {
        final a = LayrzColumn<int>(key: const ValueKey('col'), headerText: 'A', valueBuilder: (item) => '$item');

        // ignore: unrelated_type_equality_checks
        expect(a == 'not a column', isFalse);
      });
    });
  });
}
