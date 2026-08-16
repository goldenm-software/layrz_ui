import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants/constants.dart';

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

  /// Creates a new [LayrzMotionTokens].
  const LayrzMotionTokens({
    this.dHover = kHoverDuration,
    this.dPress = const Duration(milliseconds: 80),
    this.dTransition = const Duration(milliseconds: 200),
    this.dPageTransition = kPageTransitionDuration,
    this.dDialog = const Duration(milliseconds: 300),
    this.easing = Curves.easeInOut,
    this.easingEnter = Curves.easeOut,
    this.easingExit = Curves.easeIn,
  });

  /// Returns a copy of this motion tokens object with the given fields replaced.
  LayrzMotionTokens copyWith({
    Duration? dHover,
    Duration? dPress,
    Duration? dTransition,
    Duration? dPageTransition,
    Duration? dDialog,
    Curve? easing,
    Curve? easingEnter,
    Curve? easingExit,
  }) {
    return LayrzMotionTokens(
      dHover: dHover ?? this.dHover,
      dPress: dPress ?? this.dPress,
      dTransition: dTransition ?? this.dTransition,
      dPageTransition: dPageTransition ?? this.dPageTransition,
      dDialog: dDialog ?? this.dDialog,
      easing: easing ?? this.easing,
      easingEnter: easingEnter ?? this.easingEnter,
      easingExit: easingExit ?? this.easingExit,
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
          easing == other.easing &&
          easingEnter == other.easingEnter &&
          easingExit == other.easingExit;

  @override
  int get hashCode => Object.hash(
    dHover,
    dPress,
    dTransition,
    dPageTransition,
    dDialog,
    easing,
    easingEnter,
    easingExit,
  );
}
