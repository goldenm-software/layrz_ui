# LayrzShortcut — API Reference

Source: `lib/src/keyboard/src/shortcut_registry.dart`, `lib/src/keyboard/src/shortcut_handle.dart`, `lib/src/keyboard/src/shortcut_format.dart`
- `LayrzShortcut` class (`StatefulWidget`)
- `LayrzShortcutState` class
- `LayrzShortcutHandle` class (`final`)
- `formatLayrzShortcut` top-level function

---

## Examples

```dart
// Register/deregister lifecycle
final registry = LayrzShortcut.maybeOf(context);
final handle = registry?.register(
  keys: {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS},
  onInvoke: _save,
  debugLabel: 'Save document',
);
// later, typically in dispose():
if (handle != null) registry?.deregister(handle);

// Platform-specific modifiers, no automatic remapping
final saveShortcut = LayrzPlatform.isMacOS
    ? {LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS}
    : {LogicalKeyboardKey.control, LogicalKeyboardKey.keyS};

LayrzShortcut.of(context).register(
  keys: saveShortcut,
  onInvoke: _save,
  debugLabel: 'Save document',
);

// Display formatting
formatLayrzShortcut({LogicalKeyboardKey.control, LogicalKeyboardKey.keyS});
// → 'Ctrl+S' (Windows/Linux) — pass `platform:` explicitly for cross-platform generation/tests
```

---

## `LayrzShortcut`

```dart
class LayrzShortcut extends StatefulWidget {
  const LayrzShortcut({super.key, required this.child});

  final Widget child;

  static LayrzShortcutState of(BuildContext context);
  static LayrzShortcutState? maybeOf(BuildContext context);
}
```

| Member | Notes |
|---|---|
| `child` | The subtree this registry is exposed to via `of`/`maybeOf`. |
| `of(context)` | Throws (via `assert`) if no ancestor `LayrzShortcut` is found. |
| `maybeOf(context)` | Returns `null` if there is no ancestor — an O(1) `dependOnInheritedWidgetOfExactType` lookup, no `GlobalKey` fallback. |

Application code should not normally construct this — `LayrzApp` installs the one instance an app needs. A widget test exercising `register`/`deregister` in isolation may construct one directly, as long as the tree has a `ShortcutRegistrar` ancestor (any `WidgetsApp`-based tree has one).

---

## `LayrzShortcutState`

```dart
class LayrzShortcutState extends State<LayrzShortcut> {
  LayrzShortcutHandle register({
    required Set<LogicalKeyboardKey> keys,
    required VoidCallback onInvoke,
    String? debugLabel,
  });

  void deregister(LayrzShortcutHandle handle);
}
```

| Member | Signature | Notes |
|---|---|---|
| `register` | `LayrzShortcutHandle register({required Set<LogicalKeyboardKey> keys, required VoidCallback onInvoke, String? debugLabel})` | `keys` — all must be held together (e.g. `{control, keyS}`). Empty `keys` is a documented no-op: a valid handle is returned but nothing binds. `onInvoke` fires with no arguments on the chord. `debugLabel` is debug-only collision messaging, never shown to end users. Follows first-wins conflict policy on a duplicate activator. |
| `deregister` | `void deregister(LayrzShortcutHandle handle)` | Idempotent; safe post-unmount; unknown/already-removed handle is a silent no-op. |

---

## `LayrzShortcutHandle`

```dart
final class LayrzShortcutHandle {
  const LayrzShortcutHandle();
}
```

Opaque capability token — carries no public state. Equality/hashing are the default identity-based implementation (two handles equal only if the same instance). Never constructed by application code directly; only received from `register` and passed to `deregister`.

---

## `formatLayrzShortcut`

```dart
String formatLayrzShortcut(
  Set<LogicalKeyboardKey>? keys, {
  LayrzPlatform? platform,
});
```

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `keys` | `Set<LogicalKeyboardKey>?` | — | The shortcut to format. `null`/empty/only-unrecognized-non-modifier-keys → returns `''`. |
| `platform` | `LayrzPlatform?` | `LayrzPlatform.current` | Pass explicitly for testing or cross-platform string generation. |

| Key | macOS | Windows/Linux |
|---|---|---|
| `meta` | `⌘` | `Win` |
| `control` | `⌃` | `Ctrl` |
| `alt` | `⌥` | `Alt` |
| `shift` | `⇧` | `Shift` |
| other | `keyLabel` (uppercase) | same |

- **Canonical ordering**: macOS uses `⌃⌥⇧⌘` + key, concatenated with no separator (e.g. `⇧⌘S`); Windows/Linux uses `Ctrl`, `Alt`, `Shift`, `Win`, then the key, joined with `+` (e.g. `Shift+Ctrl+S`).
- **Left/right variants** (`controlLeft`, `shiftRight`, etc.) are normalized to their base modifier.
- **No Ctrl↔Cmd remapping.** This function renders exactly the `keys` it is given — it never converts `control` to `meta` or vice versa. The caller decides which modifiers to pass, typically branching on `LayrzPlatform.isMacOS`.

---

## Conflict policy

Two callers registering the identical `LogicalKeySet` is **first-wins, never last-wins**:

| Build mode | Behavior on duplicate |
|---|---|
| Debug | Throws a `FlutterError` naming both the existing and the new registration's `debugLabel`s. |
| Release | The real `ShortcutRegistry.addAll` call is skipped; `register` still returns a live handle, but it's inert — `deregister` on it is a safe no-op, and the existing owner's binding is untouched. |

---

## Behavior notes

- **Thin wrapper, not a new dispatch mechanism.** `LayrzShortcut` resolves the existing `ShortcutRegistry`/`ShortcutRegistrar` that `WidgetsApp` (and therefore `LayrzApp`) already installs at its root — it does not install a second registrar.
- **Ancestry-resolved, no `GlobalKey`.** `.of`/`.maybeOf` resolve through a private `InheritedWidget` (`_LayrzShortcutScope`), mirroring `LayrzTheme` and `LayrzSnackbarMessenger`.
- **App-global for v1.** No nested sub-scope mechanism (e.g. a modal temporarily shadowing global shortcuts). A second `LayrzShortcut` installed under an existing one is detected, asserted against in debug, and rendered inertly (its `child` passes through unwrapped).
- **`onInvoke` wiring.** Internally wrapped in a `VoidCallbackIntent` bound through `ShortcutRegistry.addAll` to `VoidCallbackAction` — the `Action` `WidgetsApp` installs by default for that intent type, so no extra `actions` wiring is required by callers.

---

## Related: `LayrzDropdownMenu` auto-binding

`LayrzDropdownEntry.shortcut` (a `Set<LogicalKeyboardKey>?`) is functional, not just a display hint — `LayrzDropdownMenu` auto-registers every enabled entry's non-empty `shortcut` to its `onTap` via the ambient `LayrzShortcut` registry, for as long as the menu widget is mounted. The shortcut fires without the menu panel ever being opened. Resolution uses `LayrzShortcut.maybeOf`, so the menu still displays its shortcut hint text (via `formatLayrzShortcut`) even outside a `LayrzApp` subtree, just without binding the key.
