import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_error.dart';

void main() {
  group('LayrzCodeError', () {
    test('stores the given fields', () {
      const error = LayrzCodeError(line: 3, column: 7, message: 'Unexpected token');

      expect(error.line, 3);
      expect(error.column, 7);
      expect(error.message, 'Unexpected token');
    });

    test('equal instances compare equal and share a hashCode', () {
      const a = LayrzCodeError(line: 1, column: 2, message: 'oops');
      const b = LayrzCodeError(line: 1, column: 2, message: 'oops');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing line makes instances unequal', () {
      const a = LayrzCodeError(line: 1, column: 2, message: 'oops');
      const b = LayrzCodeError(line: 2, column: 2, message: 'oops');

      expect(a, isNot(equals(b)));
    });

    test('differing column makes instances unequal', () {
      const a = LayrzCodeError(line: 1, column: 2, message: 'oops');
      const b = LayrzCodeError(line: 1, column: 3, message: 'oops');

      expect(a, isNot(equals(b)));
    });

    test('differing message makes instances unequal', () {
      const a = LayrzCodeError(line: 1, column: 2, message: 'oops');
      const b = LayrzCodeError(line: 1, column: 2, message: 'different');

      expect(a, isNot(equals(b)));
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzCodeError(line: 1, column: 2, message: 'oops');
      final copy = original.copyWith(message: 'fixed');

      expect(copy.line, original.line);
      expect(copy.column, original.column);
      expect(copy.message, 'fixed');
    });

    test('copyWith with no arguments returns an equal instance', () {
      const original = LayrzCodeError(line: 5, column: 9, message: 'oops');
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('toString is human-readable and includes all fields', () {
      const error = LayrzCodeError(line: 4, column: 8, message: 'bad syntax');
      final text = error.toString();

      expect(text, contains('4'));
      expect(text, contains('8'));
      expect(text, contains('bad syntax'));
    });
  });
}
