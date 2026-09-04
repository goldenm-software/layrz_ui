import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/login/password_strength.dart';

void main() {
  group('evaluatePasswordStrength', () {
    test('empty string scores LayrzPasswordStrength.empty', () {
      expect(evaluatePasswordStrength(''), LayrzPasswordStrength.empty);
    });

    test('a single lowercase character scores weak', () {
      expect(evaluatePasswordStrength('a'), LayrzPasswordStrength.weak);
    });

    test('7 lowercase-only characters (below the 8-char floor) scores weak', () {
      expect(evaluatePasswordStrength('abcdefg'), LayrzPasswordStrength.weak);
    });

    test('8 lowercase-only characters (single class, single length point) scores weak', () {
      expect(evaluatePasswordStrength('abcdefgh'), LayrzPasswordStrength.weak);
    });

    test('common all-lowercase dictionary word scores weak', () {
      expect(evaluatePasswordStrength('password'), LayrzPasswordStrength.weak);
    });

    test('12 lowercase-only characters (single class, both length points) scores medium', () {
      expect(evaluatePasswordStrength('abcdefghijkl'), LayrzPasswordStrength.medium);
    });

    test('8 chars mixing lower+upper (2 classes, single length point) scores medium', () {
      expect(evaluatePasswordStrength('Abcdefgh'), LayrzPasswordStrength.medium);
    });

    test('9 chars mixing upper+digit (2 classes, single length point) scores medium', () {
      expect(evaluatePasswordStrength('PASSWORD1'), LayrzPasswordStrength.medium);
    });

    test('short 4-char password with 3 classes (no length points) scores medium', () {
      expect(evaluatePasswordStrength('Ab1!'), LayrzPasswordStrength.medium);
    });

    test('9 chars mixing lower+upper+digit (3 classes, single length point) scores strong', () {
      expect(evaluatePasswordStrength('Abcdefgh1'), LayrzPasswordStrength.strong);
    });

    test('10 chars mixing all four classes scores strong', () {
      expect(evaluatePasswordStrength('Abcdefgh1!'), LayrzPasswordStrength.strong);
    });

    test('14 chars mixing lower+digit+special (long, high variety) scores strong', () {
      expect(evaluatePasswordStrength('abcdefghijkl1!'), LayrzPasswordStrength.strong);
    });

    test('11 chars mixing all four classes scores strong', () {
      expect(evaluatePasswordStrength('P@ssw0rd123'), LayrzPasswordStrength.strong);
    });

    test('is a pure function: identical input always yields identical output', () {
      const candidate = r'Some$$Candidate123';
      final first = evaluatePasswordStrength(candidate);
      final second = evaluatePasswordStrength(candidate);
      expect(first, second);
    });

    test('whitespace-only input is treated as low-variety, non-empty input', () {
      // Whitespace is not counted as any of the four scored classes, and is not
      // itself the empty string, so it must resolve to a non-empty bucket.
      expect(evaluatePasswordStrength('   '), isNot(LayrzPasswordStrength.empty));
    });
  });

  group('LayrzPasswordStrength enum', () {
    test('exposes exactly the four documented values in ascending-severity order', () {
      expect(LayrzPasswordStrength.values, [
        LayrzPasswordStrength.empty,
        LayrzPasswordStrength.weak,
        LayrzPasswordStrength.medium,
        LayrzPasswordStrength.strong,
      ]);
    });
  });
}
