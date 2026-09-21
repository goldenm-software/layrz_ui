import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('strftimePatternUses24HourClock', () {
    test('%I:%M %p is 12-hour', () {
      expect(strftimePatternUses24HourClock('%I:%M %p'), isFalse);
    });

    test('%H:%M is 24-hour', () {
      expect(strftimePatternUses24HourClock('%H:%M'), isTrue);
    });

    test('%p alone is 12-hour', () {
      expect(strftimePatternUses24HourClock('%p'), isFalse);
    });

    test('%I alone (no %p) is still 12-hour', () {
      expect(strftimePatternUses24HourClock('%I:%M'), isFalse);
    });

    test('a date-only pattern with no hour directive is 24-hour', () {
      expect(strftimePatternUses24HourClock('%Y-%m-%d'), isTrue);
    });

    test('an escaped %%I is a literal, not a directive -- stays 24-hour', () {
      expect(strftimePatternUses24HourClock('%%I:%M'), isTrue);
    });

    test('an escaped %%p is a literal, not a directive -- stays 24-hour', () {
      expect(strftimePatternUses24HourClock('%H:%M %%p'), isTrue);
    });

    test('%H:%M:%S with seconds is still 24-hour', () {
      expect(strftimePatternUses24HourClock('%H:%M:%S'), isTrue);
    });

    test('%I:%M:%S %p with seconds is still 12-hour', () {
      expect(strftimePatternUses24HourClock('%I:%M:%S %p'), isFalse);
    });
  });

  group('strftimePatternShowsSeconds', () {
    test('%I:%M %p has no seconds', () {
      expect(strftimePatternShowsSeconds('%I:%M %p'), isFalse);
    });

    test('%H:%M has no seconds', () {
      expect(strftimePatternShowsSeconds('%H:%M'), isFalse);
    });

    test('%H:%M:%S shows seconds', () {
      expect(strftimePatternShowsSeconds('%H:%M:%S'), isTrue);
    });

    test('%I:%M:%S %p shows seconds', () {
      expect(strftimePatternShowsSeconds('%I:%M:%S %p'), isTrue);
    });

    test('a date-only pattern has no seconds', () {
      expect(strftimePatternShowsSeconds('%Y-%m-%d'), isFalse);
    });

    test('an escaped %%S is a literal, not a directive -- no seconds', () {
      expect(strftimePatternShowsSeconds('%H:%M %%S'), isFalse);
    });
  });
}
