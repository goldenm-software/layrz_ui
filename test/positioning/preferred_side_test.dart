import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzPreferredSide.opposite', () {
    test('top opposite is bottom', () {
      expect(LayrzPreferredSide.top.opposite, LayrzPreferredSide.bottom);
    });

    test('bottom opposite is top', () {
      expect(LayrzPreferredSide.bottom.opposite, LayrzPreferredSide.top);
    });

    test('left opposite is right', () {
      expect(LayrzPreferredSide.left.opposite, LayrzPreferredSide.right);
    });

    test('right opposite is left', () {
      expect(LayrzPreferredSide.right.opposite, LayrzPreferredSide.left);
    });

    test('opposite is its own inverse for every value', () {
      for (final side in LayrzPreferredSide.values) {
        expect(side.opposite.opposite, side);
      }
    });
  });

  group('LayrzPreferredSide.isVertical / isHorizontal', () {
    test('top is vertical, not horizontal', () {
      expect(LayrzPreferredSide.top.isVertical, isTrue);
      expect(LayrzPreferredSide.top.isHorizontal, isFalse);
    });

    test('bottom is vertical, not horizontal', () {
      expect(LayrzPreferredSide.bottom.isVertical, isTrue);
      expect(LayrzPreferredSide.bottom.isHorizontal, isFalse);
    });

    test('left is horizontal, not vertical', () {
      expect(LayrzPreferredSide.left.isVertical, isFalse);
      expect(LayrzPreferredSide.left.isHorizontal, isTrue);
    });

    test('right is horizontal, not vertical', () {
      expect(LayrzPreferredSide.right.isVertical, isFalse);
      expect(LayrzPreferredSide.right.isHorizontal, isTrue);
    });

    test('isVertical and isHorizontal are mutually exclusive for every value', () {
      for (final side in LayrzPreferredSide.values) {
        expect(side.isVertical, !side.isHorizontal);
      }
    });
  });
}
