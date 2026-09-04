import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzMotionTokens', () {
    test('default constructor uses correct duration defaults', () {
      const tokens = LayrzMotionTokens();

      expect(tokens.dHover, equals(kHoverDuration));
      expect(tokens.dPress, equals(const Duration(milliseconds: 80)));
      expect(tokens.dTransition, equals(const Duration(milliseconds: 200)));
      expect(tokens.dPageTransition, equals(kPageTransitionDuration));
      expect(tokens.dDialog, equals(const Duration(milliseconds: 300)));
      expect(tokens.dIndeterminate, equals(kIndeterminateDuration));
    });

    test('dHover equals kHoverDuration constant', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.dHover, equals(kHoverDuration));
      expect(tokens.dHover, equals(const Duration(milliseconds: 100)));
    });

    test('dPageTransition equals kPageTransitionDuration constant', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.dPageTransition, equals(kPageTransitionDuration));
      expect(tokens.dPageTransition, equals(const Duration(milliseconds: 250)));
    });

    test('dIndeterminate equals kIndeterminateDuration constant', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.dIndeterminate, equals(kIndeterminateDuration));
      expect(tokens.dIndeterminate, equals(const Duration(milliseconds: 1500)));
    });

    test('default easing is easeInOut', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.easing, equals(Curves.easeInOut));
    });

    test('default easingEnter is easeOut', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.easingEnter, equals(Curves.easeOut));
    });

    test('default easingExit is easeIn', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.easingExit, equals(Curves.easeIn));
    });

    test('copyWith creates new instance with replaced fields', () {
      const original = LayrzMotionTokens();
      final modified = original.copyWith(
        dHover: const Duration(milliseconds: 150),
        easing: Curves.easeIn,
      );

      expect(modified.dHover, equals(const Duration(milliseconds: 150)));
      expect(modified.easing, equals(Curves.easeIn));
      expect(modified.dPress, equals(original.dPress));
      expect(
        original.dHover,
        equals(const Duration(milliseconds: 100)),
      ); // original unchanged
    });

    test('equality works for identical values', () {
      const tokens1 = LayrzMotionTokens();
      const tokens2 = LayrzMotionTokens();
      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      const original = LayrzMotionTokens();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different durations', () {
      const tokens1 = LayrzMotionTokens();
      final tokens2 = LayrzMotionTokens(
        dHover: const Duration(milliseconds: 150),
      );
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('inequality works for different curves', () {
      const tokens1 = LayrzMotionTokens();
      final tokens2 = LayrzMotionTokens(easing: Curves.linear);
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      const tokens1 = LayrzMotionTokens();
      const tokens2 = LayrzMotionTokens();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different durations', () {
      const tokens1 = LayrzMotionTokens();
      final tokens2 = LayrzMotionTokens(
        dHover: const Duration(milliseconds: 150),
      );
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('all durations are positive', () {
      const tokens = LayrzMotionTokens();

      expect(tokens.dHover.inMilliseconds, greaterThan(0));
      expect(tokens.dPress.inMilliseconds, greaterThan(0));
      expect(tokens.dTransition.inMilliseconds, greaterThan(0));
      expect(tokens.dPageTransition.inMilliseconds, greaterThan(0));
      expect(tokens.dDialog.inMilliseconds, greaterThan(0));
      expect(tokens.dIndeterminate.inMilliseconds, greaterThan(0));
    });

    test('dPress is faster than dTransition', () {
      const tokens = LayrzMotionTokens();
      expect(
        tokens.dPress.inMilliseconds,
        lessThan(tokens.dTransition.inMilliseconds),
      );
    });

    test('dIndeterminate is slower than dDialog', () {
      const tokens = LayrzMotionTokens();
      expect(
        tokens.dIndeterminate.inMilliseconds,
        greaterThan(tokens.dDialog.inMilliseconds),
      );
    });

    test('copyWith replaces dIndeterminate independently', () {
      const original = LayrzMotionTokens();
      final modified = original.copyWith(
        dIndeterminate: const Duration(milliseconds: 1200),
      );

      expect(modified.dIndeterminate, equals(const Duration(milliseconds: 1200)));
      expect(modified.dDialog, equals(original.dDialog));
      expect(original.dIndeterminate, equals(const Duration(milliseconds: 1500))); // original unchanged
    });

    test('default easingEmphasized is easeInOutCirc', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.easingEmphasized, equals(Curves.easeInOutCirc));
    });

    test('easing is unchanged by the introduction of easingEmphasized', () {
      const tokens = LayrzMotionTokens();
      expect(tokens.easing, equals(Curves.easeInOut));
      expect(tokens.easing, isNot(equals(tokens.easingEmphasized)));
    });

    test('copyWith replaces easingEmphasized independently', () {
      const original = LayrzMotionTokens();
      final modified = original.copyWith(easingEmphasized: Curves.linear);

      expect(modified.easingEmphasized, equals(Curves.linear));
      expect(modified.easing, equals(original.easing)); // easing untouched
      expect(original.easingEmphasized, equals(Curves.easeInOutCirc)); // original unchanged
    });

    test('equality accounts for easingEmphasized', () {
      const tokens1 = LayrzMotionTokens();
      final tokens2 = LayrzMotionTokens(easingEmphasized: Curves.linear);
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode differs when easingEmphasized differs', () {
      const tokens1 = LayrzMotionTokens();
      final tokens2 = LayrzMotionTokens(easingEmphasized: Curves.linear);
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });
  });
}
