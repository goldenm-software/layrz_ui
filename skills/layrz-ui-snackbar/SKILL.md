---
name: layrz-ui-snackbar
description: Use LayrzSnackbar in a layrz_ui Flutter app. Apply when showing transient toast feedback — success/danger/warning/info/context severity types, duration-driven auto-dismiss vs. persistent toasts, whole-card onTap, below-content action buttons, shown via LayrzSnackbarMessenger.of(context).show(...).
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.success`, `.danger`, `.custom`) — never the fully-qualified form (`LayrzSnackbarType.success`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any transient feedback toast: "Changes saved", "Failed to delete", "Sync complete", an "Undo" prompt.
- Use severity `type` to convey outcome: `.success` (default), `.danger`, `.warning`, `.info`, `.context` (neutral, e.g. Undo prompts).
- Use `type: .custom` only when you must override both `icon` and `color` together.
- Use `duration: null` for a toast that must stay until the user (or code) explicitly dismisses it — e.g. "Syncing…" while a background operation runs.
- Use `actions` for a row of buttons below the content (e.g. "Manage rule" / "Dismiss"); use `onTap` for a single whole-card tap action (e.g. "Tap to undo").
- **Do not use** for an inline, page-embedded status message — use `LayrzAlert` instead. `LayrzSnackbar` is exclusively for the overlay-based transient toast.
- **Do not use** for a blocking confirmation the user must answer before continuing — use `LayrzDialog` instead.

---

## Minimal usage

```dart
LayrzSnackbarMessenger.of(context).show(
  const LayrzSnackbar(
    titleText: 'Changes saved',
    descriptionText: 'Your profile has been updated successfully.',
    type: .success,
  ),
);
```

---

## Key behaviors

- **`LayrzSnackbar` is pure data** — no `BuildContext`, no animation state. It is shown exclusively through `LayrzSnackbarMessenger.of(context).show(...)` (or its alias `.showSnackbar(...)`).
- **`duration` is the single source of truth for dismissal — there is no `isDismissible` field.** Non-null (default `Duration(seconds: 10)`, flat across every `type`) auto-dismisses with a progress bar and a close button. Explicit `null` makes the toast persistent — no bar, no close button, no auto-dismiss; only removable via `dismissAll()` or an `onTap`/`actions` callback.
- **The custom-type contract is a two-way debug assertion:** `type == .custom` ⇒ `icon` and `color` must both be non-null; every other `type` ⇒ both must be null.
- **`onTap` always dismisses after running** — there is no tap-without-dismiss mode. This is distinct from `actions`, where tapping a button runs **only that button's own `onTap`** and does **not** automatically dismiss — if an action should also close the toast, its own `onTap` must trigger dismissal itself.
- `actions` is strictly typed `List<LayrzButton>` — no other widget type is accepted.
- Note the type value is **`.danger`, not `.error`** — matches `LayrzAlertType` naming.
- White-card treatment: the card stays white/light regardless of severity; icon and title paint in the accent color, description stays neutral grey.

---

## `LayrzSnackbarType` reference

| Type | Icon | Accent color |
|---|---|---|
| `.success` (default) | `MdiIcons.checkCircle` | `tokens.colors.success` |
| `.danger` | `MdiIcons.alertCircle` | `tokens.colors.danger` |
| `.warning` | `MdiIcons.alert` | `tokens.colors.warning` |
| `.info` | `MdiIcons.information` | `tokens.colors.info` |
| `.context` | `MdiIcons.messageText` | `tokens.colors.contextual` |
| `.custom` | caller-supplied `icon` | caller-supplied `color` |

---

## Common patterns

```dart
// Persistent toast — no bar, no close button, no auto-dismiss
LayrzSnackbarMessenger.of(context).show(
  const LayrzSnackbar(
    titleText: 'Syncing…',
    descriptionText: 'This clears automatically once the sync finishes.',
    duration: null,
  ),
);

// Whole-card tap — runs the callback, then dismisses
LayrzSnackbarMessenger.of(context).show(
  LayrzSnackbar(
    titleText: 'Item deleted',
    descriptionText: 'Tap to undo this action.',
    type: .context,
    onTap: () => restoreDeletedItem(),
  ),
);

// Action buttons row — each fires its own onTap independently
LayrzSnackbarMessenger.of(context).show(
  LayrzSnackbar(
    titleText: 'Rule triggered',
    descriptionText: 'Speed limit exceeded on Unit 42.',
    type: .warning,
    actions: [
      LayrzButton(
        labelText: 'Manage rule',
        type: .warning,
        onTap: () => openRuleSettings(),
      ),
      LayrzButton(
        labelText: 'Dismiss',
        style: .outlined,
        onTap: () {},
      ),
    ],
  ),
);

// Custom type with explicit icon + color
LayrzSnackbarMessenger.of(context).show(
  LayrzSnackbar(
    titleText: 'Cross-post to Slack',
    descriptionText: 'Custom color and icon example.',
    type: .custom,
    icon: MdiIcons.slack,
    color: const Color(0xFF4A154B),
  ),
);

// Dismiss everything (e.g. on logout)
LayrzSnackbarMessenger.of(context).dismissAll();
```

---

## App setup conventions

- **There is nothing to wire up.** `LayrzApp` installs the `LayrzSnackbarMessenger` host automatically, as a descendant of `LayrzTheme` and an ancestor of the routed content — application code never constructs, wires, or `builder:`-wraps a `LayrzSnackbarMessenger` itself. Do not add one to your widget tree.
- Access the messenger from any descendant's `BuildContext` via `LayrzSnackbarMessenger.of(context)` (throws if no ancestor is found — this should never happen in app code) or `.maybeOf(context)` (returns `null` — use in widget tests that have not wrapped the tree with a messenger).
- **There is no `GlobalKey`-based static accessor** — this is a deliberate departure from `layrz_theme`'s `ThemedSnackbarMessenger`. A caller without a `BuildContext` (a service/repository layer) must thread one through, or raise the event to a layer that has one.
- Never construct a second `LayrzSnackbarMessenger` inside a subtree that already has `LayrzApp`'s installed one as an ancestor — it asserts in debug and renders inertly instead of installing a second overlay.
- Placement is fixed top-center on every breakpoint — there is no configuration for this.
