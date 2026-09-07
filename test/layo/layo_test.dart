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
          child: Center(child: Layo(width: 150, animate: false)),
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
          child: Center(child: Layo(width: 300, animate: false)),
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
          child: Center(child: SizedBox(width: 200, child: Layo(animate: false))),
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
          child: Center(child: Layo(width: 120, animate: false)),
        ),
      );

      final customPaintFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      expect(customPaintFinder, findsOneWidget);

      final renderedSize = tester.getSize(customPaintFinder);
      expect(renderedSize.width, closeTo(120, 0.01));
      expect(renderedSize.height, closeTo(120 * 833 / 500, 0.01));
    });

    guardedTestWidgets('is a StatefulWidget backed by TickerProviderStateMixin', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120)),
        ),
      );

      expect(find.byType(Layo), findsOneWidget);
      final state = tester.state(find.byType(Layo));
      expect(state, isA<TickerProviderStateMixin>());
    });

    guardedTestWidgets('animate: true drives pulseT away from rest while ticking, without any setState rebuild', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120)),
        ),
      );

      LayoPainter painterAt() {
        final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
        return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
      }

      final initialPainter = painterAt();
      expect(initialPainter.pulseT, 0.0);
      expect(initialPainter.blinkT, 0.0);

      // Advance to the quarter-cycle point of the ~2s linear pulse loop
      // (LayoPainter itself applies the sine easing at paint time).
      await tester.pump(const Duration(milliseconds: 500));

      final midPulsePainter = painterAt();
      expect(midPulsePainter.pulseT, closeTo(0.25, 0.05));
      expect(midPulsePainter.pulseT, isNot(equals(initialPainter.pulseT)));
    });

    guardedTestWidgets('animate: false renders a fully static painter: pulseT and blinkT stay at rest', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false)),
        ),
      );

      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      final before = tester.widget<CustomPaint>(finder).painter! as LayoPainter;
      expect(before.pulseT, 0.0);
      expect(before.blinkT, 0.0);

      // Advance well past a full pulse cycle and past the shortest possible
      // blink-scheduling interval; a static Layo must never move.
      await tester.pump(const Duration(seconds: 7));

      final after = tester.widget<CustomPaint>(finder).painter! as LayoPainter;
      expect(after.pulseT, 0.0);
      expect(after.blinkT, 0.0);
    });

    guardedTestWidgets(
      'reduced motion (MediaQuery.disableAnimations) forces a static painter even with animate: true',
      (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const Center(child: Layo(width: 120)),
            ),
          ),
        );

        final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
        final before = tester.widget<CustomPaint>(finder).painter! as LayoPainter;
        expect(before.pulseT, 0.0);
        expect(before.blinkT, 0.0);

        await tester.pump(const Duration(seconds: 7));

        final after = tester.widget<CustomPaint>(finder).painter! as LayoPainter;
        expect(after.pulseT, 0.0);
        expect(after.blinkT, 0.0);
      },
    );

    guardedTestWidgets('TickerMode(enabled: false) pauses the pulse even with animate: true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: TickerMode(
              enabled: false,
              child: Layo(width: 120),
            ),
          ),
        ),
      );

      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      final before = tester.widget<CustomPaint>(finder).painter! as LayoPainter;
      expect(before.pulseT, 0.0);

      await tester.pump(const Duration(seconds: 3));

      final after = tester.widget<CustomPaint>(finder).painter! as LayoPainter;
      expect(after.pulseT, 0.0, reason: 'TickerMode(enabled: false) must fully pause the idle pulse');
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

    guardedTestWidgets('shouldRepaint is true when pulseT differs', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const painterA = LayoPainter();
      const painterB = LayoPainter(pulseT: 0.5);
      expect(painterA.shouldRepaint(painterB), isTrue);
    });

    guardedTestWidgets('shouldRepaint is true when blinkT differs', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const painterA = LayoPainter();
      const painterB = LayoPainter(blinkT: 1.0);
      expect(painterA.shouldRepaint(painterB), isTrue);
    });

    guardedTestWidgets('default LayoPainter is at rest: pulseT and blinkT both zero', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const painter = LayoPainter();
      expect(painter.pulseT, 0.0);
      expect(painter.blinkT, 0.0);
    });

    guardedTestWidgets('renders correctly at a small avatar-sized width without overflow', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 32)),
        ),
      );

      final renderedSize = tester.getSize(find.byType(AspectRatio));
      expect(renderedSize.width, closeTo(32, 0.01));

      // Pump a full pulse cycle plus room for a blink to fire, at the small
      // avatar size, to ensure no error/overflow surfaces from the animated
      // path at this size (guardedTestWidgets asserts no exception overall).
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
