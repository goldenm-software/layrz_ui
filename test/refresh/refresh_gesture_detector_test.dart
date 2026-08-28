import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_controller.dart';
import 'package:layrz_ui/src/refresh/src/refresh_gesture_detector.dart';
import 'package:layrz_ui/src/refresh/src/refresh_state.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// Builds a scrollable tall enough to overscroll reliably and wraps it in the
/// gesture detector under test.
///
/// Deliberately uses the platform-default [ScrollPhysics] rather than pinning
/// [ClampingScrollPhysics] or [BouncingScrollPhysics] explicitly: what matters
/// for this widget is that a real drag produces [OverscrollNotification]s at
/// the boundary, which the default physics already does. Test-driven default
/// [TargetPlatform] is `android`, whose default physics is
/// [ClampingScrollPhysics] -- confirmed to dispatch overscroll during an
/// active drag, since overscroll dispatch happens in [ScrollPosition] itself
/// rather than being physics-gated.
Widget _buildHarness({
  required LayrzRefreshController controller,
  required Future<void> Function() onRefresh,
  double triggerDistance = 80.0,
}) {
  return SizedBox(
    height: 400,
    width: 400,
    child: LayrzRefreshGestureDetector(
      controller: controller,
      onRefresh: onRefresh,
      triggerDistance: triggerDistance,
      child: ListView(
        children: List.generate(20, (i) => SizedBox(height: 60, child: Text('Item $i'))),
      ),
    ),
  );
}

