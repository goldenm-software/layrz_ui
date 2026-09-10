import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzBadgeType', () {
    testWidgets('info resolves to tokens.colors.info', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      expect(LayrzBadgeType.info.colorToken(tokens), equals(tokens.colors.info));
    });

    testWidgets('success resolves to tokens.colors.success', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      expect(LayrzBadgeType.success.colorToken(tokens), equals(tokens.colors.success));
    });

    testWidgets('warning resolves to tokens.colors.warning', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      expect(LayrzBadgeType.warning.colorToken(tokens), equals(tokens.colors.warning));
    });

    testWidgets('danger resolves to tokens.colors.danger', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      expect(LayrzBadgeType.danger.colorToken(tokens), equals(tokens.colors.danger));
    });

    testWidgets('context resolves to tokens.colors.contextual', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      expect(LayrzBadgeType.context.colorToken(tokens), equals(tokens.colors.contextual));
    });

    testWidgets('custom resolves to null, deferring to an explicit color', (tester) async {
      await pumpThemed(tester, Container());
      final tokens = LayrzTheme.of(tester.element(find.byType(Container))).tokens;

      expect(LayrzBadgeType.custom.colorToken(tokens), isNull);
    });

    test('enum has exactly six values in the documented order', () {
      expect(LayrzBadgeType.values, [
        LayrzBadgeType.info,
        LayrzBadgeType.success,
        LayrzBadgeType.warning,
        LayrzBadgeType.danger,
        LayrzBadgeType.context,
        LayrzBadgeType.custom,
      ]);
    });
  });
}
