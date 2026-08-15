import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons/buttons.dart';

void main() {
  group('LayrzButtonStyle', () {
    group('enum values', () {
      test('has exactly 10 style variants', () {
        expect(LayrzButtonStyle.values.length, equals(10));
      });

      test('contains all expected non-Fab styles', () {
        expect(
          LayrzButtonStyle.values,
          containsAll([
            LayrzButtonStyle.filled,
            LayrzButtonStyle.elevated,
            LayrzButtonStyle.filledTonal,
            LayrzButtonStyle.outlined,
            LayrzButtonStyle.outlinedTonal,
          ]),
        );
      });

      test('contains all expected Fab styles', () {
        expect(
          LayrzButtonStyle.values,
          containsAll([
            LayrzButtonStyle.filledFab,
            LayrzButtonStyle.elevatedFab,
            LayrzButtonStyle.filledTonalFab,
            LayrzButtonStyle.outlinedFab,
            LayrzButtonStyle.outlinedTonalFab,
          ]),
        );
      });
    });

    group('isFab extension property', () {
      test('filled is not Fab', () {
        expect(LayrzButtonStyle.filled.isFab, isFalse);
      });

      test('filledFab is Fab', () {
        expect(LayrzButtonStyle.filledFab.isFab, isTrue);
      });

      test('elevated is not Fab', () {
        expect(LayrzButtonStyle.elevated.isFab, isFalse);
      });

      test('elevatedFab is Fab', () {
        expect(LayrzButtonStyle.elevatedFab.isFab, isTrue);
      });

      test('filledTonal is not Fab', () {
        expect(LayrzButtonStyle.filledTonal.isFab, isFalse);
      });

      test('filledTonalFab is Fab', () {
        expect(LayrzButtonStyle.filledTonalFab.isFab, isTrue);
      });

      test('outlined is not Fab', () {
        expect(LayrzButtonStyle.outlined.isFab, isFalse);
      });

      test('outlinedFab is Fab', () {
        expect(LayrzButtonStyle.outlinedFab.isFab, isTrue);
      });

      test('outlinedTonal is not Fab', () {
        expect(LayrzButtonStyle.outlinedTonal.isFab, isFalse);
      });

      test('outlinedTonalFab is Fab', () {
        expect(LayrzButtonStyle.outlinedTonalFab.isFab, isTrue);
      });
    });

    group('isTonal extension property', () {
      test('filled is not tonal', () {
        expect(LayrzButtonStyle.filled.isTonal, isFalse);
      });

      test('filledFab is not tonal', () {
        expect(LayrzButtonStyle.filledFab.isTonal, isFalse);
      });

      test('elevated is not tonal', () {
        expect(LayrzButtonStyle.elevated.isTonal, isFalse);
      });

      test('elevatedFab is not tonal', () {
        expect(LayrzButtonStyle.elevatedFab.isTonal, isFalse);
      });

      test('filledTonal is tonal', () {
        expect(LayrzButtonStyle.filledTonal.isTonal, isTrue);
      });

      test('filledTonalFab is tonal', () {
        expect(LayrzButtonStyle.filledTonalFab.isTonal, isTrue);
      });

      test('outlined is not tonal', () {
        expect(LayrzButtonStyle.outlined.isTonal, isFalse);
      });

      test('outlinedFab is not tonal', () {
        expect(LayrzButtonStyle.outlinedFab.isTonal, isFalse);
      });

      test('outlinedTonal is tonal', () {
        expect(LayrzButtonStyle.outlinedTonal.isTonal, isTrue);
      });

      test('outlinedTonalFab is tonal', () {
        expect(LayrzButtonStyle.outlinedTonalFab.isTonal, isTrue);
      });
    });

    group('hasBorder extension property', () {
      test('filled does not have border', () {
        expect(LayrzButtonStyle.filled.hasBorder, isFalse);
      });

      test('filledFab does not have border', () {
        expect(LayrzButtonStyle.filledFab.hasBorder, isFalse);
      });

      test('elevated does not have border', () {
        expect(LayrzButtonStyle.elevated.hasBorder, isFalse);
      });

      test('elevatedFab does not have border', () {
        expect(LayrzButtonStyle.elevatedFab.hasBorder, isFalse);
      });

      test('filledTonal does not have border', () {
        expect(LayrzButtonStyle.filledTonal.hasBorder, isFalse);
      });

      test('filledTonalFab does not have border', () {
        expect(LayrzButtonStyle.filledTonalFab.hasBorder, isFalse);
      });

      test('outlined has border', () {
        expect(LayrzButtonStyle.outlined.hasBorder, isTrue);
      });

      test('outlinedFab has border', () {
        expect(LayrzButtonStyle.outlinedFab.hasBorder, isTrue);
      });

      test('outlinedTonal has border', () {
        expect(LayrzButtonStyle.outlinedTonal.hasBorder, isTrue);
      });

      test('outlinedTonalFab has border', () {
        expect(LayrzButtonStyle.outlinedTonalFab.hasBorder, isTrue);
      });
    });

    group('hasShadow extension property', () {
      test('filled does not have shadow', () {
        expect(LayrzButtonStyle.filled.hasShadow, isFalse);
      });

      test('filledFab does not have shadow', () {
        expect(LayrzButtonStyle.filledFab.hasShadow, isFalse);
      });

      test('elevated has shadow', () {
        expect(LayrzButtonStyle.elevated.hasShadow, isTrue);
      });

      test('elevatedFab has shadow', () {
        expect(LayrzButtonStyle.elevatedFab.hasShadow, isTrue);
      });

      test('filledTonal does not have shadow', () {
        expect(LayrzButtonStyle.filledTonal.hasShadow, isFalse);
      });

      test('filledTonalFab does not have shadow', () {
        expect(LayrzButtonStyle.filledTonalFab.hasShadow, isFalse);
      });

      test('outlined does not have shadow', () {
        expect(LayrzButtonStyle.outlined.hasShadow, isFalse);
      });

      test('outlinedFab does not have shadow', () {
        expect(LayrzButtonStyle.outlinedFab.hasShadow, isFalse);
      });

      test('outlinedTonal does not have shadow', () {
        expect(LayrzButtonStyle.outlinedTonal.hasShadow, isFalse);
      });

      test('outlinedTonalFab does not have shadow', () {
        expect(LayrzButtonStyle.outlinedTonalFab.hasShadow, isFalse);
      });
    });

    group('Extension property matrix (all styles)', () {
      test('all non-Fab styles match their Fab counterparts in isTonal and hasBorder', () {
        for (final style in LayrzButtonStyle.values) {
          if (style.isFab) continue;
          final fabStyle = _getFabCounterpart(style);
          expect(
            style.isTonal,
            equals(fabStyle.isTonal),
            reason: '$style.isTonal should equal $fabStyle.isTonal',
          );
          expect(
            style.hasBorder,
            equals(fabStyle.hasBorder),
            reason: '$style.hasBorder should equal $fabStyle.hasBorder',
          );
          expect(
            style.hasShadow,
            equals(fabStyle.hasShadow),
            reason: '$style.hasShadow should equal $fabStyle.hasShadow',
          );
        }
      });
    });
  });
}

/// Helper function to get the Fab counterpart of a non-Fab style.
LayrzButtonStyle _getFabCounterpart(LayrzButtonStyle style) {
  switch (style) {
    case LayrzButtonStyle.filled:
      return LayrzButtonStyle.filledFab;
    case LayrzButtonStyle.elevated:
      return LayrzButtonStyle.elevatedFab;
    case LayrzButtonStyle.filledTonal:
      return LayrzButtonStyle.filledTonalFab;
    case LayrzButtonStyle.outlined:
      return LayrzButtonStyle.outlinedFab;
    case LayrzButtonStyle.outlinedTonal:
      return LayrzButtonStyle.outlinedTonalFab;
    default:
      throw AssertionError('$style is already a Fab style');
  }
}
