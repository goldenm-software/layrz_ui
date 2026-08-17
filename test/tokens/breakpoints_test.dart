import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzBreakpointTokens', () {
    group('default constructor', () {
      test('uses correct default values', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.xs, equals(600.0));
        expect(tokens.sm, equals(960.0));
        expect(tokens.md, equals(1264.0));
        expect(tokens.lg, equals(1904.0));
      });

      test('threshold values are strictly ascending', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.xs < tokens.sm, isTrue);
        expect(tokens.sm < tokens.md, isTrue);
        expect(tokens.md < tokens.lg, isTrue);
      });
    });

    group('bandAt: band resolution at default thresholds', () {
      test('width < xs threshold maps to xs band', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(0), equals(LayrzBreakpoint.xs));
        expect(tokens.bandAt(100), equals(LayrzBreakpoint.xs));
        expect(tokens.bandAt(599.9), equals(LayrzBreakpoint.xs));
      });

      test('xs <= width < sm threshold maps to sm band', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(600.0), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(700), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(959.9), equals(LayrzBreakpoint.sm));
      });

      test('sm <= width < md threshold maps to md band', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(960.0), equals(LayrzBreakpoint.md));
        expect(tokens.bandAt(1100), equals(LayrzBreakpoint.md));
        expect(tokens.bandAt(1263.9), equals(LayrzBreakpoint.md));
      });

      test('md <= width < lg threshold maps to lg band', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(1264.0), equals(LayrzBreakpoint.lg));
        expect(tokens.bandAt(1500), equals(LayrzBreakpoint.lg));
        expect(tokens.bandAt(1903.9), equals(LayrzBreakpoint.lg));
      });

      test('width >= lg threshold maps to xl band', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(1904.0), equals(LayrzBreakpoint.xl));
        expect(tokens.bandAt(2000), equals(LayrzBreakpoint.xl));
        expect(tokens.bandAt(4000), equals(LayrzBreakpoint.xl));
      });
    });

    group('bandAt: band resolution with custom thresholds', () {
      test('custom xs threshold changes xs/sm boundary', () {
        const tokens = LayrzBreakpointTokens(xs: 500.0);

        expect(tokens.bandAt(400), equals(LayrzBreakpoint.xs));
        expect(tokens.bandAt(499.9), equals(LayrzBreakpoint.xs));
        expect(tokens.bandAt(500.0), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(550), equals(LayrzBreakpoint.sm));
      });

      test('custom sm threshold changes sm/md boundary', () {
        const tokens = LayrzBreakpointTokens(sm: 1000.0);

        expect(tokens.bandAt(600), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(999.9), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(1000.0), equals(LayrzBreakpoint.md));
        expect(tokens.bandAt(1100), equals(LayrzBreakpoint.md));
      });

      test('all custom thresholds work together', () {
        const tokens = LayrzBreakpointTokens(
          xs: 400.0,
          sm: 800.0,
          md: 1200.0,
          lg: 1800.0,
        );

        expect(tokens.bandAt(300), equals(LayrzBreakpoint.xs));
        expect(tokens.bandAt(500), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(1000), equals(LayrzBreakpoint.md));
        expect(tokens.bandAt(1500), equals(LayrzBreakpoint.lg));
        expect(tokens.bandAt(2000), equals(LayrzBreakpoint.xl));
      });
    });

    group('bandAt: exact boundary values', () {
      test('599.9 is xs, 600.0 is sm', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(599.9), equals(LayrzBreakpoint.xs));
        expect(tokens.bandAt(600.0), equals(LayrzBreakpoint.sm));
      });

      test('959.9 is sm, 960.0 is md', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(959.9), equals(LayrzBreakpoint.sm));
        expect(tokens.bandAt(960.0), equals(LayrzBreakpoint.md));
      });

      test('1263.9 is md, 1264.0 is lg', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(1263.9), equals(LayrzBreakpoint.md));
        expect(tokens.bandAt(1264.0), equals(LayrzBreakpoint.lg));
      });

      test('1903.9 is lg, 1904.0 is xl', () {
        const tokens = LayrzBreakpointTokens();

        expect(tokens.bandAt(1903.9), equals(LayrzBreakpoint.lg));
        expect(tokens.bandAt(1904.0), equals(LayrzBreakpoint.xl));
      });
    });

    group('copyWith', () {
      test('copies with single field override', () {
        const original = LayrzBreakpointTokens();
        final modified = original.copyWith(xs: 500.0);

        expect(modified.xs, equals(500.0));
        expect(modified.sm, equals(original.sm));
        expect(modified.md, equals(original.md));
        expect(modified.lg, equals(original.lg));
      });

      test('copies with multiple field overrides', () {
        const original = LayrzBreakpointTokens();
        final modified = original.copyWith(
          xs: 400.0,
          md: 1200.0,
        );

        expect(modified.xs, equals(400.0));
        expect(modified.sm, equals(original.sm));
        expect(modified.md, equals(1200.0));
        expect(modified.lg, equals(original.lg));
      });

      test('copies with all fields overridden', () {
        const original = LayrzBreakpointTokens();
        final modified = original.copyWith(
          xs: 400.0,
          sm: 800.0,
          md: 1200.0,
          lg: 1800.0,
        );

        expect(modified.xs, equals(400.0));
        expect(modified.sm, equals(800.0));
        expect(modified.md, equals(1200.0));
        expect(modified.lg, equals(1800.0));
      });

      test('copyWith with no arguments returns equal instance', () {
        const original = LayrzBreakpointTokens();
        final copy = original.copyWith();

        expect(copy, equals(original));
      });

      test('original is unchanged by copyWith', () {
        const original = LayrzBreakpointTokens();
        original.copyWith(xs: 500.0);

        expect(original.xs, equals(600.0));
      });
    });

    group('equality and hashing', () {
      test('identical instances are equal', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens();

        expect(tokens1, equals(tokens2));
      });

      test('instances with same values are equal', () {
        const tokens1 = LayrzBreakpointTokens(xs: 500.0, sm: 900.0);
        const tokens2 = LayrzBreakpointTokens(xs: 500.0, sm: 900.0);

        expect(tokens1, equals(tokens2));
      });

      test('instances with different xs are not equal', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens(xs: 500.0);

        expect(tokens1, isNot(equals(tokens2)));
      });

      test('instances with different sm are not equal', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens(sm: 1000.0);

        expect(tokens1, isNot(equals(tokens2)));
      });

      test('instances with different md are not equal', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens(md: 1300.0);

        expect(tokens1, isNot(equals(tokens2)));
      });

      test('instances with different lg are not equal', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens(lg: 2000.0);

        expect(tokens1, isNot(equals(tokens2)));
      });

      test('hashCode is stable for same values', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens();

        expect(tokens1.hashCode, equals(tokens2.hashCode));
      });

      test('hashCode differs for different values', () {
        const tokens1 = LayrzBreakpointTokens();
        const tokens2 = LayrzBreakpointTokens(xs: 500.0);

        expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
      });
    });

    group('custom thresholds change resolved bands', () {
      test('custom thresholds change which span a column resolves to', () {
        // This test demonstrates the whole point of the refactor:
        // custom breakpoint tokens actually affect which span a column selects
        const defaultBreakpoints = LayrzBreakpointTokens();
        const customBreakpoints = LayrzBreakpointTokens(xs: 500.0);

        // At width 550, default thresholds (xs=600) → xs band
        expect(defaultBreakpoints.bandAt(550), equals(LayrzBreakpoint.xs));

        // But with custom xs=500, width 550 should be sm band
        expect(customBreakpoints.bandAt(550), equals(LayrzBreakpoint.sm));

        // Width 450 is xs in both cases
        expect(defaultBreakpoints.bandAt(450), equals(LayrzBreakpoint.xs));
        expect(customBreakpoints.bandAt(450), equals(LayrzBreakpoint.xs));

        // Width 620 is sm with default, but xs with custom xs=700
        const customXs700 = LayrzBreakpointTokens(xs: 700.0);
        expect(defaultBreakpoints.bandAt(620), equals(LayrzBreakpoint.sm));
        expect(customXs700.bandAt(620), equals(LayrzBreakpoint.xs));
      });
    });
  });
}
