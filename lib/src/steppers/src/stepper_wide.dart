import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'step.dart';
import 'step_indicator.dart';
import 'stepper_state.dart';

/// The height, in logical pixels, of the fixed indicator band rendered by
/// [LayrzStepperWideHeader].
///
/// This band holds every [LayrzStepIndicator] and its connecting lines, all
/// vertically centred on the same midline. Its height is fixed and does not
/// depend on label content in any way, which is what makes it structurally
/// impossible for a wrapped, two-line label to shift an indicator: the label
/// lives in a second band below this one, and nothing in that second band can
/// feed a height back into this one. It is sized to match
/// [kLayrzStepIndicatorSize] exactly, since the indicator is the tallest
/// element the band needs to fit.
const double kLayrzStepperWideBandHeight = kLayrzStepIndicatorSize;

/// The horizontal, full-width step header for [LayrzStepper] on wide viewports.
///
/// Renders one equal-width flex cell per step in [steps], left to right. Each
/// cell stacks two independent bands in a [Column]:
///
/// - **Band 1** (fixed height [kLayrzStepperWideBandHeight]): the
///   [LayrzStepIndicator] circle, centred, with a connector line segment on
///   either side that stretches to meet the neighbouring cell's segment,
///   vertically centred on the indicator's own midline. An upcoming step's
///   indicator additionally carries a small locked-affordance badge in this
///   same band (see the non-colour lock cue applied in [_StepCell]) — a state
///   cue about the indicator itself, so it stays legible even at extreme step
///   counts where band 2's label may have ellipsized to near-nothing.
/// - **Band 2**: the step's label, hanging below band 1, capped at two lines
///   with an ellipsis and no recovery affordance (no tooltip, no long-press) —
///   a truncated label stays truncated.
///
/// This two-band structure is the fix for a real, previously-shipped bug: when
/// a step is instead modelled as a single `Column[circle, label]` and those
/// columns sit as centre-aligned siblings in a `Row`, a step whose label wraps
/// to two lines grows its own column taller than its neighbours, which
/// re-centres that column and visibly offsets its circle against the others
/// and against the connector line. Because band 1 here has a height fixed
/// independently of band 2's content, that feedback path does not exist: no
/// label, however long, can reach back into band 1's layout.
///
/// The header spans the full width available to it and never scrolls — a
/// stepper "using the entire space available" and a horizontally-scrolling
/// header are opposites. There is deliberately no maximum step count, no
/// assertion, and no fallback layout for large step counts: steps squeeze
/// instead, and legibility at extreme counts is the caller's responsibility.
class LayrzStepperWideHeader extends StatelessWidget {
  /// Creates a [LayrzStepperWideHeader].
  const LayrzStepperWideHeader({
    required this.steps,
    required this.currentIndex,
    required this.onStepTap,
    super.key,
  });

  /// The ordered list of steps to render, one cell per entry.
  ///
  /// There is no maximum length enforced by this widget: an unusually long
  /// list of steps squeezes into narrower cells rather than being capped,
  /// scrolled, or rejected.
  final List<LayrzStep> steps;

  /// The zero-based index of the step currently active in the stepper.
  ///
  /// Drives which steps render as completed, active, or upcoming, and which
  /// connector segments are painted in the "progressed" colour.
  final int currentIndex;

  /// Called with a step's zero-based index when a tappable step is activated.
  ///
  /// Only steps in [LayrzStepperState.completed] or [LayrzStepperState.active]
  /// are tappable; [LayrzStepperState.upcoming] steps are locked and ignore
  /// taps entirely.
  final ValueChanged<int> onStepTap;

  /// Resolves the [LayrzStepperState] for the step at [index].
  ///
  /// The step at [currentIndex] is always [LayrzStepperState.active],
  /// overriding any explicit [LayrzStep.state]. Otherwise an explicit state is
  /// honoured; steps before [currentIndex] with no explicit state default to
  /// [LayrzStepperState.completed], and steps after default to
  /// [LayrzStepperState.upcoming].
  LayrzStepperState _stateOf(int index) {
    if (index == currentIndex) return LayrzStepperState.active;
    final explicit = steps[index].state;
    if (explicit != null) return explicit;
    return index < currentIndex ? LayrzStepperState.completed : LayrzStepperState.upcoming;
  }

