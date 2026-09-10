import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/snackbar/src/snackbar_type.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

void main() {
  group('LayrzSnackbarType', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    group('icon resolution', () {
      test('success type returns checkCircle', () {
        expect(LayrzSnackbarType.success.icon, equals(MdiIcons.checkCircle));
      });

      test('danger type returns alertCircle', () {
        expect(LayrzSnackbarType.danger.icon, equals(MdiIcons.alertCircle));
      });

      test('warning type returns alert', () {
        expect(LayrzSnackbarType.warning.icon, equals(MdiIcons.alert));
      });

      test('info type returns information', () {
        expect(LayrzSnackbarType.info.icon, equals(MdiIcons.information));
      });

      test('context type returns messageText', () {
        expect(LayrzSnackbarType.context.icon, equals(MdiIcons.messageText));
      });

      test('custom type returns null (caller provides icon)', () {
        expect(LayrzSnackbarType.custom.icon, isNull);
      });
    });

    group('accentColor resolution', () {
      // Each accent is the plain semantic token, matching the same semantic used
      // by buttons/chips/badges rather than a darkened variant.
      test('success type returns the plain success token', () {
        expect(LayrzSnackbarType.success.accentColor(tokens), equals(tokens.colors.success));
      });

      test('danger type returns the plain danger token', () {
        expect(LayrzSnackbarType.danger.accentColor(tokens), equals(tokens.colors.danger));
      });

      test('warning type returns the plain warning token', () {
        expect(LayrzSnackbarType.warning.accentColor(tokens), equals(tokens.colors.warning));
      });

      test('info type returns the plain info token', () {
        expect(LayrzSnackbarType.info.accentColor(tokens), equals(tokens.colors.info));
      });

      test('context type returns the plain contextual token', () {
        expect(LayrzSnackbarType.context.accentColor(tokens), equals(tokens.colors.contextual));
      });

      test('custom type returns null (caller provides color)', () {
        expect(LayrzSnackbarType.custom.accentColor(tokens), isNull);
      });

      test('accent colors are the light-theme semantic hexes', () {
        expect(LayrzSnackbarType.danger.accentColor(tokens)!.toHex(), equals('#F44336'));
        expect(LayrzSnackbarType.success.accentColor(tokens)!.toHex(), equals('#4CAF50'));
        expect(LayrzSnackbarType.warning.accentColor(tokens)!.toHex(), equals('#EF6C00'));
        expect(LayrzSnackbarType.info.accentColor(tokens)!.toHex(), equals('#2196F3'));
        expect(LayrzSnackbarType.context.accentColor(tokens)!.toHex(), equals('#9E9E9E'));
      });
    });

    test('enum values are exactly custom, success, danger, warning, info, context', () {
      expect(
        LayrzSnackbarType.values,
        equals(const [
          LayrzSnackbarType.custom,
          LayrzSnackbarType.success,
          LayrzSnackbarType.danger,
          LayrzSnackbarType.warning,
          LayrzSnackbarType.info,
          LayrzSnackbarType.context,
        ]),
      );
    });
  });
}
