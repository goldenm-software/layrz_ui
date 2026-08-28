import 'package:flutter/widgets.dart';

/// The signature shared by [PageRouteBuilder]'s `transitionsBuilder` and
/// go_router's `CustomTransitionPage.transitionsBuilder`.
///
/// Both call sites — Flutter's own imperative [Navigator] and the go_router
/// package used elsewhere in this codebase — declare an identical function
/// shape:
///
/// ```dart
/// Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)
/// ```
///
/// `layrz_ui` does not depend on `go_router` (it is a dependency of
/// `example/` only, never of the published package), so this typedef cannot
/// reference go_router's own `CustomTransitionPage` type directly. Because
/// the shape is structurally identical, a plain function built against this
/// typedef is assignable to either call site with zero adapter code and zero
/// new dependencies — see [LayrzPageTransitions] for the ready-made builders,
/// and its class doc for both call sites worked through in full.
///
/// [context] is the [BuildContext] of the outgoing route, present so a
/// builder can read ambient state such as [MediaQuery.disableAnimationsOf].
/// [animation] drives the incoming route's transition, running from `0.0` to
/// `1.0` as it becomes current. [secondaryAnimation] drives this route's own
/// transition when a route pushed on top of it starts or finishes its
/// transition — most builders in this file only use it for the outgoing
/// route's exit half of a swap. [child] is the page content to wrap; a
/// builder must return a widget that renders it, typically as the innermost
/// child of one or more transition widgets.
typedef LayrzTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);
