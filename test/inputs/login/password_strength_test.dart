import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/login/password_strength.dart';

void main() {
  group('LayrzPasswordRequirements.evaluate — per-requirement booleans', () {
    test('empty string meets none of the four requirements', () {
      final result = LayrzPasswordRequirements.evaluate('');
      expect(result.hasLowercase, isFalse);
      expect(result.hasUppercase, isFalse);
      expect(result.hasDigit, isFalse);
      expect(result.hasSpecial, isFalse);
    });

    test('detects a lowercase letter', () {
      expect(LayrzPasswordRequirements.evaluate('a').hasLowercase, isTrue);
      expect(LayrzPasswordRequirements.evaluate('A1!').hasLowercase, isFalse);
    });

    test('detects an uppercase letter', () {
      expect(LayrzPasswordRequirements.evaluate('A').hasUppercase, isTrue);
      expect(LayrzPasswordRequirements.evaluate('a1!').hasUppercase, isFalse);
    });

    test('detects a digit', () {
      expect(LayrzPasswordRequirements.evaluate('1').hasDigit, isTrue);
      expect(LayrzPasswordRequirements.evaluate('aA!').hasDigit, isFalse);
    });

    test('detects a special character from the exact layrz_theme set', () {
      for (final char in r'''!@#$%^&*()_-+=[]{};:'",.<>/?`~|\'''.split('')) {
        expect(
          LayrzPasswordRequirements.evaluate(char).hasSpecial,
          isTrue,
          reason: '"$char" must be recognized as a special character',
        );
      }
      expect(LayrzPasswordRequirements.evaluate('aA1').hasSpecial, isFalse);
    });

    test('a fully mixed password meets all four requirements', () {
      final result = LayrzPasswordRequirements.evaluate('Abcdefg1!');
      expect(result.hasLowercase, isTrue);
      expect(result.hasUppercase, isTrue);
      expect(result.hasDigit, isTrue);
      expect(result.hasSpecial, isTrue);
    });
  });

  group('LayrzPasswordRequirements.evaluate — allowed characters', () {
    test('a password using only allowed classes passes the whole-string check', () {
      expect(LayrzPasswordRequirements.evaluate('Abcdefg1!').hasOnlyAllowedCharacters, isTrue);
    });

    test('a disallowed character (e.g. an emoji) fails the whole-string check', () {
      expect(LayrzPasswordRequirements.evaluate('Abcdefg1!😀').hasOnlyAllowedCharacters, isFalse);
    });

    test('a disallowed character (plain space) fails the whole-string check', () {
      expect(LayrzPasswordRequirements.evaluate('Abcdefg 1!').hasOnlyAllowedCharacters, isFalse);
    });

    test('empty string fails the whole-string check (the `+` quantifier requires ≥1 char)', () {
      expect(LayrzPasswordRequirements.evaluate('').hasOnlyAllowedCharacters, isFalse);
    });
  });

  group('LayrzPasswordRequirements.isValid', () {
    test('empty password is invalid', () {
      expect(LayrzPasswordRequirements.evaluate('').isValid, isFalse);
    });

    test('a password missing one requirement (no digit) is invalid regardless of length', () {
      expect(LayrzPasswordRequirements.evaluate('Abcdefghijklmnop!').isValid, isFalse);
    });

    test('a password containing a disallowed character is invalid even if all four requirements match', () {
      // Meets lowercase/uppercase/digit/special, but the emoji is outside `allowed`.
      expect(LayrzPasswordRequirements.evaluate('Abcdefg1!😀').isValid, isFalse);
    });

    test('a password meeting all four requirements and using only allowed characters is valid', () {
      expect(LayrzPasswordRequirements.evaluate('Abcdefg1!').isValid, isTrue);
    });
  });

  group('LayrzPasswordRequirements.level — length→level boundaries', () {
    // layrz_theme's exact table: <8 -> 0, <12 -> 1, <16 -> 2, <20 -> 3, >=20 -> 4.
    // Every candidate below is otherwise fully valid (all four requirements, only
    // allowed characters), so length alone determines the level, and each boundary
    // (7/8, 11/12, 15/16, 19/20) is checked on both sides.
    String validOfLength(int length) {
      const base = 'Aa1!';
      final buffer = StringBuffer(base);
      while (buffer.length < length) {
        buffer.write('x');
      }
      return buffer.toString().substring(0, length);
    }

    test('invalid password is level 0 regardless of length', () {
      expect(LayrzPasswordRequirements.evaluate('').level, 0);
      expect(LayrzPasswordRequirements.evaluate('aaaaaaaaaaaaaaaaaaaaaaaaa').level, 0);
    });

    test('length 7 (below the 8-char floor) is level 0', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(7)).level, 0);
    });

    test('length 8 (the 8-char floor) is level 1', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(8)).level, 1);
    });

    test('length 11 (just below the 12-char floor) is level 1', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(11)).level, 1);
    });

    test('length 12 (the 12-char floor) is level 2', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(12)).level, 2);
    });

    test('length 15 (just below the 16-char floor) is level 2', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(15)).level, 2);
    });

    test('length 16 (the 16-char floor) is level 3', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(16)).level, 3);
    });

    test('length 19 (just below the 20-char floor) is level 3', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(19)).level, 3);
    });

    test('length 20 (the 20-char floor) is level 4', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(20)).level, 4);
    });

    test('a much longer valid password is still level 4', () {
      expect(LayrzPasswordRequirements.evaluate(validOfLength(40)).level, 4);
    });

    test('is a pure function: identical input always yields identical output', () {
      const candidate = r'Some$$Candidate123';
      final first = LayrzPasswordRequirements.evaluate(candidate);
      final second = LayrzPasswordRequirements.evaluate(candidate);
      expect(first, second);
    });
  });

  group('LayrzPasswordRequirements.strengthLevel', () {
    test('maps level 0 to invalid when the password is non-empty but fails validity', () {
      expect(
        LayrzPasswordRequirements.evaluate('abcdefghijklmnop').strengthLevel,
        LayrzPasswordStrengthLevel.invalid,
      );
    });

    test('maps each valid level to its named bucket', () {
      String validOfLength(int length) {
        const base = 'Aa1!';
        final buffer = StringBuffer(base);
        while (buffer.length < length) {
          buffer.write('x');
        }
        return buffer.toString().substring(0, length);
      }

      expect(
        LayrzPasswordRequirements.evaluate(validOfLength(8)).strengthLevel,
        LayrzPasswordStrengthLevel.weak,
      );
      expect(
        LayrzPasswordRequirements.evaluate(validOfLength(12)).strengthLevel,
        LayrzPasswordStrengthLevel.medium,
      );
      expect(
        LayrzPasswordRequirements.evaluate(validOfLength(16)).strengthLevel,
        LayrzPasswordStrengthLevel.strong,
      );
      expect(
        LayrzPasswordRequirements.evaluate(validOfLength(20)).strengthLevel,
        LayrzPasswordStrengthLevel.veryStrong,
      );
    });
  });

  group('LayrzPasswordStrengthLevel enum', () {
    test('exposes exactly the six documented values in ascending-severity order', () {
      expect(LayrzPasswordStrengthLevel.values, [
        LayrzPasswordStrengthLevel.invalid,
        LayrzPasswordStrengthLevel.veryWeak,
        LayrzPasswordStrengthLevel.weak,
        LayrzPasswordStrengthLevel.medium,
        LayrzPasswordStrengthLevel.strong,
        LayrzPasswordStrengthLevel.veryStrong,
      ]);
    });
  });

  group('LayrzPasswordRequirements equality', () {
    test('two evaluations of the same password are equal', () {
      expect(LayrzPasswordRequirements.evaluate('Abcdefg1!'), LayrzPasswordRequirements.evaluate('Abcdefg1!'));
    });

    test('two evaluations of different passwords are not equal', () {
      expect(
        LayrzPasswordRequirements.evaluate('Abcdefg1!'),
        isNot(LayrzPasswordRequirements.evaluate('Zyxwvut2@')),
      );
    });
  });
}
