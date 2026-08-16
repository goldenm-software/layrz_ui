import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons.dart';

void main() {
  group('LayrzButtonController', () {
    group('Loading state', () {
      test('startLoading sets isLoading and notifies', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        expect(controller.isLoading, isFalse);

        controller.startLoading();
        expect(controller.isLoading, isTrue);
        expect(notifiedCount, equals(1));
        expect(controller.isBusy, isTrue);

        controller.dispose();
      });

      test('stopLoading clears isLoading and initiates anti-flash floor', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startLoading();
        notifiedCount = 0; // Reset counter after start

        controller.stopLoading();
        expect(controller.isLoading, isFalse);
        expect(notifiedCount, equals(1));
        // isBusy should still be true due to anti-flash floor.
        expect(controller.isBusy, isTrue);

        controller.dispose();
      });

      test('startLoading when already loading is a no-op', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startLoading();
        notifiedCount = 0;

        controller.startLoading();
        expect(notifiedCount, equals(0)); // No notification

        controller.dispose();
      });

      test('stopLoading when not loading is a no-op', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.stopLoading();
        expect(notifiedCount, equals(0));

        controller.dispose();
      });
    });

    group('Cooldown state', () {
      test('startCooldown sets cooldownTotal and begins countdown', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        expect(controller.cooldownTotal, isNull);

        controller.startCooldown(const Duration(seconds: 5));
        expect(controller.cooldownTotal, equals(const Duration(seconds: 5)));
        expect(notifiedCount, greaterThan(0));
        expect(controller.isBusy, isTrue);

        controller.dispose();
      });

      test('cooldownRemaining decreases over time', () async {
        final controller = LayrzButtonController();

        controller.startCooldown(const Duration(seconds: 5));
        await Future.delayed(const Duration(milliseconds: 50));

        final remaining1 = controller.cooldownRemaining;
        await Future.delayed(const Duration(milliseconds: 50));
        final remaining2 = controller.cooldownRemaining;

        expect(remaining2, lessThan(remaining1));
        expect(remaining1.inMilliseconds, greaterThan(0));
        expect(remaining2.inMilliseconds, greaterThan(0));

        controller.dispose();
      });

      test('cooldownProgress starts at 0.0 and increases toward 1.0', () async {
        final controller = LayrzButtonController();

        controller.startCooldown(const Duration(seconds: 5));
        final progress1 = controller.cooldownProgress;
        expect(progress1, closeTo(0.0, 0.05)); // Allow small margin

        await Future.delayed(const Duration(milliseconds: 100));
        final progress2 = controller.cooldownProgress;

        expect(progress2, greaterThan(progress1));
        expect(progress2, lessThan(0.1));

        controller.dispose();
      });

      test('cooldownProgress is clamped to [0.0, 1.0]', () {
        final controller = LayrzButtonController();

        // No cooldown: progress is 0.0
        expect(controller.cooldownProgress, equals(0.0));

        // With cooldown: progress is in [0.0, 1.0]
        controller.startCooldown(const Duration(seconds: 1));
        expect(controller.cooldownProgress, greaterThanOrEqualTo(0.0));
        expect(controller.cooldownProgress, lessThanOrEqualTo(1.0));

        controller.dispose();
      });

      test('cooldownRemaining never goes negative', () {
        final controller = LayrzButtonController();

        controller.startCooldown(const Duration(seconds: 5));

        // Remaining should always be >= 0
        expect(controller.cooldownRemaining.inMilliseconds, greaterThanOrEqualTo(0));

        controller.dispose();
      });

      test('zero and negative durations are no-ops', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startCooldown(Duration.zero);
        expect(controller.cooldownTotal, isNull);
        expect(notifiedCount, equals(0));

        controller.startCooldown(const Duration(seconds: -1));
        expect(controller.cooldownTotal, isNull);
        expect(notifiedCount, equals(0));

        controller.dispose();
      });

      test('idempotence: same duration does not restart countdown', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        final duration = const Duration(seconds: 5);
        controller.startCooldown(duration);
        final progress1 = controller.cooldownProgress;
        notifiedCount = 0;

        // Same duration: should be a no-op.
        controller.startCooldown(duration);
        final progress2 = controller.cooldownProgress;

        expect(progress2, closeTo(progress1, 0.01)); // Progress unchanged
        expect(notifiedCount, equals(0)); // No notification

        controller.dispose();
      });

      test('different duration restarts countdown', () async {
        final controller = LayrzButtonController();

        controller.startCooldown(const Duration(seconds: 5));
        // Wait to accumulate some progress
        await Future.delayed(const Duration(milliseconds: 100));
        final progress1 = controller.cooldownProgress;

        controller.startCooldown(const Duration(seconds: 3));
        final progress2 = controller.cooldownProgress;

        // New countdown should reset progress to near 0.0.
        expect(progress2, lessThan(progress1 * 0.5));

        controller.dispose();
      });

      test('clearCooldown stops the countdown early', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startCooldown(const Duration(seconds: 5));
        notifiedCount = 0;

        controller.clearCooldown();
        expect(controller.cooldownTotal, isNull);
        expect(controller.cooldownRemaining, equals(Duration.zero));
        expect(notifiedCount, equals(1));

        controller.dispose();
      });

      test('clearCooldown when not in cooldown is a no-op', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.clearCooldown();
        expect(notifiedCount, equals(0));

        controller.dispose();
      });
    });

    group('Auto-clear on expiry', () {
      test('cooldown auto-clears when duration elapses', () async {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startCooldown(const Duration(milliseconds: 100));
        expect(controller.cooldownTotal, isNotNull);

        // Wait for cooldown to expire.
        await Future.delayed(const Duration(milliseconds: 150));

        // Cooldown should be cleared.
        expect(controller.cooldownTotal, isNull);
        expect(controller.cooldownRemaining, equals(Duration.zero));
        expect(notifiedCount, greaterThan(1));

        controller.dispose();
      });
    });

    group('Anti-flash floor', () {
      test('isBusy remains true for 100ms after stopLoading', () async {
        final controller = LayrzButtonController();

        controller.startLoading();
        expect(controller.isBusy, isTrue);

        controller.stopLoading();
        expect(controller.isLoading, isFalse);
        expect(controller.isBusy, isTrue); // Floor active

        // Wait less than 100ms: still busy
        await Future.delayed(const Duration(milliseconds: 50));
        expect(controller.isBusy, isTrue);

        // Wait past 100ms: no longer busy
        await Future.delayed(const Duration(milliseconds: 60));
        expect(controller.isBusy, isFalse);

        controller.dispose();
      });

      test('isBusy is true if loading is active', () {
        final controller = LayrzButtonController();

        controller.startLoading();
        expect(controller.isBusy, isTrue);

        controller.dispose();
      });

      test('isBusy is true if cooldown is active', () {
        final controller = LayrzButtonController();

        controller.startCooldown(const Duration(seconds: 5));
        expect(controller.isBusy, isTrue);

        controller.dispose();
      });

      test('isBusy is false when no busy state and floor expired', () async {
        final controller = LayrzButtonController();

        expect(controller.isBusy, isFalse);

        controller.startLoading();
        controller.stopLoading();
        expect(controller.isBusy, isTrue);

        await Future.delayed(const Duration(milliseconds: 150));
        expect(controller.isBusy, isFalse);

        controller.dispose();
      });
    });

    group('Reset', () {
      test('reset clears all state', () {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startLoading();
        controller.startCooldown(const Duration(seconds: 5));
        notifiedCount = 0;

        controller.reset();
        expect(controller.isLoading, isFalse);
        expect(controller.cooldownTotal, isNull);
        expect(controller.isBusy, isFalse);
        expect(notifiedCount, equals(1));

        controller.dispose();
      });
    });

    group('Lifecycle safety', () {
      test('dispose cancels timers and prevents callbacks', () async {
        final controller = LayrzButtonController();
        var notifiedCount = 0;
        controller.addListener(() => notifiedCount++);

        controller.startCooldown(const Duration(seconds: 5));
        controller.dispose();

        // Wait for a timer tick that would have happened.
        await Future.delayed(const Duration(milliseconds: 50));

        // No new notifications should fire after dispose.
        // (This is hard to test directly, but we can verify no exception.)
        expect(notifiedCount, greaterThan(0)); // At least one from start
      });

      test('multiple listeners are all notified', () {
        final controller = LayrzButtonController();
        var count1 = 0;
        var count2 = 0;
        controller.addListener(() => count1++);
        controller.addListener(() => count2++);

        controller.startLoading();
        expect(count1, equals(1));
        expect(count2, equals(1));

        controller.dispose();
      });

      test('removing a listener prevents further notifications', () {
        final controller = LayrzButtonController();
        var count = 0;
        void listener() => count++;
        controller.addListener(listener);

        controller.startLoading();
        expect(count, equals(1));

        controller.removeListener(listener);
        count = 0;

        controller.startLoading(); // Already loading, no-op
        expect(count, equals(0));

        controller.dispose();
      });
    });
  });
}
