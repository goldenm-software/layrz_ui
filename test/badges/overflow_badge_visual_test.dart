import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzOverflowBadgeVisual', () {
    test('formats the hidden count with a plus prefix', () {
      expect(LayrzOverflowBadgeVisual.formatOverflow(3), '+3');
      expect(LayrzOverflowBadgeVisual.formatOverflow(99), '+99');
    });

    test('caps at +99 and clamps negatives to +0', () {
      expect(LayrzOverflowBadgeVisual.formatOverflow(150), '+99');
      expect(LayrzOverflowBadgeVisual.formatOverflow(-2), '+0');
    });

    testWidgets('renders +N inside the badge', (tester) async {
      await pumpThemed(tester, const LayrzOverflowBadgeVisual(count: 3));

      expect(find.text('+3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is a LayrzBadgeVisual with the same type and color', (tester) async {
      const Color color = Color(0xFF001E60);
      await pumpThemed(
        tester,
        const LayrzOverflowBadgeVisual(count: 2, type: LayrzBadgeType.custom, color: color),
      );

      final LayrzBadgeVisual badge = tester.widget<LayrzBadgeVisual>(find.byType(LayrzOverflowBadgeVisual));
      expect(badge.type, LayrzBadgeType.custom);
      expect(badge.color, color);
    });

    testWidgets('LayrzBadgeVisual still renders the bare count', (tester) async {
      await pumpThemed(tester, const LayrzBadgeVisual(count: 3));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('+3'), findsNothing);
    });
  });
}
