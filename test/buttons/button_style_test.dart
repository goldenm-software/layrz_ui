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
            LayrzButtonStyle.filled,
            LayrzButtonStyle.outlined,
            LayrzButtonStyle.text,
          ]),
        );
      });

      test('contains all expected Fab styles', () {
        expect(
          LayrzButtonStyle.values,
          containsAll([
            LayrzButtonStyle.filledFab,
            LayrzButtonStyle.outlinedFab,
            LayrzButtonStyle.textFab,
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

      test('outlined is not Fab', () {
        expect(LayrzButtonStyle.outlined.isFab, isFalse);
      });

      test('outlinedFab is Fab', () {
        expect(LayrzButtonStyle.outlinedFab.isFab, isTrue);
      });

      test('text is not Fab', () {
        expect(LayrzButtonStyle.text.isFab, isFalse);
      });

      test('textFab is Fab', () {
        expect(LayrzButtonStyle.textFab.isFab, isTrue);
      });
    });

    group('hasBorder extension property', () {
      test('filled does not have border', () {
        expect(LayrzButtonStyle.filled.hasBorder, isFalse);
      });

      test('filledFab does not have border', () {
        expect(LayrzButtonStyle.filledFab.hasBorder, isFalse);
      });

      test('outlined has border', () {
        expect(LayrzButtonStyle.outlined.hasBorder, isTrue);
      });

      test('outlinedFab has border', () {
        expect(LayrzButtonStyle.outlinedFab.hasBorder, isTrue);
      });

      test('text does not have border', () {
        expect(LayrzButtonStyle.text.hasBorder, isFalse);
      });

      test('textFab does not have border', () {
        expect(LayrzButtonStyle.textFab.hasBorder, isFalse);
      });
    });

    group('hasShadow extension property', () {
      test('filled has shadow', () {
        expect(LayrzButtonStyle.filled.hasShadow, isTrue);
      });

      test('filledFab has shadow', () {
        expect(LayrzButtonStyle.filledFab.hasShadow, isTrue);
      });

      test('outlined does not have shadow', () {
        expect(LayrzButtonStyle.outlined.hasShadow, isFalse);
      });

      test('outlinedFab does not have shadow', () {
        expect(LayrzButtonStyle.outlinedFab.hasShadow, isFalse);
      });

      test('text does not have shadow', () {
        expect(LayrzButtonStyle.text.hasShadow, isFalse);
      });

      test('textFab does not have shadow', () {
        expect(LayrzButtonStyle.textFab.hasShadow, isFalse);
      });
    });

    group('Extension property matrix (all styles)', () {
      test('all non-Fab styles match their Fab counterparts in hasBorder and hasShadow', () {
        for (final style in LayrzButtonStyle.values) {
          if (style.isFab) continue;
          final fabStyle = style.asFab;
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
      test('filled maps to filledFab', () {
        expect(LayrzButtonStyle.filled.asFab, equals(LayrzButtonStyle.filledFab));
      });

      test('filledFab returns itself', () {
        expect(LayrzButtonStyle.filledFab.asFab, equals(LayrzButtonStyle.filledFab));
      });

      test('outlined maps to outlinedFab', () {
        expect(LayrzButtonStyle.outlined.asFab, equals(LayrzButtonStyle.outlinedFab));
      });

      test('outlinedFab returns itself', () {
        expect(LayrzButtonStyle.outlinedFab.asFab, equals(LayrzButtonStyle.outlinedFab));
      });

      test('text maps to textFab', () {
        expect(LayrzButtonStyle.text.asFab, equals(LayrzButtonStyle.textFab));
      });

      test('textFab returns itself', () {
        expect(LayrzButtonStyle.textFab.asFab, equals(LayrzButtonStyle.textFab));
      });
    });
  });
}
