import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/input_style_spec.dart';

/// A single animated digit box rendered inside [LayrzOtpInput]'s slot row.
///
/// [_OtpSlot] is a purely presentational, stateless widget: it paints one character
/// (or an empty box, when [character] is `null` or empty) and animates two things:
///
/// - **Fill color and border color** — via an [AnimatedContainer] driven by
///   [LayrzTokens.motion]'s `dHover` duration and `easing` curve. Only color is animated;
///   border *width* stays fixed at [LayrzBorderTokens.base] in every state, per decision
///   D15 — interaction states must never change geometry (including border width), only
///   appearance.
/// - **The digit's entrance** — via an [AnimatedSwitcher] keyed by [character], so that
///   transitioning from empty to a filled digit (or from one digit to another) triggers a
///   scale+fade "pop" over [LayrzTokens.motion]'s `dTransition` duration and
///   `easingEmphasized` curve.
///
/// The caller ([LayrzOtpInput]) is responsible for computing [isFocused] (true only when
/// this slot's index equals the caret index **and** the hidden field actually has focus)
/// and [hasErrors] (mirrors [LayrzOtpInput.errors]), and for resolving [tokens] and
/// [readOnly]/[disabled] from its own widget configuration. This widget never reads
/// [BuildContext] itself beyond what [AnimatedContainer]/[AnimatedSwitcher] require, so it
/// stays trivially testable and reusable.
class OtpSlot extends StatelessWidget {
  /// The single character this slot displays, or `null`/empty for an empty slot.
  final String? character;

  /// Whether this slot is the one the caret currently sits at.
  ///
  /// Only meaningful — and only ever `true` — when the hidden field backing
  /// [LayrzOtpInput] actually has focus. The caller is responsible for that gating;
  /// this widget only reacts to the boolean it is given.
  final bool isFocused;

  /// Whether [LayrzOtpInput.errors] is non-empty, so every slot paints its danger state
  /// together rather than only the slot nearest the caret.
  final bool hasErrors;

  /// Whether the parent [LayrzOtpInput] is read-only.
  final bool readOnly;

  /// Whether the parent [LayrzOtpInput] is disabled.
  final bool disabled;

  /// The resolved design tokens used for color, spacing, radius, border, and motion.
  final LayrzTokens tokens;

  /// Creates a new [OtpSlot] with the given properties.
  const OtpSlot({
    super.key,
    required this.character,
    required this.isFocused,
    required this.hasErrors,
    required this.readOnly,
    required this.disabled,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{
      if (disabled) WidgetState.disabled,
      if (isFocused) WidgetState.focused,
    };

    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: readOnly,
    );

    final hasCharacter = character != null && character!.isNotEmpty;

    // The shared spec signals focus with a border color change alone (transparent →
    // primary), which reads too weakly on an empty slot for the user to tell which box
    // is selected. A focused, non-error slot additionally gets a subtle primary-tonal
    // fill so selection is unmistakable even before a digit is typed. This changes
    // color only — never geometry — so decision D15 still holds.
    final backgroundColor = isFocused && !hasErrors && !disabled
        ? tokens.colors.primary.withOpacityValue(tokens.colors.tonalOpacity).flattenOn(spec.backgroundColor)
        : spec.backgroundColor;

    return AnimatedContainer(
      duration: tokens.motion.dHover,
      curve: tokens.motion.easing,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: tokens.radius.br2,
        border: Border.all(
          color: spec.borderColor,
          width: tokens.border.base,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: tokens.motion.dTransition,
        switchInCurve: tokens.motion.easingEmphasized,
        switchOutCurve: tokens.motion.easingEmphasized,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          hasCharacter ? character! : '',
          key: ValueKey<String>(hasCharacter ? character! : '_empty'),
          textAlign: TextAlign.center,
          style: tokens.typography.headline.copyWith(
            color: spec.textColor,
            // The digit is the only glyph in a short, centered box. Without a tight
            // line height its font's natural leading is distributed by the line box
            // and pushes the glyph visibly high; height 1.0 with even leading centers
            // the glyph itself on the box, matching the reference.
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}
