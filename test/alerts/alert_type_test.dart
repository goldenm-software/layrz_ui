import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzAlertType', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
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
      test('info type returns info.shade500', () {
        expect(
          LayrzAlertType.info.colorToken(tokens),
          equals(tokens.colors.info.shade500),
        );
      });

      test('success type returns success.shade500', () {
        expect(
          LayrzAlertType.success.colorToken(tokens),
          equals(tokens.colors.success.shade500),
        );
      });

      test('warning type returns warning.shade500', () {
        expect(
          LayrzAlertType.warning.colorToken(tokens),
          equals(tokens.colors.warning.shade500),
        );
      });

      test('danger type returns danger.shade500', () {
        expect(
          LayrzAlertType.danger.colorToken(tokens),
          equals(tokens.colors.danger.shade500),
        );
      });

      test('context type returns contextual.shade500', () {
        expect(
          LayrzAlertType.context.colorToken(tokens),
          equals(tokens.colors.contextual.shade500),
        );
      });

      test('custom type returns null (caller provides color)', () {
        expect(LayrzAlertType.custom.colorToken(tokens), isNull);
      });
    });
  });
}
