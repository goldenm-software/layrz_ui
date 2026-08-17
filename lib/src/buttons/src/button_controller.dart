import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:layrz_ui/src/constants/constants.dart';

/// A controller that drives the busy state of one or more [LayrzButton] widgets.
///
/// This controller manages loading and cooldown states in a thread-safe, lifecycle-safe manner.
/// Multiple buttons can share a single controller instance, enabling lockstep busy-state management
/// across a form or action group.
///
/// **Architecture:**
/// The controller owns the state and timing logic. Buttons are pure observers that subscribe via
/// `addListener` and paint from the controller's current values. This ensures all buttons driven
/// by the same controller move in perfect sync, preventing frame-by-frame drift or flicker.
///
/// **Lifecycle safety:**
/// - Buttons attach and detach listeners dynamically (see [LayrzButton]'s `didUpdateWidget`).
/// - Disposal is caller-owned. If a button's controller is disposed before the button unmounts,
///   the button remains functional and will not throw or `setState` after unmount.
/// - All timers are cancelled on `dispose()`, preventing callbacks from firing after disposal.
///
/// **Safety guards:**
/// - **Input validation:** `startCooldown` with zero or negative Duration is a no-op.
/// - **Idempotence:** Calling `startCooldown` with a cooldown already running and the same
///   total duration does not restart the countdown. Different durations deliberately restart.
/// - **Clamped paint:** Progress always [0.0, 1.0]; remaining always >= 0; displayed seconds clamp at 0.
/// - **Anti-flash floor:** A busy state visible < 100ms is held visible until that floor elapses,
///   preventing strobe effects from quick server responses. This governs both visual and interactive
///   state — buttons stay disabled for the whole held window.
///
/// **Cooldown auto-clear:**
/// When a cooldown Duration elapses, the controller automatically clears it and notifies.
/// This reverses an earlier design constraint: the controller, as the application's busy-state agent,
/// may clear without overstepping. The button still never clears the controller itself.
class LayrzButtonController extends ChangeNotifier {
  /// Whether the button is currently in a loading state.
  bool _isLoading = false;

  /// The total cooldown duration if a cooldown is active, null otherwise.
  Duration? _cooldownTotal;

  /// The elapsed time within the current cooldown countdown.
  ///
  /// When null, no cooldown is active.
  /// When a duration, it counts from 0 up to [_cooldownTotal].
  /// This is updated by the cooldown timer approximately every ~16ms (one frame).
  Duration? _cooldownElapsed;

  /// Timer for the cooldown countdown. Ticked at ~60fps.
  ///
  /// When null, no cooldown timer is active.
  /// On each tick, [_cooldownElapsed] advances toward [_cooldownTotal].
  /// When [_cooldownElapsed] reaches [_cooldownTotal], the timer is cancelled
  /// and the cooldown is cleared via [_clearCooldownInternal].
  Timer? _cooldownTimer;

  /// Timer for the anti-flash floor. Fires after 100ms to allow the button to re-enable.
  ///
  /// When null, no anti-flash floor is active.
  /// When non-null, the button remains busy even if loading/cooldown have stopped.
  /// This prevents flicker and rapid state changes from quick server responses.
  Timer? _floorTimer;

  /// Whether the anti-flash floor is currently active.
  ///
  /// When true, the button remains busy even if loading/cooldown have stopped,
  /// until [_floorTimer] fires and sets this to false.
  bool _floorActive = false;

  /// Gets whether the button is loading.
  bool get isLoading => _isLoading;

  /// Gets the total cooldown duration if a cooldown is active, null otherwise.
  Duration? get cooldownTotal => _cooldownTotal;

