# LayrzColorExtensions / LayrzContextExtensions — API Reference

Source: `lib/src/extensions/src/color.dart`, `lib/src/extensions/src/context.dart`
- `LayrzColorExtensions` — `extension on Color`
- `LayrzContextExtensions` — `extension on BuildContext`

Both are exported from the root barrel (`import 'package:layrz_ui/layrz_ui.dart';`) — no separate import needed.

---

## Examples

```dart
// Color: hex round-trip
final color = const Color(0xFF001E60);
final hex = color.toHex();                          // '#001E60'
final restored = LayrzColorExtensions.fromHex(hex);  // Color(0xFF001E60)

// Color: hex with alpha
final withAlpha = color.toHexWithAlpha();            // '#FF001E60'
final restoredWithAlpha = LayrzColorExtensions.fromHexWithAlpha(withAlpha);

// Color: JSON shorthand
final json = color.toJson();                         // same as toHex()
final fromJson = LayrzColorExtensions.fromJson(json); // same as fromHex()

// Color: 32-bit ARGB int
final argb = color.toInt();

// Color: contrast
final textColor = color.contrastColor; // black or white

// Color: opacity / flatten / darken / lighten
final semi = color.withOpacityValue(0.5);
final opaque = semi.flattenOn(context.tokens.colors.sf1);
final darker = color.darken(0.2);
final lighter = color.lighten(0.2);
final isFullyOpaque = color.isOpaque;

// Context: theme/tokens
final theme = context.theme;
final tokens = context.tokens;
final tokenizer = context.tokenizer;
final l10n = context.l10n;

// Context: responsive
final band = context.breakpoint;    // LayrzBreakpoint.xs..xl
final compact = context.isCompact;  // true for xs/sm

// Context: quick text styles
Text('Title', style: context.titleStyle);
Text('Subtitle', style: context.subtitleStyle);
Text('Body', style: context.bodyStyle);

// Context: theme extensions
final custom = context.themeExtension<MyThemeExtension>();
final maybeCustom = context.maybeThemeExtension<MyThemeExtension>();
```

---

## Extension methods — `LayrzColorExtensions` (on `Color`)

| Method | Signature | Notes |
|---|---|---|
| `toJson` | `String toJson()` | Alias for `toHex()`. |
| `toHex` | `String toHex()` | 6-digit uppercase hex, no alpha (e.g. `#001E60`). |
| `toHexWithAlpha` | `String toHexWithAlpha()` | 8-digit uppercase hex, alpha first (e.g. `#FF001E60`). |
| `toInt` | `int toInt()` | Encodes as a 32-bit ARGB integer. |
| `withOpacityValue` | `Color withOpacityValue(double opacity)` | Returns this color at `opacity` (0.0–1.0). Implemented via `withValues(alpha: opacity)` — the codebase-mandated replacement for the deprecated `.withOpacity()`. |
| `flattenOn` | `Color flattenOn(Color background)` | Composites this color over `background` via `Color.alphaBlend`, returning a fully opaque, pixel-identical result **when painted directly over that same background**. Use to avoid a `BoxDecoration` shadow smudging through a translucent fill. |
| `darken` | `Color darken([double amount = 0.1])` | Composites black at `amount` opacity over this color (alpha-blend, not HSL), preserving this color's own alpha. `amount` must be 0.0–1.0. |
| `lighten` | `Color lighten([double amount = 0.1])` | Composites white at `amount` opacity over this color, same mechanism as `darken`. |

## Static methods — `LayrzColorExtensions` (not instance methods)

| Method | Signature | Notes |
|---|---|---|
| `fromJson` | `static Color fromJson(String json)` | Alias for `fromHex`. |
| `fromHex` | `static Color fromHex(String hex)` | Parses `#RRGGBB` or `RRGGBB` (leading `#` optional). Fully opaque result. |
| `fromHexWithAlpha` | `static Color fromHexWithAlpha(String hex)` | Parses `#AARRGGBB` or `AARRGGBB` (leading `#` optional). |

**Call these on the extension type, never on `Color` itself** — `Color.fromHex(...)` does not compile.

## Getters — `LayrzColorExtensions` (on `Color`)

