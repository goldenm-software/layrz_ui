import 'package:flutter/widgets.dart';

/// Hosts a single, app-wide pointer-position notifier and exposes it to
/// descendants via [LayoCursorScope.maybeOf], so any [Layo] with
/// `followCursor: true` can track the live cursor position anywhere on
/// screen — not merely while the pointer sits directly over that particular
/// [Layo].
///
/// [LayrzApp] installs exactly one [LayoCursorScope] near the root of the
/// widget tree when `enableLayoCursorTracking` is `true` (the opt-in default
/// is `false`, so no app pays for this unless it asks). This widget itself is
/// intentionally dumb: it neither owns a [MouseRegion] nor listens for
/// pointer events — it only *carries* a caller-supplied [ValueNotifier] down
/// the tree as an [InheritedWidget], so the [MouseRegion] that actually
/// writes into that notifier (installed by `LayrzApp`, above this scope) can
/// live and die with the app root's own [State], while every descendant
/// reads the same single notifier instance without triggering a rebuild of
/// anything between the app root and itself.
///
/// **Why this indirection matters:** a [ValueNotifier] read via
/// [InheritedWidget] does not, by itself, cause [InheritedWidget] machinery
/// to rebuild dependents on every pointer move — [maybeOf] returns the
/// notifier object itself (a stable reference that survives every pointer
/// move), not the position it currently holds, and [updateShouldNotify]
/// compares that same stable reference. A [Layo] that wants to react to
/// pointer movement therefore adds its own listener directly to the notifier
/// (see `Layo`'s own `followCursor` wiring) rather than depending on this
/// [InheritedWidget] rebuilding — so a pointer move never rebuilds this scope,
/// anything above it, or any sibling that merely calls [maybeOf] once and
/// stores the reference.
class LayoCursorScope extends InheritedWidget {
  /// Creates a [LayoCursorScope] carrying [notifier] down to [child].
  ///
  /// [notifier] is the single, app-owned [ValueNotifier] a [MouseRegion]
  /// installed above this scope writes into on every hover event; `null`
  /// means "no pointer currently known" (no pointer down, the pointer has
  /// left the app's content area, or the platform reports no mouse at all).
  /// [child] is the subtree that can read [notifier] via [maybeOf].
  const LayoCursorScope({required this.notifier, required super.child, super.key});

  /// The app-wide pointer position, in global (screen) coordinates, or `null`
  /// when no pointer position is currently known.
  ///
  /// Owned by whichever [State] installed this scope (ordinarily
  /// `LayrzApp`'s own private state) — this widget never creates, disposes,
  /// or mutates it itself; it only carries the reference down the tree.
  final ValueNotifier<Offset?> notifier;

  /// Returns the nearest ancestor [LayoCursorScope]'s [notifier], or `null`
  /// if no [LayoCursorScope] is present above [context].
  ///
  /// [context] is the [BuildContext] to search upward from. A `null` result
  /// means the app never opted into cursor tracking (`LayrzApp`'s
  /// `enableLayoCursorTracking` is at its default `false`) — callers must
  /// treat that as "no global tracking available" and degrade silently
  /// rather than throwing, exactly as `Layo.followCursor`'s own safe-fallback
  /// contract requires.
  ///
  /// Deliberately uses [BuildContext.getInheritedWidgetOfExactType] rather
  /// than [BuildContext.dependOnInheritedWidgetOfExactType]: a caller reading
  /// this once (to grab the stable notifier reference and attach its own
  /// listener) must not register a build-time dependency that would rebuild
  /// the calling widget every time this [InheritedWidget] rebuilds above it
  /// — see the class doc comment's "why this indirection matters" section.
  static ValueNotifier<Offset?>? maybeOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LayoCursorScope>();
    return scope?.notifier;
  }

  @override
  bool updateShouldNotify(LayoCursorScope oldWidget) => notifier != oldWidget.notifier;
}
