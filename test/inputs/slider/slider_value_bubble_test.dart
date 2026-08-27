import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzSliderValueBubble', () {
    guardedTestWidgets('renders the given text', (tester) async {
      final tokens = LayrzTokens.light();
      await pumpThemed(
        tester,
        LayrzSliderValueBubble(
          text: '42',
          color: tokens.colors.fg1,
          textColor: tokens.colors.sf1,
          tokens: tokens,
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    guardedTestWidgets('applies the given fill and text colours', (tester) async {
      final tokens = LayrzTokens.light();
      const fill = Color(0xFF123456);
      const textColor = Color(0xFFABCDEF);

      await pumpThemed(
        tester,
        LayrzSliderValueBubble(
          text: '7',
          color: fill,
          textColor: textColor,
          tokens: tokens,
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, fill);

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, textColor);
    });

    guardedTestWidgets('paints a shadow from the shadow tokens', (tester) async {
      final tokens = LayrzTokens.light();
      await pumpThemed(
        tester,
        LayrzSliderValueBubble(
          text: '1',
          color: tokens.colors.fg1,
          textColor: tokens.colors.sf1,
          tokens: tokens,
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
    });
  });
}
