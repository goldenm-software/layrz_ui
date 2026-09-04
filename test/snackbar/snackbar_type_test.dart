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
      test('success type returns success.shade800', () {
        expect(
          LayrzSnackbarType.success.accentColor(tokens),
          equals(tokens.colors.success.shade800),
        );
      });

      test('danger type returns danger.shade700', () {
        expect(
          LayrzSnackbarType.danger.accentColor(tokens),
          equals(tokens.colors.danger.shade700),
        );
      });

      test('warning type returns warning.shade600', () {
        expect(
          LayrzSnackbarType.warning.accentColor(tokens),
          equals(tokens.colors.warning.shade600),
        );
      });

      test('info type returns info.shade800', () {
        expect(
          LayrzSnackbarType.info.accentColor(tokens),
          equals(tokens.colors.info.shade800),
        );
      });

      test('context type returns contextual.shade800', () {
        expect(
          LayrzSnackbarType.context.accentColor(tokens),
          equals(tokens.colors.contextual.shade800),
        );
      });

      test('custom type returns null (caller provides color)', () {
        expect(LayrzSnackbarType.custom.accentColor(tokens), isNull);
      });

      test('accent colors match the design-spec hexes where the token allows', () {
        // danger #D32F2F, success #2E7D32, warning #E65100, info #1565C0
        // (context intentionally diverges — see accentColor doc comment: the
        // contextual token is Material grey, not blue-grey, so #37474F has no
        // exact match on this swatch).
        expect(LayrzSnackbarType.danger.accentColor(tokens)!.toHex(), equals('#D32F2F'));
        expect(LayrzSnackbarType.success.accentColor(tokens)!.toHex(), equals('#2E7D32'));
        expect(LayrzSnackbarType.warning.accentColor(tokens)!.toHex(), equals('#E65100'));
        expect(LayrzSnackbarType.info.accentColor(tokens)!.toHex(), equals('#1565C0'));
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
