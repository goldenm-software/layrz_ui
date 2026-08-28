import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'stepper_state.dart';

/// The diameter, in logical pixels, of a [LayrzStepIndicator] circle.
///
/// Shared by both the wide and compact stepper layouts so the indicator band
/// occupies a fixed, predictable height regardless of label length.
const double kLayrzStepIndicatorSize = 40.0;

/// The size, in logical pixels, of the glyph rendered inside a [LayrzStepIndicator].
///
/// Applies to both the state glyphs ([MdiIcons.check], [MdiIcons.alertCircle]) and
/// any caller-supplied [LayrzStepIndicator.icon].
const double kLayrzStepIndicatorGlyphSize = 16.0;

/// The circular indicator rendered for a single step in a [LayrzStepper].
///
/// [LayrzStepIndicator] owns the entire content-resolution rule for what appears
/// inside a step's circle, and is the **only** place that rule may live — it must
/// not be duplicated into any layout file. The rule (WCAG 1.4.1, see
/// `engineering/decisions.md` D57): state is never colour-only, so [completed]
/// and [error] steps always carry a distinct glyph regardless of what identity
/// [icon] the caller supplied:
///
/// | [state] | Circle content | Background |
/// |---|---|---|
/// | [LayrzStepperState.completed] | [MdiIcons.check] — always, overriding [icon] | success |
/// | [LayrzStepperState.error] | [MdiIcons.alertCircle] — always, overriding [icon] | danger |
/// | [LayrzStepperState.active] | [icon] if supplied, else the 1-based [index] | primary |
/// | [LayrzStepperState.upcoming] | [icon] if supplied, else the 1-based [index] | surface |
///
/// This override is fixed and intentionally not caller-configurable: there is no
/// parameter to disable it, because the state glyph communicates the step's
/// *status*, while [icon] communicates the step's *identity* (e.g. a credit-card
/// glyph for a billing step). Losing the status glyph would make [state] readable
/// by colour alone, which fails WCAG 1.4.1.
class LayrzStepIndicator extends StatelessWidget {
  /// Creates a [LayrzStepIndicator].
  const LayrzStepIndicator({
    required this.index,
    required this.state,
    this.icon,
    super.key,
  });

  /// The zero-based position of this step within the stepper.
  ///
  /// Used both to render the 1-based step number when no [icon] is supplied and
  /// (by callers) to build the step's semantics label.
  final int index;

  /// The current state of this step.
  ///
  /// Drives both the background colour and the glyph-override rule described in
  /// the class documentation.
  final LayrzStepperState state;

  /// The caller-supplied identity icon for this step, e.g. a credit-card glyph
  /// for a billing step.
  ///
  /// Rendered only when [state] is [LayrzStepperState.active] or
  /// [LayrzStepperState.upcoming] and is otherwise overridden by the state glyph.
  /// When null, the 1-based [index] is rendered as text instead.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final isCompleted = state == LayrzStepperState.completed;
    final isError = state == LayrzStepperState.error;
    final isActive = state == LayrzStepperState.active;
    final isUpcoming = state == LayrzStepperState.upcoming;

    final Color backgroundColor;
    if (isActive) {
      backgroundColor = tokens.colors.primary;
    } else if (isCompleted) {
      backgroundColor = tokens.colors.success;
    } else if (isError) {
      backgroundColor = tokens.colors.danger;
    } else {
      backgroundColor = tokens.colors.sf3;
    }

    final foregroundColor = isActive || isCompleted || isError ? tokens.colors.sf1 : tokens.colors.fg2;

    final Widget content;
    if (isCompleted) {
      // Completed always shows the checkmark, overriding any caller-supplied icon.
      content = Icon(
        MdiIcons.check,
        color: foregroundColor,
        size: kLayrzStepIndicatorGlyphSize,
      );
    } else if (isError) {
      // Error always shows the alert glyph, overriding any caller-supplied icon.
      content = Icon(
        MdiIcons.alertCircle,
        color: foregroundColor,
        size: kLayrzStepIndicatorGlyphSize,
      );
    } else if (icon != null) {
      content = Icon(
        icon,
        color: foregroundColor,
        size: kLayrzStepIndicatorGlyphSize,
      );
    } else {
      content = Text(
        '${index + 1}',
        style: tokens.typography.label.copyWith(color: foregroundColor),
      );
    }

    return Container(
      width: kLayrzStepIndicatorSize,
      height: kLayrzStepIndicatorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: isUpcoming
            ? Border.all(
                color: tokens.colors.divider,
                width: 1.5,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}
