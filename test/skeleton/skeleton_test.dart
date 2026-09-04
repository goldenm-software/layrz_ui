import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzSkeleton', () {
    guardedTestWidgets('renders its child tree of primitives', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeleton(
          child: Column(
            children: [
              LayrzSkeletonBox(width: 100, height: 20),
              LayrzSkeletonCircle(diameter: 40),
              LayrzSkeletonLine(width: 80),
            ],
          ),
        ),
      );

      expect(find.byType(LayrzSkeleton), findsOneWidget);
      expect(find.byType(LayrzSkeletonBox), findsOneWidget);
      expect(find.byType(LayrzSkeletonCircle), findsOneWidget);
      expect(find.byType(LayrzSkeletonLine), findsOneWidget);

      // Stop the repeating ticker before the test ends.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('animates the shared shimmer when motion is enabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeleton(
          child: LayrzSkeletonBox(width: 100, height: 20),
        ),
      );

      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayrzSkeleton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayrzSkeleton), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('renders a static block with no scheduled frames under reduced motion', (tester) async {
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
              child: const Center(
                child: LayrzSkeleton(
                  child: LayrzSkeletonBox(width: 100, height: 20),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LayrzSkeleton), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    guardedTestWidgets('toggling reduce-motion at runtime starts and stops the ticker', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool disableAnimations = true;
      late StateSetter setter;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: Localizations(
                locale: const Locale('en'),
                delegates: const [
                  DefaultWidgetsLocalizations.delegate,
                  LayrzUiL10nDelegate(),
                ],
                child: LayrzTheme(
                  data: LayrzThemeData.light(),
                  child: const Center(
                    child: LayrzSkeleton(
                      child: LayrzSkeletonBox(width: 100, height: 20),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);

      setter(() => disableAnimations = false);
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('announces exactly one Loading node and excludes primitives from semantics', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          const LayrzSkeleton(
            child: Column(
              children: [
                LayrzSkeletonBox(width: 100, height: 20),
                LayrzSkeletonCircle(diameter: 40),
                LayrzSkeletonLine(width: 80),
              ],
            ),
          ),
        );

        final semanticsNode = tester.getSemantics(find.byType(LayrzSkeleton));
        expect(semanticsNode, matchesSemantics(label: 'Loading', hasTapAction: false, isButton: false));

        // Every descendant primitive must be excluded from the semantics
        // tree -- only the one container-level node above should exist.
        // ignore: deprecated_member_use
        final rootSemantics = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
        var loadingNodeCount = 0;
        void visit(SemanticsNode node) {
          if (node.label == 'Loading') loadingNodeCount++;
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(rootSemantics);
        expect(loadingNodeCount, 1);
      } finally {
        handle.dispose();
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('primitives with explicit width/height occupy exactly that box (no-reflow)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzSkeleton(
          child: LayrzSkeletonBox(width: 137, height: 53),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonBox));
      expect(box.size, const Size(137, 53));

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
