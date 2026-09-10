---
name: layrz-ui-find-bar
description: Use LayrzFindBar in a layrz_ui Flutter widget. Apply when reasoning about the floating, browser-style find-in-page bar that LayrzFindInPageHost shows/hides automatically — a compact LayrzTextInput query field, live "N of M" match counter, previous/next navigation, and a close button. Not normally constructed directly by application code.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- You will very rarely construct this directly — `LayrzFindInPageHost` builds and positions it automatically inside a root-`Overlay` `OverlayEntry` whenever `LayrzFindInPageController.isOpen` becomes `true`, and removes it the instant find closes.
- Reach for this skill when you need to understand the find bar's behavior (keyboard handling, sizing, composition) to customize `LayrzFindInPageController` interaction, or in the rare case of building a custom overlay host that reuses this widget directly.
- **Do not use** to build your own "search this list" UI — that's a job for `LayrzSearchInput` or a plain `LayrzTextInput`; `LayrzFindBar` is specifically the page-wide find-in-page bar tied to a `LayrzFindInPageController`.
- **Do not use** by calling `controller.close()` from inside a custom `onClose` — the bar itself never calls `close()` directly; the host is the one place deciding everything "closing find" entails (including tearing down its own overlay entry). Mirror that split if building a similar host.

---

## Minimal usage

```dart
// Normally never constructed directly — this is what LayrzFindInPageHost does internally:
LayrzFindBar(
  controller: findController,
  onClose: () => hostCloseFind(),
)
```

Application code almost always reaches find through the host instead:

```dart
LayrzFindInPageHost.of(context).controller.open();
```

---

## Key behaviors

- **`LayrzTextInput`, not a raw `EditableText`.** A raw `EditableText` was proven to fail web text input during development; the query field is a full `LayrzTextInput` (`hideDetails: true`).
- **Local key handling only.** Enter (next match), Shift+Enter (previous match), and Escape (close) are handled by a `Focus` wrapping just this bar — they are never registered as app-wide shortcuts, unlike Ctrl/Cmd+F itself (which `LayrzFindInPageHost` registers via `LayrzShortcut`).
- **Geometry never changes with search state.** The indeterminate "searching" progress line always reserves its layout slot; only its opacity toggles between searching and settled — the bar's height is identical whether or not a search is in flight.
- **`onClose` is the only path to dismissal** — this widget never calls `LayrzFindInPageController.close()` itself, so the host stays the single place deciding what "closing find" means (including removing its own overlay entry).
- **Responsive query field width.** Targets a comfortable default width on desktop and shrinks — down to a usability floor — only when the bar's own available width is too narrow for the full row of counter/prev/next/close. A very narrow viewport accepts a small, deliberate overflow rather than shrinking the field further.
- Auto-focuses the query field on its first frame after opening, matching a browser find bar's own convention.

---

## Common patterns

```dart
// Understanding the composition — this is what LayrzFindInPageHost builds:
Positioned(
  top: margin,
  right: margin,
  child: LayrzFindBar(
    controller: findInPageController,
    onClose: () {
      // The host's own close handling — e.g. remove this bar's OverlayEntry
      // and then call findInPageController.close().
    },
  ),
)
```

---

## Usage conventions

- Never construct `LayrzFindBar` in application screens — it's an implementation detail of `LayrzFindInPageHost`'s find-in-page feature, not a general-purpose search bar.
- If building a custom host that reuses this widget, keep `onClose` as the single place that calls `LayrzFindInPageController.close()` — do not have the bar itself close the controller, or overlay teardown and controller state can drift out of sync.
- When customizing find UI copy or icons is needed, prefer changing them at the theme/token level rather than forking this widget — it already reads every color/spacing value from `context.tokens`.
