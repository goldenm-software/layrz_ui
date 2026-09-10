---
name: layrz-ui-selection-magnifier
description: Use LayrzSelectionMagnifier in a layrz_ui Flutter widget. Apply when wiring touch-platform text-selection magnification into a custom EditableText via `LayrzSelectionMagnifier.magnifierConfigurationFor(...)` passed to `magnifierConfiguration` — Material-free, gated on LayrzPlatform.isTouchOS (Android/iOS, native or mobile web), no-op on desktop.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Wiring the magnifying lens that follows the user's finger during long-press+drag text selection on touch platforms, for a custom `EditableText`-based widget.
- **The real entry point is the static `LayrzSelectionMagnifier.magnifierConfigurationFor(...)`**, passed to `EditableText.magnifierConfiguration` — not the widget's own `build()`, which is an unused `SizedBox.shrink()` placeholder (the class exists as a namespace for the static method, mirroring `LayrzTextSelectionControls`'s own composition style).
- **Do not use** on `LayrzTextInput` or anything built on it — magnification is already wired in for those.
- **Do not gate this on `LayrzPlatform.isMobile`** — the underlying gate is `LayrzPlatform.isTouchOS`, which (unlike `isMobile`) correctly reports `true` for Android/iOS running in a mobile browser too. Using `isMobile` here would be the wrong check to reproduce, though you never need to check platform yourself — `magnifierConfigurationFor` already does it internally.
- **Do not expect anything from constructing `LayrzSelectionMagnifier()` directly** — it renders nothing (`SizedBox.shrink()`); all real behavior is in the static method.

---

## Minimal usage

```dart
EditableText(
  controller: controller,
  focusNode: focusNode,
  style: style,
  cursorColor: cursorColor,
  backgroundCursorColor: backgroundCursorColor,
  selectionControls: LayrzTextSelectionControls.instance,
  magnifierConfiguration: LayrzSelectionMagnifier.magnifierConfigurationFor(),
)
```

---

## Key behaviors

- **Returns `null` on non-touch platforms.** `magnifierConfigurationFor` returns `null` when `LayrzPlatform.isTouchOS` is `false` — pass the result straight through; `EditableText.magnifierConfiguration` accepts `null` and simply shows no magnifier.
- **`scale` defaults to `1.25`** — 25% magnification, tuned to keep magnified text recognizable without extreme distortion. `1.0` = actual size, `1.5`+ for stronger magnification (e.g. accessibility).
- **Platform gate is `LayrzPlatform.isTouchOS`, not `.isMobile`.** `isTouchOS` reports `true` for Android/iOS on both native and mobile web; `isMobile` routes through `LayrzPlatform.current`, which short-circuits on web and would incorrectly report `false` for a mobile browser — using the wrong one strips the magnifier from platforms it's meant to support.
- **Lens is fixed-size**: 77.37 × 37.9 logical pixels (Material's own standard magnifier dimensions) — not configurable.
- **Desktop platforms show nothing** — Windows, macOS, Linux, and desktop web never render a magnifier regardless of `scale`.

---

## Common patterns

```dart
// 1. Default magnification (recommended for most text sizes)
EditableText(
  // ...
  magnifierConfiguration: LayrzSelectionMagnifier.magnifierConfigurationFor(),
)

// 2. Stronger magnification for small text / accessibility
EditableText(
  // ...
  magnifierConfiguration: LayrzSelectionMagnifier.magnifierConfigurationFor(scale: 1.5),
)
```

---

## Usage conventions

- Always call `magnifierConfigurationFor` as a static method — never construct `LayrzSelectionMagnifier()` and expect it to do anything on its own.
- Pass the result of `magnifierConfigurationFor` straight to `EditableText.magnifierConfiguration` without null-checking or platform-branching yourself — the method already returns `null` on the right platforms.
- Pair with `LayrzTextSelectionControls.instance` on the same `EditableText` for the full Material-free selection experience (handles + toolbar + magnifier).
