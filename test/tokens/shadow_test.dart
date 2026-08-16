import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens.dart';

void main() {
  group('LayrzShadowTokens', () {
    test('default constructor uses correct defaults', () {
      const tokens = LayrzShadowTokens();

      expect(tokens.surfaceColor, equals(const Color(0xFFFFFFFF)));
      expect(tokens.baseRadius, equals(8.0));
      expect(tokens.shadowColor, equals(const Color(0xFF000000)));
      expect(tokens.outlineColor, equals(const Color.fromRGBO(0, 0, 0, 0.1)));
    });

    test('elevation1 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation1;

      expect(shadows, isA<List<BoxShadow>>());
      expect(shadows.length, equals(1));

      final shadow = shadows[0];
      expect(shadow.spreadRadius, equals(0));
      expect(shadow.offset, equals(const Offset(0, 1)));
      expect(shadow.blurRadius, greaterThan(0));
    });

    test('elevation3 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation3;

      expect(shadows.length, equals(1));
      expect(shadows[0].spreadRadius, equals(0));
      expect(shadows[0].offset, equals(const Offset(0, 3)));
    });

    test('elevation5 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation5;

      expect(shadows.length, equals(1));
      expect(shadows[0].spreadRadius, equals(0));
      expect(shadows[0].offset, equals(const Offset(0, 5)));
    });

    test('elevation0 should return empty shadow list', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation(elevation: 0);
      expect(shadows.boxShadow, isNull);
    });

    test(
      'elevation() at level 0 draws outline when hideOnElevationZero is false',
      () {
        const tokens = LayrzShadowTokens();
        final decor = tokens.elevation(
          elevation: 0,
          hideOnElevationZero: false,
        );

        expect(decor.border, isNotNull);
        expect(decor.border!.top.width, equals(1.0));
      },
    );

    test(
      'elevation() at level 0 hides outline when hideOnElevationZero is true',
      () {
        const tokens = LayrzShadowTokens();
        final decor = tokens.elevation(elevation: 0, hideOnElevationZero: true);

        expect(decor.border, isNull);
      },
    );

    test(
      'elevation3 from getter equals elevation(elevation: 3) from method',
      () {
        const tokens = LayrzShadowTokens();
        final fromGetter = tokens.elevation3;
        final fromMethod = tokens.elevation(elevation: 3).boxShadow!;

        expect(fromGetter.length, equals(fromMethod.length));
        expect(fromGetter.length, equals(1)); // single shadow
        expect(fromGetter[0].blurRadius, equals(fromMethod[0].blurRadius));
        expect(fromGetter[0].offset, equals(fromMethod[0].offset));
        expect(fromGetter[0].spreadRadius, equals(fromMethod[0].spreadRadius));
        expect(fromGetter[0].color.a, closeTo(fromMethod[0].color.a, 0.01));
      },
    );

    test('elevation() respects color parameter', () {
      const tokens = LayrzShadowTokens();
      const customColor = Color(0xFF888888);
      final decor = tokens.elevation(elevation: 1, color: customColor);

      expect(decor.color, equals(customColor));
    });

    test('elevation() respects radius parameter', () {
      const tokens = LayrzShadowTokens();
      final decor = tokens.elevation(elevation: 1, radius: 12.0);

      expect(decor.borderRadius, equals(BorderRadius.circular(12.0)));
    });

    test('elevation() reverses offset when reverse is true', () {
      const tokens = LayrzShadowTokens();
      final normal = tokens.elevation(elevation: 3, reverse: false);
      final reversed = tokens.elevation(elevation: 3, reverse: true);

      expect(normal.boxShadow!.length, equals(1));
      expect(reversed.boxShadow!.length, equals(1));

      final normalOffset = normal.boxShadow![0].offset.dy;
      final reversedOffset = reversed.boxShadow![0].offset.dy;
      expect(reversedOffset, equals(-normalOffset));
    });

    test('copyWith creates new instance with replaced fields', () {
      const original = LayrzShadowTokens();
      const newColor = Color(0xFF999999);
      final modified = original.copyWith(
        surfaceColor: newColor,
        baseRadius: 12.0,
      );

      expect(modified.surfaceColor, equals(newColor));
      expect(modified.baseRadius, equals(12.0));
      expect(modified.shadowColor, equals(original.shadowColor));
      expect(
        original.surfaceColor,
        equals(const Color(0xFFFFFFFF)),
      ); // original unchanged
    });

    test('equality works for identical values', () {
      const tokens1 = LayrzShadowTokens();
      const tokens2 = LayrzShadowTokens();
      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      const original = LayrzShadowTokens();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different surfaceColor', () {
      const tokens1 = LayrzShadowTokens();
      final tokens2 = LayrzShadowTokens(surfaceColor: const Color(0xFF888888));
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      const tokens1 = LayrzShadowTokens();
      const tokens2 = LayrzShadowTokens();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      const tokens1 = LayrzShadowTokens();
      final tokens2 = LayrzShadowTokens(surfaceColor: const Color(0xFF888888));
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('elevation 0 returns no shadow', () {
      const tokens = LayrzShadowTokens();
      final decor = tokens.elevation(elevation: 0.0);
      expect(decor.boxShadow, isNull); // no shadow at elevation 0
    });

    test('elevation1 has non-zero offset for visibility', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation1;
      // Regression test: elevation 1 offset must be > 0 so shadow is visible behind opaque surfaces
      expect(shadows[0].offset.dy, equals(1.0));
      expect(shadows[0].offset.dy, greaterThan(0.0));
    });

    test('elevation1 has non-trivial opacity', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation1;
      // Regression test: elevation 1 opacity must be sufficient to read on screen
      final actualAlpha = shadows[0].color.a;
      expect(actualAlpha, greaterThan(0.0));
    });

    test('elevation assertion fails for elevation > 5', () {
      const tokens = LayrzShadowTokens();
      expect(() => tokens.elevation(elevation: 6), throwsAssertionError);
    });

    test('elevation assertion fails for elevation < 0', () {
      const tokens = LayrzShadowTokens();
      expect(() => tokens.elevation(elevation: -1), throwsAssertionError);
    });

    // Compact shadow ramp tests
    test('compact1 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.compact1;

      expect(shadows, isA<List<BoxShadow>>());
      expect(shadows.length, equals(1));

      final shadow = shadows[0];
      expect(shadow.spreadRadius, equals(0));
      expect(shadow.offset, equals(const Offset(0, 3)));
      expect(shadow.blurRadius, greaterThan(0));
    });

    test('compact2 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.compact2;

      expect(shadows.length, equals(1));
      expect(shadows[0].spreadRadius, equals(0));
      expect(shadows[0].offset, equals(const Offset(0, 4)));
    });

    test('compact3 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.compact3;

      expect(shadows.length, equals(1));
      expect(shadows[0].spreadRadius, equals(0));
      expect(shadows[0].offset, equals(const Offset(0, 5)));
    });

    test('compact4 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.compact4;

      expect(shadows.length, equals(1));
      expect(shadows[0].spreadRadius, equals(0));
      expect(shadows[0].offset, equals(const Offset(0, 6)));
    });

    test('compact5 returns single shadow', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.compact5;

      expect(shadows.length, equals(1));
      expect(shadows[0].spreadRadius, equals(0));
      expect(shadows[0].offset, equals(const Offset(0, 7)));
    });

    test('compact shadow has greater opacity and offset than elevation at same level', () {
      const tokens = LayrzShadowTokens();
      final compact = tokens.compact1[0];
      final elevation = tokens.elevation1[0];

      // Compact ramp is darker: 18%–30% opacity vs 10%–22%
      expect(compact.color.a, greaterThan(elevation.color.a));
      // Compact ramp has larger vertical offset for visibility on small components
      expect(compact.offset.dy, greaterThan(elevation.offset.dy));
    });

    test('compact2 shadow is darker with greater offset than elevation2', () {
      const tokens = LayrzShadowTokens();
      final compact = tokens.compact2[0];
      final elevation = tokens.elevation2[0];

      // Compact ramp is darker
      expect(compact.color.a, greaterThan(elevation.color.a));
      // Compact ramp has larger vertical offset
      expect(compact.offset.dy, greaterThan(elevation.offset.dy));
    });

    test('compact1 has sufficient offset for visibility', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.compact1;
      // Regression test: compact 1 offset must be large enough so shadow is
      // clearly visible at small component sizes
      expect(shadows[0].offset.dy, equals(3.0));
      expect(shadows[0].offset.dy, greaterThanOrEqualTo(2.0));
    });

    test('compact0 returns no shadow', () {
      const tokens = LayrzShadowTokens();
      final decor = tokens.compact(elevation: 0);
      expect(decor.boxShadow, isNull);
    });

    test(
      'compact() at level 0 draws outline when hideOnElevationZero is false',
      () {
        const tokens = LayrzShadowTokens();
        final decor = tokens.compact(
          elevation: 0,
          hideOnElevationZero: false,
        );

        expect(decor.border, isNotNull);
        expect(decor.border!.top.width, equals(1.0));
      },
    );

    test(
      'compact() at level 0 hides outline when hideOnElevationZero is true',
      () {
        const tokens = LayrzShadowTokens();
        final decor = tokens.compact(elevation: 0, hideOnElevationZero: true);

        expect(decor.border, isNull);
      },
    );

    test(
      'compact3 from getter equals compact(elevation: 3) from method',
      () {
        const tokens = LayrzShadowTokens();
        final fromGetter = tokens.compact3;
        final fromMethod = tokens.compact(elevation: 3).boxShadow!;

        expect(fromGetter.length, equals(fromMethod.length));
        expect(fromGetter.length, equals(1)); // single shadow
        expect(fromGetter[0].blurRadius, equals(fromMethod[0].blurRadius));
        expect(fromGetter[0].offset, equals(fromMethod[0].offset));
        expect(fromGetter[0].spreadRadius, equals(fromMethod[0].spreadRadius));
        expect(fromGetter[0].color.a, closeTo(fromMethod[0].color.a, 0.01));
      },
    );

    test('compact() respects color parameter', () {
      const tokens = LayrzShadowTokens();
      const customColor = Color(0xFF888888);
      final decor = tokens.compact(elevation: 1, color: customColor);

      expect(decor.color, equals(customColor));
    });

    test('compact() respects radius parameter', () {
      const tokens = LayrzShadowTokens();
      final decor = tokens.compact(elevation: 1, radius: 12.0);

      expect(decor.borderRadius, equals(BorderRadius.circular(12.0)));
    });

    test('compact() reverses offset when reverse is true', () {
      const tokens = LayrzShadowTokens();
      final normal = tokens.compact(elevation: 3, reverse: false);
      final reversed = tokens.compact(elevation: 3, reverse: true);

      expect(normal.boxShadow!.length, equals(1));
      expect(reversed.boxShadow!.length, equals(1));

      final normalOffset = normal.boxShadow![0].offset.dy;
      final reversedOffset = reversed.boxShadow![0].offset.dy;
      expect(reversedOffset, equals(-normalOffset));
    });

    test('compact opacity increases monotonically', () {
      const tokens = LayrzShadowTokens();
      final c1 = tokens.compact1[0].color.a;
      final c2 = tokens.compact2[0].color.a;
      final c3 = tokens.compact3[0].color.a;
      final c4 = tokens.compact4[0].color.a;
      final c5 = tokens.compact5[0].color.a;

      expect(c2, greaterThan(c1));
      expect(c3, greaterThan(c2));
      expect(c4, greaterThan(c3));
      expect(c5, greaterThan(c4));
    });

    test('compact blur increases monotonically', () {
      const tokens = LayrzShadowTokens();
      final c1 = tokens.compact1[0].blurRadius;
      final c2 = tokens.compact2[0].blurRadius;
      final c3 = tokens.compact3[0].blurRadius;
      final c4 = tokens.compact4[0].blurRadius;
      final c5 = tokens.compact5[0].blurRadius;

      expect(c2, greaterThan(c1));
      expect(c3, greaterThan(c2));
      expect(c4, greaterThan(c3));
      expect(c5, greaterThan(c4));
    });

    test('compact assertion fails for elevation > 5', () {
      const tokens = LayrzShadowTokens();
      expect(() => tokens.compact(elevation: 6), throwsAssertionError);
    });

    test('compact assertion fails for elevation < 0', () {
      const tokens = LayrzShadowTokens();
      expect(() => tokens.compact(elevation: -1), throwsAssertionError);
    });
  });
}
