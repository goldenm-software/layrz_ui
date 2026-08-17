import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  const defaultBreakpoints = LayrzBreakpointTokens();

  group('LayrzCol', () {
    group('spanAt: band resolution', () {
      testWidgets('xs band (< 600) returns xs', (tester) async {
        const col = LayrzCol(xs: 6, child: SizedBox());
        expect(col.spanAt(599.9, defaultBreakpoints), equals(6));
        expect(col.spanAt(400, defaultBreakpoints), equals(6));
        expect(col.spanAt(100, defaultBreakpoints), equals(6));
      });

      testWidgets('sm band (600–959) returns sm if set, else xs', (tester) async {
        const col = LayrzCol(xs: 12, sm: 8, child: SizedBox());
        expect(col.spanAt(600, defaultBreakpoints), equals(8));
        expect(col.spanAt(750, defaultBreakpoints), equals(8));
        expect(col.spanAt(959.9, defaultBreakpoints), equals(8));

        const colNoSm = LayrzCol(xs: 12, child: SizedBox());
        expect(colNoSm.spanAt(600, defaultBreakpoints), equals(12));
        expect(colNoSm.spanAt(750, defaultBreakpoints), equals(12));
      });

      testWidgets('md band (960–1263) cascades: md → sm → xs', (tester) async {
        const colMd = LayrzCol(xs: 12, md: 6, child: SizedBox());
        expect(colMd.spanAt(960, defaultBreakpoints), equals(6));
        expect(colMd.spanAt(1200, defaultBreakpoints), equals(6));

        const colSmMd = LayrzCol(xs: 12, sm: 8, md: 4, child: SizedBox());
        expect(colSmMd.spanAt(960, defaultBreakpoints), equals(4));

        const colSmNoMd = LayrzCol(xs: 12, sm: 6, child: SizedBox());
        expect(colSmNoMd.spanAt(960, defaultBreakpoints), equals(6));
      });

      testWidgets('lg band (1264–1903) cascades: lg → md → sm → xs', (tester) async {
        const colLg = LayrzCol(xs: 12, lg: 3, child: SizedBox());
        expect(colLg.spanAt(1264, defaultBreakpoints), equals(3));
        expect(colLg.spanAt(1500, defaultBreakpoints), equals(3));

        const colMdLg = LayrzCol(xs: 12, md: 6, lg: 3, child: SizedBox());
        expect(colMdLg.spanAt(1264, defaultBreakpoints), equals(3));
      });

      testWidgets('xl band (≥ 1904) cascades: xl → lg → md → sm → xs', (tester) async {
        const colXl = LayrzCol(xs: 12, xl: 2, child: SizedBox());
        expect(colXl.spanAt(1904, defaultBreakpoints), equals(2));
        expect(colXl.spanAt(2400, defaultBreakpoints), equals(2));

        const colSmXl = LayrzCol(xs: 12, sm: 6, xl: 1, child: SizedBox());
        expect(colSmXl.spanAt(1904, defaultBreakpoints), equals(1));
      });
    });

    group('spanAt: boundary values', () {
      testWidgets('599.9 is xs band, 600.0 is sm band', (tester) async {
        const col = LayrzCol(xs: 6, sm: 4, child: SizedBox());
        expect(col.spanAt(599.9, defaultBreakpoints), equals(6));
        expect(col.spanAt(600.0, defaultBreakpoints), equals(4));
      });

      testWidgets('959.9 is sm band, 960.0 is md band', (tester) async {
        const col = LayrzCol(xs: 12, sm: 8, md: 4, child: SizedBox());
        expect(col.spanAt(959.9, defaultBreakpoints), equals(8));
        expect(col.spanAt(960.0, defaultBreakpoints), equals(4));
      });

      testWidgets('1263.9 is md band, 1264.0 is lg band', (tester) async {
        const col = LayrzCol(xs: 12, md: 8, lg: 3, child: SizedBox());
        expect(col.spanAt(1263.9, defaultBreakpoints), equals(8));
        expect(col.spanAt(1264.0, defaultBreakpoints), equals(3));
      });

      testWidgets('1903.9 is lg band, 1904.0 is xl band', (tester) async {
        const col = LayrzCol(xs: 12, lg: 6, xl: 2, child: SizedBox());
        expect(col.spanAt(1903.9, defaultBreakpoints), equals(6));
        expect(col.spanAt(1904.0, defaultBreakpoints), equals(2));
      });
    });

    group('spanAt: cascade matrix', () {
      testWidgets('only xs set: all bands return xs', (tester) async {
        const col = LayrzCol(xs: 8, child: SizedBox());
        expect(col.spanAt(400, defaultBreakpoints), equals(8));
        expect(col.spanAt(700, defaultBreakpoints), equals(8));
        expect(col.spanAt(1000, defaultBreakpoints), equals(8));
        expect(col.spanAt(1500, defaultBreakpoints), equals(8));
        expect(col.spanAt(2000, defaultBreakpoints), equals(8));
      });

      testWidgets('xs + md set: sm returns xs, lg returns md, xl returns md', (tester) async {
        const col = LayrzCol(xs: 10, md: 5, child: SizedBox());
        expect(col.spanAt(700, defaultBreakpoints), equals(10)); // sm band
        expect(col.spanAt(1000, defaultBreakpoints), equals(5)); // md band
        expect(col.spanAt(1500, defaultBreakpoints), equals(5)); // lg band uses md
        expect(col.spanAt(2000, defaultBreakpoints), equals(5)); // xl band uses md
      });

      testWidgets('all five set: each band returns its explicit value', (tester) async {
        const col = LayrzCol(xs: 12, sm: 8, md: 6, lg: 4, xl: 2, child: SizedBox());
        expect(col.spanAt(400, defaultBreakpoints), equals(12));
        expect(col.spanAt(700, defaultBreakpoints), equals(8));
        expect(col.spanAt(1000, defaultBreakpoints), equals(6));
        expect(col.spanAt(1500, defaultBreakpoints), equals(4));
        expect(col.spanAt(2000, defaultBreakpoints), equals(2));
      });
    });

    group('build', () {
      testWidgets('returns child unwrapped', (tester) async {
        const child = Text('Test');
        const col = LayrzCol(xs: 6, child: child);
        // The build method simply returns child unwrapped
        expect(identical(col.child, child), isTrue);
      });
    });

    group('assertions', () {
      testWidgets('xs = 0 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('xs = 13 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 13, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('sm = 0 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, sm: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('sm = 13 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, sm: 13, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('md = 0 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, md: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('md = 13 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, md: 13, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('lg = 0 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, lg: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('lg = 13 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, lg: 13, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('xl = 0 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, xl: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('xl = 13 throws assertion error', (tester) async {
        expect(
          () => LayrzCol(xs: 6, xl: 13, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      testWidgets('xs = 1 is valid', (tester) async {
        const col = LayrzCol(xs: 1, child: SizedBox());
        expect(col.xs, equals(1));
      });

      testWidgets('xs = 12 is valid', (tester) async {
        const col = LayrzCol(xs: 12, child: SizedBox());
        expect(col.xs, equals(12));
      });
    });

    group('spanAt: custom breakpoints change resolved span', () {
      testWidgets('custom xs threshold changes which span resolves at width 550', (tester) async {
        const col = LayrzCol(xs: 12, sm: 6, child: SizedBox());

        // With default breakpoints (xs=600), width 550 is in xs band → span 12
        expect(col.spanAt(550, defaultBreakpoints), equals(12));

        // With custom breakpoints (xs=500), width 550 is in sm band → span 6
        const customBreakpoints = LayrzBreakpointTokens(xs: 500);
        expect(col.spanAt(550, customBreakpoints), equals(6));
      });

      testWidgets('custom md threshold changes which span resolves at width 1000', (tester) async {
        const col = LayrzCol(xs: 12, sm: 10, lg: 4, child: SizedBox());

        // With default breakpoints, width 1000 is in md band → span 12 (no md, falls back to sm=10)
        expect(col.spanAt(1000, defaultBreakpoints), equals(10));

        // With custom breakpoints (xs=700, sm=1100), width 1000 is in sm band → span 10
        const customBreakpoints = LayrzBreakpointTokens(xs: 700, sm: 1100);
        expect(col.spanAt(1000, customBreakpoints), equals(10));

        // With custom breakpoints where 1000 falls into lg band
        const customBreakpointsLg = LayrzBreakpointTokens(
          xs: 600,
          sm: 700,
          md: 800,
          lg: 900,
        );
        // Width 1000 is in lg band → span 4
        expect(col.spanAt(1000, customBreakpointsLg), equals(4));
      });
    });
  });
}
