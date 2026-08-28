import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'step.dart';
import 'step_indicator.dart';
import 'stepper_state.dart';

/// The vertical, "acts like an accordion" layout rendered by [LayrzStepper] on
/// compact viewports (`context.isCompact`, i.e. narrower than 960px).
///
/// [LayrzStepperCompactLayout] flips the stepper's axis from left-to-right to
/// top-to-bottom. Every step renders as a header row; the **active** step's
/// header additionally hosts its [LayrzStep.body] inline, directly beneath it.
/// Only one step is ever open — the active one — and it is not independent
/// disclosure state: it is driven entirely by [currentIndex], the same value
/// that drives the wide layout. Tapping a completed step's header calls
/// [onStepTap], which moves [currentIndex] and therefore moves which body is
/// shown. There is no per-row expanded/collapsed flag anywhere in this widget.
///
/// This is deliberately **not** a general-purpose accordion: it cannot have
/// zero or multiple steps open, and upcoming steps can never be opened by the
/// user, no matter how many are tapped. Per Kenny's brief, this is a stepper
/// wearing accordion clothing for the *feel* of it, not a disclosure widget.
///
/// A persistent "Step X of Y" counter is rendered above the stack, additive to
/// the per-step headers below it: the stack answers "what am I getting into",
/// the counter answers "how much is left" at a glance. The counter text is
/// localized via [LayrzUiL10nSteppersMixin.steppersStepCounterLabel] — see
/// `package:layrz_ui/src/l10n/l10n.dart`.
///
/// This layout renders no navigation buttons of its own. A single Back/Next
/// row for the whole stepper is owned by the parent [LayrzStepper] widget and
/// sits below this layout, unchanged in role from the wide layout — per-step
/// buttons here would make each row read as an independent panel, which is
/// exactly the "it's not an accordion" distinction the brief draws.
class LayrzStepperCompactLayout extends StatelessWidget {
  /// Creates a [LayrzStepperCompactLayout].
  const LayrzStepperCompactLayout({
    required this.steps,
    required this.currentIndex,
    required this.onStepTap,
    super.key,
  });

  /// The full ordered list of steps to render, top to bottom.
  final List<LayrzStep> steps;

  /// The zero-based index of the currently active step.
  ///
  /// This is the single source of truth for which step's body is expanded.
  /// There is no independent open/closed state anywhere in this widget.
  final int currentIndex;

  /// Called with a step's zero-based index when its header is tapped.
  ///
  /// Only invoked for tappable steps — [LayrzStepperState.completed] or
  /// [LayrzStepperState.active]. [LayrzStepperState.upcoming] steps are locked
  /// and never invoke this callback, no matter how many times they are tapped.
  final void Function(int index) onStepTap;

  /// Resolves the display state for [step] at [index], given [currentIndex].
  ///
  /// Mirrors the state-resolution rule used by the wide layout and the parent
  /// [LayrzStepper]: the active index always wins as
  /// [LayrzStepperState.active]; an explicit [LayrzStep.state] override is
  /// respected otherwise; steps before [currentIndex] default to
  /// [LayrzStepperState.completed] and steps after default to
  /// [LayrzStepperState.upcoming].
  LayrzStepperState _resolveState(LayrzStep step, int index) {
    if (index == currentIndex) {
      return LayrzStepperState.active;
    }
    if (step.state != null) {
      return step.state!;
    }
    if (index < currentIndex) {
      return LayrzStepperState.completed;
    }
    return LayrzStepperState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final stepCount = steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Persistent counter — additive to the stack below, never a replacement.
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.sp3,
            vertical: tokens.spacing.sp2,
          ),
          child: Semantics(
            label: l10n.steppersStepCounterLabel(currentIndex + 1, stepCount),
            // The wrapper's label above is built from the exact same call as
            // the descendant `Text` below, so without this flag the merged
            // announcement would repeat the counter text twice.
            excludeSemantics: true,
            child: Text(
              l10n.steppersStepCounterLabel(currentIndex + 1, stepCount),
              style: tokens.typography.label,
            ),
          ),
        ),
        for (int i = 0; i < stepCount; i++)
          _CompactStepRow(
            step: steps[i],
            index: i,
            stepCount: stepCount,
            positionLabel: l10n.steppersStepCounterLabel(i + 1, stepCount),
            state: _resolveState(steps[i], i),
            isOpen: i == currentIndex,
            onTap: onStepTap,
          ),
      ],
    );
  }
}

