import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('parseStrftimePattern', () {
    test('a pattern with no directives parses to a single literal token', () {
      final tokens = parseStrftimePattern('plain text');
      expect(tokens, [const StrftimeLiteralToken('plain text')]);
    });

    test('a single directive parses to a single directive token', () {
      final tokens = parseStrftimePattern('%Y');
      expect(tokens, [const StrftimeDirectiveToken(StrftimeDirectiveKind.year4)]);
    });

    test('literal text and a directive interleave correctly', () {
      final tokens = parseStrftimePattern('Year: %Y!');
      expect(tokens, [
        const StrftimeLiteralToken('Year: '),
        const StrftimeDirectiveToken(StrftimeDirectiveKind.year4),
        const StrftimeLiteralToken('!'),
      ]);
    });

    test('consecutive directives with no literal between them parse separately', () {
      final tokens = parseStrftimePattern('%Y%m%d');
      expect(tokens, [
        const StrftimeDirectiveToken(StrftimeDirectiveKind.year4),
        const StrftimeDirectiveToken(StrftimeDirectiveKind.month2),
        const StrftimeDirectiveToken(StrftimeDirectiveKind.day2),
      ]);
    });

    test('an empty pattern parses to no tokens', () {
      expect(parseStrftimePattern(''), isEmpty);
    });

    test('every directive letter maps to the expected kind', () {
      const expectedByChar = {
        'Y': StrftimeDirectiveKind.year4,
        'y': StrftimeDirectiveKind.year2,
        'm': StrftimeDirectiveKind.month2,
        'd': StrftimeDirectiveKind.day2,
        'H': StrftimeDirectiveKind.hour24,
        'I': StrftimeDirectiveKind.hour12,
        'M': StrftimeDirectiveKind.minute2,
        'S': StrftimeDirectiveKind.second2,
        'B': StrftimeDirectiveKind.monthNameFull,
        'b': StrftimeDirectiveKind.monthNameAbbreviated,
        'A': StrftimeDirectiveKind.weekdayNameFull,
        'a': StrftimeDirectiveKind.weekdayNameAbbreviated,
        'p': StrftimeDirectiveKind.meridiem,
        'j': StrftimeDirectiveKind.dayOfYear3,
        '%': StrftimeDirectiveKind.literalPercent,
      };

      for (final entry in expectedByChar.entries) {
        final tokens = parseStrftimePattern('%${entry.key}');
        expect(tokens, [StrftimeDirectiveToken(entry.value)], reason: 'directive %${entry.key}');
      }
    });
  });

  group('StrftimeLiteralToken', () {
    test('equality and hashCode are value-based', () {
      const a = StrftimeLiteralToken('x');
      const b = StrftimeLiteralToken('x');
      const c = StrftimeLiteralToken('y');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString includes the literal text', () {
      expect(const StrftimeLiteralToken('hello').toString(), contains('hello'));
    });
  });

  group('StrftimeDirectiveToken', () {
    test('equality and hashCode are value-based', () {
      const a = StrftimeDirectiveToken(StrftimeDirectiveKind.year4);
      const b = StrftimeDirectiveToken(StrftimeDirectiveKind.year4);
      const c = StrftimeDirectiveToken(StrftimeDirectiveKind.year2);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString includes the kind', () {
      expect(const StrftimeDirectiveToken(StrftimeDirectiveKind.year4).toString(), contains('year4'));
    });
  });
}
