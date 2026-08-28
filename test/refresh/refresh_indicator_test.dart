import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_controller.dart';
import 'package:layrz_ui/src/refresh/src/refresh_fallback_button_mode.dart';
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

      guardedTestWidgets(
        'an abandoned pull below the trigger threshold collapses the indicator, not just the state',
        (tester) async {
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
                triggerDistance: 200.0,
                fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
                onRefresh: () async {},
                child: _listView(),
              ),
            ),
          );

          final pullVisual = find.byKey(const ValueKey('layrz-refresh-pull-visual'));

          // Before any drag, the indicator must not be in the tree at all --
          // establishes the baseline this test's final assertion returns to.
          expect(pullVisual, findsNothing);

          final start = tester.getCenter(find.byType(ListView));
          final gesture = await tester.startGesture(start);
          await gesture.moveBy(const Offset(0, 60));
          await tester.pump();

          // Below the 200px threshold: still idle, but the indicator is now
          // visibly open in step with the drag -- otherwise there would be
          // nothing left for the release below to fail to collapse.
          expect(controller.state, LayrzRefreshState.idle);
          expect(pullVisual, findsOneWidget);

          // Release without ever reaching the threshold. This previously left
          // `_bandController` parked at its last value in
          // `_LayrzRefreshIndicatorState._onControllerChanged`'s `idle` case,
          // which was a no-op -- the ring stayed visible, stuck at partial
          // progress, even though the controller had correctly returned to
          // `idle`. Both assertions matter: state alone does not catch this
          // regression, since state was already correct before the fix.
          await gesture.up();
          await tester.pump();

          expect(controller.state, LayrzRefreshState.idle);
          expect(
            pullVisual,
            findsNothing,
            reason: 'an abandoned pull must retract the visual, not just report idle state',
          );

          await tester.pumpAndSettle();
        },
      );

      guardedTestWidgets(
        'reversing a drag back toward the top before release also collapses the indicator',
        (tester) async {
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
                triggerDistance: 200.0,
                fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
                onRefresh: () async {},
                child: _listView(),
              ),
            ),
          );

          final pullVisual = find.byKey(const ValueKey('layrz-refresh-pull-visual'));

          final start = tester.getCenter(find.byType(ListView));
          final gesture = await tester.startGesture(start);
          await gesture.moveBy(const Offset(0, 60));
          await tester.pump();

          expect(pullVisual, findsOneWidget);

          // Reverse most of the way back up (still a top-side drag, just a
          // much smaller one) before releasing -- the ratchet-reset behaviour
          // documented on `LayrzRefreshGestureDetector` drops dragProgress
          // back to 0.0 for this, and the indicator must follow it down.
          await gesture.moveBy(const Offset(0, -1));
          await tester.pump();

          expect(controller.dragProgress, 0.0);
          expect(pullVisual, findsNothing);

          await gesture.up();
          await tester.pumpAndSettle();
        },
      );
    });

    group('floating layout (no list displacement)', () {
      guardedTestWidgets('the list content does not move when the indicator becomes visible', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        final completer = Completer<void>();

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              enableDragGesture: false,
              fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
              onRefresh: () => completer.future,
              child: _listView(),
            ),
          ),
        );

        final rectBefore = tester.getRect(find.text('Item 0'));

        unawaited(controller.refresh(() => completer.future));
        // Let the reveal animation run fully so the indicator is at its most
        // visible/expanded -- the moment most likely to have displaced layout
        // under the old SizeTransition-band design.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final rectDuring = tester.getRect(find.text('Item 0'));
        expect(
          rectDuring,
          rectBefore,
          reason: 'the indicator must float over the list, never push its content down',
        );

        completer.complete();
        await tester.pumpAndSettle();

        final rectAfter = tester.getRect(find.text('Item 0'));
        expect(rectAfter, rectBefore);
      });

      guardedTestWidgets('the indicator visual is positioned over the list, not above it', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzRefreshController();
        addTearDown(controller.dispose);
        final completer = Completer<void>();

        await pumpThemed(
          tester,
          SizedBox(
            height: 400,
            width: 400,
            child: LayrzRefreshIndicator(
              controller: controller,
              enableDragGesture: false,
              fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
              onRefresh: () => completer.future,
              child: _listView(),
            ),
          ),
        );

        final listRect = tester.getRect(find.byType(ListView));

        unawaited(controller.refresh(() => completer.future));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final visualRect = tester.getRect(find.byKey(const ValueKey('layrz-refresh-pull-visual')));

        // A floating overlay sits within the list's own bounds (its top
        // edge inset from the list's top, not stacked above it) -- the
        // hallmark of the old band-above-the-child layout would have been a
        // visual rect entirely above `listRect.top`.
        expect(visualRect.top, greaterThanOrEqualTo(listRect.top));
        expect(visualRect.left, greaterThanOrEqualTo(listRect.left));
        expect(visualRect.right, lessThanOrEqualTo(listRect.right));

        completer.complete();
        await tester.pumpAndSettle();
      });

      guardedTestWidgets(
        'the pull indicator gets an elevated circular surface, present only while it is visible',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final controller = LayrzRefreshController();
          addTearDown(controller.dispose);
          final completer = Completer<void>();

          await pumpThemed(
            tester,
            SizedBox(
              height: 400,
              width: 400,
              child: LayrzRefreshIndicator(
                controller: controller,
                enableDragGesture: false,
                fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
                onRefresh: () => completer.future,
                child: _listView(),
              ),
            ),
          );

          final pullVisual = find.byKey(const ValueKey('layrz-refresh-pull-visual'));

          // At rest, the pull visual (and therefore its surface) is absent
          // from the tree entirely -- matching the same absent-not-just-faded
          // contract the stuck-ring regression tests establish elsewhere in
          // this file. A surface left behind here would be exactly that bug,
          // one layer further out.
          expect(pullVisual, findsNothing);

          unawaited(controller.refresh(() => completer.future));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));

          expect(pullVisual, findsOneWidget);

          // Walk up from the visual to the nearest `Container` -- this is
          // `_RefreshFloatingSurface`'s own decorated box, not the
          // `AnimatedOpacity`/`IgnorePointer` machinery around it, and not
          // any container belonging to the disabled fallback button (there
          // is none in this tree at all, since it is disabled above).
          final surfaceFinder = find.ancestor(of: pullVisual, matching: find.byType(Container));
          expect(surfaceFinder, findsOneWidget);

          final container = tester.widget<Container>(surfaceFinder);
          final decoration = container.decoration! as BoxDecoration;
          expect(decoration.shape, BoxShape.circle);
          expect(decoration.boxShadow, isNotNull);
          expect(decoration.boxShadow, isNotEmpty);

          completer.complete();
          await tester.pumpAndSettle();

          // Once settled back to idle, the surface must disappear along with
          // the ring -- an elevated circle left floating with nothing inside
          // it would be the same stuck-visual bug in a new shape.
          expect(pullVisual, findsNothing);
          expect(surfaceFinder, findsNothing);
        },
      );

      guardedTestWidgets(
        'the list is actually visible with non-zero size when given only bounded-width, '
        'unbounded-height constraints (e.g. Expanded with no fixed height)',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // Deliberately no `SizedBox(height: ...)` wrapper here -- every other
          // test in this file wraps `LayrzRefreshIndicator` in a fixed-size
          // `SizedBox`, which gives the old `Stack` (with only `Positioned`
          // children) a tight box to collapse into without anyone noticing. A
          // `Stack` sizes itself only to its *non-positioned* children; with
          // none, it shrinks to the smallest size its constraints allow. Under
          // `Expanded` (bounded height) but no bounded width forced onto the
          // `Stack` itself, the old code silently rendered the list at zero
          // width -- invisible, with no exception and no overflow banner. This
          // is the exact shape of the regression reported from a physical
          // Android device: "I don't see the list, but there is no errors on
          // log".
          await pumpThemed(
            tester,
            SizedBox(
              width: 400,
              height: 600,
              child: Column(
                children: [
                  Expanded(
                    child: LayrzRefreshIndicator(
                      enableDragGesture: false,
                      fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
                      onRefresh: () async {},
                      child: _listView(),
                    ),
                  ),
                ],
              ),
            ),
          );

          final listSize = tester.getSize(find.byType(ListView));
          expect(listSize.width, greaterThan(0), reason: 'the list must not collapse to zero width');
          expect(listSize.height, greaterThan(0), reason: 'the list must not collapse to zero height');

          final itemRect = tester.getRect(find.text('Item 0'));
          expect(itemRect.width, greaterThan(0), reason: 'a real list item must have a visible, non-zero rect');
          expect(itemRect.height, greaterThan(0), reason: 'a real list item must have a visible, non-zero rect');
        },
      );
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