/// A single header-plus-body row within [LayrzStepperCompactLayout].
///
/// Renders the step's [LayrzStepIndicator], its label, a trailing affordance
/// glyph, and — only while [isOpen] — the step's body inline beneath the
/// header, animated in and out with [AnimatedSize].
class _CompactStepRow extends StatelessWidget {
  /// Creates a [_CompactStepRow].
  const _CompactStepRow({
    required this.step,
    required this.index,
    required this.stepCount,
    required this.state,
    required this.isOpen,
    required this.onTap,
    required this.positionLabel,
  });

  /// The step data this row renders.
  final LayrzStep step;

  /// This row's zero-based position within the stepper.
  final int index;

  /// The total number of steps in the stepper, used to build the semantics label.
  final int stepCount;

  /// The localized "Step N of M" position phrase for this row, reused from the
  /// persistent counter's own localization so the position portion of this
  /// row's semantics label is never a second, un-localized copy of that string.
  final String positionLabel;

  /// The resolved display state for this row.
  final LayrzStepperState state;

  /// Whether this row is the currently active (open) step.
  ///
  /// Exactly one row across the whole stack has this set to true, since it is
  /// derived directly from `index == currentIndex` in the parent.
  final bool isOpen;

  /// Called with [index] when this row's header is tapped, if tappable.
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    // Completed, active, and error steps are all tappable — completed to
    // jump back for review, active because it is already open, and error so
    // the step that failed can be jumped to for correction, per
    // LayrzStepperState.error's own contract. Only upcoming steps stay
    // locked.
    final isTappable =
        state == LayrzStepperState.completed || state == LayrzStepperState.active || state == LayrzStepperState.error;
    final isUpcoming = state == LayrzStepperState.upcoming;

    // steppersStateLabel already includes "locked" for the upcoming case, so
    // both layouts announce the same state identically — a screen-reader
    // user resizing a window must not hear a step's status change when
    // nothing about the step did.
    final stateLabel = l10n.steppersStateLabel(state);

    // Tappable rows get a disclosure glyph; locked rows get a distinct lock
    // glyph instead, and never both. A locked row that looks identical to a
    // tappable one and does nothing on tap is indistinguishable from a frozen
    // app — this is the non-colour cue that closes that gap, since the
    // desktop-only deferred-cursor cue does not exist on touch. See
    // _CompactStepHeader.trailingIcon for the concrete icon constants.
    final trailingIcon = isUpcoming ? MdiIcons.lockOutline : MdiIcons.chevronDown;

    final header = _CompactStepHeader(
      step: step,
      index: index,
      state: state,
      isTappable: isTappable,
      trailingIcon: trailingIcon,
      onTap: isTappable ? () => onTap(index) : null,
    );

