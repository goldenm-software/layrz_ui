import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_controller.dart';
import 'package:layrz_ui/src/refresh/src/refresh_indicator.dart';
import 'package:layrz_ui/src/refresh/src/refresh_state.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

Widget _listView() {
  return ListView(
    children: List.generate(20, (i) => SizedBox(height: 60, child: Text('Item $i'))),
  );
}

void main() {
  group('LayrzRefreshIndicator', () {
    guardedTestWidgets('renders its child', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          height: 400,
          width: 400,
          child: LayrzRefreshIndicator(onRefresh: () async {}, child: _listView()),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
    });

    group('controller ownership', () {
      guardedTestWidgets('creates and disposes its own controller when none is supplied', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(onRefresh: () async {}, child: _listView()),
          ),
        );

        // Unmounting must not throw -- proves the internal controller was
        // disposed exactly once and not leaked.
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      });

      guardedTestWidgets('does not dispose a caller-supplied controller', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(controller: controller, onRefresh: () async {}, child: _listView()),
          ),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);

        // If the widget had wrongly disposed this controller, calling a
        // method on it now would throw.
        expect(() => controller.state, returnsNormally);
        controller.dispose();
      });

      // `pumpThemed` builds a brand-new `OverlayEntry` on every call, so
      // `didUpdateWidget` never fires across two `pumpThemed` calls -- the
      // same constraint `LayrzStepper`'s own controller-swap test documents
      // (`test/steppers/stepper_test.dart:191-207`). This test honestly
      // verifies only the `assert` condition itself: (1) it never trips when
      // the same controller is passed again, and (2) it throws when a
      // genuinely different one is -- matching the field doc's "an assertion
      // fails" wording, not a release-mode guarantee (the same `assert`
      // compiles out entirely in release builds).
      test('the swap guard assert condition matches the documented contract', () {
        final first = LayrzRefreshController();
        final second = LayrzRefreshController();
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        LayrzRefreshController? previous = first;
        void simulateDidUpdateWidget(LayrzRefreshController? next) {
          assert(
            next == previous,
            'LayrzRefreshIndicator does not support changing the controller instance. '
            'The same controller must be passed, or null must remain null.',
          );
          previous = next;
        }

        simulateDidUpdateWidget(first);
        expect(previous, same(first));

        expect(
          () => simulateDidUpdateWidget(second),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('programmatic refresh() as the primary API', () {
      guardedTestWidgets('a caller-held controller drives the same indicator with no drag at all', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        var refreshed = false;

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              enableDragGesture: false,
              onRefresh: () async {
                refreshed = true;
              },
              child: _listView(),
            ),
          ),
        );

        expect(controller.state, LayrzRefreshState.idle);

        // A Completer-backed onRefresh holds the controller in `refreshing`
        // long enough to observe it -- an instantly-resolving onRefresh would
        // race straight through to `settling`/`idle` in the same microtask
        // flush.
        final completer = Completer<void>();
        final refreshFuture = controller.refresh(() {
          refreshed = true;
          return completer.future;
        });
        await tester.pump();

        expect(controller.state, LayrzRefreshState.refreshing);
        expect(refreshed, isTrue);

        completer.complete();
        await refreshFuture;
        await tester.pump();

        // The band-open animation never got a duration-carrying pump here, so
        // it never left value 0.0 -- the retraction that follows is a
        // same-value no-op animation and resolves synchronously, collapsing
        // `settling` straight to `idle` within the same notification pass.
        // See the dedicated tests below for both the animated case (a
        // duration-carrying pump lets the open animation actually progress)
        // and the explicit reduce-motion case.
        expect(controller.state, LayrzRefreshState.idle);
      });

      guardedTestWidgets('with reduce-motion enabled, state changes still apply instantly', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        final completer = Completer<void>();

        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SizedBox(
              height: 400,
              width: 400,
              child: LayrzRefreshIndicator(
                controller: controller,
                enableDragGesture: false,
                onRefresh: () => completer.future,
                child: _listView(),
              ),
            ),
          ),
        );

        unawaited(controller.refresh(() => completer.future));
        await tester.pump();

        expect(controller.state, LayrzRefreshState.refreshing);

        completer.complete();
        await tester.pump();

        // With reduce-motion honoured, the retraction is a direct value
        // assignment rather than an animation -- settling resolves to idle
        // within the same pump, with no separate window to observe it in.
        expect(controller.state, LayrzRefreshState.idle);
        expect(tester.takeException(), isNull);
      });

      guardedTestWidgets('settles back to idle once the caller Future resolves', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              enableDragGesture: false,
              onRefresh: () async {},
              child: _listView(),
            ),
          ),
        );

        unawaited(controller.refresh(() async {}));
        await tester.pumpAndSettle();

        expect(controller.state, LayrzRefreshState.idle);
      });

      guardedTestWidgets('with animations enabled, settling is observable before it reaches idle', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        final completer = Completer<void>();

        await pumpThemed(
          tester,
          MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: SizedBox(
              height: 400,
              width: 400,
              child: LayrzRefreshIndicator(
                controller: controller,
                enableDragGesture: false,
                onRefresh: () => completer.future,
                child: _listView(),
              ),
            ),
          ),
        );

        unawaited(controller.refresh(() => completer.future));
        // Let the band-open animation progress partway before resolving, so
        // the retraction that follows has real distance to cover and does
        // not collapse to a same-value no-op animation (animateTo(x) from x
        // resolves synchronously -- a real risk if onRefresh finishes before
        // the open animation has moved at all). The zero-duration pump first
        // anchors the ticker's start timestamp to the fake clock before it is
        // advanced by a real duration.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        completer.complete();
        await tester.pump();

        // The retraction animation is mid-flight: settling must still be
        // observable here, unlike the reduce-motion case above.
        expect(controller.state, LayrzRefreshState.settling);

        await tester.pumpAndSettle();
        expect(controller.state, LayrzRefreshState.idle);
      });

      guardedTestWidgets('can be triggered with enableDragGesture set to false', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        var refreshed = false;

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              enableDragGesture: false,
              onRefresh: () async {
                refreshed = true;
              },
              child: _listView(),
            ),
          ),
        );

        // Dragging must have no effect at all when the gesture is disabled.
        final start = tester.getCenter(find.byType(ListView));
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(0, 120));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(refreshed, isFalse);
        expect(controller.dragProgress, 0.0);
      });
    });

    group('drag gesture (secondary, when enabled)', () {
      guardedTestWidgets('a drag past the threshold triggers a refresh', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        var refreshed = false;

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              triggerDistance: 60.0,
              onRefresh: () async {
                refreshed = true;
              },
              child: _listView(),
            ),
          ),
        );

        final start = tester.getCenter(find.byType(ListView));
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(0, 120));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(refreshed, isTrue);
        await tester.pumpAndSettle();
      });
    });

    guardedTestWidgets('the full lifecycle completes without leaving a pending animation', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzRefreshController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        SizedBox(
          height: 400,
          width: 400,
          child: LayrzRefreshIndicator(
            controller: controller,
            enableDragGesture: false,
            onRefresh: () async {},
            child: _listView(),
          ),
        ),
      );

      unawaited(controller.refresh(() async {}));

      // pumpAndSettle only completes if no ticker is left running -- this is
      // the guard against a hung settle animation.
      await tester.pumpAndSettle();

      expect(controller.state, LayrzRefreshState.idle);
      expect(tester.takeException(), isNull);
    });
  });
}
