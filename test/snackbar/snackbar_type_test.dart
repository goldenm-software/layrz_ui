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
      test('success type returns success.darken(0.3)', () {
        expect(
          LayrzSnackbarType.success.accentColor(tokens),
          equals(tokens.colors.success.darken(0.3)),
        );
      });

      test('danger type returns danger.darken(0.22)', () {
        expect(
          LayrzSnackbarType.danger.accentColor(tokens),
          equals(tokens.colors.danger.darken(0.22)),
        );
      });

      test('warning type returns warning.darken(0.15)', () {
        expect(
          LayrzSnackbarType.warning.accentColor(tokens),
          equals(tokens.colors.warning.darken(0.15)),
        );
      });

      test('info type returns info.darken(0.3)', () {
        expect(
          LayrzSnackbarType.info.accentColor(tokens),
          equals(tokens.colors.info.darken(0.3)),
        );
      });

      test('context type returns contextual.darken(0.3)', () {
        expect(
          LayrzSnackbarType.context.accentColor(tokens),
          equals(tokens.colors.contextual.darken(0.3)),
        );
      });

      test('custom type returns null (caller provides color)', () {
        expect(LayrzSnackbarType.custom.accentColor(tokens), isNull);
      });

      test('accent colors match the derived-darken hexes', () {
        // Each accent is `tokens.colors.<sem>.darken(<amount>)` composited over
        // opaque black (see LayrzColorExtensions.darken). Computed from the
        // light-theme base hexes: danger #F44336, success #4CAF50,
        // warning #EF6C00, info #2196F3, contextual #9E9E9E.
        expect(LayrzSnackbarType.danger.accentColor(tokens)!.toHex(), equals('#BE342A'));
        expect(LayrzSnackbarType.success.accentColor(tokens)!.toHex(), equals('#357A38'));
        expect(LayrzSnackbarType.warning.accentColor(tokens)!.toHex(), equals('#CB5C00'));
        expect(LayrzSnackbarType.info.accentColor(tokens)!.toHex(), equals('#1769AA'));
        expect(LayrzSnackbarType.context.accentColor(tokens)!.toHex(), equals('#6F6F6F'));
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
