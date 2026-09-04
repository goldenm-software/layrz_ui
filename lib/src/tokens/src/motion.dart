import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';

/// Immutable motion tokens for animation durations and easing curves in the design system.
///
/// Motion tokens define consistent timing and easing for all animations, from
/// quick hover effects to page transitions.
@immutable
class LayrzMotionTokens {
  /// Duration for hover and micro-interaction animations.
  ///
  /// Must equal [kHoverDuration] (100 milliseconds) to maintain consistency with
  /// the existing animation constant.
  final Duration dHover;

  /// Duration for press/tap animations.
  ///
  /// Defaults to 80 milliseconds, faster than hover for snappier feedback.
  final Duration dPress;

  /// Duration for standard transition animations.
  ///
  /// Defaults to 200 milliseconds, used for state changes and component transitions.
  final Duration dTransition;

  /// Duration for page transition animations.
  ///
  /// Must equal [kPageTransitionDuration] (250 milliseconds) to maintain consistency
  /// with the existing page transition constant.
  final Duration dPageTransition;

  /// Duration for dialog entrance and exit animations.
  ///
  /// Defaults to 300 milliseconds, giving dialogs a more prominent entrance.
  final Duration dDialog;

  /// Duration for a single indeterminate sweep cycle in looping progress
  /// indicators (e.g. `LayrzProgressBar`'s indeterminate mode).
  ///
  /// Must equal [kIndeterminateDuration] (1500 milliseconds) to maintain
  /// consistency with the existing indeterminate duration constant, and to
  /// match `LayrzButtonIndicator`'s hardcoded indeterminate cycle so the two
  /// loading affordances in the design system read at the same speed. This is
  /// deliberately slower than [dDialog]: a repeating sweep at dialog speed
  /// (300ms) completes over three cycles per second, which reads as frantic
  /// rather than as a calm, ongoing operation.
  final Duration dIndeterminate;

  /// Standard easing curve for most animations.
  ///
  /// Defaults to [Curves.easeInOut], which is the most common easing curve
  /// for smooth, natural-feeling animations.
  final Curve easing;

  /// Easing curve for entrance animations.
  ///
  /// Defaults to [Curves.easeOut], which starts fast and decelerates, creating
  /// a snappy entrance effect.
  final Curve easingEnter;

  /// Easing curve for exit animations.
  ///
  /// Defaults to [Curves.easeIn], which starts slow and accelerates, creating
  /// a natural exit effect.
  final Curve easingExit;

  /// Easing curve for emphasized reveal animations.
  ///
  /// Defaults to [Curves.easeInOutCirc], a more pronounced acceleration and
  /// deceleration than [easing]. Used by disclosure components — e.g.
  /// `LayrzAccordion`'s expand/collapse reveal — where the standard [easing]
  /// curve reads as too subtle for a large content-height change. This is a
  /// distinct field from [easing], not a replacement for it: nothing else in
  /// the design system reads this curve by default.
  final Curve easingEmphasized;

  /// Creates a new [LayrzMotionTokens].
  const LayrzMotionTokens({
    this.dHover = kHoverDuration,
    this.dPress = const Duration(milliseconds: 80),
    this.dTransition = const Duration(milliseconds: 200),
    this.dPageTransition = kPageTransitionDuration,
    this.dDialog = const Duration(milliseconds: 300),
    this.dIndeterminate = kIndeterminateDuration,
    this.easing = Curves.easeInOut,
    this.easingEnter = Curves.easeOut,
    this.easingExit = Curves.easeIn,
    this.easingEmphasized = Curves.easeInOutCirc,
  });

  /// Returns a copy of this motion tokens object with the given fields replaced.
  LayrzMotionTokens copyWith({
    Duration? dHover,
    Duration? dPress,
    Duration? dTransition,
    Duration? dPageTransition,
    Duration? dDialog,
    Duration? dIndeterminate,
    Curve? easing,
    Curve? easingEnter,
    Curve? easingExit,
    Curve? easingEmphasized,
  }) {
    return LayrzMotionTokens(
      dHover: dHover ?? this.dHover,
      dPress: dPress ?? this.dPress,
      dTransition: dTransition ?? this.dTransition,
      dPageTransition: dPageTransition ?? this.dPageTransition,
      dDialog: dDialog ?? this.dDialog,
      dIndeterminate: dIndeterminate ?? this.dIndeterminate,
      easing: easing ?? this.easing,
      easingEnter: easingEnter ?? this.easingEnter,
      easingExit: easingExit ?? this.easingExit,
      easingEmphasized: easingEmphasized ?? this.easingEmphasized,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzMotionTokens &&
          runtimeType == other.runtimeType &&
          dHover == other.dHover &&
          dPress == other.dPress &&
          dTransition == other.dTransition &&
          dPageTransition == other.dPageTransition &&
          dDialog == other.dDialog &&
          dIndeterminate == other.dIndeterminate &&
          easing == other.easing &&
          easingEnter == other.easingEnter &&
          easingExit == other.easingExit &&
          easingEmphasized == other.easingEmphasized;

  @override
  int get hashCode => Object.hash(
    dHover,
    dPress,
    dTransition,
    dPageTransition,
    dDialog,
    dIndeterminate,
    easing,
    easingEnter,
    easingExit,
    easingEmphasized,
  );
}
