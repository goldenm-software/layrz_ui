# LayrzBadge — API Reference

Source: `lib/src/badges/src/badge.dart`
- `LayrzBadge` class
- `LayrzBadgeVisual` companion — `lib/src/badges/src/badge_visual.dart`
- `LayrzBadgeType` enum — `lib/src/badges/src/badge_type.dart`
- `LayrzBadgeAlignment` enum — `lib/src/badges/src/badge_alignment.dart`
- `LayrzBadgeStyleSpec` — `lib/src/badges/src/badge_style_spec.dart`

---

## Examples

```dart
// Count badge, default danger color, top-right
LayrzBadge(
  label: 'Notifications',
  count: 3,
  child: LayrzButton(icon: MdiIcons.bell, style: .text, onTap: openNotifications),
)

// Bare presence dot — both count and icon omitted
LayrzBadge(
  label: 'Online',
  type: .success,
  child: LayrzAvatar(url: user.avatarUrl),
)

// Icon badge
LayrzBadge(
  label: 'Verified account',
  icon: MdiIcons.checkDecagram,
  type: .info,
  child: LayrzAvatar(url: user.avatarUrl),
)

// Custom color, bottom-left corner
LayrzBadge(
  label: 'Custom status',
  type: .custom,
  color: const Color(0xFF6A0DAD),
  alignment: .bottomLeft,
  child: LayrzAvatar(url: user.avatarUrl),
)

// Hidden without remounting child
LayrzBadge(
  label: 'Unread messages',
  count: unreadCount,
  isVisible: unreadCount > 0,
  child: LayrzButton(icon: MdiIcons.email, style: .text, onTap: openInbox),
)

// Standalone visual — inline in a Row, not overlapping anything
Row(
  children: [
    Text('Status'),
    const SizedBox(width: 6),
    Semantics(
      label: 'Online',
      child: const LayrzBadgeVisual(type: LayrzBadgeType.success),
    ),
  ],
)

// LayrzBadgeVisual.formatCount — static helper
LayrzBadgeVisual.formatCount(150); // '99+'
LayrzBadgeVisual.formatCount(-1);  // '0'
LayrzBadgeVisual.formatCount(42);  // '42'
```

---

## Constructor

```dart
const LayrzBadge({
  required this.child,
  required this.label,
  this.count,
  this.icon,
  this.type = LayrzBadgeType.danger,
  this.color,
  this.alignment = LayrzBadgeAlignment.topRight,
  this.isVisible = true,
  super.key,
});
```

No constructor asserts. If both `count` and `icon` are non-null, `count` takes precedence.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | — | **Required.** The widget the badge overlays. Never affects `child`'s layout size — painted on top via `Positioned`. |
| `label` | `String` | — | **Required.** Human-readable description of what the badge signifies (e.g. `'Notifications'`), used to build the merged accessibility announcement. Never the raw count. |
| `count` | `int?` | `null` | The number to display, formatted via `LayrzBadgeVisual.formatCount`. When both this and `icon` are null, renders as a bare presence dot. |
| `icon` | `IconData?` | `null` | Icon glyph. Ignored when `count` is non-null. |
| `type` | `LayrzBadgeType` | `.danger` | Semantic color for the badge background. Ignored in favor of `color` only when `color` is explicitly non-null. |
| `color` | `Color?` | `null` | Explicit background color, overriding `type`'s resolved token. |
| `alignment` | `LayrzBadgeAlignment` | `.topRight` | Which corner of `child` the badge anchors to. |
| `isVisible` | `bool` | `true` | When `false`, only `child` renders — no badge visual or overlay is painted, but the widget tree stays stable. |

---

## `LayrzBadgeType` enum

Mirrors `LayrzChipType`'s vocabulary exactly, so semantic-color selection reads the same way across chips and badges.

| Value | Token color | Notes |
|---|---|---|
| `.info` | `tokens.colors.info` | Neutral badges. |
| `.success` | `tokens.colors.success` | Positive badges (e.g. "online"). |
| `.warning` | `tokens.colors.warning` | Cautionary badges. |
| `.danger` | `tokens.colors.danger` | Destructive/critical badges. **Default** — the conventional color for notification counts. |
| `.context` | `tokens.colors.contextual` | Context-dependent badges. |
| `.custom` | `color` param (fallback `tokens.colors.primary.shade500`) | Explicit color override. |

---

## `LayrzBadgeAlignment` enum

| Value | Corner |
|---|---|
| `.topRight` | Top-right. **Default** — conventional position for notification counts. |
| `.topLeft` | Top-left. |
| `.bottomRight` | Bottom-right. |
| `.bottomLeft` | Bottom-left. |

---

## Companion widgets

### `LayrzBadgeVisual`

The bare, unpositioned visual — no `Stack`/`Positioned` overlay, no host sizing. Use it when a badge needs to sit inline (e.g. in a `Row` next to a label) rather than overlapping another widget.

```dart
const LayrzBadgeVisual({
  this.count,
  this.icon,
  this.type = LayrzBadgeType.danger,
  this.color,
  super.key,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `count` | `int?` | `null` | Same semantics as `LayrzBadge.count`. Takes precedence over `icon` if both are set. |
| `icon` | `IconData?` | `null` | Same semantics as `LayrzBadge.icon`. |
| `type` | `LayrzBadgeType` | `.danger` | Same semantics as `LayrzBadge.type`. |
| `color` | `Color?` | `null` | Same semantics as `LayrzBadge.color`. |

`LayrzBadgeVisual` intentionally attaches **no** `Semantics` node of its own — a caller placing it directly in a `Row` is responsible for merging its own semantics (see the standalone example above).

**Static helper:** `LayrzBadgeVisual.formatCount(int count)` — 0–99 render literally, values above `kLayrzBadgeMaxCount` (99) render as `99+`, negative values clamp to `0`.

### `LayrzBadgeStyleSpec`

An immutable, paint-only spec (`backgroundColor`, `contentColor`) resolved via `LayrzBadgeStyleSpec.resolve(type:, color:, tokens:)`. `contentColor` is always derived from the resolved background via `contrastColor`, so number/icon content has adequate contrast regardless of the chosen accent. Not typically constructed directly by consumers.

---

## Behavior notes

- **Sizing**: a count/icon badge is `tokens.spacing.sp4` (20lp) diameter; the bare presence dot is smaller, `tokens.spacing.sp2` (10lp) — exactly half, landing in the conventional ~8–10lp-against-a-40lp-avatar proportion for a presence indicator.
- **Corner overlay**: `LayrzBadge` positions the badge via `Positioned.fill` → `Align(alignment: alignment.alignment)` → `FractionalTranslation`, nudging it outward past `child`'s edge so it reads as sitting on the corner rather than fully inside the bounding box.
- **Accessibility announcement**: built by `LayrzBadge._announcement()` — `'$label, $formatted unread'` for a count, `'$label, new'` for an icon or bare dot, or just `label` when `isVisible` is false. `child`'s own semantics (and the badge visual's auto-generated text/icon semantics) are excluded from the tree so nothing duplicates into the merged announcement.
- **`computeWidth`/layout cost**: `LayrzBadgeVisual` and `LayrzBadge` do not expose a width-measurement helper of their own (that exists on `LayrzChip`, not badges) — the badge's own size is fixed by its diameter constants above, not measured.
