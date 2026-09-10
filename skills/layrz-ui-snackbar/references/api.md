# LayrzSnackbar — API Reference

Source: `lib/src/snackbar/src/snackbar.dart` (`LayrzSnackbar` payload)
- `lib/src/snackbar/src/snackbar_messenger.dart` — `LayrzSnackbarMessenger` / `LayrzSnackbarMessengerState`
- `lib/src/snackbar/src/snackbar_type.dart` — `LayrzSnackbarType` enum
- `lib/src/snackbar/src/snackbar_style_spec.dart` — `LayrzSnackbarStyleSpec`
- `lib/src/snackbar/src/snackbar_view.dart` — `LayrzSnackbarView` (internal rendering, not constructed by callers)

---

## Examples

```dart
// Default success toast (10s auto-dismiss)
LayrzSnackbarMessenger.of(context).show(
  const LayrzSnackbar(titleText: 'Saved', descriptionText: 'Done.'),
);

// Explicit 5s duration
LayrzSnackbarMessenger.of(context).show(
  const LayrzSnackbar(
    titleText: 'Saved',
    descriptionText: 'Done.',
    duration: Duration(seconds: 5),
  ),
);

// Persistent (no auto-dismiss)
LayrzSnackbarMessenger.of(context).show(
  const LayrzSnackbar(
    titleText: 'Syncing…',
    descriptionText: 'This clears automatically once the sync finishes.',
    duration: null,
  ),
);

// Danger type
LayrzSnackbarMessenger.of(context).show(
  const LayrzSnackbar(
    titleText: 'Failed to delete',
    descriptionText: 'The item could not be removed. Try again.',
    type: LayrzSnackbarType.danger,
  ),
);

// Whole-card onTap (always dismisses after running)
LayrzSnackbarMessenger.of(context).show(
  LayrzSnackbar(
    titleText: 'Item deleted',
    descriptionText: 'Tap to undo this action.',
    type: LayrzSnackbarType.context,
    onTap: () => restoreDeletedItem(),
  ),
);

// Action buttons (each fires independently, does not auto-dismiss)
LayrzSnackbarMessenger.of(context).show(
  LayrzSnackbar(
    titleText: 'Rule triggered',
    descriptionText: 'Speed limit exceeded on Unit 42.',
    type: LayrzSnackbarType.warning,
    actions: [
      LayrzButton(labelText: 'Manage rule', type: LayrzButtonType.warning, onTap: () => openRuleSettings()),
      LayrzButton(labelText: 'Dismiss', style: LayrzButtonStyle.outlined, onTap: () {}),
    ],
  ),
);

// Custom type
LayrzSnackbarMessenger.of(context).show(
  LayrzSnackbar(
    titleText: 'Cross-post to Slack',
    descriptionText: 'Custom color and icon example.',
    type: LayrzSnackbarType.custom,
    icon: MdiIcons.slack,
    color: const Color(0xFF4A154B),
  ),
);

// Dismiss everything
LayrzSnackbarMessenger.of(context).dismissAll();
```

---

## Constructor

### `LayrzSnackbar`

```dart
const LayrzSnackbar({
  required this.titleText,
  required this.descriptionText,
  this.type = LayrzSnackbarType.success,
  this.icon,
  this.color,
  this.duration = const Duration(seconds: 10),
  this.onTap,
  this.actions = const [],
}) : assert(
       (type == LayrzSnackbarType.custom && icon != null && color != null) ||
           (type != LayrzSnackbarType.custom && icon == null && color == null),
       'LayrzSnackbar: when type is LayrzSnackbarType.custom, both icon and color '
       'must be supplied; for every other type, both icon and color must be null.',
     );
```

### `LayrzSnackbarMessenger`

```dart
const LayrzSnackbarMessenger({
  super.key,
  required this.child,
  this.maxWidth = kLayrzSnackbarMaxWidth,       // 440
  this.padding = const EdgeInsets.all(16),
  this.maxVisible = kLayrzSnackbarMaxVisible,   // 3
});
```

**Application code does not construct this widget** — `LayrzApp` installs exactly one automatically. The constructor stays public only so the auto-install guard has something to detect.

---

## Properties

### `LayrzSnackbar`

| Property | Type | Default | Notes |
|---|---|---|---|
| `titleText` | `String` | required | Bold first line, painted in the accent color. Read together with `descriptionText` by the live-region announcement. |
| `descriptionText` | `String` | required | Second line, neutral grey. Renamed from `layrz_theme`'s `message`. |
| `type` | `LayrzSnackbarType` | `.success` | Drives icon + accent color. See enum table. |
| `icon` | `IconData?` | `null` | Valid only when `type` is `.custom` (two-way debug assertion). |
| `color` | `Color?` | `null` | Valid only when `type` is `.custom` (two-way debug assertion). |
| `duration` | `Duration?` | `Duration(seconds: 10)` | Single source of truth for dismissal. Flat 10s default across every `type` — no severity scaling. `null` makes the toast persistent. |
| `onTap` | `VoidCallback?` | `null` | Whole-card tap action. Runs the callback and **always** dismisses afterward. |
| `actions` | `List<LayrzButton>` | `[]` | Buttons rendered below the content, wrapping on compact viewports. Each button's own `onTap` does **not** auto-dismiss. |

