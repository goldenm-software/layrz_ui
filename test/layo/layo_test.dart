import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

void main() {
  group('Layo', () {
    guardedTestWidgets('with an explicit width renders an AspectRatio of 500/833 sized accordingly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 150)),
        ),
      );

      final aspectRatioFinder = find.byType(AspectRatio);
      expect(aspectRatioFinder, findsOneWidget);

      final aspectRatio = tester.widget<AspectRatio>(aspectRatioFinder);
      expect(aspectRatio.aspectRatio, 500 / 833);

      final renderedSize = tester.getSize(aspectRatioFinder);
      expect(renderedSize.width, closeTo(150, 0.01));
      expect(renderedSize.height, closeTo(150 * 833 / 500, 0.01));
    });

    guardedTestWidgets('with a different explicit width scales both dimensions accordingly', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 300)),
        ),
      );

      final renderedSize = tester.getSize(find.byType(AspectRatio));
      expect(renderedSize.width, closeTo(300, 0.01));
      expect(renderedSize.height, closeTo(300 * 833 / 500, 0.01));
    });

    guardedTestWidgets('with no width fills a bounded parent width and derives height from the aspect ratio', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 200, child: Layo())),
        ),
      );

      final renderedSize = tester.getSize(find.byType(AspectRatio));
      expect(renderedSize.width, closeTo(200, 0.01));
      expect(renderedSize.height, closeTo(200 * 833 / 500, 0.01));
    });

    guardedTestWidgets('paints a CustomPaint using LayoPainter sized to fill the AspectRatio box', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120)),
        ),
      );

      final customPaintFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      expect(customPaintFinder, findsOneWidget);

      final renderedSize = tester.getSize(customPaintFinder);
      expect(renderedSize.width, closeTo(120, 0.01));
      expect(renderedSize.height, closeTo(120 * 833 / 500, 0.01));
    });

    guardedTestWidgets('shouldRepaint is false for an identically-configured LayoPainter', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const painterA = LayoPainter();
      const painterB = LayoPainter();
      expect(painterA.shouldRepaint(painterB), isFalse);
    });

    guardedTestWidgets('shouldRepaint is true when a color differs', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const painterA = LayoPainter();
      const painterB = LayoPainter(accentColor: Color(0xFFFF0000));
      expect(painterA.shouldRepaint(painterB), isTrue);
    });

    guardedTestWidgets('shouldRepaint is true when faceShadowColor differs', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const painterA = LayoPainter();
      const painterB = LayoPainter(faceShadowColor: Color(0xFFFF0000));
      expect(painterA.shouldRepaint(painterB), isTrue);
    });
  });
}
