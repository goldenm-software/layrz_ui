---
name: layrz-ui-tab-view
description: Use LayrzTabView in a layrz_ui Flutter widget. Apply when rendering a fixed, author-defined tab strip and content switcher — scrollable (default) or evenly-distributed (isScrollable: false) pill layout, with per-tab leading/trailing icon or widget slots.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A fixed, author-defined set of pill-shaped tabs above a content area that swaps per selection — settings pages, detail-view sections, filter groups.
- Use `isScrollable: true` (default) for many tabs, or tabs with variable-width labels.
- Use `isScrollable: false` for a small, fixed set of tabs that should stretch edge-to-edge.
- **Do not use** for a runtime-managed, user-opened/closed/reordered tab set (browser-style workspace) — use `LayrzWorkspaceTabs` instead.
- **Do not use** for app-level primary navigation — use `LayrzLayout`'s nav rail/drawer instead.

---

## Minimal usage

```dart
LayrzTabView(
  tabs: [
    LayrzTab(labelText: 'Overview', child: OverviewPane()),
    LayrzTab(labelText: 'Details', child: DetailsPane()),
    LayrzTab(labelText: 'History', child: HistoryPane()),
  ],
)
```

---

## Key behaviors

- **Selection is owned internally** — `LayrzTabView` is a `StatefulWidget`; tapping a tab swaps content and calls `onTabChanged`. There is no external selection controller.
- **`initialIndex` only affects the first mount**, and is clamped into `[0, tabs.length - 1]` rather than asserted — an out-of-range persisted index never throws.
- **`onTabChanged` fires only on a user-initiated tap on a non-selected tab** — never on mount, never for a re-tap of the already-active tab.
- **`tabs` must be non-empty** — asserted in the constructor.
- **Button-scale pills, not chips**: minimum height `kLayrzButtonHeight` (45px), label at `kLayrzButtonFontSize` (14px), leading/trailing icons at `kLayrzButtonIconSize` (22px) — matches `LayrzButton` sizing, not the smaller `tokens.typography.label` size.
- **Geometry never changes with selection (D15)** — only color changes between idle/hover/press/selected; height, padding, and corner radius stay identical.

---

## Common patterns

```dart
// 1. Expanded (evenly distributed) tabs
LayrzTabView(
  isScrollable: false,
  tabs: [
    LayrzTab(labelText: 'Palette', child: PalettePicker()),
    LayrzTab(labelText: 'Wheel', child: WheelPicker()),
  ],
)

// 2. Leading + trailing icon slots
LayrzTabView(
  tabs: [
    LayrzTab(
      labelText: 'Alerts',
      leadingIcon: MdiIcons.bellOutline,
      trailingIcon: MdiIcons.chevronRight,
      child: AlertsList(),
    ),
    LayrzTab(
      labelText: 'Settings',
      leadingIcon: MdiIcons.cogOutline,
      child: SettingsPane(),
    ),
  ],
)

// 3. Listening for changes and starting on a non-first tab
LayrzTabView(
  initialIndex: 1,
  onTabChanged: (index) => debugPrint('Switched to tab $index'),
  tabs: tabs,
)

// 4. Custom padding and content gap
LayrzTabView(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  contentGap: 0, // butt content directly against the strip
  tabs: tabs,
)
```

---

## Usage conventions

- Localize every `LayrzTab.labelText` via `LayrzUiL10n.of(context).<key>` — never hardcode strings.
- Reserve `LayrzTab.label` (a custom widget) for content `labelText` genuinely cannot express — it opts out of the token-consistent weight/color swap between selected and idle states.
- Use `leadingIcon`/`trailingIcon` (an `IconData`, sized/colored automatically) for the common case; reach for `leading`/`trailing` (arbitrary widgets) only for a badge or custom-styled indicator.
- Give `LayrzTabView` a bounded-height ancestor when its tab content itself needs to scroll — the widget does not impose scrolling on `LayrzTab.child` for you.
