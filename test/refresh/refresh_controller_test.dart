import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/refresh/src/refresh_controller.dart';
import 'package:layrz_ui/src/refresh/src/refresh_state.dart';

void main() {
  group('LayrzRefreshController', () {
    late LayrzRefreshController controller;

    setUp(() {
      controller = LayrzRefreshController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts idle with zero drag progress', () {
      expect(controller.state, LayrzRefreshState.idle);
      expect(controller.dragProgress, 0.0);
      expect(controller.isRefreshing, isFalse);
    });

    group('programmatic refresh() — the primary API', () {
      test('moves straight to refreshing with no armed step', () async {
        final states = <LayrzRefreshState>[];
        controller.addListener(() => states.add(controller.state));

        final completer = Completer<void>();
        final future = controller.refresh(() => completer.future);

        expect(controller.state, LayrzRefreshState.refreshing);
        expect(controller.isRefreshing, isTrue);
        expect(states, isNot(contains(LayrzRefreshState.armed)));

        completer.complete();
        await future;

        expect(controller.state, LayrzRefreshState.settling);
      });

      test('is callable with no gesture involved at all', () async {
        var called = false;
        await controller.refresh(() async {
          called = true;
        });

        expect(called, isTrue);
        expect(controller.dragProgress, 0.0, reason: 'a programmatic refresh never touches drag progress');
      });

      test('is a no-op while already refreshing', () async {
        var callCount = 0;
        final completer = Completer<void>();

        final first = controller.refresh(() {
          callCount++;
          return completer.future;
        });

        // Second call while the first is still in flight must not re-enter onRefresh.
        await controller.refresh(() async {
          callCount++;
        });

        expect(callCount, 1);

        completer.complete();
        await first;
      });

      test('is a no-op while settling', () async {
        await controller.refresh(() async {});
        expect(controller.state, LayrzRefreshState.settling);

        var calledAgain = false;
        await controller.refresh(() async {
          calledAgain = true;
        });

        expect(calledAgain, isFalse);
      });

      test('settles and rethrows if onRefresh throws', () async {
        expect(
          () => controller.refresh(() async {
            throw StateError('boom');
          }),
          throwsA(isA<StateError>()),
        );

        // Let the microtask queue drain the throw before asserting state.
        await Future<void>.delayed(Duration.zero).catchError((_) {});
        expect(controller.state, LayrzRefreshState.settling);
      });

      test('notifies listeners on every transition', () async {
        final notifications = <LayrzRefreshState>[];
        controller.addListener(() => notifications.add(controller.state));

        await controller.refresh(() async {});

        expect(notifications, [LayrzRefreshState.refreshing, LayrzRefreshState.settling]);
      });
    });

    group('settle()', () {
      test('returns to idle only from settling', () async {
        // Calling settle() from idle is a no-op.
        controller.settle();
        expect(controller.state, LayrzRefreshState.idle);

        await controller.refresh(() async {});
        expect(controller.state, LayrzRefreshState.settling);

        controller.settle();
        expect(controller.state, LayrzRefreshState.idle);
        expect(controller.dragProgress, 0.0);
      });
    });

    group('drag-progress path (optional, secondary)', () {
      test('updateDragProgress clamps to [0.0, 1.0]', () {
        controller.updateDragProgress(1.5);
        expect(controller.dragProgress, 1.0);

        controller.updateDragProgress(-0.5);
        expect(controller.dragProgress, 0.0);
      });

      test('reaching 1.0 arms the controller', () {
        controller.updateDragProgress(0.5);
        expect(controller.state, LayrzRefreshState.idle);

        controller.updateDragProgress(1.0);
        expect(controller.state, LayrzRefreshState.armed);
      });

      test('dropping back below 1.0 while armed returns to idle', () {
        controller.updateDragProgress(1.0);
        expect(controller.state, LayrzRefreshState.armed);

        controller.updateDragProgress(0.4);
        expect(controller.state, LayrzRefreshState.idle);
      });

      test('is ignored once refreshing has committed', () async {
        final completer = Completer<void>();
        final future = controller.refresh(() => completer.future);

        controller.updateDragProgress(0.9);
        expect(controller.dragProgress, 0.0, reason: 'a drag update must not disturb an in-flight refresh');

        completer.complete();
        await future;
      });

      test('releaseDrag commits to refresh when armed', () async {
        var called = false;
        controller.updateDragProgress(1.0);
        expect(controller.state, LayrzRefreshState.armed);

        await controller.releaseDrag(() async {
          called = true;
        });

        expect(called, isTrue);
        expect(controller.state, LayrzRefreshState.settling);
      });

      test('releaseDrag resets to idle without refreshing when not armed', () async {
        var called = false;
        controller.updateDragProgress(0.3);

        await controller.releaseDrag(() async {
          called = true;
        });

        expect(called, isFalse);
        expect(controller.dragProgress, 0.0);
        expect(controller.state, LayrzRefreshState.idle);
      });
    });

    group('isRefreshing', () {
      test('true for refreshing and settling, false for idle and armed', () async {
        expect(controller.isRefreshing, isFalse);

        controller.updateDragProgress(1.0);
        expect(controller.isRefreshing, isFalse);

        final completer = Completer<void>();
        final future = controller.refresh(() => completer.future);
        expect(controller.isRefreshing, isTrue);

        completer.complete();
        await future;
        expect(controller.isRefreshing, isTrue);

        controller.settle();
        expect(controller.isRefreshing, isFalse);
      });
    });
  });
}
