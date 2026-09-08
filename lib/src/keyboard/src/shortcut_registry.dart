import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'shortcut_handle.dart';

/// One live registration [LayrzShortcutState] is tracking internally.
///
/// Deliberately private bookkeeping — never exposed to callers, who only ever
/// see the opaque [LayrzShortcutHandle] token. Holds everything
/// [LayrzShortcutState.deregister] needs to unwind a registration: the
/// activator it was filed under (so the ownership map entry can be cleared)
/// and the real [ShortcutRegistryEntry] this registration produced, when it
/// produced one at all.
class _LiveRegistration {
  /// Creates a [_LiveRegistration] for an activator that was actually filed
  /// with the underlying [ShortcutRegistry].
  ///
  /// [activator] is the [LogicalKeySet] this registration is keyed under in
  /// [LayrzShortcutState._ownerByActivator]. [entry] is the real
  /// [ShortcutRegistryEntry] returned by [ShortcutRegistry.addAll] — disposing
  /// it is what actually unbinds the key combination.
  _LiveRegistration.bound({required this.activator, required ShortcutRegistryEntry this.entry});

  /// Creates a [_LiveRegistration] for a handle that never touched the
  /// underlying registry — either because it was registered with an empty
  /// key set (a documented no-op), or because it lost the first-wins conflict
  /// check against an already-live activator.
  ///
  /// [activator] is still recorded (`null` for the empty-key-set case, or the
  /// contested [LogicalKeySet] for a losing duplicate) purely for debug
  /// bookkeeping; [entry] is always `null` here, since there is nothing to
  /// dispose.
  _LiveRegistration.inert({required this.activator}) : entry = null;

  /// The [LogicalKeySet] this registration is filed under, or `null` for an
  /// inert empty-key-set registration that was never filed under any
  /// activator at all.
  final LogicalKeySet? activator;

  /// The real [ShortcutRegistryEntry] this registration owns, or `null` for
  /// an inert registration (empty key set, or lost a first-wins conflict).
  final ShortcutRegistryEntry? entry;
}

/// [InheritedWidget] exposing a [LayrzShortcutState] to descendants by tree
/// ancestry.
///
/// This is the sole mechanism behind [LayrzShortcut.of] and
/// [LayrzShortcut.maybeOf] — mirroring [LayrzSnackbarMessenger]'s
/// `_LayrzSnackbarScope` and [LayrzTheme]. There is deliberately no
/// [GlobalKey]-based path: `layrz_theme`'s global-key-based messenger caused a
/// lot of trouble in practice, so every ancestry-resolved host in `layrz_ui`
/// — this one included — is ancestry-only.
class _LayrzShortcutScope extends InheritedWidget {
  /// The state instance this scope exposes to descendants.
  final LayrzShortcutState state;

  /// Creates a [_LayrzShortcutScope] wrapping [child] and exposing [state].
  const _LayrzShortcutScope({required this.state, required super.child});

  /// Never triggers a rebuild on its own — [state] is a stable [State]
  /// identity for the lifetime of the registry, and registration bookkeeping
  /// does not drive this widget's own build; callers who need to react to
  /// registration changes do so through their own state, not this scope's.
  @override
  bool updateShouldNotify(_LayrzShortcutScope oldWidget) => false;
}

/// App-wide keyboard-shortcut registry.
///
/// [LayrzShortcut] is a thin, ancestry-resolved wrapper around Flutter's
/// existing [ShortcutRegistry] — it does not roll its own key-dispatch
/// mechanism and does not install a second [ShortcutRegistrar]. [WidgetsApp]
/// (which [LayrzApp] is built on) already installs exactly one
/// [ShortcutRegistrar] at its root, so [ShortcutRegistry.of] resolves from any
/// descendant context. [LayrzShortcut] resolves that same registry once and
/// layers three things on top of it that plain [ShortcutRegistry] callers
/// would otherwise have to write by hand every time:
///
/// * an opaque, dispose-style API ([register]/[deregister]) keyed on
///   [LayrzShortcutHandle] instead of a caller-managed
///   [ShortcutRegistryEntry],
/// * a debug-time collision assertion that names both competing
///   `debugLabel`s (see the "Conflict policy" section below), and
/// * a documented, non-crashing behaviour for an empty key set.
///
/// **Installation is automatic.** [LayrzApp] installs exactly one
/// [LayrzShortcut] in its subtree, the same way it installs
/// [LayrzSnackbarMessenger]. Application code never constructs one itself —
/// reach the host from any descendant via:
/// ```dart
/// final handle = LayrzShortcut.of(context).register(
///   keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
///   onInvoke: _save,
///   debugLabel: 'Save document',
/// );
/// // later, typically in dispose():
/// LayrzShortcut.of(context).deregister(handle);
/// ```
/// `.of(context)`/`.maybeOf(context)` resolve by **tree ancestry only** — an
/// [InheritedWidget] this widget exposes from its `build` — mirroring
/// [LayrzSnackbarMessenger.of]. There is no [GlobalKey] anywhere in this
/// class.
///
/// **Conflict policy.** Two callers registering the exact same activator (the
/// same [LogicalKeySet]) is treated as first-wins, never last-wins:
/// tearing a live binding out from under its current owner just because a
/// second caller happened to register later would be a surprising, silent
/// behaviour change for the first owner. Concretely:
/// * In debug mode, a duplicate registration throws a [FlutterError] naming
///   both the existing and the new registration's `debugLabel`s, so the
///   collision surfaces immediately during development.
/// * In release mode, the real [ShortcutRegistry.addAll] call is skipped for
///   the duplicate, and [register] still returns a live handle — it is simply
///   *inert*: [deregister] on it is a safe no-op, and the existing owner's
///   binding is completely untouched.
///
/// Flutter's own [ShortcutRegistry] also asserts internally on duplicate
/// activators; this class's own pre-check exists only to produce a clearer,
/// `debugLabel`-naming message and to control what happens in release mode
/// (first-wins, rather than whatever [ShortcutRegistry] would otherwise do).
///
/// **Scoping.** This is an app-global registry for v1 — there is no nested
/// sub-scope mechanism yet (e.g. a modal dialog temporarily shadowing global
/// shortcuts). Nothing here assumes there is only ever one
/// [LayrzShortcut] in a tree, though: every access goes through
/// [of]/[maybeOf] tree resolution, so a nested scope could be introduced
/// later (a descendant [LayrzShortcut] resolving to itself rather than the
/// outer one) without changing this public API. For now, installing a second
/// [LayrzShortcut] under an existing one is treated the same way a
/// duplicate [LayrzSnackbarMessenger] is: detected, asserted against in
/// debug, and rendered inertly (its [child] passes through, unwrapped) rather
/// than creating a real second scope.
class LayrzShortcut extends StatefulWidget {
  /// The subtree this registry is exposed to via [of]/[maybeOf].
  final Widget child;

