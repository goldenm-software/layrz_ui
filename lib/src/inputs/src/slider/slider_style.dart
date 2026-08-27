import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// The four colours [LayrzSliderPainter] needs to paint one frame of the
/// track and thumb, already resolved for the current interaction state.
///
/// A plain data holder returned by [resolveLayrzSliderColors] — kept
/// deliberately free of any widget or `BuildContext` dependency so the state
/// precedence itself can be unit-tested the same way
/// `resolveLayrzLayoutPresentation` is: by calling a function and asserting
/// on its return value, with no tree to pump.
@immutable
class LayrzSliderColors {
  /// The colour of the unfilled portion of the track.
  final Color trackColor;

  /// The colour of the filled (active) portion of the track.
  final Color activeTrackColor;

  /// The fill colour of the thumb glyph.
  final Color thumbColor;

  /// The colour of the thumb's border ring.
  final Color thumbBorderColor;

  /// Creates a resolved colour set for one paint frame of a [LayrzSlider].
  const LayrzSliderColors({
    required this.trackColor,
    required this.activeTrackColor,
    required this.thumbColor,
    required this.thumbBorderColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSliderColors &&
          runtimeType == other.runtimeType &&
          trackColor == other.trackColor &&
          activeTrackColor == other.activeTrackColor &&
          thumbColor == other.thumbColor &&
          thumbBorderColor == other.thumbBorderColor;

  @override
  int get hashCode => Object.hash(trackColor, activeTrackColor, thumbColor, thumbBorderColor);
}

/// Resolves the track and thumb colours for a [LayrzSlider] frame from its
/// current interaction state, following the precedence documented on
/// `LayrzCheckboxInput`/`LayrzSwitchInput`: **disabled > error > pressed
/// (including an active drag) > hover/focused > default**.
///
/// [states] is the widget's live `Set<WidgetState>` (hovered/pressed/focused
/// as currently active); [isDisabled] and [hasErrors] short-circuit to their
/// own fixed palettes ahead of any interaction state; [isDragging] folds into
/// the same visual tier as [WidgetState.pressed] because a drag that has
/// moved the pointer off the thumb's paint bounds but stayed within the
/// larger hit-slop region must keep showing pressed feedback; [isFocusVisible]
/// distinguishes keyboard focus (shown) from pointer-acquired focus (not
/// shown), matching the `_focusFromPointer` convention used elsewhere in this
/// module. Per decision D15, only colour varies here — no geometry value is
/// read or returned by this function.
LayrzSliderColors resolveLayrzSliderColors({
  required LayrzTokens tokens,
  required Set<WidgetState> states,
  required bool isDisabled,
  required bool hasErrors,
  required bool isDragging,
  required bool isFocusVisible,
}) {
  if (isDisabled) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.fg4,
      thumbColor: tokens.colors.fg4,
      thumbBorderColor: tokens.colors.sf1,
    );
  }

  if (hasErrors) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.danger,
      thumbColor: tokens.colors.danger,
      thumbBorderColor: tokens.colors.sf1,
    );
  }

  if (states.contains(WidgetState.pressed) || isDragging) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.primary.shade600,
      thumbColor: tokens.colors.primary.shade600,
      thumbBorderColor: tokens.colors.sf1,
    );
  }

  if (states.contains(WidgetState.hovered) || isFocusVisible) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.primary,
      thumbColor: tokens.colors.primary,
      thumbBorderColor: isFocusVisible ? tokens.colors.primary.shade700 : tokens.colors.sf1,
    );
  }

  return LayrzSliderColors(
    trackColor: tokens.colors.sf3,
    activeTrackColor: tokens.colors.primary,
    thumbColor: tokens.colors.primary,
    thumbBorderColor: tokens.colors.sf1,
  );
}
