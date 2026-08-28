import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTransitionType', () {
    test('has exactly five values, one per shipped transition', () {
      expect(LayrzTransitionType.values, hasLength(5));
      expect(
        LayrzTransitionType.values,
        containsAll(<LayrzTransitionType>[
          LayrzTransitionType.fade,
          LayrzTransitionType.slide,
          LayrzTransitionType.scale,
          LayrzTransitionType.rotation,
          LayrzTransitionType.none,
        ]),
      );
    });

    test('resolve(fade) returns LayrzPageTransitions.fade', () {
      expect(
        LayrzPageTransitions.resolve(LayrzTransitionType.fade),
        equals(LayrzPageTransitions.fade),
      );
    });

    test('resolve(slide) returns LayrzPageTransitions.slide', () {
      expect(
        LayrzPageTransitions.resolve(LayrzTransitionType.slide),
        equals(LayrzPageTransitions.slide),
      );
    });

    test('resolve(scale) returns LayrzPageTransitions.scale', () {
      expect(
        LayrzPageTransitions.resolve(LayrzTransitionType.scale),
        equals(LayrzPageTransitions.scale),
      );
    });

    test('resolve(rotation) returns LayrzPageTransitions.rotation', () {
      expect(
        LayrzPageTransitions.resolve(LayrzTransitionType.rotation),
        equals(LayrzPageTransitions.rotation),
      );
    });

    test('resolve(none) returns LayrzPageTransitions.none', () {
      expect(
        LayrzPageTransitions.resolve(LayrzTransitionType.none),
        equals(LayrzPageTransitions.none),
      );
    });
  });
}
