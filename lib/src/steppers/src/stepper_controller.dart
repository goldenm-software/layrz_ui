import 'package:flutter/foundation.dart';

/// A controller that drives the step navigation of a [LayrzStepper].
///
/// This controller manages the current step index and step transitions.
/// Multiple steppers can share a single controller, enabling synchronized navigation
/// (e.g. nested steppers or sidebars that reflect the main flow).
///
/// **Architecture:**
/// The controller owns the step state. The stepper is a pure observer that subscribes
/// via `addListener` and reads the current step index. This ensures all dependents
/// see a consistent view of which step is active.
///
/// **Lifecycle and disposal:**
/// - **Disposal is caller-owned.** If a stepper's controller is passed by the caller,
///   the stepper does NOT dispose it. If the stepper creates an internal controller
///   (via the constructor's default), the stepper disposes its own instance.
/// - This contract ensures controllers can be shared across multiple widgets without
///   early disposal, and allows callers to reuse controllers across stepper instances.
/// - See [LayrzStepper]'s constructor documentation for the exact lifecycle contract.
///
/// **Controller immutability guarantee:**
/// An assertion will fail if a different controller instance is passed via
/// [LayrzStepper.controller] on a rebuild of the same stepper widget. The controller
/// must never be swapped mid-lifecycle. This prevents listener subscription chaos and
/// ensures a stable reference for programmatic navigation.
///
/// **Navigation safety:**
/// - Transitions clamp to valid step indices (0 to stepCount-1).
/// - [goTo] and [next]/[previous] check bounds before updating.
/// - [canAdvance] is a callback the stepper checks before allowing advancement.
class LayrzStepperController extends ChangeNotifier {
  /// The total number of steps in the stepper.
  ///
  /// This is set by the stepper after the controller is attached.
  int _stepCount = 0;

  /// The zero-based index of the currently active step.
  int _currentStepIndex = 0;

  /// Callback to determine if the current step can advance.
  ///
  /// If null, all steps can advance freely.
  /// If non-null, the stepper calls this before allowing [next] to succeed.
  /// The callback can return a [Future] for async validation (e.g. server checks).
  Future<bool> Function()? _canAdvance;

  /// Tracks whether this controller has been disposed.
  bool _disposed = false;

  /// Gets the zero-based index of the currently active step.
  int get currentStepIndex => _currentStepIndex;

  /// Gets the total number of steps.
  int get stepCount => _stepCount;

  /// Gets whether the stepper can move to the next step.
  ///
  /// True if the current step is not the last step.
  bool get canMoveNext => _currentStepIndex < _stepCount - 1;

  /// Gets whether the stepper can move to the previous step.
  ///
  /// True if the current step is not the first step.
  bool get canMovePrevious => _currentStepIndex > 0;

  /// Advances to the next step if allowed and in bounds.
  ///
  /// Before advancing, the stepper calls the [canAdvance] callback (if set).
  /// If it returns false or the callback is not set, advancement is denied.
  /// Calling [next] when already on the last step is a no-op.
  Future<void> next() async {
    if (!canMoveNext) return;

    // Check the validation gate if set.
    if (_canAdvance != null) {
      final allowed = await _canAdvance!();
      if (!allowed) return;
    }

    _currentStepIndex++;
    notifyListeners();
  }

  /// Moves to the previous step without validation.
  ///
  /// Unlike [next], this does not check [canAdvance].
  /// Calling [previous] when already on the first step is a no-op, but still notifies listeners.
  void previous() {
    if (canMovePrevious) {
      _currentStepIndex--;
    }
    notifyListeners();
  }

  /// Jumps directly to the step at the given [index].
  ///
  /// The index must be in [0, stepCount). If out of bounds, this is a no-op.
  /// This does not check [canAdvance]; it allows jumping backward to review
  /// completed steps without validation.
  void goTo(int index) {
    if (index < 0 || index >= _stepCount) return;

    _currentStepIndex = index;
    notifyListeners();
  }

  /// Sets the callback to determine if the current step can advance.
  ///
  /// The callback is invoked by the stepper before allowing [next] to proceed.
  /// If the callback returns false, the step is not advanced.
  /// Passing null removes the validation gate.
  void setCanAdvance(Future<bool> Function()? callback) {
    _canAdvance = callback;
  }

  /// Internal: Sets the total step count.
  ///
  /// Called by the stepper after building. Not for public use.
  void setStepCount(int count) {
    assert(count > 0, 'Step count must be positive');
    _stepCount = count;
    // Clamp current index to valid range in case it's out of bounds.
    if (_currentStepIndex >= _stepCount) {
      _currentStepIndex = _stepCount - 1;
    }
  }

  /// Internal: Resets to the first step.
  ///
  /// Called when the stepper rebuilds with a different step list.
  void reset() {
    _currentStepIndex = 0;
    _stepCount = 0;
    notifyListeners();
  }

  /// Disposes the controller and releases resources.
  ///
  /// Safe to call multiple times. Subsequent calls are no-ops.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
