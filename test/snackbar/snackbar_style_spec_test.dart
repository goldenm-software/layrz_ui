import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_style_spec.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_type.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

void main() {
  group('LayrzSnackbarStyleSpec', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    group('resolve — semantic types (white-card treatment)', () {
      for (final type in [
        LayrzSnackbarType.success,
        LayrzSnackbarType.danger,
        LayrzSnackbarType.warning,
        LayrzSnackbarType.info,
        LayrzSnackbarType.context,
      ]) {
        test('$type resolves surfaceColor to the light card surface, not the semantic color', () {
          final spec = LayrzSnackbarStyleSpec.resolve(type, tokens);

          expect(spec.surfaceColor, equals(tokens.colors.sf1));
          expect(spec.surfaceColor, isNot(equals(type.accentColor(tokens))));
        });

        test('$type resolves accentColor/titleColor/iconColor/progressColor to the semantic color', () {
          final spec = LayrzSnackbarStyleSpec.resolve(type, tokens);
          final expectedAccent = type.accentColor(tokens);

          expect(spec.accentColor, equals(expectedAccent));
          expect(spec.titleColor, equals(expectedAccent));
          expect(spec.iconColor, equals(expectedAccent));
          expect(spec.progressColor, equals(expectedAccent));
        });

        test('$type resolves descriptionColor to the neutral grey token, not the accent', () {
          final spec = LayrzSnackbarStyleSpec.resolve(type, tokens);

          expect(spec.descriptionColor, equals(tokens.colors.fg2));
          expect(spec.descriptionColor, isNot(equals(spec.accentColor)));
        });
      }

      test('borderColor resolves from the divider token, not a semantic tint', () {
        final spec = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.danger, tokens);

        expect(spec.borderColor, equals(tokens.colors.divider));
        expect(spec.borderColor, isNot(equals(spec.accentColor)));
      });

      test('shadow is a soft neutral shadow, not tinted by the accent color', () {
        final spec = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.danger, tokens);

        expect(spec.shadow, hasLength(1));
        expect(spec.shadow.first.color, isNot(equals(spec.accentColor)));
        expect(spec.shadow.first.blurRadius, equals(20));
        expect(spec.shadow.first.offset, equals(const Offset(0, 6)));
      });
    });

    group('resolve — custom type', () {
      test('uses customColor as accentColor when provided', () {
        const customColor = Color(0xFF123456);
        final spec = LayrzSnackbarStyleSpec.resolve(
          LayrzSnackbarType.custom,
          tokens,
          customColor: customColor,
          customIcon: null,
        );

        expect(spec.accentColor, equals(customColor));
        expect(spec.titleColor, equals(customColor));
        expect(spec.iconColor, equals(customColor));
        expect(spec.progressColor, equals(customColor));
      });

      test('surfaceColor stays the light card surface for the custom path too', () {
        const customColor = Color(0xFF123456);
        final spec = LayrzSnackbarStyleSpec.resolve(
          LayrzSnackbarType.custom,
          tokens,
          customColor: customColor,
        );

        expect(spec.surfaceColor, equals(tokens.colors.sf1));
      });

      test('falls back to tokens.colors.primary.shade500 when customColor is null', () {
        final spec = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.custom, tokens);

        expect(spec.accentColor, equals(tokens.colors.primary.shade500));
      });

      test('descriptionColor stays the neutral grey token regardless of the custom accent', () {
        const customColor = Color(0xFF123456);
        final spec = LayrzSnackbarStyleSpec.resolve(
          LayrzSnackbarType.custom,
          tokens,
          customColor: customColor,
        );

        expect(spec.descriptionColor, equals(tokens.colors.fg2));
      });
    });

    group('copyWith', () {
      test('replaces only the given fields', () {
        final spec = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.success, tokens);
        const replacement = Color(0xFFABCDEF);

        final copy = spec.copyWith(surfaceColor: replacement);

        expect(copy.surfaceColor, equals(replacement));
        expect(copy.accentColor, equals(spec.accentColor));
        expect(copy.titleColor, equals(spec.titleColor));
        expect(copy.descriptionColor, equals(spec.descriptionColor));
        expect(copy.iconColor, equals(spec.iconColor));
        expect(copy.progressColor, equals(spec.progressColor));
        expect(copy.borderColor, equals(spec.borderColor));
        expect(copy.shadow, equals(spec.shadow));
      });
    });

    group('equality', () {
      test('two specs resolved from the same inputs are equal', () {
        final a = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.info, tokens);
        final b = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.info, tokens);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('specs resolved from different types are not equal', () {
        final a = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.info, tokens);
        final b = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.warning, tokens);

        expect(a, isNot(equals(b)));
      });

      test('specs with differing shadow lists are not equal', () {
        final a = LayrzSnackbarStyleSpec.resolve(LayrzSnackbarType.info, tokens);
        final b = a.copyWith(shadow: const [BoxShadow(color: Color(0xFF000000))]);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
