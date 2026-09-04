import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/ai_marker/src/ai_marker_burst.dart';

void main() {
  group('LayrzAiMarkerBurst', () {
    const burst = LayrzAiMarkerBurst();

    test('the big star starts near its minimum scale/opacity at value 0.0', () {
      final frame = burst.bigStarAt(0.0);
      expect(frame.scale, closeTo(0.6, 0.01));
      expect(frame.opacity, closeTo(0.0, 0.01));
    });

    test('the big star settles at scale 1.0 / opacity 1.0 once its interval completes', () {
      final frame = burst.bigStarAt(burst.burstFraction);
      expect(frame.scale, closeTo(1.0, 0.01));
      expect(frame.opacity, closeTo(1.0, 0.01));
    });

    test('the big star holds settled for the remainder of the cycle', () {
      final midHold = burst.bigStarAt((burst.burstFraction + 1.0) / 2);
      final end = burst.bigStarAt(1.0);
      expect(midHold.scale, closeTo(1.0, 0.01));
      expect(end.scale, closeTo(1.0, 0.01));
    });

    test('the small star is fully invisible before its delayed interval starts', () {
      final frame = burst.smallStarAt(burst.smallStarDelay / 2);
      expect(frame.scale, 0.0);
      expect(frame.opacity, 0.0);
    });

    test('the small star settles at scale 1.0 / opacity 1.0 once its own interval completes', () {
      final settleValue = (burst.smallStarDelay + burst.burstFraction).clamp(0.0, 1.0);
      final frame = burst.smallStarAt(settleValue);
      expect(frame.scale, closeTo(1.0, 0.01));
      expect(frame.opacity, closeTo(1.0, 0.01));
    });

    test('the two stars are never in identical phase mid-burst (staggered, not synchronized)', () {
      // Sampled partway through the big star's burst, while the small star's
      // delayed interval has only just started (or not yet) -- if the two
      // curves were not staggered, both frames would be identical at every
      // sampled value. This is the concrete regression test for "staggered,
      // not simultaneous."
      final sampleValue = burst.smallStarDelay / 2 + 0.05;
      final bigFrame = burst.bigStarAt(sampleValue);
      final smallFrame = burst.smallStarAt(sampleValue);

      expect(bigFrame, isNot(equals(smallFrame)));
      expect(bigFrame.scale, isNot(closeTo(smallFrame.scale, 0.001)));
    });

    test('the small star visibly lags the big star at every sampled cycle position', () {
      // For a range of sample points, the small star's scale should never
      // exceed the big star's scale by an amount that would suggest it leads
      // rather than follows -- concretely, close to the very start of the
      // cycle the small star has not appeared while the big star has begun.
      const sampleValue = 0.05;
      final bigFrame = burst.bigStarAt(sampleValue);
      final smallFrame = burst.smallStarAt(sampleValue);

      expect(bigFrame.opacity, greaterThan(smallFrame.opacity));
    });

    test('kLayrzAiMarkerSettledFrame is the fully-settled resting pose', () {
      expect(kLayrzAiMarkerSettledFrame.scale, 1.0);
      expect(kLayrzAiMarkerSettledFrame.opacity, 1.0);
    });

    test('values outside [0.0, 1.0] are clamped defensively', () {
      final below = burst.bigStarAt(-0.5);
      final above = burst.bigStarAt(1.5);
      expect(below.opacity, greaterThanOrEqualTo(0.0));
      expect(above.scale, closeTo(1.0, 0.01));
    });

    test('LayrzAiMarkerBurstFrame equality is scale-based', () {
      const a = LayrzAiMarkerBurstFrame(scale: 1.0, opacity: 1.0);
      const b = LayrzAiMarkerBurstFrame(scale: 1.0, opacity: 0.5);
      const c = LayrzAiMarkerBurstFrame(scale: 0.5, opacity: 1.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, isNot(equals(c.hashCode)));
    });

    test('LayrzAiMarkerBurst equality compares stagger parameters', () {
      const a = LayrzAiMarkerBurst();
      const b = LayrzAiMarkerBurst();
      const c = LayrzAiMarkerBurst(smallStarDelay: 0.3);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('custom stagger parameters are honored', () {
      const custom = LayrzAiMarkerBurst(smallStarDelay: 0.4, burstFraction: 0.3);
      expect(custom.smallStarAt(0.2).scale, 0.0);
      expect(custom.smallStarAt(0.2).opacity, 0.0);
      final settled = custom.smallStarAt(0.4 + 0.3);
      expect(settled.scale, closeTo(1.0, 0.01));
    });
  });
}
