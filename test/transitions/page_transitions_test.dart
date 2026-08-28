import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Pumps [builder] wrapped in the ambient tree it needs ([MediaQuery] driving
/// reduce-motion and [Directionality] for the slide transition), returning
/// the [AnimationController] driving [Animation<double>] so the test can move
/// it through intermediate frames and assert on in-flight state, not just
/// the two endpoints.
Future<AnimationController> _pumpBuilder(
  WidgetTester tester,
  LayrzTransitionBuilder builder, {
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final controller = AnimationController(
    vsync: tester,
    duration: const Duration(milliseconds: 250),
  );
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: textDirection,
        child: LayrzTheme(
          data: LayrzThemeData.light(),
          child: Builder(
            builder: (context) => builder(
              context,
              controller,
              const AlwaysStoppedAnimation<double>(0.0),
              const ColoredBox(color: Color(0xFF112233), child: SizedBox(width: 40, height: 40)),
            ),
          ),
        ),
      ),
    ),
  );

  return controller;
}

void main() {
  group('LayrzPageTransitions.fade', () {
    testWidgets('opacity tracks the animation through intermediate frames', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _pumpBuilder(tester, LayrzPageTransitions.fade);

      FadeTransition fadeWidgetAt() => tester.widget<FadeTransition>(find.byType(FadeTransition));

      expect(fadeWidgetAt().opacity.value, 0.0);

      controller.value = 0.5;
      await tester.pump();
      expect(fadeWidgetAt().opacity.value, closeTo(0.5, 1e-9));

      controller.value = 1.0;
      await tester.pump();
      expect(fadeWidgetAt().opacity.value, 1.0);
    });

    testWidgets('collapses to none when reduce-motion is requested', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.fade, disableAnimations: true);

      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });

  group('LayrzPageTransitions.slide', () {
    testWidgets('position tracks the animation through intermediate frames (LTR)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _pumpBuilder(tester, LayrzPageTransitions.slide);

      SlideTransition slideWidgetAt() => tester.widget<SlideTransition>(find.byType(SlideTransition));

      expect(slideWidgetAt().position.value.dx, 1.0);
      expect(slideWidgetAt().position.value.dy, 0.0);

      controller.value = 1.0;
      await tester.pump();
      final endValue = slideWidgetAt().position.value;
      expect(endValue.dx, closeTo(0.0, 1e-9));
      expect(endValue.dy, 0.0);

      controller.value = 0.0;
      controller.value = 0.5;
      await tester.pump();
      final midValue = slideWidgetAt().position.value;
      expect(midValue.dx, lessThan(1.0));
      expect(midValue.dx, greaterThan(0.0));
    });

    testWidgets('slides in from the opposite edge under RTL', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.slide, textDirection: TextDirection.rtl);

      final slideWidget = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideWidget.position.value.dx, -1.0);
    });

    testWidgets('collapses to none when reduce-motion is requested', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.slide, disableAnimations: true);

      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });

  group('LayrzPageTransitions.scale', () {
    testWidgets('scale and opacity track the animation through intermediate frames', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _pumpBuilder(tester, LayrzPageTransitions.scale);

      ScaleTransition scaleWidgetAt() => tester.widget<ScaleTransition>(find.byType(ScaleTransition));
      FadeTransition fadeWidgetAt() => tester.widget<FadeTransition>(find.byType(FadeTransition));

      expect(scaleWidgetAt().scale.value, closeTo(0.92, 1e-9));
      expect(fadeWidgetAt().opacity.value, 0.0);

      controller.value = 0.5;
      await tester.pump();
      final midScale = scaleWidgetAt().scale.value;
      expect(midScale, greaterThan(0.92));
      expect(midScale, lessThan(1.0));
      expect(fadeWidgetAt().opacity.value, closeTo(0.5, 1e-9));

      controller.value = 1.0;
      await tester.pump();
      expect(scaleWidgetAt().scale.value, 1.0);
      expect(fadeWidgetAt().opacity.value, 1.0);
    });

    testWidgets('collapses to none when reduce-motion is requested', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.scale, disableAnimations: true);

      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });

  group('LayrzPageTransitions.rotation', () {
    testWidgets('turns and opacity track the animation through intermediate frames', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _pumpBuilder(tester, LayrzPageTransitions.rotation);

      RotationTransition rotationWidgetAt() => tester.widget<RotationTransition>(find.byType(RotationTransition));
      FadeTransition fadeWidgetAt() => tester.widget<FadeTransition>(find.byType(FadeTransition));

      expect(rotationWidgetAt().turns.value, closeTo(-0.02, 1e-9));
      expect(fadeWidgetAt().opacity.value, 0.0);

      controller.value = 0.5;
      await tester.pump();
      final midTurns = rotationWidgetAt().turns.value;
      expect(midTurns, greaterThan(-0.02));
      expect(midTurns, lessThan(0.0));

      controller.value = 1.0;
      await tester.pump();
      expect(rotationWidgetAt().turns.value, 0.0);
      expect(fadeWidgetAt().opacity.value, 1.0);
    });

    testWidgets('collapses to none when reduce-motion is requested', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.rotation, disableAnimations: true);

      expect(find.byType(RotationTransition), findsNothing);
      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });

  group('LayrzPageTransitions.none', () {
    testWidgets('returns the child unwrapped, with no transition widget at all', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.none);

      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(RotationTransition), findsNothing);
      expect(find.byType(ColoredBox), findsOneWidget);
    });

    testWidgets('is unaffected by reduce-motion, since it already is the reduced form', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpBuilder(tester, LayrzPageTransitions.none, disableAnimations: true);

      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });
}
