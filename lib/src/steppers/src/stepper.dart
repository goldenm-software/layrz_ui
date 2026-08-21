import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/preview.dart';

import 'step.dart';
import 'stepper_controller.dart';
import 'stepper_state.dart';

/// A stateful horizontal step indicator and navigator that owns the entire step flow.
///
/// [LayrzStepper] renders:
/// - A step header showing all steps in a horizontal line (or a summary on narrow viewports)
/// - The body widget of the currently active step
/// - Back and next buttons to navigate between steps
///
/// The stepper uses a [LayrzStepperController] to manage step progression. The controller
/// can be supplied by the caller for programmatic control, or created and owned by the
/// stepper itself.
///
/// **Architecture:**
/// The controller owns the step state (current index, step count). The stepper is a pure
/// observer that rebuilds when the controller notifies. This ensures all navigation sources
/// (back/next buttons, header taps, or programmatic calls via the controller) move through
/// a single state point.
///
/// **Lifecycle and disposal:**
/// - If [controller] is null, the stepper creates and disposes its own [LayrzStepperController].
/// - If [controller] is non-null, the caller owns disposal. The stepper does not dispose
///   caller-supplied controllers, allowing them to be shared across multiple widgets.
/// - An assertion will fail if a different controller instance is passed on a rebuild
///   of the same stepper widget. The controller must never be swapped.
///
/// **Step states and navigation:**
/// Each step has a [LayrzStepperState] (upcoming, active, completed, or error). The stepper
/// automatically manages state transitions:
/// - Completed steps are tappable; tapping jumps back for review.
/// - Upcoming steps are locked and visually greyed out.
/// - The active step shows its body.
/// - Error steps show a distinct glyph (not colour alone) and can be jumped to for correction.
///
/// **Validation and advancement:**
/// Before allowing [next], the stepper checks the [LayrzStepperController.canAdvance]
/// callback (if set). This callback can be async, allowing the stepper to gate advancement
/// on server validation or local checks. The callback returns false to deny advancement.
///
/// **Responsive overflow:**
/// - On wide viewports, all step circles are shown with labels.
/// - On narrow viewports (< 960px, [isCompact]), a summary "Step X of Y" is shown instead.
///   This avoids horizontal scroll and keeps the UI clean on phones.
///
/// **Accessibility:**
/// - Step headers have semantics labels including position and state.
/// - Completed steps are distinguishable without colour (a checkmark icon is present).
/// - Back and next buttons are labelled for screen readers.
class LayrzStepper extends StatefulWidget {
  /// Creates a [LayrzStepper].
  const LayrzStepper({
    required this.steps,
    this.controller,
    this.onStepChanged,
    this.backButtonLabel = 'Back',
    this.nextButtonLabel = 'Next',
    super.key,
  }) : assert(steps.length > 0, 'At least one step is required');

  /// The list of steps to display.
  ///
  /// Must contain at least one step. Each step includes a label and a body widget.
  final List<LayrzStep> steps;

  /// Optional controller for programmatic navigation.
  ///
  /// If null, the stepper creates and owns an internal controller.
  /// If non-null, the caller owns disposal. The stepper will not dispose this controller.
  /// The controller instance must never be swapped; an assertion will fail if a different
  /// controller is passed on a rebuild.
  final LayrzStepperController? controller;

  /// Callback fired when the active step changes.
  ///
  /// Receives the zero-based index of the new active step.
  /// Useful for side effects like saving state or analytics.
  final void Function(int stepIndex)? onStepChanged;

  /// Label text for the "Back" button.
  ///
  /// Defaults to "Back".
  final String backButtonLabel;

  /// Label text for the "Next" button.
  ///
  /// Defaults to "Next".
  final String nextButtonLabel;

  @override
  State<LayrzStepper> createState() => _LayrzStepperState();
}

class _LayrzStepperState extends State<LayrzStepper> {
  late LayrzStepperController _internalController;
  late LayrzStepperController _effectiveController;

  @override
  void initState() {
    super.initState();

    // Set up the controller: use the caller's if provided, otherwise create our own.
    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _internalController = LayrzStepperController();
      _effectiveController = _internalController;
    }

    // Initialize the step count.
    _effectiveController.setStepCount(widget.steps.length);

