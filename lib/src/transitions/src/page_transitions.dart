import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'transition_builder.dart';
import 'transition_type.dart';

/// A namespace of ready-made [LayrzTransitionBuilder] functions for page
/// transitions, usable with both Flutter's imperative [Navigator] (via
/// [PageRouteBuilder.transitionsBuilder]) and go_router (via
/// `CustomTransitionPage.transitionsBuilder`) without adding a dependency on
/// go_router — see [LayrzTransitionBuilder]'s doc comment for why the two
/// call sites accept the same function shape.
///
/// This class is never instantiated; every member is `static`.
///
/// ### Using with `PageRouteBuilder` (imperative [Navigator])
///
/// ```dart
/// Navigator.of(context).push(
///   PageRouteBuilder(
///     pageBuilder: (context, animation, secondaryAnimation) => const DetailPage(),
///     transitionsBuilder: LayrzPageTransitions.slide,
///   ),
/// );
/// ```
///
/// ### Using with go_router's `CustomTransitionPage`
///
/// ```dart
/// GoRoute(
///   path: '/detail',
///   pageBuilder: (context, state) => CustomTransitionPage(
///     key: state.pageKey,
///     child: const DetailPage(),
///     transitionsBuilder: LayrzPageTransitions.scale,
///   ),
/// );
/// ```
///
/// ### Reduced motion
///
/// Every builder in this class checks [MediaQuery.disableAnimationsOf] first
/// and, when it reports `true`, delegates to [none] instead of running its
/// own animation. A user who has asked their platform for reduced motion
/// therefore never sees an animated page transition from this class,
/// regardless of which named builder a caller selected. This check happens
/// once per builder invocation (a route push or pop), not per frame, so it
/// has no meaningful performance cost.
abstract final class LayrzPageTransitions {
  /// Fades the incoming page in while fading the outgoing page out.
  ///
  /// Built on [FadeTransition]. This is the transition this design system
  /// recommends as a page-transition default for callers who have not chosen
  /// one — see [LayrzTransitionType.fade].
  ///
  /// [context] is read once, before returning the built widget, to resolve
  /// [MediaQuery.disableAnimationsOf]; it is not otherwise used. [animation]
  /// drives the incoming page's opacity from `0.0` to `1.0`.
  /// [secondaryAnimation] is unused: a fade needs no coordination with the
  /// route above it, since both pages fading independently already reads as
  /// a single crossfade. [child] is the page content to fade in.
  static Widget fade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return none(context, animation, secondaryAnimation, child);
    }

    return FadeTransition(opacity: animation, child: child);
  }

  /// Slides the incoming page in from the trailing edge (right, in an
  /// left-to-right context) while the outgoing page stays fixed beneath it.
  ///
  /// Built on [SlideTransition]. [context] is read once to resolve
  /// [MediaQuery.disableAnimationsOf] and, when reduced motion is not
  /// requested, to resolve [Directionality] so the slide's start edge
  /// matches the ambient text direction. [animation] drives the incoming
  /// page's horizontal offset from a full-width offscreen position to
  /// `Offset.zero`. [secondaryAnimation] is unused, matching [fade]'s
  /// reasoning — the incoming page's own slide is sufficient to read as a
  /// single transition. [child] is the page content to slide in.
  static Widget slide(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return none(context, animation, secondaryAnimation, child);
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final beginOffset = Offset(isRtl ? -1.0 : 1.0, 0.0);

    final tokens = context.tokens;
    final positionAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: tokens.motion.easingEnter));

    return SlideTransition(position: positionAnimation, child: child);
  }

  /// Scales the incoming page up from a slightly reduced size while fading
  /// it in.
  ///
  /// Built on [ScaleTransition] composed with [FadeTransition]. [context] is
  /// read once to resolve [MediaQuery.disableAnimationsOf] and, when reduced
  /// motion is not requested, to resolve [LayrzTokens.motion] for the curve
  /// applied to the scale. [animation] drives both the scale (from `0.92` to
  /// `1.0`) and the opacity (from `0.0` to `1.0`) of the incoming page.
  /// [secondaryAnimation] is unused, matching [fade]'s reasoning. [child] is
  /// the page content to scale and fade in.
  static Widget scale(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return none(context, animation, secondaryAnimation, child);
    }

    final tokens = context.tokens;
    final curvedAnimation = CurvedAnimation(parent: animation, curve: tokens.motion.easingEnter);
    final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation);

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: scaleAnimation, child: child),
    );
  }

  /// Rotates the incoming page into place while fading it in.
  ///
  /// Built on [RotationTransition] composed with [FadeTransition]. [context]
  /// is read once to resolve [MediaQuery.disableAnimationsOf] and, when
  /// reduced motion is not requested, to resolve [LayrzTokens.motion] for the
  /// curve applied to the rotation. [animation] drives both the rotation
  /// (from a `-0.02` turn to `0.0`, a subtle settle rather than a full spin)
  /// and the opacity (from `0.0` to `1.0`) of the incoming page.
  /// [secondaryAnimation] is unused, matching [fade]'s reasoning. [child] is
  /// the page content to rotate and fade in.
  static Widget rotation(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return none(context, animation, secondaryAnimation, child);
    }

    final tokens = context.tokens;
    final curvedAnimation = CurvedAnimation(parent: animation, curve: tokens.motion.easingEnter);
    final turnsAnimation = Tween<double>(begin: -0.02, end: 0.0).animate(curvedAnimation);

    return FadeTransition(
      opacity: animation,
      child: RotationTransition(turns: turnsAnimation, child: child),
    );
  }

  /// No transition: the incoming page is returned unwrapped and appears
  /// instantly.
  ///
  /// [context], [animation] and [secondaryAnimation] are accepted only to
  /// satisfy the [LayrzTransitionBuilder] signature and are otherwise
  /// unused. [child] is returned as-is. Every other builder in this class
  /// delegates to this one when [MediaQuery.disableAnimationsOf] reports
  /// that the user has requested reduced motion, so this is also the
  /// effective transition for any of them under that condition.
  static Widget none(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  /// Resolves the [LayrzTransitionBuilder] that corresponds to [type].
  ///
  /// Lets a caller hold a [LayrzTransitionType] value — for example, a single
  /// app-wide setting — and resolve the matching builder without a manual
  /// switch statement of their own.
  static LayrzTransitionBuilder resolve(LayrzTransitionType type) {
    switch (type) {
      case LayrzTransitionType.fade:
        return fade;
      case LayrzTransitionType.slide:
        return slide;
      case LayrzTransitionType.scale:
        return scale;
      case LayrzTransitionType.rotation:
        return rotation;
      case LayrzTransitionType.none:
        return none;
    }
  }
}