  /// Creates a [LayrzShortcut] wrapping [child].
  ///
  /// Application code should not normally construct this directly —
  /// [LayrzApp] installs the one instance an app needs automatically. Widget
  /// tests that exercise [register]/[deregister] in isolation (without a full
  /// [LayrzApp]) may construct one directly, as long as the tree still has a
  /// [ShortcutRegistrar] ancestor (any [WidgetsApp]-based tree has one).
  const LayrzShortcut({super.key, required this.child});

  /// Returns the [LayrzShortcutState] from the nearest ancestor
  /// [LayrzShortcut].
  ///
  /// [context] is the [BuildContext] to search upward from. Throws (via
  /// [assert]) if no ancestor is found — use [maybeOf] when the ancestor's
  /// presence is not guaranteed. In application code this should always
  /// succeed, since [LayrzApp] installs the host automatically.
  static LayrzShortcutState of(BuildContext context) {
    final state = maybeOf(context);
    assert(
      state != null,
      'LayrzShortcut.of() called with a context that does not contain a '
      'LayrzShortcut ancestor. This should not happen in application code — '
      'LayrzApp installs the shortcut registry host automatically. In a widget '
      'test, wrap the tree under test with a LayrzShortcut (with a ShortcutRegistrar '
      'ancestor, e.g. inside a WidgetsApp/LayrzApp).',
    );
    return state!;
  }

  /// Returns the [LayrzShortcutState] from the nearest ancestor
  /// [LayrzShortcut], or `null` if there is none.
  ///
  /// [context] is the [BuildContext] to search upward from. Resolution is by
  /// tree ancestry via [_LayrzShortcutScope] — an O(1),
  /// `dependOnInheritedWidgetOfExactType` lookup, mirroring
  /// [LayrzSnackbarMessenger.maybeOf]. There is no [GlobalKey]-based
  /// fallback.
  static LayrzShortcutState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LayrzShortcutScope>()?.state;
  }

  @override
  State<LayrzShortcut> createState() => LayrzShortcutState();
}

/// The [State] backing [LayrzShortcut].
///
/// Exposes [register] and [deregister] as the imperative entry points
/// callers use via [LayrzShortcut.of]/[LayrzShortcut.maybeOf]. Internally,
/// this wraps the [ShortcutRegistry] resolved from the ambient
/// [ShortcutRegistrar] that [WidgetsApp] (and therefore [LayrzApp]) already
/// installs — see the class-level doc on [LayrzShortcut] for the full
/// behavioural contract, including the conflict policy.
class LayrzShortcutState extends State<LayrzShortcut> {
  /// Every live registration this state currently owns, keyed by the opaque
  /// handle returned from [register].
  ///
  /// Cleared entries are removed outright by [deregister] rather than left
  /// behind with a disposed marker, so the map's size always reflects the
  /// number of currently-active registrations (inert ones included).
  final Map<LayrzShortcutHandle, _LiveRegistration> _registrations = <LayrzShortcutHandle, _LiveRegistration>{};

  /// The current owning handle for each live [LogicalKeySet] activator.
  ///
  /// This is the pre-check [register] consults before ever calling
  /// [ShortcutRegistry.addAll] — it is what makes the conflict policy
  /// first-wins: an activator already present here is never displaced by a
  /// later [register] call for the same keys, only reported (debug) or
  /// quietly skipped in favour of an inert handle (release).
  final Map<LogicalKeySet, LayrzShortcutHandle> _ownerByActivator = <LogicalKeySet, LayrzShortcutHandle>{};

