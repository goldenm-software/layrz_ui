import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzSkeletonLine', () {
    guardedTestWidgets('occupies exactly width x the default height (no-reflow)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonLine(width: 150));

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonLine));
      expect(box.size, const Size(150, kDefaultLayrzSkeletonLineHeight));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('honors an explicit height over the default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonLine(width: 150, height: 30));

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonLine));
      expect(box.size, const Size(150, 30));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('derives height from matchTextStyle when height is omitted', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeletonLine(width: 150, matchTextStyle: TextStyle(fontSize: 20, height: 1.5)),
      );

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonLine));
      expect(box.size, const Size(150, 30));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('falls back to a 1.2 line-height multiplier when matchTextStyle has no height', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeletonLine(width: 150, matchTextStyle: TextStyle(fontSize: 10)),
      );

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonLine));
      expect(box.size, const Size(150, 12));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('an explicit height takes precedence over matchTextStyle', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeletonLine(width: 150, height: 8, matchTextStyle: TextStyle(fontSize: 40)),
      );

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonLine));
      expect(box.size, const Size(150, 8));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('applies the default line-radius rounding', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonLine(width: 100));

      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(kDefaultLayrzSkeletonLineRadius));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('shimmers with a self-owned controller when used standalone', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzSkeletonLine(width: 100));

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
              child: const Center(child: LayrzSkeletonLine(width: 100)),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Regression: the static frame must recolor the line itself in place
      // (ColorFiltered) rather than painting baseColor into a separate,
      // rectangular DecoratedBox behind it -- a box painted behind a rounded
      // shape has square corners peeking out past the shape's own rounded
      // corners, which read as a stray border/outline around the shape.
      final colorFilter = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(colorFilter.colorFilter, const ColorFilter.mode(Color(0xFFF0F0F0), BlendMode.srcIn));

      // Only one DecoratedBox exists in the static path -- the line's own,
      // still filled with the opaque mask color -- not a second one behind
      // it carrying baseColor with mismatched (square) geometry.
      expect(find.byType(DecoratedBox), findsOneWidget);
      final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF000000));
    });
  });
}
