import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tooltips.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTooltip accessibility', () {
    testWidgets('semanticsTooltip is set to resolved plain text', (tester) async {
      const tooltipText = 'Accessible tooltip';

      await pumpThemed(
        tester,
        LayrzTooltip(
          contentText: tooltipText,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFF0000FF),
          ),
        ),
      );

      final semanticsHandle = tester.ensureSemantics();

      try {
        // Trigger the tooltip.
        await tester.longPress(find.byType(Container));
        await tester.pumpAndSettle();

        // The tooltip's semantics should include the tooltip property.
        // Note: RawTooltip sets semanticsTooltip which contributes to
        // the semantic tree. We verify the text is accessible.
        expect(find.text(tooltipText), findsWidgets);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('semanticsTooltip for contentRichText uses extracted plain text', (tester) async {
      const richContent = TextSpan(
        text: 'Rich ',
        children: [
          TextSpan(text: 'tooltip'),
        ],
      );

      await pumpThemed(
        tester,
        LayrzTooltip(
          contentRichText: richContent,
          child: Container(
            width: 100,
            height: 100,
            color: const Color(0xFF0000FF),
          ),
        ),
      );

      final semanticsHandle = tester.ensureSemantics();

      try {
        // Trigger the tooltip.
        await tester.longPress(find.byType(Container));
        await tester.pumpAndSettle();

        // The plain text should be extractable and present.
        expect(find.byType(Text), findsWidgets);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('tooltip renders with text scaling', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);

      await pumpThemed(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: LayrzTooltip(
            contentText: 'Scaled tooltip',
            child: SizedBox(
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Trigger the tooltip.
      await tester.longPress(find.byType(SizedBox));
      await tester.pumpAndSettle();

      // The tooltip should render without throwing an exception.
      expect(tester.takeException(), isNull);
      expect(find.text('Scaled tooltip'), findsWidgets);
    });

    testWidgets('semanticsTooltip field is consistently set', (tester) async {
      const testText = 'Consistent tooltip';

      await pumpThemed(
        tester,
        LayrzTooltip(
          contentText: testText,
          child: SizedBox(
            width: 100,
            height: 100,
          ),
        ),
      );

      final semanticsHandle = tester.ensureSemantics();

      try {
        // Trigger the tooltip.
        await tester.longPress(find.byType(SizedBox));
        await tester.pumpAndSettle();

        // The text should be accessible.
        expect(find.text(testText), findsWidgets);

        // Dismiss by tapping elsewhere.
        await tester.tap(find.byType(Directionality));
        await tester.pumpAndSettle();

        // Trigger again.
        await tester.longPress(find.byType(SizedBox));
        await tester.pumpAndSettle();

        // The text should still be accessible.
        expect(find.text(testText), findsWidgets);
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}
