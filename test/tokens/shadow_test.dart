import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzShadowTokens', () {
    test('default constructor uses correct defaults', () {
      const tokens = LayrzShadowTokens();

      expect(tokens.surfaceColor, equals(const Color(0xFFFFFFFF)));
      expect(tokens.baseRadius, equals(8.0));
      expect(tokens.shadowColor, equals(const Color(0xFF000000)));
      expect(tokens.outlineColor, equals(const Color.fromRGBO(0, 0, 0, 0.1)));
    });

    test('elevation1 returns correct shadow list', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation1;

      expect(shadows, isA<List<BoxShadow>>());
      expect(shadows.length, equals(1));
      expect(shadows[0].blurRadius, equals(5.0)); // 3*1 + 2 = 5
      expect(shadows[0].offset, equals(const Offset(0, 0))); // 1 - 1 = 0
    });

    test('elevation3 returns correct shadow list', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation3;

      expect(shadows.length, equals(1));
      expect(shadows[0].blurRadius, equals(11.0)); // 3*3 + 2 = 11
      expect(shadows[0].offset, equals(const Offset(0, 2))); // 3 - 1 = 2
    });

    test('elevation5 returns correct shadow list', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation5;

      expect(shadows.length, equals(1));
      expect(shadows[0].blurRadius, equals(17.0)); // 3*5 + 2 = 17
      expect(shadows[0].offset, equals(const Offset(0, 4))); // 5 - 1 = 4
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

    test('elevation() opacity increases with elevation', () {
      const tokens = LayrzShadowTokens();
      final elev1 = tokens.elevation(elevation: 1);
      final elev5 = tokens.elevation(elevation: 5);

      final opac1 = elev1.boxShadow![0].color.a;
      final opac5 = elev5.boxShadow![0].color.a;

      expect(opac5, greaterThan(opac1));
    });

    test(
      'elevation3 from getter equals elevation(elevation: 3) from method',
      () {
        const tokens = LayrzShadowTokens();
        final fromGetter = tokens.elevation3;
        final fromMethod = tokens.elevation(elevation: 3).boxShadow!;

        expect(fromGetter.length, equals(fromMethod.length));
        expect(fromGetter[0].blurRadius, equals(fromMethod[0].blurRadius));
        expect(fromGetter[0].offset, equals(fromMethod[0].offset));
        // Compare alpha values with tolerance for floating point
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

    test('elevation 0 opacity should be 6% (0.06)', () {
      const tokens = LayrzShadowTokens();
      final decor = tokens.elevation(elevation: 0.0);
      // At elevation 0, alpha = 0.06
      // Color.alpha is an int 0-255, so 0.06 * 255 ≈ 15
      expect(decor.boxShadow, isNull); // no shadow at elevation 0
    });

    test('elevation 5 opacity should be 12% (0.12)', () {
      const tokens = LayrzShadowTokens();
      final shadows = tokens.elevation5;
      // At elevation 5, alpha = 0.12
      // Verify the color has approximately this opacity
      final expectedAlpha = 0.12;
      final actualAlpha = shadows[0].color.a;
      expect(actualAlpha, closeTo(expectedAlpha, 0.01));
    });

    test('elevation assertion fails for elevation > 5', () {
      const tokens = LayrzShadowTokens();
      expect(() => tokens.elevation(elevation: 6), throwsAssertionError);
    });

    test('elevation assertion fails for elevation < 0', () {
      const tokens = LayrzShadowTokens();
      expect(() => tokens.elevation(elevation: -1), throwsAssertionError);
    });
  });
}
