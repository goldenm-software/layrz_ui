---
name: layrz-ui-tab
description: Use LayrzTab in a layrz_ui Flutter widget. Apply when populating LayrzTabView's tabs list — a plain-text or custom label, optional leading/trailing icon or widget slots, and the child content shown while that tab is active.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The element type of `LayrzTabView.tabs` — always constructed inline when building that list, never used as a standalone widget.
- Carries a label (`labelText` or `label`), optional leading/trailing slots, and the required `child` content shown while that tab is active.
- **Do not use** outside a `LayrzTabView.tabs` list — `LayrzTab` has no `build` method and cannot be placed directly in a widget tree.
- **Do not use** for a runtime-managed workspace tab — use `LayrzWorkspaceTab` (with `LayrzWorkspaceTabs`) instead.

---

## Minimal usage

```dart
LayrzTab(
  labelText: 'Overview',
  child: OverviewPane(),
)
```

---

## Key behaviors

- **Exactly one of `labelText`/`label` must be non-null** — asserted in the constructor. `labelText` gets token-consistent weight/color styling from `LayrzTabView`; `label` is rendered untouched (opts out of that styling).
- **At most one of `leading`/`leadingIcon` may be non-null** — asserted. Leave both null for no leading slot.
- **At most one of `trailing`/`trailingIcon` may be non-null** — asserted. Leave both null for no trailing slot.
- **`child` is required** — a tab with no content to switch to is not meaningful.
- **Owns no interaction state** — selection, hover, and focus all live in `LayrzTabView`; `LayrzTab` is a plain immutable value with no `State`.

---

## Common patterns

```dart
// 1. Custom label widget (e.g. with a badge)
LayrzTab(
  label: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Live'),
      const SizedBox(width: 4),
      LayrzBadge(count: unreadCount),
    ],
  ),
  child: LiveFeedPane(),
)

// 2. Leading icon + trailing icon
LayrzTab(
  labelText: 'Alerts',
  leadingIcon: MdiIcons.bellOutline,
  trailingIcon: MdiIcons.chevronRight,
  child: AlertsList(),
)

// 3. Custom trailing widget (a badge instead of a plain icon)
LayrzTab(
  labelText: 'Inbox',
  leadingIcon: MdiIcons.emailOutline,
  trailing: LayrzBadge(count: 5),
  child: InboxPane(),
)
```

---

## Usage conventions

- Prefer `labelText` over `label` unless the label genuinely needs content `Text` cannot express — `label` opts out of `LayrzTabView`'s selected/idle weight and color rules.
- Localize `labelText` via `LayrzUiL10n.of(context).<key>` — never hardcode strings.
- Use `leadingIcon`/`trailingIcon` for a plain `IconData`; reach for `leading`/`trailing` only when the slot needs a badge or other custom-styled widget.
- Keep `child` lightweight enough to build eagerly — `LayrzTabView` does not lazy-build inactive tabs' `child` on your behalf beyond only rendering the active one.
