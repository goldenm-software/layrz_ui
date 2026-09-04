import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/skeleton/src/shimmer_painter.dart';

void main() {
  group('LayrzShimmerGradient', () {
    const baseColor = Color(0xFFE0E0E0);
    const highlightColor = Color(0xFFFFFFFF);
    const rect = Rect.fromLTWH(0, 0, 100, 20);

    test('forAnimationValue clamps an out-of-range value', () {
      final tooHigh = LayrzShimmerGradient.forAnimationValue(
        value: 1.5,
        baseColor: baseColor,
        highlightColor: highlightColor,
        shaderRect: rect,
      );
      final tooLow = LayrzShimmerGradient.forAnimationValue(
        value: -0.5,
        baseColor: baseColor,
        highlightColor: highlightColor,
        shaderRect: rect,
      );

      expect(tooHigh.position, equals(1.0));
      expect(tooLow.position, equals(0.0));
    });

    test('gradient stops are monotonically non-decreasing at every position', () {
      for (var i = 0; i <= 10; i++) {
        final value = i / 10;
        final shimmer = LayrzShimmerGradient.forAnimationValue(
          value: value,
          baseColor: baseColor,
          highlightColor: highlightColor,
          shaderRect: rect,
        );

        // At the very start/end of the cycle the band's center hasn't
        // entered [0.0, 1.0] yet, so gradient falls back to a flat two-color
        // gradient with no explicit stops -- nothing to check ordering on.
        final stops = shimmer.gradient.stops;
        if (stops == null) continue;

        for (var j = 1; j < stops.length; j++) {
          expect(
            stops[j],
            greaterThanOrEqualTo(stops[j - 1]),
            reason: 'stops must be non-decreasing at position=$value: $stops',
          );
        }
        for (final stop in stops) {
          expect(stop, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('gradient direction sweeps left to right', () {
      final shimmer = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );

      expect(shimmer.gradient.begin, equals(Alignment.centerLeft));
      expect(shimmer.gradient.end, equals(Alignment.centerRight));
    });

    test('gradient colors place highlightColor at the center stop', () {
      final shimmer = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );

      final colors = shimmer.gradient.colors;
      expect(colors.first, equals(baseColor));
      expect(colors.last, equals(baseColor));
      expect(colors[2], equals(highlightColor));
    });

    test('createShader produces a non-null Shader', () {
      final shimmer = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );

      expect(shimmer.createShader(), isNotNull);
    });

    test('bandWidth defaults to 0.3', () {
      const shimmer = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );

      expect(shimmer.bandWidth, equals(0.3));
    });

    test('equality holds for identical field values', () {
      const a = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );
      const b = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality holds when position differs (shouldRepaint-style check)', () {
      const a = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.2,
        shaderRect: rect,
      );
      const b = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.8,
        shaderRect: rect,
      );

      expect(a, isNot(equals(b)));
    });

    test('inequality holds when shaderRect differs', () {
      const a = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: rect,
      );
      const b = LayrzShimmerGradient(
        baseColor: baseColor,
        highlightColor: highlightColor,
        position: 0.5,
        shaderRect: Rect.fromLTWH(0, 0, 200, 40),
      );

      expect(a, isNot(equals(b)));
    });

    test(
      'position 0.0 (band entirely before the visible range) and 1.0 (entirely past it) '
      'fall back to a flat baseColor gradient instead of a collapsed highlight stop',
      () {
        // Regression: clamping the band's stops into [0.0, 1.0] when the band
        // sits entirely outside that range used to collapse bandStart,
        // bandCenter and bandEnd onto the same clamped value while colors
        // still placed highlightColor at that point -- LinearGradient then
        // interpolated a zero-width jump into and back out of
        // highlightColor right at the shape's edge, painting a thin bright
        // line pinned to it every animation cycle. The fix returns a flat
        // two-stop [baseColor, baseColor] gradient whenever the band's
        // unclamped extent doesn't intersect [0.0, 1.0] at all.
        for (final value in [0.0, 1.0]) {
          final shimmer = LayrzShimmerGradient.forAnimationValue(
            value: value,
            baseColor: baseColor,
            highlightColor: highlightColor,
            shaderRect: rect,
          );

          final gradient = shimmer.gradient;
          expect(gradient.colors, equals([baseColor, baseColor]), reason: 'at position=$value');
          expect(gradient.stops, isNull, reason: 'at position=$value');
        }
      },
    );

    test('a partially-entered band never places highlightColor at stop 0.0', () {
      // At position 0.15 the band's true center (~0.045) has just crossed
      // into [0.0, 1.0], so this renders the banded gradient rather than
      // the flat fallback above -- a fast but continuous ramp, not the
      // zero-width discontinuity that motivated it. highlightColor must
      // never land exactly on the shape's edge stop (0.0) here.
      final shimmer = LayrzShimmerGradient.forAnimationValue(
        value: 0.15,
        baseColor: baseColor,
        highlightColor: highlightColor,
        shaderRect: rect,
      );

      final gradient = shimmer.gradient;
      final stops = gradient.stops!;
      final colors = gradient.colors;
      for (var i = 0; i < stops.length; i++) {
        if (stops[i] == 0.0) {
          expect(colors[i], equals(baseColor), reason: 'stop 0.0 must never carry highlightColor');
        }
      }
    });
  });
}
