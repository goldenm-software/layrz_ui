import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'step.dart';
import 'stepper_compact.dart';
import 'stepper_controller.dart';
import 'stepper_state.dart';
import 'stepper_wide.dart';

/// A stateful step navigator that owns the step flow's controller and
/// delegates all layout painting to a wide or compact surface.
///
/// [LayrzStepper] is a thin coordinator: it owns the [LayrzStepperController]
/// lifecycle, resolves the active step's state on tap, and picks a layout —
/// [LayrzStepperWideHeader] on wide viewports or [LayrzStepperCompactLayout]
/// (a vertical accordion with an inline active body and a persistent counter)
/// on compact ones ([isCompact], `< 960px` by default). It owns no
/// circle/connector/label rendering itself; see those two layouts and
/// [LayrzStepIndicator] for that. On the wide layout, the active step's body
/// renders below the header; the compact layout renders it inline as part of
/// its own accordion row instead. A single Back/Next row, driven by
/// [LayrzStepperController.canAdvance], sits below either layout.
///
/// **Lifecycle:** if [controller] is null, the stepper creates and disposes
/// its own; if non-null, the caller owns disposal and the instance must never
/// be swapped (an assertion fails on a rebuild that changes it).
///
/// **States:** each step has a [LayrzStepperState] — completed steps are
/// tappable (jump back for review), upcoming steps are locked, the active
/// step shows its body, and error steps show a distinct glyph (never colour
/// alone) and can be jumped to for correction.
class LayrzStepper extends StatefulWidget {
  /// Creates a [LayrzStepper].
  const LayrzStepper({
    required this.steps,
    this.controller,
    this.onStepChanged,
    this.backButtonLabel,
    this.nextButtonLabel,
    this.isCompact,
    super.key,
  }) : assert(steps.length > 0, 'At least one step is required');

  /// The list of steps to display. Must contain at least one step.
  final List<LayrzStep> steps;

  /// Optional controller for programmatic navigation.
  ///
  /// If null, the stepper creates, owns and disposes an internal controller.
  /// If non-null, the caller owns disposal and the instance must never be
  /// swapped; an assertion fails if a different controller is passed on a
  /// rebuild.
  final LayrzStepperController? controller;

  /// Callback fired with the zero-based index of the new active step whenever
  /// it changes. Useful for side effects like saving state or analytics.
  final void Function(int stepIndex)? onStepChanged;

  /// Optional override for the "Back" button label.
  ///
  /// Defaults to [LayrzUiL10n.steppersPreviousButtonLabel] when null.
  final String? backButtonLabel;

  /// Optional override for the "Next" button label.
  ///
  /// Defaults to [LayrzUiL10n.steppersNextButtonLabel] when null.
  final String? nextButtonLabel;

  /// Overrides which layout is chosen, regardless of viewport width.
  ///
  /// Defaults to `null`, which derives the layout from `context.isCompact`
  /// (`true` below the 960 logical-pixel `sm`/`md` breakpoint). Pass `true`
  /// to force [LayrzStepperCompactLayout] or `false` to force
  /// [LayrzStepperWideHeader] regardless of the actual viewport — useful for
  /// testing both branches without resizing the test surface.
  final bool? isCompact;

  @override
  State<LayrzStepper> createState() => _LayrzStepperState();
}

class _LayrzStepperState extends State<LayrzStepper> {
  late LayrzStepperController _internalController;
  late LayrzStepperController _effectiveController;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _internalController = LayrzStepperController();
      _effectiveController = _internalController;
    }

    _effectiveController.setStepCount(widget.steps.length);
    _effectiveController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(LayrzStepper oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(
      widget.controller == oldWidget.controller,
      'LayrzStepper does not support changing the controller instance. '
      'The same controller must be passed, or null must remain null.',
    );

    if (widget.steps.length != oldWidget.steps.length) {
      _effectiveController.setStepCount(widget.steps.length);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);

    // Caller-supplied controllers are caller-disposed; see field doc on [controller].
    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      widget.onStepChanged?.call(_effectiveController.currentStepIndex);
    }
  }

  Future<void> _handleNext() async {
    await _effectiveController.next();
  }

  void _handlePrevious() {
    _effectiveController.previous();
  }

  // Both LayrzStepperWideHeader and LayrzStepperCompactLayout already gate
  // their own onTap to tappable (completed/active) rows — an upcoming row's
  // GestureDetector.onTap is null, so this callback never fires for one. No
  // second tappability check is needed here; duplicating that rule risks it
  // diverging from the layouts' copy (see step_indicator.dart's WCAG rule for
  // why a single source of truth matters for step state).
  void _handleStepTap(int index) => _effectiveController.goTo(index);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isCompact = widget.isCompact ?? context.isCompact;
    final currentIndex = _effectiveController.currentStepIndex;
    final canGoBack = currentIndex > 0;
    final canGoNext = currentIndex < widget.steps.length - 1;
    final l10n = LayrzUiL10n.of(context);
    final backLabel = widget.backButtonLabel ?? l10n.steppersPreviousButtonLabel;
    final nextLabel = widget.nextButtonLabel ?? l10n.steppersNextButtonLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCompact)
          LayrzStepperCompactLayout(
            steps: widget.steps,
            currentIndex: currentIndex,
            onStepTap: _handleStepTap,
          )
        else ...[
          LayrzStepperWideHeader(
            steps: widget.steps,
            currentIndex: currentIndex,
            onStepTap: _handleStepTap,
          ),
          SizedBox(height: tokens.spacing.sp4),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.sp3),
                child: widget.steps[currentIndex].body,
              ),
            ),
          ),
        ],
        SizedBox(height: tokens.spacing.sp4),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp2),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: backLabel,
                  child: LayrzButton(
                    labelText: backLabel,
                    onTap: canGoBack ? _handlePrevious : null,
                    type: LayrzButtonType.info,
                  ),
                ),
              ),
              SizedBox(width: tokens.spacing.sp3),
              Expanded(
                child: Semantics(
                  label: nextLabel,
                  child: LayrzButton(
                    labelText: nextLabel,
                    onTap: canGoNext ? _handleNext : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
