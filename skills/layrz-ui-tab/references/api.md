# LayrzTab — API Reference

Source: `lib/src/tabs/src/tab.dart`
- `LayrzTab` class

---

## Examples

```dart
// Plain-text label
LayrzTab(
  labelText: 'Overview',
  child: OverviewPane(),
)

// Custom label widget
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

// Leading icon and trailing icon
LayrzTab(
  labelText: 'Alerts',
  leadingIcon: MdiIcons.bellOutline,
  trailingIcon: MdiIcons.chevronRight,
  child: AlertsList(),
)

// Custom trailing widget (e.g. a badge)
LayrzTab(
  labelText: 'Inbox',
  leadingIcon: MdiIcons.emailOutline,
  trailing: LayrzBadge(count: 5),
  child: InboxPane(),
)
```

---

## Constructor

```dart
const LayrzTab({
  this.labelText,
  this.label,
  this.leading,
  this.leadingIcon,
  this.trailing,
  this.trailingIcon,
  required this.child,
}) : assert(
       (labelText == null) != (label == null),
       'Provide exactly one of labelText or label, not both and not neither.',
     ),
     assert(
       leading == null || leadingIcon == null,
       'Provide at most one of leading or leadingIcon, not both.',
     ),
     assert(
       trailing == null || trailingIcon == null,
       'Provide at most one of trailing or trailingIcon, not both.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Plain-text label. Mutually exclusive with `label` — exactly one required. Rendered as `Text` styled with `tokens.typography.label`, sized/weighted by `LayrzTabView`'s selection rules. |
| `label` | `Widget?` | `null` | Custom label widget. Mutually exclusive with `labelText` — exactly one required. Rendered untouched; `LayrzTabView` applies no text styling to it. |
| `leading` | `Widget?` | `null` | Custom widget in the leading slot, before the label. Mutually exclusive with `leadingIcon`. |
| `leadingIcon` | `IconData?` | `null` | Icon in the leading slot. Mutually exclusive with `leading`. Rendered via `Icon`, sized `kLayrzButtonIconSize`, colored to match the pill's current label color. |
| `trailing` | `Widget?` | `null` | Custom widget in the trailing (suffix) slot, after the label. Mutually exclusive with `trailingIcon`. |
| `trailingIcon` | `IconData?` | `null` | Icon in the trailing slot. Mutually exclusive with `trailing`. Same sizing/coloring as `leadingIcon`. |
| `child` | `Widget` | required | Content `LayrzTabView` displays when this tab is active. |

---

## Behavior notes

- **Not a widget on its own**: `LayrzTab` has no `build` method — it is only ever read by `LayrzTabView`, as an entry in its `tabs` list.
- **Owns no interaction state**: selection, hover, focus, and color resolution are entirely `LayrzTabView`'s responsibility. `LayrzTab` is `@immutable` and carries only data.
- **`labelText` vs `label` styling trade-off**: choosing `label` opts out of the token-consistent weight/color swap `LayrzTabView` applies to `labelText` between selected and idle states — a custom `label` widget is responsible for its own visual state if that distinction matters.
- No `copyWith`/`==`/`hashCode` are defined on `LayrzTab` in source — construct a new instance to change any field.