Read-only getters: `isPersistent` (`true` iff `duration == null`), `isAutoDismiss` (`true` iff `duration != null`).

### `LayrzSnackbarMessenger`

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | required | The hosted subtree. Painted as a sibling under the messenger's own `Overlay`; toast presentation never shifts `child`'s layout. |
| `maxWidth` | `double` | `440` (`kLayrzSnackbarMaxWidth`) | Maximum card width in logical pixels. |
| `padding` | `EdgeInsets` | `EdgeInsets.all(16)` | Inset from the `Overlay`'s edges. On compact viewports, the effective top inset is the larger of `padding.top` and the device's top safe-area padding. |
| `maxVisible` | `int` | `3` (`kLayrzSnackbarMaxVisible`) | Max toasts visible in the accordion deck at once. Anything beyond collapses into a "+N · Dismiss all" affordance. Pass a larger value (e.g. `50`) to effectively disable the overflow affordance. |

---

## `LayrzSnackbarType` enum

Note **`.danger`, not `.error`** — mirrors `LayrzAlertType` and the repo's `danger` color token.

| Value | Icon (`MdiIcons`) | Accent color |
|---|---|---|
| `.custom` | caller-supplied `icon` | caller-supplied `color` |
| `.success` (default) | `checkCircle` | `tokens.colors.success` |
| `.danger` | `alertCircle` | `tokens.colors.danger` |
| `.warning` | `alert` | `tokens.colors.warning` |
| `.info` | `information` | `tokens.colors.info` |
| `.context` | `messageText` | `tokens.colors.contextual` |

For every non-custom type, the icon and title paint in the resolved accent color over the white card; the description always stays neutral grey.

---

## Static members (`LayrzSnackbarMessengerState`)

| Member | Signature | Notes |
|---|---|---|
| `show` | `void show(LayrzSnackbar snackbar)` | Enqueues a toast at the top of the list (newest first). |
| `showSnackbar` | `void showSnackbar(LayrzSnackbar snackbar)` | Alias for `show`, matching `ThemedSnackbarMessenger`'s prior naming. |
| `dismissAll` | `void dismissAll()` | Clears every queued toast, visible or collapsed. |
| `LayrzSnackbarMessenger.of` | `static LayrzSnackbarMessengerState of(BuildContext context)` | Resolves the nearest ancestor's state by tree ancestry. Throws `FlutterError` if none found. |
| `LayrzSnackbarMessenger.maybeOf` | `static LayrzSnackbarMessengerState? maybeOf(BuildContext context)` | Same lookup, returns `null` instead of throwing. |

---

## Companion widgets

The `snackbar` barrel (`lib/src/snackbar/snackbar.dart`) also exports:

- **`LayrzSnackbarStyleSpec`** — resolves per-`type` icon/accent color, honoring `.custom`'s `icon`/`color` override.
- **`LayrzSnackbarView`** — the internal card rendering widget the messenger builds per entry; not constructed directly by application code.

---

## Behavior notes

- **Duration model.** Non-null `duration` (default `Duration(seconds: 10)`, flat across every `type`) shows the draining bottom-edge progress bar and a close button, auto-dismissing on timeout. Explicit `null` is persistent: no bar, no drain timer, no auto-dismiss, no close button — removable only via `dismissAll()`, an `actions` button's own callback, or the whole-card `onTap`.
- **Hovering the deck pauses every visible toast's drain**, resuming exactly where it left off on hover-exit. No-op for persistent toasts.
- **Dismissal paths:** timeout, close-tap (only when auto-dismissing), whole-card tap (only when `onTap` set — runs then dismisses), swipe-up or swipe-right, and `dismissAll()`. A race between two dismissal paths in the same frame is guarded — a toast is only ever torn down once.
- **Accordion stacking.** At rest, up to `maxVisible` toasts show as a compact deck (front card full content, older cards peeking a slim sliver). Hovering fans the deck out to show every card's full content with no overlap. Overflow beyond `maxVisible` collapses into a "+N · Dismiss all" affordance — nothing is dropped silently.
- **Placement:** top-center on every breakpoint, inset below the safe area on compact viewports. Not configurable.
- **Auto-install, no global key.** `LayrzApp` installs the host automatically as a descendant of `LayrzTheme`. `.of`/`.maybeOf` resolve by tree ancestry only via an `InheritedWidget` — no `GlobalKey` anywhere in this class, unlike `layrz_theme`'s `ThemedSnackbarMessenger`.
- **Accessibility.** The card is a live region, announcing `titleText` + `descriptionText` together when first presented. The close button and the overflow affordance both carry their own localized semantic labels. Interaction states (hover) vary color/opacity only, never geometry.