    return Semantics(
      button: isTappable,
      label: '$positionLabel, ${step.labelText}. $stateLabel.',
      enabled: isTappable,
      // The real GestureDetector lives inside `_CompactStepHeader`, wrapped in
      // `ExcludeSemantics` so it does not contribute a second, competing node
      // (see the comment on that `ExcludeSemantics` below). Excluding it also
      // strips its tap action from the tree entirely, so the action is
      // re-declared explicitly here — on the one node a screen reader actually
      // sees — gated to tappable rows exactly like `enabled` and `button`.
      onTap: isTappable ? () => onTap(index) : null,
      // `expanded` is deliberately null (not false) for a locked row.
      // SemanticsProperties.expanded means "this subtree represents
      // something that CAN be expanded/collapsed" when non-null; a locked
      // row cannot ever be expanded by the user, so announcing `false` would
      // wrongly imply it is a closed-but-openable disclosure, contradicting
      // the `enabled: false` on this same node. Only tappable rows (which
      // genuinely toggle which one is open) carry a boolean here.
      expanded: isTappable ? isOpen : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          AnimatedSize(
            duration: tokens.motion.dTransition,
            curve: tokens.motion.easing,
            alignment: Alignment.topCenter,
            // ExcludeFocus keeps a collapsed step's content out of the tab
            // order — required for narrow desktop windows, where isCompact is
            // width-based and a mouse-and-keyboard user can otherwise still
            // tab into a body that is visually hidden. ExcludeSemantics keeps
            // it out of the screen-reader tree for the same reason.
            child: ExcludeFocus(
              excluding: !isOpen,
              child: ExcludeSemantics(
                excluding: !isOpen,
                child: isOpen
                    ? Padding(
                        padding: EdgeInsets.only(
                          left: tokens.spacing.sp3,
                          right: tokens.spacing.sp3,
                          bottom: tokens.spacing.sp3,
                        ),
                        child: step.body,
                      )
                    // A collapsed step contributes zero-height content.
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The tappable (or locked) header row for a single step in the compact layout.
///
/// Renders as a `Row` behind a `MouseRegion` + `GestureDetector` pair. A
/// dedicated [StatefulWidget] is used (rather than the stateless
/// [LayrzTappable]) so the header can vary its background colour on hover
/// without owning press/animation state it does not need — see
/// [_CompactStepHeaderState] for the hover handling required for narrow
/// desktop windows, where `context.isCompact` is width-based and a
/// mouse-and-keyboard user needs a visible cue that the row is clickable.
class _CompactStepHeader extends StatefulWidget {
  /// Creates a [_CompactStepHeader].
  const _CompactStepHeader({
    required this.step,
    required this.index,
    required this.state,
    required this.isTappable,
    required this.trailingIcon,
    required this.onTap,
  });

  /// The step data this header renders the label and indicator for.
  final LayrzStep step;

  /// This header's zero-based position within the stepper.
  final int index;

  /// The resolved display state for this header, forwarded to
  /// [LayrzStepIndicator].
  final LayrzStepperState state;

  /// Whether this header responds to taps and hover.
  ///
  /// False for [LayrzStepperState.upcoming] rows, which stay locked.
  final bool isTappable;

  /// The trailing glyph for this header — a disclosure chevron when tappable,
  /// or a distinct lock glyph when locked. Resolved once by the parent
  /// [_CompactStepRow], which owns the single source of truth for which icon
  /// maps to which state.
  final IconData trailingIcon;

  /// Called when the header is tapped. Null when [isTappable] is false, so no
  /// gesture is wired for locked rows at all.
  final VoidCallback? onTap;

  @override
  State<_CompactStepHeader> createState() => _CompactStepHeaderState();
}

class _CompactStepHeaderState extends State<_CompactStepHeader> {
  /// Whether the pointer currently hovers this header.
  ///
  /// Desktop-only signal: a narrow resized desktop window is still
  /// [BuildContext.isCompact] (width-based), so a mouse user needs this
  /// explicit hover cue since [MouseCursor.defer] alone is not visible enough
  /// and does not exist on touch at all.
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final backgroundColor = widget.isTappable && _isHovered ? tokens.colors.sf2 : tokens.colors.sf1;

    final row = Container(
      color: backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sp3,
        vertical: tokens.spacing.sp2,
      ),
      child: Row(
        children: [
          LayrzStepIndicator(
            index: widget.index,
            state: widget.state,
            icon: widget.step.icon,
          ),
          SizedBox(width: tokens.spacing.sp3),
          Expanded(
            child: Text(
              widget.step.labelText,
              style: tokens.typography.body.copyWith(
                color: widget.state == LayrzStepperState.upcoming ? tokens.colors.fg2 : tokens.colors.fg1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: tokens.spacing.sp2),
          Icon(
            widget.trailingIcon,
            size: kLayrzStepIndicatorGlyphSize,
            color: widget.isTappable ? tokens.colors.fg2 : tokens.colors.fg3,
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: widget.isTappable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      // ExcludeSemantics here: the parent `Semantics` in `_CompactStepRow`
      // already carries the full position/state/expanded label for this row,
      // so this GestureDetector must not contribute a second, redundant node.
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: row,
        ),
      ),
    );
  }
}
