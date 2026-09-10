import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

void main() {
  group('LayrzAlertType', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    group('icon resolution', () {
      test('info type returns informationBoxOutline', () {
        expect(
          LayrzAlertType.info.icon,
          equals(MdiIcons.informationBoxOutline),
        );
      });

      test('success type returns checkboxOutline', () {
        expect(
          LayrzAlertType.success.icon,
          equals(MdiIcons.checkboxOutline),
        );
      });

      test('warning type returns alertBoxOutline', () {
        expect(
          LayrzAlertType.warning.icon,
          equals(MdiIcons.alertBoxOutline),
        );
      });

      test('danger type returns closeBoxOutline', () {
        expect(
          LayrzAlertType.danger.icon,
          equals(MdiIcons.closeBoxOutline),
        );
      });

      test('context type returns dotsSquare', () {
        expect(
          LayrzAlertType.context.icon,
          equals(MdiIcons.dotsSquare),
        );
      });

      test('custom type returns null (caller provides icon)', () {
        expect(LayrzAlertType.custom.icon, isNull);
      });
    });

    group('color resolution', () {
      test('info type returns.info', () {
        expect(
          LayrzAlertType.info.colorToken(tokens),
          equals(tokens.colors.info),
        );
      });

      test('success type returns.success', () {
        expect(
          LayrzAlertType.success.colorToken(tokens),
          equals(tokens.colors.success),
        );
      });

      test('warning type returns.warning', () {
        expect(
          LayrzAlertType.warning.colorToken(tokens),
          equals(tokens.colors.warning),
        );
      });

      test('danger type returns.danger', () {
        expect(
          LayrzAlertType.danger.colorToken(tokens),
          equals(tokens.colors.danger),
        );
      });

      test('context type returns.contextual', () {
        expect(
          LayrzAlertType.context.colorToken(tokens),
          equals(tokens.colors.contextual),
        );
      });

      test('custom type returns null (caller provides color)', () {
        expect(LayrzAlertType.custom.colorToken(tokens), isNull);
      });
    });
  });
}
