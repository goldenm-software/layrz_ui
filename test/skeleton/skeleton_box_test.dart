import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzSkeletonBox', () {
    guardedTestWidgets('occupies exactly the given width and height (no-reflow)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonBox(width: 200, height: 120));

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonBox));
      expect(box.size, const Size(200, 120));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('applies the given border radius', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonBox(width: 100, height: 40, borderRadius: 12));

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('defaults to sharp corners when borderRadius is omitted', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonBox(width: 100, height: 40));

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.zero);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('shimmers with a self-owned controller when used standalone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonBox(width: 100, height: 40));

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
              child: const Center(child: LayrzSkeletonBox(width: 100, height: 40)),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Regression: the static frame must recolor the shape itself in place
      // (ColorFiltered) rather than painting baseColor into a separate,
      // rectangular DecoratedBox behind it -- a box painted behind a rounded
      // shape has square corners peeking out past the shape's own rounded
      // corners, which read as a stray border/outline around the shape.
      final colorFilter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(colorFilter.colorFilter, const ColorFilter.mode(Color(0xFFF0F0F0), BlendMode.srcIn));

      // Only one DecoratedBox exists in the static path -- the shape's own,
      // still filled with the opaque mask color -- not a second one behind
      // it carrying baseColor with mismatched (square) geometry.
      expect(find.byType(DecoratedBox), findsOneWidget);
      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF000000));
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
          child: LayrzSkeletonBox(width: 100, height: 40),
        ),
      );

      // Only one ticking AnimationController exists for the whole subtree --
      // the box does not create a second, independent one when nested.
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
