---
name: layrz-ui-shortcut
description: Use LayrzShortcut in a layrz_ui Flutter app. Apply when registering an app-wide keyboard shortcut — reach the host installed by LayrzApp via `LayrzShortcut.of(context)`/`.maybeOf(context)`, call `register(keys:, onInvoke:, debugLabel:)` and `deregister(handle)`, or format a shortcut hint with `formatLayrzShortcut`.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Registering an app-wide keyboard shortcut (e.g. Ctrl/Cmd+S for save) that should fire regardless of which widget has focus.
- Displaying a platform-native shortcut hint (`⌘S` on macOS, `Ctrl+S` elsewhere) via `formatLayrzShortcut` — e.g. right-aligned in a `LayrzDropdownEntry`.
- **Do not construct `LayrzShortcut` yourself in application code** — `LayrzApp` installs exactly one automatically. Reach it via `.of(context)`/`.maybeOf(context)`.
- **Do not use** for a shortcut scoped to only-while-a-specific-widget-has-focus (e.g. Enter/Escape inside a dialog or find bar) — that's a local `Focus.onKeyEvent`/`Shortcuts` wrapper (see how `LayrzFindBar` and `LayrzDialog` handle Enter/Escape locally), not this app-wide registry.
- **Do not expect Ctrl↔Cmd remapping.** `layrz_ui` never substitutes one modifier for another — branch on `LayrzPlatform.isMacOS` yourself when registering cross-platform shortcuts.

---

## Minimal usage

```dart
final registry = LayrzShortcut.maybeOf(context);
final handle = registry?.register(
  keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
  onInvoke: _save,
  debugLabel: 'Save document',
);
```

---

## Key behaviors

- **Installed automatically by `LayrzApp`**, the same way `LayrzSnackbarMessenger` is installed — application code never constructs `LayrzShortcut` itself.
- **Register in `didChangeDependencies`, not `initState`.** The `InheritedWidget` `LayrzShortcut.maybeOf` depends on isn't guaranteed available yet during `initState`. Deregister in `dispose`, guarding on a `_registered` flag so it only registers once.
- **Use `maybeOf` (not `.of`) unless a `LayrzApp` ancestor is guaranteed** — `maybeOf` returns `null` with no crash outside a `LayrzShortcut` subtree (bare widget tests, Storybook-style previews); `.of` asserts.
- **`keys` empty is a documented no-op** — `register` still returns a valid handle, but nothing binds to any key combination. This avoids callers having to special-case "no shortcut configured" at the call site.
- **First-registration-wins conflict policy.** Two callers registering the identical key combination never displace each other: in debug mode the second call throws a `FlutterError` naming both `debugLabel`s; in release mode it returns a live-but-inert handle and the first owner's binding stays untouched.
- **`deregister` is idempotent and safe post-unmount** — call it unconditionally from `dispose()` without tracking whether registration actually succeeded.
- **No Ctrl↔Cmd remapping.** Pass different key sets per platform (`LayrzPlatform.isMacOS ? {meta, keyS} : {control, keyS}`) if a shortcut should differ across macOS and Windows/Linux — `formatLayrzShortcut` and `register` both use exactly the keys given, with zero implicit translation.

---

## Common patterns

```dart
// 1. Full register/deregister lifecycle in a StatefulWidget
class _SaveButtonState extends State<SaveButton> {
  LayrzShortcutHandle? _handle;
  bool _registered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registered) return;
    _registered = true;

    final registry = LayrzShortcut.maybeOf(context);
    if (registry == null) return; // No host — shortcut simply doesn't bind.

    _handle = registry.register(
      keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
      onInvoke: widget.onSave,
      debugLabel: 'SaveButton',
    );
  }

  @override
  void dispose() {
    final handle = _handle;
    if (handle != null) {
      LayrzShortcut.maybeOf(context)?.deregister(handle);
    }
    super.dispose();
  }
}

// 2. Platform-specific modifier, no remapping
final saveShortcut = LayrzPlatform.isMacOS
    ? {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS}
    : {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS};

LayrzShortcut.of(context).register(
  keys: saveShortcut,
  onInvoke: _save,
  debugLabel: 'Save document',
);

// 3. Formatting a shortcut hint for display
Text(formatLayrzShortcut({LogicalKeyboardKey.control, LogicalKeyboardKey.keyS}))
// → 'Ctrl+S' on Windows/Linux, '⌘S' on macOS (if the set used `meta` instead)
```

---

## Usage conventions

- Cache the resolved `LayrzShortcutState` at registration time (not re-resolved in `dispose`) if there is any chance the element could already be deactivated by the time `dispose` runs — `dependOnInheritedWidgetOfExactType` asserts on a deactivated widget.
- Keep `debugLabel` populated on every registration — it has zero runtime effect but is what makes a debug-mode collision message actually useful.
- Never hand-roll shortcut-hint formatting — always use `formatLayrzShortcut` so hints stay platform-consistent with what `LayrzDropdownEntry` itself renders.