| Getter | Type | Notes |
|---|---|---|
| `hex` | `String` | Alias for `toHex()`. |
| `hexWithAlpha` | `String` | Alias for `toHexWithAlpha()`. |
| `contrastColor` | `Color` | Black or white, whichever contrasts better, via `v² > 0.15` on `(luminance + 0.05)` — matches Material's `estimateBrightnessForColor`. Intentionally favors white more than strict WCAG (`0.0525`/≈`0.179`). |
| `opposite` | `Color` | Alias for `contrastColor`. |
| `isOpaque` | `bool` | `true` when `a == 1.0`. |

---

## Getters — `LayrzContextExtensions` (on `BuildContext`)

| Getter | Type | Equivalent / Notes |
|---|---|---|
| `theme` | `LayrzThemeData` | `LayrzTheme.of(this)`. |
| `tokens` | `LayrzTokens` | `LayrzTheme.of(this).tokens`. Preferred way to access design values. |
| `breakpoint` | `LayrzBreakpoint` | Resolved from `MediaQuery.sizeOf(this).width` — always viewport-driven, never container-driven. One of `.xs`/`.sm`/`.md`/`.lg`/`.xl`. |
| `isCompact` | `bool` | `true` for `.xs`/`.sm` (< 960px), `false` for `.md`/`.lg`/`.xl`. **The single source of truth for responsive sizing decisions** — never substitute `LayrzPlatform.isMobile`, which is OS-based, not width-based. |
| `isDark` | `bool` | **BETA.** `true` when `LayrzTheme.of(this).brightness == Brightness.dark`. Do not build on this — the design system targets light mode only. |
| `brightness` | `Brightness` | **BETA.** Shorthand for `LayrzTheme.of(this).brightness`. |
| `tokenizer` | `LayrzTokenizer` | `LayrzTokenizer(tokens)` — group getters and flat shortcuts over design tokens. |
| `l10n` | `LayrzUiL10n` | `LayrzUiL10n.of(this)` — the preferred way to access localized strings. |
| `primaryColor` | `Color` | `LayrzTheme.of(this).primaryColor`. |
| `titleStyle` | `TextStyle` | Bold, 18pt, derived from `LayrzThemeData.textStyle`. |
| `subtitleStyle` | `TextStyle` | Bold, 16pt, derived from `LayrzThemeData.textStyle`. |
| `bodyStyle` | `TextStyle` | Base text style from `LayrzThemeData.textStyle`. |

## Extension methods — `LayrzContextExtensions` (on `BuildContext`)

| Method | Signature | Notes |
|---|---|---|
| `themeExtension<T>` | `T themeExtension<T extends LayrzThemeExtension<T>>()` | Retrieves a registered theme extension, **throws** (assert) if not found. |
| `maybeThemeExtension<T>` | `T? maybeThemeExtension<T extends LayrzThemeExtension<T>>()` | Same, but returns `null` instead of throwing. |

---

## Pitfalls

- **No `Color.fromHex(...)`.** The parsers are static members of `LayrzColorExtensions`, called as `LayrzColorExtensions.fromHex(...)` — not as a constructor on `Color`.
- **`contrastColor`'s 0.15 threshold is not strict WCAG AA.** Some mid-luminance colors (Material green ≈ 0.328 luminance) resolve to white text at ~2.78:1 contrast, below the 4.5:1 AA bar. Choose darker accent colors rather than relying on this getter for compliance-critical pairings.
- **`flattenOn` results are surface-specific.** The returned opaque color is only pixel-correct when painted over the exact `background` argument — caching and reusing it against a different surface is wrong.
- **`darken`/`lighten` are alpha-blend, not HSL.** There is no `.shadeXXX` swatch API on semantic color tokens in this design system — use these methods to derive a tone instead.
- **`isCompact`/`breakpoint` are never a substitute for `LayrzPlatform.isMobile`/`.isTouchOS`, and vice versa.** Viewport width and OS identity are orthogonal; conflating them is a real, easy-to-miss bug (see the `layrz-ui-selection-magnifier` skill for a concrete case where the wrong one strips a feature from a real target platform).
- **`isDark`/`brightness` are BETA and unsupported for feature work** — this design system is light-mode only (decision D7); dark-mode branches should not be introduced against these getters.