  /// Whether the step at [index] currently accepts taps.
  ///
  /// Mirrors the stepper-wide contract: only completed and active steps are
  /// tappable, so a caller can jump back to review or forward to the step
  /// already in progress, but never ahead into a locked step.
  bool _isTappable(int index) {
    final state = _stateOf(index);
    return state == LayrzStepperState.completed || state == LayrzStepperState.active;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < steps.length; index++)
          Expanded(
            child: _StepCell(
              step: steps[index],
              index: index,
              stepCount: steps.length,
              state: _stateOf(index),
              isTappable: _isTappable(index),
              // The segment to this cell's left is "progressed" when the
              // previous step is at or before the active one.
              leftConnectorProgressed: index > 0 && index <= currentIndex,
              // The segment to this cell's right is "progressed" when this
              // step is strictly before the active one.
              rightConnectorProgressed: index < steps.length - 1 && index < currentIndex,
              onTap: () => onStepTap(index),
              positionLabel: l10n.steppersStepCounterLabel(index + 1, steps.length),
              stateLabel: l10n.steppersStateLabel(_stateOf(index)),
            ),
          ),
      ],
    );
  }
}

/// A single step's cell within [LayrzStepperWideHeader]: the two-band column
/// of indicator+connectors over a label, wrapped in the tap and semantics
/// contract for that step.
class _StepCell extends StatelessWidget {
  const _StepCell({
    required this.step,
    required this.index,
    required this.stepCount,
    required this.state,
    required this.isTappable,
    required this.leftConnectorProgressed,
    required this.rightConnectorProgressed,
    required this.onTap,
    required this.positionLabel,
    required this.stateLabel,
  });

  /// The step data rendered by this cell.
  final LayrzStep step;

  /// The zero-based position of this step among all steps.
  final int index;

  /// The total number of steps in the stepper, used for the semantics label.
  final int stepCount;

  /// The resolved state of this step.
  final LayrzStepperState state;

  /// Whether this cell currently accepts taps.
  final bool isTappable;

  /// Whether the connector segment to the left of this cell's indicator
  /// should render in the "progressed" (primary) colour.
  final bool leftConnectorProgressed;

  /// Whether the connector segment to the right of this cell's indicator
  /// should render in the "progressed" (primary) colour.
  final bool rightConnectorProgressed;

  /// Invoked when this cell is tapped while [isTappable] is true.
  final VoidCallback onTap;

  /// The localized "Step X of Y" fragment prefixing this cell's semantics label.
  ///
  /// Built from [LayrzUiL10nSteppersMixin.steppersStepCounterLabel] so a
  /// screen-reader announcement is translated the same as the rest of the UI.
  final String positionLabel;

  /// The localized human-readable state fragment appended to this cell's
  /// semantics label.
  ///
  /// Built from [LayrzUiL10nSteppersMixin.steppersStateLabel], which already
  /// includes the "locked" wording for [LayrzStepperState.upcoming] — the
  /// same state must announce identically regardless of which layout renders
  /// it, so this fragment is used as-is with no further suffixing.
  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isUpcoming = state == LayrzStepperState.upcoming;
    final cursor = isTappable ? SystemMouseCursors.click : MouseCursor.defer;

    return Semantics(
      label: '$positionLabel, ${step.labelText}. $stateLabel.',
      enabled: isTappable,
      child: GestureDetector(
        onTap: isTappable ? onTap : null,
        child: MouseRegion(
          cursor: cursor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Band 1 — fixed height, independent of the label below it. The
              // lock affordance for an upcoming step is anchored here, on the
              // indicator row itself, rather than beside the label: it is a
              // state cue about the indicator, and it must stay legible even
              // when the label beneath has ellipsized to near-nothing at
              // extreme step counts.
              SizedBox(
                height: kLayrzStepperWideBandHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: index == 0 ? const SizedBox.shrink() : _Connector(progressed: leftConnectorProgressed),
                    ),
                    Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        LayrzStepIndicator(
                          index: index,
                          state: state,
                          icon: step.icon,
                        ),
                        if (isUpcoming)
                          Icon(
                            MdiIcons.lockOutline,
                            size: kLayrzStepIndicatorGlyphSize,
                            color: tokens.colors.fg2,
                          ),
                      ],
                    ),
                    Expanded(
                      child: index == stepCount - 1
                          ? const SizedBox.shrink()
                          : _Connector(progressed: rightConnectorProgressed),
                    ),
                  ],
                ),
              ),
              // Band 2 — the label, hanging below band 1. Its height can never
              // feed back into band 1's SizedBox above.
              SizedBox(height: tokens.spacing.sp1),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
                child: Text(
                  step.labelText,
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
}

/// A single connector line segment drawn inside band 1, stretching to fill
/// the flex space it is given between two adjacent [LayrzStepIndicator]s.
///
/// Two of these — the right segment of one cell and the left segment of the
/// next — sit edge to edge across the gap between two indicators and are
/// always coloured identically, so together they read as one continuous line
/// rather than two.
class _Connector extends StatelessWidget {
  const _Connector({required this.progressed});

  /// Whether this segment lies on the "reached" side of the active step and
  /// should render in the primary colour, versus the neutral divider colour.
  final bool progressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Align(
      alignment: Alignment.center,
      child: Container(
        height: 2,
        color: progressed ? tokens.colors.primary : tokens.colors.divider,
      ),
    );
  }
}
