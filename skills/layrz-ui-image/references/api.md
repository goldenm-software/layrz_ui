# LayrzImage — API Reference

Source: `lib/src/images/src/image.dart` (source-detection helpers in `lib/src/images/src/image_source.dart`)
- `LayrzImage` class

---

## Examples

```dart
// Network raster image
LayrzImage(
  source: 'https://example.com/user-avatar.png',
  width: 64,
  height: 64,
  fit: .cover,
  placeholder: Container(color: context.theme.tokens.colors.sf2),
  fallback: const Icon(MdiIcons.accountCircleOutline, size: 64),
)

// Data-URI (base64)
LayrzImage(
  source: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
  width: 48,
  height: 48,
)

// Bare base64 (no data: prefix)
LayrzImage(
  source: base64ImageData,
  width: 40,
  height: 40,
  fit: .cover,
  fallback: Container(color: context.theme.tokens.colors.sf3),
)

// Asset path
LayrzImage(
  source: 'assets/images/logo.png',
  width: 200,
  height: 100,
  fit: .contain,
)

// SVG (auto-detected from data-URI MIME type)
LayrzImage(
  source: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPC9zdmc+',
  width: 100,
  height: 100,
)
```

---

## Constructor

```dart
const LayrzImage({
  super.key,
  required this.source,
  this.width,
  this.height,
  this.fit = BoxFit.cover,
  this.alignment = Alignment.center,
  this.filterQuality = FilterQuality.medium,
  this.placeholder,
  this.fallback,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `source` | `String` | — | Required. An http(s) URL, `data:` URI, bare base64 string, or asset path. |
| `width` | `double?` | `null` | Unconstrained when `null`. Set at least one of `width`/`height`. |
| `height` | `double?` | `null` | Unconstrained when `null`. |
| `fit` | `BoxFit` | `BoxFit.cover` | How the image fills its bounds. |
| `alignment` | `Alignment` | `Alignment.center` | Position within bounds when `fit` does not fill them entirely. |
| `filterQuality` | `FilterQuality` | `FilterQuality.medium` | Resampling quality; `.high` for quality, `.low` for performance. |
| `placeholder` | `Widget?` | `null` | Shown while a **network** image loads. Ignored for asset/data-URI sources. `null` shows a blank area while loading. |
| `fallback` | `Widget?` | `null` | Shown on any failure (network error, malformed base64, missing asset, unsupported format). `null` shows a blank area on error. |

---

## Source format resolution (in order)

| # | Detection | Routed to |
|---|---|---|
| 1 | Path ends with `.svg`, or data-URI MIME type is `image/svg+xml` | `SvgPicture.network` / `.memory` / `.asset` |
| 2 | Starts with `http://` or `https://` | `Image.network` (raster) |
| 3 | Starts with `data:` | Decoded to bytes → `Image.memory` |
| 4 | Base64-safe charset only (`[A-Za-z0-9+/=]`), no `http`/`data:` prefix, no `.svg` suffix | Decoded to bytes → `Image.memory` |
| 5 | Anything else | `Image.asset` |

---

## Behavior notes

- **Malformed base64**: caught internally; `build()` never throws. `fallback` renders instead.
- **Decoded-bytes cache**: keyed by source string hash, capped at **50 entries**, FIFO (oldest-inserted) eviction. Avoids redundant decoding of the same base64 payload across list items or repeated renders. Network images rely on Flutter's own built-in image cache instead — transparent to the caller.
- **SVG placeholder/fallback**: apply the same way as raster — `placeholder` only for network SVGs (via `SvgPicture.network`'s `placeholderBuilder`), `fallback` on decode/asset failure.
- **No Material dependency**: built only on `package:flutter/widgets.dart` + `package:flutter_svg`.
- **Companion**: `LayrzAvatar`'s `.image()` constructor and its `LayrzAvatarUrl`/`LayrzAvatarBase64` sources route through `LayrzImage` internally — see the `layrz-ui-avatar` skill for avatar-specific shape/shadow/fallback conventions layered on top.
