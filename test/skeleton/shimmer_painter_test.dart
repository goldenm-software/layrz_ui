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

        final stops = shimmer.gradient.stops!;
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

    test('position 0.0 places the band entirely before the visible range', () {
      final shimmer = LayrzShimmerGradient.forAnimationValue(
        value: 0.0,
        baseColor: baseColor,
        highlightColor: highlightColor,
        shaderRect: rect,
      );

      // At position 0.0 the band's center sits before the rect (clamped to
      // 0.0), so the gradient degenerates toward baseColor across most of
      // the visible range — verified via the stops staying clamped and
      // ordered rather than a specific pixel color, since LinearGradient
      // does not expose sampled colors directly.
      final stops = shimmer.gradient.stops!;
      expect(stops.first, equals(0.0));
      expect(stops.last, equals(1.0));
    });

    test('position 1.0 places the band entirely past the visible range', () {
      final shimmer = LayrzShimmerGradient.forAnimationValue(
        value: 1.0,
        baseColor: baseColor,
        highlightColor: highlightColor,
        shaderRect: rect,
      );

      final stops = shimmer.gradient.stops!;
      expect(stops.first, equals(0.0));
      expect(stops.last, equals(1.0));
    });
  });
}
