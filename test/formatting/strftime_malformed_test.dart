import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  const l10n = LayrzUiL10nDefault();
  final reference = DateTime(2026, 9, 16, 14, 5, 9);

  group('formatStrftime — malformed/unsupported directives never throw', () {
    test('an unsupported directive letter passes through literally', () {
      expect(() => formatStrftime(reference, '%Q', l10n), returnsNormally);
      expect(formatStrftime(reference, '%Q', l10n), '%Q');
    });

    test('a trailing lone percent passes through literally', () {
      expect(() => formatStrftime(reference, 'value: %', l10n), returnsNormally);
      expect(formatStrftime(reference, 'value: %', l10n), 'value: %');
    });

    test('an unsupported directive mixed with a supported one only fails the unsupported part', () {
      expect(formatStrftime(reference, '%Y-%Q-%d', l10n), '2026-%Q-16');
    });

    test('multiple unsupported directives in one pattern all pass through', () {
      expect(formatStrftime(reference, '%Q%W%Z', l10n), '%Q%W%Z');
    });

    test('a lowercase-vs-uppercase unsupported letter is not silently coerced to a supported directive', () {
      // 'z' (lowercase) is not in the supported set even though other
      // lowercase directives exist -- it must pass through, not resolve to
      // some other directive.
      expect(formatStrftime(reference, '%z', l10n), '%z');
    });

    test('an empty pattern renders to an empty string without throwing', () {
      expect(() => formatStrftime(reference, '', l10n), returnsNormally);
      expect(formatStrftime(reference, '', l10n), '');
    });

    test('a pattern that is entirely unsupported directives round-trips unchanged', () {
      expect(formatStrftime(reference, '%Q%%%W', l10n), '%Q%%W');
    });
  });
}