  /// Gets the remaining time until cooldown expires.
  ///
  /// Returns [Duration.zero] if no cooldown is active.
  /// Returns a clamped non-negative duration.
  Duration get cooldownRemaining {
    if (_cooldownTotal == null || _cooldownElapsed == null) {
      return Duration.zero;
    }
    final remaining = _cooldownTotal! - _cooldownElapsed!;
    // Clamp to zero (never negative).
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Gets the cooldown progress as a fraction [0.0, 1.0].
  ///
  /// - 0.0: cooldown just started
  /// - 1.0: cooldown fully elapsed
  /// - Returns 0.0 if no cooldown is active.
  ///
  /// Always clamped within [0.0, 1.0].
  double get cooldownProgress {
    if (_cooldownTotal == null || _cooldownTotal!.inMilliseconds <= 0) {
      return 0.0;
    }
    if (_cooldownElapsed == null) {
      return 0.0;
    }
    final progress = _cooldownElapsed!.inMilliseconds / _cooldownTotal!.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }

  /// Gets whether the button is in any busy state after applying the anti-flash floor.
  ///
  /// Busy states are loading or cooldown. When either begins, a timer ensures the
  /// button remains visually and interactively disabled for at least
  /// [kLayrzButtonMinBusyDuration] (100ms), even if the real busy state expires sooner.
  /// This prevents flicker and rapid state changes from quick responses.
  ///
  /// Returns `true` if:
  /// - [isLoading] is true, OR
  /// - [cooldownTotal] is non-null (cooldown is active), OR
  /// - The anti-flash floor is currently active.
  bool get isBusy => _isLoading || _cooldownTotal != null || _floorActive;

  /// Starts the loading indicator.
  ///
  /// Sets [isLoading] to true and notifies listeners.
  /// Calling this while already loading is a no-op.
  void startLoading() {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
  }

  /// Stops the loading indicator.
  ///
  /// Sets [isLoading] to false and initiates the anti-flash floor timer.
  /// The button remains disabled and visually indicates busy until the floor expires.
  /// Calling this when not loading is a no-op.
  void stopLoading() {
    if (!_isLoading) return;
    _isLoading = false;
    _startAntiFlashFloorTimer();
    notifyListeners();
  }

  /// Starts a cooldown with the given [duration].
  ///
  /// If [duration] is zero or negative, this is a no-op and no notification is sent.
  /// If a cooldown is already running with the **same** total duration, this is a no-op
  /// and the countdown is not restarted (idempotence). If the duration is **different**,
  /// the cooldown restarts.
  void startCooldown(Duration duration) {
    // Input validation: zero or negative is a no-op.
    if (duration.inMilliseconds <= 0) {
      return;
    }

    // Idempotence: if cooldown is already running with same total, do nothing.
    if (_cooldownTotal == duration) {
      return;
    }

    // Different duration: cancel the old timer and start a new countdown.
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownTotal = duration;
    _cooldownElapsed = Duration.zero;

    // Start the countdown timer (tick at ~60fps, ~16ms per frame).
    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_cooldownElapsed == null || _cooldownTotal == null) return;

      _cooldownElapsed = _cooldownElapsed! + const Duration(milliseconds: 16);

      // Check if cooldown is complete.
      if (_cooldownElapsed! >= _cooldownTotal!) {
        _clearCooldownInternal();
      } else {
        // Cooldown still running; notify to update progress.
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Clears an active cooldown early, before it expires.
  ///
  /// Sets [cooldownTotal] to null and cancels the cooldown timer.
  /// Unlike natural cooldown expiry, an explicit clear does NOT apply the anti-flash floor.
  /// The button immediately becomes tappable.
  /// This distinction reflects that explicit actions by the user or application
  /// override the need to hold the disabled state for user safety.
  /// Calling this when no cooldown is active is a no-op.
  void clearCooldown() {
    if (_cooldownTotal == null) return;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownTotal = null;
    _cooldownElapsed = null;
    notifyListeners();
  }

  /// Resets all busy states to inactive.
  ///
  /// Stops loading, clears cooldown, and cancels all timers.
  /// The button immediately becomes fully enabled and idle.
  void reset() {
    _isLoading = false;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownTotal = null;
    _cooldownElapsed = null;
    _floorTimer?.cancel();
    _floorTimer = null;
    _floorActive = false;
    notifyListeners();
  }

  /// Clears the cooldown when the countdown timer expires.
  ///
  /// Called internally when [_cooldownElapsed] reaches [_cooldownTotal].
  /// Initiates the anti-flash floor timer and notifies listeners.
  void _clearCooldownInternal() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownTotal = null;
    _cooldownElapsed = null;
    _startAntiFlashFloorTimer();
    notifyListeners();
  }

  /// Starts the anti-flash floor timer if a busy state just ended.
  ///
  /// Ensures the button remains visually and interactively disabled for at least
  /// [kLayrzButtonMinBusyDuration] (100ms) after a busy state begins, preventing
  /// flicker from quick responses.
  /// This is called when loading stops or cooldown expires naturally.
  void _startAntiFlashFloorTimer() {
    _floorTimer?.cancel();
    _floorActive = true;
    _floorTimer = Timer(kLayrzButtonMinBusyDuration, () {
      _floorActive = false;
      _floorTimer = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _floorTimer?.cancel();
    _floorTimer = null;
    _floorActive = false;
    super.dispose();
  }
}
