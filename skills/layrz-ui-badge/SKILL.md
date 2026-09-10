---
name: layrz-ui-badge
description: Use LayrzBadge in a layrz_ui Flutter widget. Apply when overlaying a notification indicator on a corner of another widget — a count, an icon, or a bare presence dot, with info/success/warning/danger/context/custom colors and top/bottom-left/right corner anchoring.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.danger`, `.topRight`) — never the fully-qualified form (`LayrzBadgeType.danger`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A notification/unread-count indicator overlaid on a bell icon, avatar, or nav item.
- A presence indicator (online/away/busy/offline) overlaid on an avatar — omit both `count` and `icon` for the bare-dot form.
- An icon badge (e.g. a small verification glyph) anchored to a corner of another widget.
- **Do not use** for a standalone compact label with no host to overlay — use `LayrzChip` instead.
- **Do not use** inline next to a label in a `Row` (not overlapping anything) — use the bare `LayrzBadgeVisual` companion instead; `LayrzBadge` always positions via `Stack`/`Positioned` over a `child`.

---

## Minimal usage

```dart
LayrzBadge(
  label: 'Notifications',
  count: unreadCount,
  child: LayrzButton(
    icon: MdiIcons.bell,
    style: .text,
    onTap: openNotifications,
  ),
)
```

---

## Key behaviors

- Content follows priority order: `count` (if non-null) → `icon` (if `count` is null) → bare presence dot (both null).
- `label` is **required** and must describe what the badge signifies (e.g. `'Notifications'`), never the raw count — the widget appends the formatted count itself to build the merged accessibility announcement (e.g. "Notifications, 3 unread").
- The badge never changes `child`'s layout size — it paints on top via `Positioned`, so wrapping any widget in `LayrzBadge` never reflows the surrounding layout.
- Counts above 99 render as exactly `99+` (never a raw large number); negative counts clamp to `0`.
- `isVisible: false` hides the badge visual entirely while keeping `child` and the widget tree stable — use this instead of conditionally omitting `LayrzBadge` so toggling doesn't remount `child`.
- `child`'s own semantics are excluded and merged into one `Semantics` node built from `label` — don't wrap `child` in its own competing `Semantics` describing the same content.

---

## Common patterns

```dart
// 1. Notification count on an icon button
LayrzBadge(
  label: 'Notifications',
  count: 3,
  child: LayrzButton(icon: MdiIcons.bell, style: .text, onTap: openNotifications),
)

// 2. Presence dot on an avatar (bare dot — no count, no icon)
LayrzBadge(
  label: 'Online',
  type: .success,
  child: LayrzAvatar(url: user.avatarUrl),
)

// 3. Icon badge, top-left corner, custom color
LayrzBadge(
  label: 'Verified',
  icon: MdiIcons.checkDecagram,
  type: .custom,
  color: const Color(0xFF2E7D32),
  alignment: .topLeft,
  child: LayrzAvatar(url: user.avatarUrl),
)

// 4. Toggle visibility without remounting the child
LayrzBadge(
  label: 'Unread messages',
  count: unreadCount,
  isVisible: unreadCount > 0,
  child: LayrzButton(icon: MdiIcons.email, style: .text, onTap: openInbox),
)
```

---

## Usage conventions

- Always pass a human-readable `label` describing the badge's meaning — never the count itself; a bare "3" read aloud next to an unlabelled icon is meaningless.
- Use plain string literals or `LayrzUiL10n.of(context).<key>` for `label` — never hardcode application copy that belongs in a localization layer.
- Default `type` is `.danger` — the conventional color for notification counts; override to `.success`/`.warning`/`.context` for presence-style semantics, or `.custom` with an explicit `color`.
- Prefer `alignment: .topRight` (the default) unless the host widget's own layout makes another corner read better (e.g. a bottom-right presence dot on a large avatar).
- For a badge that sits inline in a `Row` rather than overlapping something, use `LayrzBadgeVisual` directly instead of `LayrzBadge` — see `references/api.md`.
