---
name: layrz-ui-tooltip
description: Use LayrzTooltip in a layrz_ui Flutter widget. Apply when adding a hover (desktop) or long-press (touch) hint to any widget — plain or rich text content, top/bottom/left/right positioning with automatic viewport flipping, and .pointer/.tap trigger modes.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.top`, `.tap`) — never the fully-qualified form (`LayrzPreferredSide.top`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Adding a hint to any widget — icons, badges, custom controls, anything that benefits from an on-hover/long-press explanation.
- `LayrzButton`'s own `hintText` already uses `LayrzTooltip` internally — wrap non-button widgets directly with `LayrzTooltip` instead of reimplementing hint chrome.
- Use `.tap` trigger mode for touch-first flows where a hover/long-press gesture doesn't fit (e.g. an info icon meant to be explicitly tapped open and tapped away).
- **Do not use** for a widget that already has its own `onLongPress` handler — the child's gesture wins the arena and the tooltip won't show on touch (hover still works on desktop). Prefer `LayrzButton.hintText` for buttons.
- **Do not use** for widget/rich content beyond styled text spans — the surface only supports `contentText`/`contentRichText`, never an arbitrary `child`-shaped tooltip body.
- Requires an `Overlay` ancestor (provided by `LayrzApp`); outside one it silently degrades to rendering `child` unchanged rather than crashing.

---

## Minimal usage

```dart
LayrzTooltip(
  contentText: 'Click to copy',
  child: LayrzIconButton(icon: MdiIcons.contentCopy, onTap: copy),
)
```

---

## Key behaviors

- Exactly one of `contentText` / `contentRichText` must be non-null — an assertion throws if both or neither are provided.
- Surface styling (background, text color, padding, radius) is fixed by design tokens and not configurable — only text content varies. Use `contentRichText` for mixed styling (bold spans, etc.), not for changing the surface itself.
- `.pointer` (default) trigger: hover to show / pointer-exit to hide on desktop; long-press to show / next touch anywhere to dismiss on touch-only devices. Releasing the long-press finger does **not** dismiss it — only the next `PointerDownEvent` elsewhere does.
- `.tap` trigger: a single tap toggles the tooltip open/closed; another tap anywhere dismisses it. Hover has no effect in this mode, even on desktop.
- Wrapping a widget in `LayrzTooltip` never changes its size, position, or hit-testing — the tooltip is a separate `OverlayPortal`, and both the anchor wrapper and the tooltip surface itself are pointer-transparent.
- Position (`top`/`bottom`/`left`/`right`) automatically flips to the opposite side if it would overflow the viewport, and clamps on the cross-axis to stay on screen.

---

## Common patterns

```dart
// 1. Plain-text hint on an icon
LayrzTooltip(
  contentText: 'More information',
  position: .top,
  child: Icon(MdiIcons.informationOutline),
)

// 2. Rich-text hint with mixed styling
LayrzTooltip(
  contentRichText: TextSpan(
    text: 'Click to view ',
    children: [
      TextSpan(text: 'details', style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  ),
  child: myCustomWidget,
)

// 3. Title + content
LayrzTooltip(
  titleText: 'Shortcut',
  contentText: 'Press Ctrl+S to save',
  child: saveIcon,
)

// 4. Explicit tap-to-open / tap-away-to-close
LayrzTooltip(
  trigger: .tap,
  contentText: 'This field is required for verification.',
  child: Icon(MdiIcons.helpCircleOutline),
)

// 5. Positioned to the right of a compact anchor
LayrzTooltip(
  position: .right,
  contentText: 'Tooltip on the right',
  child: statusDot,
)
```

---

## Usage conventions

- Use plain string literals or `LayrzUiL10n.of(context).<key>` for `contentText`/`titleText` — never hardcode application copy that belongs in a localization layer.
- Prefer `.pointer` (the default) for incidental hints; reserve `.tap` for content the user should be able to deliberately open and dismiss, especially on touch devices.
- Don't wrap a widget that already owns `onLongPress` — check for a conflicting gesture handler first; if the wrapped widget is a `LayrzButton`, use its `hintText` parameter instead.
- Keep `contentText` short — the surface caps at 80% of viewport width and is meant for a brief hint, not a paragraph.