void main() {
  group('LayrzRefreshGestureDetector', () {
    late LayrzRefreshController controller;

    setUp(() {
      controller = LayrzRefreshController();
    });

    tearDown(() {
      controller.dispose();
    });

    guardedTestWidgets('a downward drag from the top updates dragProgress', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _buildHarness(controller: controller, onRefresh: () async {}),
      );

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      expect(controller.dragProgress, greaterThan(0.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    guardedTestWidgets('dragging past triggerDistance arms the controller', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _buildHarness(controller: controller, onRefresh: () async {}, triggerDistance: 60.0),
      );

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();

      expect(controller.state, LayrzRefreshState.armed);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    guardedTestWidgets('releasing past the threshold calls onRefresh', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var refreshCalled = false;

      await pumpThemed(
        tester,
        _buildHarness(
          controller: controller,
          onRefresh: () async {
            refreshCalled = true;
          },
          triggerDistance: 60.0,
        ),
      );

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(refreshCalled, isTrue);
      await tester.pumpAndSettle();
    });

    guardedTestWidgets('releasing before the threshold does not call onRefresh', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var refreshCalled = false;

      await pumpThemed(
        tester,
        _buildHarness(
          controller: controller,
          onRefresh: () async {
            refreshCalled = true;
          },
          triggerDistance: 200.0,
        ),
      );

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(refreshCalled, isFalse);
      expect(controller.state, LayrzRefreshState.idle);
    });

    guardedTestWidgets('a bottom-side overscroll does not drive dragProgress', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _buildHarness(controller: controller, onRefresh: () async {}),
      );

      // Scroll to the very bottom first, then keep dragging upward past it.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();

      expect(controller.dragProgress, 0.0);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    guardedTestWidgets('dragging back up after a partial pull resets dragProgress to zero', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _buildHarness(controller: controller, onRefresh: () async {}, triggerDistance: 200.0),
      );

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      final progressAfterPull = controller.dragProgress;
      expect(progressAfterPull, closeTo(0.3, 0.001));

      // Under ClampingScrollPhysics a reversal of any size clears the
      // boundary condition entirely in a single frame -- see
      // refresh_gesture_detector.dart's class doc for why there is no
      // intermediate "still pulling, but less" notification to read a
      // gradual decrease from. The observable, correct behaviour is a full
      // reset rather than a value stuck at its high-water mark.
      await gesture.moveBy(const Offset(0, -1));
      await tester.pump();

      expect(
        controller.dragProgress,
        0.0,
        reason: 'reversing the drag upward must reset dragProgress, not leave it stuck at the pull high-water mark',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    guardedTestWidgets(
      'a drag armed past the threshold, then reversed and released, does not refresh',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var refreshCalled = false;

        await pumpThemed(
          tester,
          _buildHarness(
            controller: controller,
            onRefresh: () async {
              refreshCalled = true;
            },
            triggerDistance: 60.0,
          ),
        );

        final start = tester.getCenter(find.byType(ListView));
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(0, 120));
        await tester.pump();

        expect(controller.state, LayrzRefreshState.armed);

        // Drag back up well below the threshold before releasing -- the list
        // is back at rest (no top-side overscroll left), so the cancellation
        // must stick.
        await gesture.moveBy(const Offset(0, -200));
        await tester.pump();

        expect(controller.state, LayrzRefreshState.idle);
        expect(controller.dragProgress, 0.0);

        await gesture.up();
        await tester.pump();

        expect(refreshCalled, isFalse, reason: 'a drag cancelled by reversal before release must not refresh');
        expect(controller.state, LayrzRefreshState.idle);

        await tester.pumpAndSettle();
      },
    );

    guardedTestWidgets(
      'an OverscrollNotification without dragDetails (e.g. a ballistic bounce-back) is ignored',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Neither a real mouse-wheel scroll nor a fling/ballistic bounce-back
        // under either stock ScrollPhysics ever reaches an OverscrollNotification
        // on a plain ListView in this Flutter version -- pointer-signal scrolls
        // clamp pixels directly without ever calling
        // ScrollPosition.didOverscrollBy, and both ClampingScrollPhysics and
        // BouncingScrollPhysics's ballistic paths were verified empirically to
        // never produce one either (Clamping's boundary spring only activates
        // when pixels is already out of range, which setPixels never allows;
        // Bouncing's applyBoundaryConditions always returns 0.0). The one case
        // the dragDetails != null guard defends against --
        // BallisticScrollActivity.dispatchOverscrollNotification, which always
        // passes dragDetails: null -- can therefore only be exercised by
        // dispatching that exact notification directly, which is what this test
        // does via a BuildContext captured from inside the detector's subtree.
        late BuildContext capturedContext;

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshGestureDetector(
              controller: controller,
              onRefresh: () async {},
              triggerDistance: 60.0,
              child: Builder(
                builder: (context) {
                  capturedContext = context;
                  return ListView(
                    children: List.generate(20, (i) => SizedBox(height: 60, child: Text('Item $i'))),
                  );
                },
              ),
            ),
          ),
        );

        final metrics = FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 1000.0,
          pixels: 0.0,
          viewportDimension: 400.0,
          axisDirection: AxisDirection.down,
          devicePixelRatio: tester.view.devicePixelRatio,
        );

        OverscrollNotification(
          metrics: metrics,
          context: capturedContext,
          overscroll: -120.0,
        ).dispatch(capturedContext);
        await tester.pump();

        expect(
          controller.dragProgress,
          0.0,
          reason: 'an OverscrollNotification with no dragDetails must not be mistaken for a real drag',
        );
        expect(controller.state, LayrzRefreshState.idle);

        await tester.pumpAndSettle();
      },
    );

    guardedTestWidgets('an in-flight refresh ignores further drag updates', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        _buildHarness(
          controller: controller,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          },
          triggerDistance: 40.0,
        ),
      );

      final start = tester.getCenter(find.byType(ListView));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.isRefreshing, isTrue);

      final gesture2 = await tester.startGesture(start);
      await gesture2.moveBy(const Offset(0, 80));
      await tester.pump();

      expect(controller.dragProgress, 0.0, reason: 'a stray drag must not disturb an in-flight refresh');

      await gesture2.up();
      await tester.pumpAndSettle();
    });
  });
}