  /// For debug messaging only: the `debugLabel` each live handle was
  /// registered with, so a collision's [FlutterError] can name both the
  /// existing and the incoming registration.
  final Map<LayrzShortcutHandle, String?> _debugLabelByHandle = <LayrzShortcutHandle, String?>{};

  /// Registers [keys] to invoke [onInvoke] when pressed, and returns a
  /// [LayrzShortcutHandle] the caller must eventually pass to [deregister].
  ///
  /// [keys] is the set of [LogicalKeyboardKey]s that must all be held at once
  /// to trigger [onInvoke] (typically one or more modifiers plus a single
  /// non-modifier key, e.g. `{LogicalKeyboardKey.control,
  /// LogicalKeyboardKey.keyS}`). **An empty set is a documented no-op**: the
  /// call still returns a valid handle (safe to hold and later pass to
  /// [deregister]), but nothing is ever bound to any key combination — this
  /// avoids callers having to special-case "no shortcut configured" call
  /// sites themselves.
  ///
  /// [onInvoke] is called with no arguments whenever the key combination is
  /// pressed while this registration is live; it is wrapped internally in a
  /// [VoidCallbackIntent] bound through [ShortcutRegistry.addAll] to
  /// [VoidCallbackAction] — the [Action] [WidgetsApp] installs by default for
  /// that intent type — so no extra `actions` wiring is required by callers.
  ///
  /// [debugLabel] is an optional human-readable name used only in debug-mode
  /// collision messages (see the "Conflict policy" section of the
  /// [LayrzShortcut] class doc) — it has no effect on runtime behaviour and
  /// is not shown to end users anywhere.
  ///
  /// If [keys] is already bound by another live registration from this same
  /// [LayrzShortcutState], this call follows the documented first-wins
  /// conflict policy: it throws a [FlutterError] in debug mode (naming both
  /// [debugLabel]s), and in release mode returns a live-but-inert handle
  /// instead of displacing the existing binding.
  LayrzShortcutHandle register({
    required Set<LogicalKeyboardKey> keys,
    required VoidCallback onInvoke,
    String? debugLabel,
  }) {
    final handle = LayrzShortcutHandle();

    if (keys.isEmpty) {
      _registrations[handle] = _LiveRegistration.inert(activator: null);
      _debugLabelByHandle[handle] = debugLabel;
      return handle;
    }

    final activator = LogicalKeySet.fromSet(keys);
    final existingOwner = _ownerByActivator[activator];

    if (existingOwner != null) {
      final existingLabel = _debugLabelByHandle[existingOwner];
      assert(
        false,
        'LayrzShortcut.register() was called with an activator that is already '
        'registered by another caller. The existing registration was labelled '
        '"${existingLabel ?? '<no debugLabel>'}"; the new (rejected) registration was '
        'labelled "${debugLabel ?? '<no debugLabel>'}". Two live registrations for the '
        'same key combination are not allowed — deregister the existing one first, or '
        'choose a different key combination. In release builds the existing registration '
        'wins and this call returns an inert handle instead of throwing.',
      );
      _registrations[handle] = _LiveRegistration.inert(activator: activator);
      _debugLabelByHandle[handle] = debugLabel;
      return handle;
    }

    final registry = ShortcutRegistry.of(context);
    final entry = registry.addAll({activator: VoidCallbackIntent(onInvoke)});

    _ownerByActivator[activator] = handle;
    _registrations[handle] = _LiveRegistration.bound(activator: activator, entry: entry);
    _debugLabelByHandle[handle] = debugLabel;
    return handle;
  }

  /// Releases the registration identified by [handle].
  ///
  /// Idempotent and safe to call more than once for the same [handle], and
  /// safe to call after this widget has unmounted — an unknown or
  /// already-removed handle is a silent no-op, never a throw. This mirrors
  /// how [ShortcutRegistryEntry.dispose] itself behaves, and lets callers
  /// deregister unconditionally from a `dispose()` without tracking whether
  /// they already did so.
  void deregister(LayrzShortcutHandle handle) {
    final registration = _registrations.remove(handle);
    if (registration == null) return;

    _debugLabelByHandle.remove(handle);

    final activator = registration.activator;
    if (activator != null && _ownerByActivator[activator] == handle) {
      _ownerByActivator.remove(activator);
    }

    registration.entry?.dispose();
  }

  @override
  void dispose() {
    for (final registration in _registrations.values) {
      registration.entry?.dispose();
    }
    _registrations.clear();
    _ownerByActivator.clear();
    _debugLabelByHandle.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancestor = context.dependOnInheritedWidgetOfExactType<_LayrzShortcutScope>();
    if (ancestor != null) {
      assert(
        false,
        'A LayrzShortcut was found further up the tree. LayrzApp already installs a '
        'shortcut registry host automatically — remove this LayrzShortcut and use '
        'LayrzShortcut.of(context) to reach the existing one instead.',
      );
      return widget.child;
    }

    return _LayrzShortcutScope(state: this, child: widget.child);
  }
}
