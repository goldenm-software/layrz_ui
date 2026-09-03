import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzColors', () {
    /// All Material swatches in the palette.
    final swatches = [
      ('red', LayrzColors.red),
      ('pink', LayrzColors.pink),
      ('purple', LayrzColors.purple),
      ('deepPurple', LayrzColors.deepPurple),
      ('indigo', LayrzColors.indigo),
      ('blue', LayrzColors.blue),
      ('lightBlue', LayrzColors.lightBlue),
      ('cyan', LayrzColors.cyan),
      ('teal', LayrzColors.teal),
      ('green', LayrzColors.green),
      ('lightGreen', LayrzColors.lightGreen),
      ('lime', LayrzColors.lime),
      ('yellow', LayrzColors.yellow),
      ('amber', LayrzColors.amber),
      ('orange', LayrzColors.orange),
      ('deepOrange', LayrzColors.deepOrange),
      ('brown', LayrzColors.brown),
      ('grey', LayrzColors.grey),
      ('blueGrey', LayrzColors.blueGrey),
    ];

    group('swatch completeness', () {
      for (final (name, swatch) in swatches) {
        test('$name swatch has all ten shades', () {
          expect(swatch.shade50, isA<Color>());
          expect(swatch.shade100, isA<Color>());
          expect(swatch.shade200, isA<Color>());
          expect(swatch.shade300, isA<Color>());
          expect(swatch.shade400, isA<Color>());
          expect(swatch.shade500, isA<Color>());
          expect(swatch.shade600, isA<Color>());
          expect(swatch.shade700, isA<Color>());
          expect(swatch.shade800, isA<Color>());
          expect(swatch.shade900, isA<Color>());
        });
      }
    });

    group('primary consistency', () {
      for (final (name, swatch) in swatches) {
        test('$name primary equals shade500', () {
          // The primary value (stored in the ColorSwatch) should equal shade500.
          // ColorSwatch stores the primary at index 500, and shade500 reads this[500].
          expect(swatch.shade500.toARGB32(), equals(swatch.toARGB32()));
        });
      }
    });

    group('material palette values', () {
      test('red palette matches Material', () {
        expect(LayrzColors.red.shade50, equals(const Color(0xFFFFEBEE)));
        expect(LayrzColors.red.shade100, equals(const Color(0xFFFFCDD2)));
        expect(LayrzColors.red.shade200, equals(const Color(0xFFEF9A9A)));
        expect(LayrzColors.red.shade300, equals(const Color(0xFFE57373)));
        expect(LayrzColors.red.shade400, equals(const Color(0xFFEF5350)));
        expect(LayrzColors.red.shade500, equals(const Color(0xFFF44336)));
        expect(LayrzColors.red.shade600, equals(const Color(0xFFE53935)));
        expect(LayrzColors.red.shade700, equals(const Color(0xFFD32F2F)));
        expect(LayrzColors.red.shade800, equals(const Color(0xFFC62828)));
        expect(LayrzColors.red.shade900, equals(const Color(0xFFB71C1C)));
      });

      test('pink palette matches Material', () {
        expect(LayrzColors.pink.shade500, equals(const Color(0xFFE91E63)));
        expect(LayrzColors.pink.shade50, equals(const Color(0xFFFCE4EC)));
        expect(LayrzColors.pink.shade100, equals(const Color(0xFFF8BBD0)));
        expect(LayrzColors.pink.shade900, equals(const Color(0xFF78063B)));
      });

      test('purple palette matches Material', () {
        expect(LayrzColors.purple.shade500, equals(const Color(0xFF9C27B0)));
        expect(LayrzColors.purple.shade50, equals(const Color(0xFFF3E5F5)));
        expect(LayrzColors.purple.shade900, equals(const Color(0xFF4A148C)));
      });

      test('deepPurple palette matches Material', () {
        expect(LayrzColors.deepPurple.shade500, equals(const Color(0xFF673AB7)));
        expect(LayrzColors.deepPurple.shade50, equals(const Color(0xFFEDE7F6)));
        expect(LayrzColors.deepPurple.shade900, equals(const Color(0xFF311B92)));
      });

      test('indigo palette matches Material', () {
        expect(LayrzColors.indigo.shade500, equals(const Color(0xFF3F51B5)));
        expect(LayrzColors.indigo.shade50, equals(const Color(0xFFE8EAF6)));
        expect(LayrzColors.indigo.shade900, equals(const Color(0xFF1A237E)));
      });

      test('blue palette matches Material', () {
        expect(LayrzColors.blue.shade50, equals(const Color(0xFFE3F2FD)));
        expect(LayrzColors.blue.shade100, equals(const Color(0xFFBBDEFB)));
        expect(LayrzColors.blue.shade200, equals(const Color(0xFF90CAF9)));
        expect(LayrzColors.blue.shade300, equals(const Color(0xFF64B5F6)));
        expect(LayrzColors.blue.shade400, equals(const Color(0xFF42A5F5)));
        expect(LayrzColors.blue.shade500, equals(const Color(0xFF2196F3)));
        expect(LayrzColors.blue.shade600, equals(const Color(0xFF1E88E5)));
        expect(LayrzColors.blue.shade700, equals(const Color(0xFF1976D2)));
        expect(LayrzColors.blue.shade800, equals(const Color(0xFF1565C0)));
        expect(LayrzColors.blue.shade900, equals(const Color(0xFF0D47A1)));
      });

      test('lightBlue palette matches Material', () {
        expect(LayrzColors.lightBlue.shade500, equals(const Color(0xFF03A9F4)));
        expect(LayrzColors.lightBlue.shade50, equals(const Color(0xFFE1F5FE)));
        expect(LayrzColors.lightBlue.shade900, equals(const Color(0xFF01579B)));
      });

      test('cyan palette matches Material', () {
        expect(LayrzColors.cyan.shade500, equals(const Color(0xFF00BCD4)));
        expect(LayrzColors.cyan.shade50, equals(const Color(0xFFE0F2F1)));
        expect(LayrzColors.cyan.shade900, equals(const Color(0xFF006064)));
      });

      test('teal palette matches Material', () {
        expect(LayrzColors.teal.shade500, equals(const Color(0xFF009688)));
        expect(LayrzColors.teal.shade50, equals(const Color(0xFFE0F2F1)));
        expect(LayrzColors.teal.shade900, equals(const Color(0xFF004D40)));
      });

      test('green palette matches Material', () {
        expect(LayrzColors.green.shade50, equals(const Color(0xFFE8F5E9)));
        expect(LayrzColors.green.shade100, equals(const Color(0xFFC8E6C9)));
        expect(LayrzColors.green.shade200, equals(const Color(0xFFA5D6A7)));
        expect(LayrzColors.green.shade300, equals(const Color(0xFF81C784)));
        expect(LayrzColors.green.shade400, equals(const Color(0xFF66BB6A)));
        expect(LayrzColors.green.shade500, equals(const Color(0xFF4CAF50)));
        expect(LayrzColors.green.shade600, equals(const Color(0xFF43A047)));
        expect(LayrzColors.green.shade700, equals(const Color(0xFF388E3C)));
        expect(LayrzColors.green.shade800, equals(const Color(0xFF2E7D32)));
        expect(LayrzColors.green.shade900, equals(const Color(0xFF1B5E20)));
      });

      test('lightGreen palette matches Material', () {
        expect(LayrzColors.lightGreen.shade500, equals(const Color(0xFF8BC34A)));
        expect(LayrzColors.lightGreen.shade50, equals(const Color(0xFFF1F8E9)));
        expect(LayrzColors.lightGreen.shade900, equals(const Color(0xFF33691E)));
      });

      test('lime palette matches Material', () {
        expect(LayrzColors.lime.shade500, equals(const Color(0xFFCDDC39)));
        expect(LayrzColors.lime.shade50, equals(const Color(0xFFFFFDE7)));
        expect(LayrzColors.lime.shade900, equals(const Color(0xFF827717)));
      });

      test('yellow palette matches Material', () {
        expect(LayrzColors.yellow.shade500, equals(const Color(0xFFFFEB3B)));
        expect(LayrzColors.yellow.shade50, equals(const Color(0xFFFFFDE7)));
        expect(LayrzColors.yellow.shade900, equals(const Color(0xFFF57F17)));
      });

      test('amber palette matches Material', () {
        expect(LayrzColors.amber.shade500, equals(const Color(0xFFFFC107)));
        expect(LayrzColors.amber.shade50, equals(const Color(0xFFFFF8E1)));
        expect(LayrzColors.amber.shade900, equals(const Color(0xFFFF6F00)));
      });

      test('orange palette matches Material', () {
        expect(LayrzColors.orange.shade50, equals(const Color(0xFFFFF3E0)));
        expect(LayrzColors.orange.shade100, equals(const Color(0xFFFFE0B2)));
        expect(LayrzColors.orange.shade200, equals(const Color(0xFFFFCC80)));
        expect(LayrzColors.orange.shade300, equals(const Color(0xFFFFB74D)));
        expect(LayrzColors.orange.shade400, equals(const Color(0xFFFFA726)));
        expect(LayrzColors.orange.shade500, equals(const Color(0xFFFF9800)));
        expect(LayrzColors.orange.shade600, equals(const Color(0xFFFB8C00)));
        expect(LayrzColors.orange.shade700, equals(const Color(0xFFF57C00)));
        expect(LayrzColors.orange.shade800, equals(const Color(0xFFEF6C00)));
        expect(LayrzColors.orange.shade900, equals(const Color(0xFFE65100)));
      });

      test('warningOrange has all ten shades and a consistent primary', () {
        // warningOrange is a layrz_ui-specific swatch (not a Material palette member,
        // hence not part of the `swatches` completeness/primary-consistency loops above),
        // so it gets its own coverage here.
        const swatch = LayrzColors.warningOrange;
        expect(swatch.shade50, isA<Color>());
        expect(swatch.shade100, isA<Color>());
        expect(swatch.shade200, isA<Color>());
        expect(swatch.shade300, isA<Color>());
        expect(swatch.shade400, isA<Color>());
        expect(swatch.shade500, isA<Color>());
        expect(swatch.shade600, isA<Color>());
        expect(swatch.shade700, isA<Color>());
        expect(swatch.shade800, isA<Color>());
        expect(swatch.shade900, isA<Color>());
        expect(swatch.shade500.toARGB32(), equals(swatch.toARGB32()));
      });

      test('warningOrange palette values and monotonic darkening', () {
        expect(LayrzColors.warningOrange.shade50, equals(const Color(0xFFFFF3E0)));
        expect(LayrzColors.warningOrange.shade100, equals(const Color(0xFFFFE0B2)));
        expect(LayrzColors.warningOrange.shade200, equals(const Color(0xFFFFCC80)));
        expect(LayrzColors.warningOrange.shade300, equals(const Color(0xFFFFB74D)));
        expect(LayrzColors.warningOrange.shade400, equals(const Color(0xFFFFA726)));
        expect(LayrzColors.warningOrange.shade500, equals(const Color(0xFFEF6C00)));
        expect(LayrzColors.warningOrange.shade600, equals(const Color(0xFFE65100)));
        expect(LayrzColors.warningOrange.shade700, equals(const Color(0xFFD84315)));
        expect(LayrzColors.warningOrange.shade800, equals(const Color(0xFFBF360C)));
        expect(LayrzColors.warningOrange.shade900, equals(const Color(0xFF8A2705)));

        // Each shade must be darker (lower luminance) than the previous one, so the
        // ramp reads coherently from lightest (50) to darkest (900).
        final shades = [
          LayrzColors.warningOrange.shade50,
          LayrzColors.warningOrange.shade100,
          LayrzColors.warningOrange.shade200,
          LayrzColors.warningOrange.shade300,
          LayrzColors.warningOrange.shade400,
          LayrzColors.warningOrange.shade500,
          LayrzColors.warningOrange.shade600,
          LayrzColors.warningOrange.shade700,
          LayrzColors.warningOrange.shade800,
          LayrzColors.warningOrange.shade900,
        ];
        for (var i = 1; i < shades.length; i++) {
          expect(
            shades[i].computeLuminance(),
            lessThan(shades[i - 1].computeLuminance()),
            reason: 'shade at index $i should be darker than the previous shade',
          );
        }
      });

      test('warningOrange 500 resolves white content, unlike Material orange 500', () {
        // The actual maintainer-facing contract: content (text/icons/badge counts)
        // painted on the warning accent must come out white.
        expect(LayrzColors.warningOrange.shade500.contrastColor, equals(const Color(0xFFFFFFFF)));
        // And this is genuinely a fix, not a no-op: the old Material orange 500 picked black.
        expect(LayrzColors.orange.shade500.contrastColor, equals(const Color(0xFF000000)));
      });

      test('deepOrange palette matches Material', () {
        expect(LayrzColors.deepOrange.shade500, equals(const Color(0xFFFF5722)));
        expect(LayrzColors.deepOrange.shade50, equals(const Color(0xFFFBE9E7)));
        expect(LayrzColors.deepOrange.shade900, equals(const Color(0xFFBF360C)));
      });

      test('brown palette matches Material', () {
        expect(LayrzColors.brown.shade500, equals(const Color(0xFF795548)));
        expect(LayrzColors.brown.shade50, equals(const Color(0xFFEFEBE9)));
        expect(LayrzColors.brown.shade900, equals(const Color(0xFF3E2723)));
      });

      test('grey palette matches Material', () {
        expect(LayrzColors.grey.shade50, equals(const Color(0xFFFAFAFA)));
        expect(LayrzColors.grey.shade100, equals(const Color(0xFFF5F5F5)));
        expect(LayrzColors.grey.shade200, equals(const Color(0xFFEEEEEE)));
        expect(LayrzColors.grey.shade300, equals(const Color(0xFFE0E0E0)));
        expect(LayrzColors.grey.shade400, equals(const Color(0xFFBDBDBD)));
        expect(LayrzColors.grey.shade500, equals(const Color(0xFF9E9E9E)));
        expect(LayrzColors.grey.shade600, equals(const Color(0xFF757575)));
        expect(LayrzColors.grey.shade700, equals(const Color(0xFF616161)));
        expect(LayrzColors.grey.shade800, equals(const Color(0xFF424242)));
        expect(LayrzColors.grey.shade900, equals(const Color(0xFF212121)));
      });

      test('blueGrey palette matches Material', () {
        expect(LayrzColors.blueGrey.shade500, equals(const Color(0xFF607D8B)));
        expect(LayrzColors.blueGrey.shade50, equals(const Color(0xFFECEFF1)));
        expect(LayrzColors.blueGrey.shade900, equals(const Color(0xFF263238)));
      });
    });

    group('achromatic colors', () {
      test('black is pure black', () {
        expect(LayrzColors.black, equals(const Color(0xFF000000)));
      });

      test('white is pure white', () {
        expect(LayrzColors.white, equals(const Color(0xFFFFFFFF)));
      });
    });

    group('semantic token regression', () {
      test('danger color tokens remain byte-identical', () {
        final tokens = LayrzColorTokens.light();
        // Verify danger is the red swatch
        expect(tokens.danger, equals(LayrzColors.red));
        // Verify all shades match exactly
        expect(tokens.danger.shade50, equals(const Color(0xFFFFEBEE)));
        expect(tokens.danger.shade100, equals(const Color(0xFFFFCDD2)));
        expect(tokens.danger.shade200, equals(const Color(0xFFEF9A9A)));
        expect(tokens.danger.shade300, equals(const Color(0xFFE57373)));
        expect(tokens.danger.shade400, equals(const Color(0xFFEF5350)));
        expect(tokens.danger.shade500, equals(const Color(0xFFF44336)));
        expect(tokens.danger.shade600, equals(const Color(0xFFE53935)));
        expect(tokens.danger.shade700, equals(const Color(0xFFD32F2F)));
        expect(tokens.danger.shade800, equals(const Color(0xFFC62828)));
        expect(tokens.danger.shade900, equals(const Color(0xFFB71C1C)));
      });

      test('success color tokens remain byte-identical', () {
        final tokens = LayrzColorTokens.light();
        // Verify success is the green swatch
        expect(tokens.success, equals(LayrzColors.green));
        // Verify primary value unchanged
        expect(tokens.success.shade500, equals(const Color(0xFF4CAF50)));
        // Verify all shades match exactly
        expect(tokens.success.shade50, equals(const Color(0xFFE8F5E9)));
        expect(tokens.success.shade100, equals(const Color(0xFFC8E6C9)));
        expect(tokens.success.shade200, equals(const Color(0xFFA5D6A7)));
        expect(tokens.success.shade300, equals(const Color(0xFF81C784)));
        expect(tokens.success.shade400, equals(const Color(0xFF66BB6A)));
        expect(tokens.success.shade500, equals(const Color(0xFF4CAF50)));
        expect(tokens.success.shade600, equals(const Color(0xFF43A047)));
        expect(tokens.success.shade700, equals(const Color(0xFF388E3C)));
        expect(tokens.success.shade800, equals(const Color(0xFF2E7D32)));
        expect(tokens.success.shade900, equals(const Color(0xFF1B5E20)));
      });

      test('warning color tokens remain byte-identical', () {
        final tokens = LayrzColorTokens.light();
        // Verify warning is the dedicated warningOrange swatch (not the Material orange
        // palette swatch, which keeps its own untouched values — see the "orange palette
        // matches Material" test above).
        expect(tokens.warning, equals(LayrzColors.warningOrange));
        // Verify primary value is the darkened 500 (Material orange's own 800 shade).
        expect(tokens.warning.shade500, equals(const Color(0xFFEF6C00)));
        // Verify all shades match exactly.
        expect(tokens.warning.shade50, equals(const Color(0xFFFFF3E0)));
        expect(tokens.warning.shade100, equals(const Color(0xFFFFE0B2)));
        expect(tokens.warning.shade200, equals(const Color(0xFFFFCC80)));
        expect(tokens.warning.shade300, equals(const Color(0xFFFFB74D)));
        expect(tokens.warning.shade400, equals(const Color(0xFFFFA726)));
        expect(tokens.warning.shade500, equals(const Color(0xFFEF6C00)));
        expect(tokens.warning.shade600, equals(const Color(0xFFE65100)));
        expect(tokens.warning.shade700, equals(const Color(0xFFD84315)));
        expect(tokens.warning.shade800, equals(const Color(0xFFBF360C)));
        expect(tokens.warning.shade900, equals(const Color(0xFF8A2705)));
      });

      test('warning content color resolves to white', () {
        // The real contract: content (text/icons/badge counts) painted on
        // tokens.colors.warning must come out white, not black.
        final tokens = LayrzColorTokens.light();
        expect(tokens.warning.shade500.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('info color tokens remain byte-identical', () {
        final tokens = LayrzColorTokens.light();
        // Verify info is the blue swatch
        expect(tokens.info, equals(LayrzColors.blue));
        // Verify primary value unchanged
        expect(tokens.info.shade500, equals(const Color(0xFF2196F3)));
        // Verify all shades match exactly
        expect(tokens.info.shade50, equals(const Color(0xFFE3F2FD)));
        expect(tokens.info.shade100, equals(const Color(0xFFBBDEFB)));
        expect(tokens.info.shade200, equals(const Color(0xFF90CAF9)));
        expect(tokens.info.shade300, equals(const Color(0xFF64B5F6)));
        expect(tokens.info.shade400, equals(const Color(0xFF42A5F5)));
        expect(tokens.info.shade500, equals(const Color(0xFF2196F3)));
        expect(tokens.info.shade600, equals(const Color(0xFF1E88E5)));
        expect(tokens.info.shade700, equals(const Color(0xFF1976D2)));
        expect(tokens.info.shade800, equals(const Color(0xFF1565C0)));
        expect(tokens.info.shade900, equals(const Color(0xFF0D47A1)));
      });

      test('contextual color tokens remain byte-identical', () {
        final tokens = LayrzColorTokens.light();
        // Verify contextual is the grey swatch
        expect(tokens.contextual, equals(LayrzColors.grey));
        // Verify primary value unchanged
        expect(tokens.contextual.shade500, equals(const Color(0xFF9E9E9E)));
        // Verify all shades match exactly
        expect(tokens.contextual.shade50, equals(const Color(0xFFFAFAFA)));
        expect(tokens.contextual.shade100, equals(const Color(0xFFF5F5F5)));
        expect(tokens.contextual.shade200, equals(const Color(0xFFEEEEEE)));
        expect(tokens.contextual.shade300, equals(const Color(0xFFE0E0E0)));
        expect(tokens.contextual.shade400, equals(const Color(0xFFBDBDBD)));
        expect(tokens.contextual.shade500, equals(const Color(0xFF9E9E9E)));
        expect(tokens.contextual.shade600, equals(const Color(0xFF757575)));
        expect(tokens.contextual.shade700, equals(const Color(0xFF616161)));
        expect(tokens.contextual.shade800, equals(const Color(0xFF424242)));
        expect(tokens.contextual.shade900, equals(const Color(0xFF212121)));
      });
    });
  });
}
