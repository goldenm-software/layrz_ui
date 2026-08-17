import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzButtonStyle', () {
    group('enum values', () {
      test('has exactly 6 style variants', () {
        expect(LayrzButtonStyle.values.length, equals(6));
      });

      test('contains all expected non-Fab styles', () {
        expect(
          LayrzButtonStyle.values,
          containsAll([
            LayrzButtonStyle.elevated,
            LayrzButtonStyle.outlined,
            LayrzButtonStyle.outlinedTonal,
          ]),
        );
      });

      test('contains all expected Fab styles', () {
        expect(
          LayrzButtonStyle.values,
          containsAll([
            LayrzButtonStyle.elevatedFab,
            LayrzButtonStyle.outlinedFab,
            LayrzButtonStyle.outlinedTonalFab,
          ]),
        );
      });
    });

    group('isFab extension property', () {
      test('elevated is not Fab', () {
        expect(LayrzButtonStyle.elevated.isFab, isFalse);
      });

      test('elevatedFab is Fab', () {
        expect(LayrzButtonStyle.elevatedFab.isFab, isTrue);
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
      test('elevated is not tonal', () {
        expect(LayrzButtonStyle.elevated.isTonal, isFalse);
      });

      test('elevatedFab is not tonal', () {
        expect(LayrzButtonStyle.elevatedFab.isTonal, isFalse);
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
      test('elevated does not have border', () {
        expect(LayrzButtonStyle.elevated.hasBorder, isFalse);
      });

      test('elevatedFab does not have border', () {
        expect(LayrzButtonStyle.elevatedFab.hasBorder, isFalse);
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
      test('elevated has shadow', () {
        expect(LayrzButtonStyle.elevated.hasShadow, isTrue);
      });

      test('elevatedFab has shadow', () {
        expect(LayrzButtonStyle.elevatedFab.hasShadow, isTrue);
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
          final fabStyle = style.asFab;
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

    group('asFab extension property', () {
      test('elevated maps to elevatedFab', () {
        expect(LayrzButtonStyle.elevated.asFab, equals(LayrzButtonStyle.elevatedFab));
      });

      test('elevatedFab returns itself', () {
        expect(LayrzButtonStyle.elevatedFab.asFab, equals(LayrzButtonStyle.elevatedFab));
      });

      test('outlined maps to outlinedFab', () {
        expect(LayrzButtonStyle.outlined.asFab, equals(LayrzButtonStyle.outlinedFab));
      });

      test('outlinedFab returns itself', () {
        expect(LayrzButtonStyle.outlinedFab.asFab, equals(LayrzButtonStyle.outlinedFab));
      });

      test('outlinedTonal maps to outlinedTonalFab', () {
        expect(LayrzButtonStyle.outlinedTonal.asFab, equals(LayrzButtonStyle.outlinedTonalFab));
      });

      test('outlinedTonalFab returns itself', () {
        expect(LayrzButtonStyle.outlinedTonalFab.asFab, equals(LayrzButtonStyle.outlinedTonalFab));
      });
    });
  });
}
