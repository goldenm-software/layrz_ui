import 'package:flutter/widgets.dart';

/// Shared route machinery for every modal surface in the design system.
///
/// [LayrzBottomSheet] and (once built) `LayrzDialog` both need a barrier,
/// reduce-motion handling, a keyboard-inset workaround, and — most
/// importantly — a guard against a double-pop. Rather than let each modal
/// surface reimplement these independently (and risk the guard being
/// forgotten in a new one), they are extracted here so every subclass gets
/// them **by construction**.
///
/// This class changes no behaviour relative to what [LayrzBottomSheet]
/// already did before the extraction: it is the same logic, given one home.
/// Sheet-specific concerns — snap sizes, the drag handle,
/// [DraggableScrollableSheet] — are **not** here; they stay in the sheet's
/// own route subclass, because they are meaningless for a dialog.
///
/// A subclass supplies its own `pageBuilder` and `transitionBuilder` to the
/// [RawDialogRoute] constructor exactly as before, and calls the protected
/// helpers below from inside that `transitionBuilder` closure:
/// - [popIfCurrent] at every dismiss site (barrier tap, Escape, drag-dismiss)
/// - [resolveAnimation] to respect [MediaQuery.disableAnimations]
/// - [keyboardViewInsetsOf] to read the keyboard inset the same
///   cache-safe way the sheet already does
abstract class LayrzModalRoute<T> extends RawDialogRoute<T> {
  /// Creates a [LayrzModalRoute].
  ///
  /// All parameters are forwarded verbatim to [RawDialogRoute]; see its
  /// documentation for their meaning. This constructor exists only to give
  /// the shared base a name distinct from [RawDialogRoute] itself — it adds
  /// no parameters and no behaviour of its own.
  LayrzModalRoute({
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.transitionDuration,
    super.transitionBuilder,
    super.settings,
  });

  /// Pops [context]'s nearest route, but only if it is still the current
  /// (topmost) route.
  ///
  /// This is the fix for a release-only data-loss bug shipped in 0.0.14: a
  /// fast double tap on a modal's barrier could call [Navigator.pop] twice
  /// in quick succession. The first pop starts removing this route; the
  /// second — arriving before that finishes — popped the route **underneath**
  /// it as well, silently dismissing the caller's own page in a release
  /// build. [ModalRoute.of]'s `isCurrent` is the SDK's own purpose-built
  /// answer to "is this route still the one to pop", and every dismiss site
  /// on a [LayrzModalRoute] subclass (barrier tap, Escape key, drag-dismiss)
  /// must call this helper instead of popping directly.
  static void popIfCurrent(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).pop();
    }
  }

  /// Returns [animation] unchanged, or a stopped animation pinned at its end
  /// value if the platform has reduce-motion enabled.
  ///
  /// [context] supplies the [MediaQuery] read; [animation] is the transition
  /// animation a subclass's `transitionBuilder` was itself handed by
  /// [RawDialogRoute]. Respecting `disableAnimations` this way shortens the
  /// transition to nothing rather than skipping it outright, which keeps the
  /// same widget tree shape (no branch needed at the call site) while still
  /// honouring the platform's accessibility preference.
  static Animation<double> resolveAnimation(
    BuildContext context,
    Animation<double> animation,
  ) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return disableAnimations ? const AlwaysStoppedAnimation(1.0) : animation;
  }

  /// Returns the current bottom view inset (typically the on-screen
  /// keyboard's height) as read from [context].
  ///
  /// This must be called from inside the route's `transitionBuilder`
  /// closure, never from a descendant [State]'s own `build`. `ModalRoute`
  /// caches its page widget (`_page`) and hands it to `transitionBuilder` as
  /// `child` rather than rebuilding it — so a state further down the tree
  /// that reads `MediaQuery.viewInsetsOf(context)` directly never sees it
  /// update once the route is open. `transitionBuilder`'s own `context`,
  /// by contrast, is confirmed to update correctly on every inset change.
  /// Callers needing this value in a descendant state must thread it down
  /// explicitly (e.g. via an `InheritedWidget` built around `child`), the
  /// same way [LayrzBottomSheet]'s `_KeyboardVisibility` does.
  static double keyboardViewInsetsOf(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom;
  }
}
