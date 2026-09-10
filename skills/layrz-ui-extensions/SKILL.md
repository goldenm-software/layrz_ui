---
name: layrz-ui-extensions
description: Use LayrzColorExtensions and LayrzContextExtensions in a layrz_ui Flutter widget. Apply when converting a Color to/from hex, computing contrast/darken/lighten/flattenOn variants, or reaching theme/tokens/breakpoint/l10n shortcuts off BuildContext — `context.theme`, `context.tokens`, `context.isCompact`, `context.breakpoint`, `context.l10n`.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full extension method/getter reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Serializing/deserializing a `Color` to/from hex strings (`toHex`/`fromHex`) — e.g. persisting a user-picked brand color.
- Computing a readable text color against an arbitrary background (`contrastColor`), or deriving a tonal fill that composites correctly under a shadow (`flattenOn`).
- Reaching any theme-derived value off `BuildContext` — `context.theme`, `context.tokens`, `context.tokenizer`, `context.primaryColor`, `context.titleStyle`/`subtitleStyle`/`bodyStyle`.
- Making a responsive layout decision — `context.isCompact` (width < 960px) or `context.breakpoint` for the specific band.
- **Do not use** `context.isCompact`/`context.breakpoint` as a stand-in for OS/platform detection — use `LayrzPlatform.isMobile`/`.isTouchOS` for that; the two answer different questions (viewport width vs. operating system) and are not interchangeable.
- **Do not use** `.withOpacity()` anywhere in this codebase — use `.withValues(alpha: x)` (Flutter's own API) or this module's `withOpacityValue(opacity)` alias.
- **Do not use** `Color.fromHex(...)` — there is no such instance/static constructor on `Color` itself; the extension's hex parsers are `LayrzColorExtensions.fromHex(...)`, called on the extension type, not on `Color`.

---

## Minimal usage

```dart
// Color extensions
final hex = myColor.toHex();                 // '#001E60'
final restored = LayrzColorExtensions.fromHex(hex);
final textColor = backgroundColor.contrastColor; // black or white, whichever contrasts better

// Context extensions
final tokens = context.tokens;
final isNarrow = context.isCompact;
```

---

## Key behaviors

- **Hex parsers are static, not instance members.** `LayrzColorExtensions.fromHex('#001E60')` — never `Color.fromHex(...)`, which does not exist and will not compile.
- **`contrastColor` uses a `0.15` luminance threshold** (matching Material's `estimateBrightnessForColor`), intentionally favoring white text more than strict WCAG 2.0 (`0.0525`/≈`0.179` crossover). A color like Material green (`#4CAF50`) gets white text at ~2.78:1 contrast — below AA 4.5:1. Prefer darker accent colors over adjusting this if strict AA compliance is required.
- **`flattenOn(background)` composites a translucent color onto a background** and returns an opaque, pixel-identical result — use it when a translucent fill would otherwise let a `BoxDecoration`'s shadow smudge through the fill instead of rendering beneath it. Only correct when painted directly over the same `background` passed in.
- **`darken`/`lighten` are alpha-blend based**, not HSL lightness — `darken(amount)` composites black at `amount` opacity over the color (preserving its own alpha); `lighten` composites white the same way. Use `darken` instead of a `.shadeXXX` swatch lookup (swatches don't exist on single-`Color` semantic tokens in this design system).
- **`context.isCompact` is viewport-width-based** (`xs`/`sm` bands, < 960px) — **not** OS-based. A narrow desktop window is compact; a landscape tablet is not. Never substitute `LayrzPlatform.isMobile` for this or vice versa.
- **`context.l10n`** resolves `LayrzUiL10n.of(this)` — the canonical way to reach localized strings from a `BuildContext` inside this design system.
- **`context.isDark`/`context.brightness`** exist but are marked **BETA** — this codebase targets light mode only; do not build features that branch on them.

---

## Common patterns

```dart
// 1. Round-trip hex serialization
final color = const Color(0xFF001E60);
final hex = color.toHex();                          // save
final restored = LayrzColorExtensions.fromHex(hex);  // load

// 2. Auto-contrast text on a dynamic background
Container(
  color: backgroundColor,
  child: Text('Label', style: TextStyle(color: backgroundColor.contrastColor)),
)

// 3. A tonal fill that still paints its shadow correctly
final tonal = accent.withOpacityValue(0.2);
final opaque = tonal.flattenOn(context.tokens.colors.sf1);

// 4. Responsive layout decision
final columns = context.isCompact ? 1 : 3;

// 5. Theme token shortcuts
Container(
  decoration: BoxDecoration(
    color: context.theme.surfaceColor,
    borderRadius: BorderRadius.circular(context.tokenizer.radius),
  ),
  child: Text('Title', style: context.titleStyle),
)
```

---

## Pitfalls

- **`Color.fromHex(...)` does not compile.** The parser is `LayrzColorExtensions.fromHex(...)` — a static method on the extension, not a constructor Dart lets you call through the receiver type.
- **`contrastColor`'s threshold is not WCAG-strict.** Do not assume every color pairing meets AA contrast just because `contrastColor` picked black or white — some mid-tone colors (e.g. Material green) fall below 4.5:1 by design; pick darker accent colors if strict compliance matters.
- **`flattenOn` is background-specific.** The opaque result it returns is only visually identical when painted over the exact `background` passed in — reusing a flattened color against a different surface produces the wrong color.
- **`isCompact`/`breakpoint` vs. `LayrzPlatform.isMobile`/`.isTouchOS` are never interchangeable.** One is viewport width, the other is OS identity — conflating them (e.g. hiding a feature on "mobile" by checking `isCompact` when the intent was actually "touch device") is a common, hard-to-notice bug.
- **`isDark`/`brightness` are BETA and out of scope.** This design system is light-mode only (decision D7) — do not wire UI behavior to these getters.
