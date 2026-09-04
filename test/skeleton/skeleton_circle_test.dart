import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzSkeletonCircle', () {
    guardedTestWidgets('occupies exactly a diameter x diameter box (no-reflow)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonCircle(diameter: 48));

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonCircle));
      expect(box.size, const Size(48, 48));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('renders as a circle shape', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonCircle(diameter: 32));

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('shimmers with a self-owned controller when used standalone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonCircle(diameter: 40));

      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(find.byType(ShaderMask), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('renders a static frame under reduced motion when standalone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              LayrzUiL10nDelegate(),
            ],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: const Center(child: LayrzSkeletonCircle(diameter: 40)),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Regression: the static frame must recolor the circle itself in place
      // (ColorFiltered) rather than painting baseColor into a separate,
      // rectangular DecoratedBox behind it -- a square box painted behind a
      // circle leaves its corners peeking out past the circle's curve,
      // which read as a stray border/outline around the circle.
      final colorFilter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(colorFilter.colorFilter, const ColorFilter.mode(Color(0xFFF0F0F0), BlendMode.srcIn));

      // Only one DecoratedBox exists in the static path -- the circle's own,
      // still filled with the opaque mask color and BoxShape.circle -- not a
      // second, rectangular one behind it carrying baseColor.
      expect(find.byType(DecoratedBox), findsOneWidget);
      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF000000));
      expect(decoration.shape, BoxShape.circle);
    });

    guardedTestWidgets('reads the shared shimmer from an ancestor LayrzSkeleton instead of a fallback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeleton(
          child: LayrzSkeletonCircle(diameter: 40),
        ),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