    // Listen for controller changes.
    _effectiveController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(LayrzStepper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Enforce the controller immutability contract.
    assert(
      widget.controller == oldWidget.controller,
      'LayrzStepper does not support changing the controller instance. '
      'The same controller must be passed, or null must remain null.',
    );

    // Update step count if the list length changed.
    if (widget.steps.length != oldWidget.steps.length) {
      _effectiveController.setStepCount(widget.steps.length);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);

    // Dispose our own controller if we created it; never dispose a caller-supplied one.
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

  void _handleStepTap(int index) {
    // Only allow tapping completed steps or the active step.
    final step = widget.steps[index];
    final isCompleted =
        step.state == LayrzStepperState.completed ||
        (step.state == null && index < _effectiveController.currentStepIndex);
    final isActive = index == _effectiveController.currentStepIndex;

    if (isCompleted || isActive) {
      _effectiveController.goTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isCompact = context.isCompact;
    final currentIndex = _effectiveController.currentStepIndex;
    final stepCount = widget.steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step header
        _buildStepHeader(context, isCompact, currentIndex, stepCount, tokens),
        // Spacing between header and body
        SizedBox(height: tokens.spacing.sp4),
        // Active step's body
        Expanded(
          child: _buildStepBody(context, currentIndex),
        ),
        // Spacing between body and buttons
        SizedBox(height: tokens.spacing.sp4),
        // Back and Next buttons
        _buildNavigationButtons(context, currentIndex, stepCount, tokens),
      ],
    );
  }

