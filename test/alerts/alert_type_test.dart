import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_icons/layrz_icons.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzAlertType', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
    });

    group('icon resolution', () {
      test('info type returns solarOutlineInfoSquare', () {
        expect(
          LayrzAlertType.info.icon,
          equals(LayrzIcons.solarOutlineInfoSquare),
        );
      });

      test('success type returns solarOutlineCheckSquare', () {
        expect(
          LayrzAlertType.success.icon,
          equals(LayrzIcons.solarOutlineCheckSquare),
        );
      });

      test('warning type returns solarOutlineDangerSquare', () {
        expect(
          LayrzAlertType.warning.icon,
          equals(LayrzIcons.solarOutlineDangerSquare),
        );
      });

      test('danger type returns solarOutlineCloseSquare', () {
        expect(
          LayrzAlertType.danger.icon,
          equals(LayrzIcons.solarOutlineCloseSquare),
        );
      });

      test('context type returns solarOutlineMenuDotsSquare', () {
        expect(
          LayrzAlertType.context.icon,
          equals(LayrzIcons.solarOutlineMenuDotsSquare),
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
