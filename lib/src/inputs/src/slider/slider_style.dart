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

  /// The thumb's elevation level, from 0 (flush, no shadow) to 5, fed to
  /// `LayrzShadowTokens.elevation()` to produce the thumb's drop shadow.
  ///
  /// Per D15, this is a colour/shadow-tier concern, not a geometry one — the
  /// thumb's painted size and corner radius never change with state, only how
  /// strongly it appears to lift off the track.
  final double thumbElevation;

  /// Creates a resolved colour set for one paint frame of a [LayrzSlider].
  const LayrzSliderColors({
    required this.trackColor,
    required this.activeTrackColor,
    required this.thumbColor,
    required this.thumbBorderColor,
    required this.thumbElevation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSliderColors &&
          runtimeType == other.runtimeType &&
          trackColor == other.trackColor &&
          activeTrackColor == other.activeTrackColor &&
          thumbColor == other.thumbColor &&
          thumbBorderColor == other.thumbBorderColor &&
          thumbElevation == other.thumbElevation;

  @override
  int get hashCode => Object.hash(trackColor, activeTrackColor, thumbColor, thumbBorderColor, thumbElevation);
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
/// module. Per decision D15, only colour and the [LayrzSliderColors.thumbElevation]
/// tier vary here — no geometry value is read or returned by this function.
///
/// Elevation follows the same precedence as colour: a **disabled** thumb sits
/// flush with no shadow (0); an **error** thumb rests at the base elevation
/// (1), matching default, since an error is a colour concern, not a lift
/// concern; a **pressed/dragging** or **hovered/focus-visible** thumb lifts
/// one level higher (2) than resting (1), giving the "elevated" affordance a
/// slightly stronger shadow while the pointer is actively engaging it.
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
      thumbElevation: 0,
    );
  }

  if (hasErrors) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.danger,
      thumbColor: tokens.colors.danger,
      thumbBorderColor: tokens.colors.sf1,
      thumbElevation: 1,
    );
  }

  if (states.contains(WidgetState.pressed) || isDragging) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.primary.shade600,
      thumbColor: tokens.colors.primary.shade600,
      thumbBorderColor: tokens.colors.sf1,
      thumbElevation: 2,
    );
  }

  if (states.contains(WidgetState.hovered) || isFocusVisible) {
    return LayrzSliderColors(
      trackColor: tokens.colors.sf3,
      activeTrackColor: tokens.colors.primary,
      thumbColor: tokens.colors.primary,
      thumbBorderColor: isFocusVisible ? tokens.colors.primary.shade700 : tokens.colors.sf1,
      thumbElevation: 2,
    );
  }

  return LayrzSliderColors(
    trackColor: tokens.colors.sf3,
    activeTrackColor: tokens.colors.primary,
    thumbColor: tokens.colors.primary,
    thumbBorderColor: tokens.colors.sf1,
    thumbElevation: 1,
  );
}
