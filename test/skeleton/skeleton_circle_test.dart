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
