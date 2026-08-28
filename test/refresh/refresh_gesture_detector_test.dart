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