  Widget _buildStepHeader(
    BuildContext context,
    bool isCompact,
    int currentIndex,
    int stepCount,
    LayrzTokens tokens,
  ) {
    if (isCompact) {
      // On compact viewports, show "Step X of Y" instead of all circles.
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp3,
          vertical: tokens.spacing.sp2,
        ),
        child: Semantics(
          label:
              'Step ${currentIndex + 1} of $stepCount. ${widget.steps[currentIndex].label}.',
          child: Text(
            'Step ${currentIndex + 1} of $stepCount',
            style: tokens.typography.label,
          ),
        ),
      );
    }

    // On wide viewports, show all step circles.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp3,
          vertical: tokens.spacing.sp2,
        ),
        child: Row(
          children: _buildStepCircles(context, currentIndex, stepCount, tokens),
        ),
      ),
    );
  }

  List<Widget> _buildStepCircles(
    BuildContext context,
    int currentIndex,
    int stepCount,
    LayrzTokens tokens,
  ) {
    final circles = <Widget>[];

    for (int i = 0; i < stepCount; i++) {
      circles.add(
        _buildStepCircle(context, i, currentIndex, tokens),
      );

      // Add connector between steps (not after the last step).
      if (i < stepCount - 1) {
        circles.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
            child: SizedBox(
              width: tokens.spacing.sp4,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _getConnectorColor(context, i, currentIndex),
                ),
              ),
            ),
          ),
        );
      }
    }

    return circles;
  }

  Widget _buildStepCircle(
    BuildContext context,
    int index,
    int currentIndex,
    LayrzTokens tokens,
  ) {
    final step = widget.steps[index];
    final state = _determineStepState(step, index, currentIndex);
    final isActive = index == currentIndex;
    final isCompleted = state == LayrzStepperState.completed;
    final isError = state == LayrzStepperState.error;
    final isUpcoming = state == LayrzStepperState.upcoming;

    // Determine colors based on state.
    final bgColor = isActive
        ? tokens.colors.primary
        : isCompleted
            ? tokens.colors.success
            : isError
                ? tokens.colors.danger
                : tokens.colors.sf3;

    final fgColor = isActive || isCompleted || isError
        ? tokens.colors.sf1
        : tokens.colors.fg2;

    final isTappable = isCompleted || isActive;
    final cursor = isTappable ? SystemMouseCursors.click : MouseCursor.defer;

    // Determine the content inside the circle.
    Widget circleContent;
    if (isCompleted) {
      // Show a checkmark icon for completed steps.
      circleContent = Icon(
        MdiIcons.check,
        color: fgColor,
        size: 16,
      );
    } else if (isError) {
      // Show an error icon for error steps.
      circleContent = Icon(
        MdiIcons.alertCircle,
        color: fgColor,
        size: 16,
      );
    } else {
      // Show the step number (1-indexed).
      circleContent = Text(
        '${index + 1}',
        style: tokens.typography.label.copyWith(
          color: fgColor,
        ),
      );
    }

    return GestureDetector(
      onTap: isTappable ? () => _handleStepTap(index) : null,
      child: MouseRegion(
        cursor: cursor,
        child: Semantics(
          label:
              'Step ${index + 1} of ${widget.steps.length}, ${step.label}. ${_semanticsStateLabel(state)}.',
          enabled: isTappable,
          child: Column(
            children: [
              // Step circle.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: isUpcoming
                      ? Border.all(
                          color: tokens.colors.divider,
                          width: 1.5,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: circleContent,
              ),
              // Step label (below the circle).
              SizedBox(height: tokens.spacing.sp1),
              SizedBox(
                width: 60,
                child: Text(
                  step.label,
                  textAlign: TextAlign.center,
                  style: tokens.typography.label.copyWith(
                    color: isUpcoming ? tokens.colors.fg2 : tokens.colors.fg1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConnectorColor(
    BuildContext context,
    int index,
    int currentIndex,
  ) {
    final tokens = context.tokens;
    // Connector is coloured (primary) if both sides are completed/active; otherwise grey.
    if (index < currentIndex) {
      return tokens.colors.primary;
    }
    return tokens.colors.divider;
  }

  String _semanticsStateLabel(LayrzStepperState state) {
    switch (state) {
      case LayrzStepperState.upcoming:
        return 'upcoming, not yet reached';
      case LayrzStepperState.active:
        return 'currently active';
      case LayrzStepperState.completed:
        return 'completed';
      case LayrzStepperState.error:
        return 'error, needs attention';
    }
  }

  LayrzStepperState _determineStepState(
    LayrzStep step,
    int stepIndex,
    int currentIndex,
  ) {
    // If the step has an explicit state set, return it (unless it's the active step).
    if (stepIndex == currentIndex) {
      return LayrzStepperState.active;
    }
    if (step.state != null) {
      return step.state!;
    }
    // Otherwise, infer from progression: before current is completed, after is upcoming.
    if (stepIndex < currentIndex) {
      return LayrzStepperState.completed;
    }
    return LayrzStepperState.upcoming;
  }

  Widget _buildStepBody(BuildContext context, int currentIndex) {
    final step = widget.steps[currentIndex];
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spacing.sp3),
        child: step.body,
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    int currentIndex,
    int stepCount,
    LayrzTokens tokens,
  ) {
    final canGoBack = currentIndex > 0;
    final canGoNext = currentIndex < stepCount - 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sp3,
        vertical: tokens.spacing.sp2,
      ),
      child: Row(
        children: [
          // Back button
          Expanded(
            child: Semantics(
              label: widget.backButtonLabel,
              child: LayrzButton(
                labelText: widget.backButtonLabel,
                onTap: canGoBack ? _handlePrevious : null,
                type: LayrzButtonType.info,
              ),
            ),
          ),
          SizedBox(width: tokens.spacing.sp3),
          // Next button
          Expanded(
            child: Semantics(
              label: widget.nextButtonLabel,
              child: LayrzButton(
                labelText: widget.nextButtonLabel,
                onTap: canGoNext ? _handleNext : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview of [LayrzStepper] with multiple steps showing the basic flow.
@Preview(
  name: 'Multi-step Flow',
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzStepperMultiStep() {
  return LayrzStepper(
    steps: [
      LayrzStep(
        label: 'Personal',
        body: _PreviewStepContent(title: 'Personal Information'),
      ),
      LayrzStep(
        label: 'Shipping',
        body: _PreviewStepContent(title: 'Shipping Address'),
      ),
      LayrzStep(
        label: 'Review',
        body: _PreviewStepContent(title: 'Review & Confirm'),
      ),
    ],
  );
}

/// Preview of [LayrzStepper] with one step in an error state.
@Preview(
  name: 'With Error State',
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzStepperWithError() {
  return LayrzStepper(
    steps: [
      LayrzStep(
        label: 'Personal',
        body: _PreviewStepContent(title: 'Personal Information'),
        state: LayrzStepperState.completed,
      ),
      LayrzStep(
        label: 'Shipping',
        body: _PreviewStepContent(title: 'Shipping Address'),
        state: LayrzStepperState.error,
      ),
      LayrzStep(
        label: 'Review',
        body: _PreviewStepContent(title: 'Review & Confirm'),
      ),
    ],
  );
}

/// A placeholder step content widget used in previews to show typical step content.
class _PreviewStepContent extends StatelessWidget {
  /// The title displayed at the top of the step content.
  final String title;

  const _PreviewStepContent({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tokens.typography.headline,
        ),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'This is the body content for the current step. '
          'It can contain forms, summaries, or any other widget.',
          style: tokens.typography.body,
          maxLines: 3,
        ),
      ],
    );
  }
}
