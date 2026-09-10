---
name: layrz-ui-image
description: Use LayrzImage in a layrz_ui Flutter widget. Apply when rendering an image from a URL, data-URI, bare base64, or asset path — automatic source detection, SVG routing, decoded-bytes caching, and placeholder/fallback states.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. This widget has no enum parameters of its own beyond native Flutter enums (`BoxFit`, `FilterQuality`, `Alignment`), which already use dot shorthand naturally.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any image whose source format may vary or is not known at compile time — network URL, data-URI, bare base64, or asset path — with **zero caller configuration** to distinguish them.
- Rendering SVGs alongside raster images interchangeably — SVG is auto-detected by `.svg` extension or `image/svg+xml` MIME type.
- Rendering the same base64 payload repeatedly (e.g. in a list) — decoded bytes are cached by source hash.
- **Do not use** for a user avatar specifically — use `LayrzAvatar` (which uses `LayrzImage` internally for its image sources, plus shape/shadow/fallback-to-initials conventions).
- **Do not use** `Image.network`/`Image.asset`/`SvgPicture.*` directly — `LayrzImage` is the house-standard image primitive and already handles error resilience and caching.

---

## Minimal usage

```dart
LayrzImage(
  source: user.avatarUrl,
  width: 64,
  height: 64,
)
```

---

## Key behaviors

- Source resolution order: SVG detection (`.svg` suffix or `image/svg+xml` data-URI) first, then network (`http://`/`https://`), then data-URI (`data:`), then bare base64 (base64-safe charset only), then asset path as the default.
- `placeholder` applies **only** to network sources — asset and data-URI sources load synchronously (or nearly so) and never show it.
- `fallback` renders on any failure: network error, malformed base64, missing asset, unsupported format. No exception is ever raised from `build()`.
- Decoded base64 bytes are cached by source hash, bounded to **50 entries** with FIFO eviction — safe to reuse the same base64 string across many widgets (e.g. a list) without redundant decoding.
- At least one of `width`/`height` should be set — an unconstrained dimension expands to fill available space, which is rarely intended.
- `fit` defaults to `BoxFit.cover` (crops to fill, preserving aspect ratio) — pick `.contain` when you must not crop (e.g. a logo).

---

## Common patterns

```dart
// 1. Network image with placeholder and fallback
LayrzImage(
  source: 'https://example.com/user-avatar.png',
  width: 64,
  height: 64,
  placeholder: const LayrzSkeleton(width: 64, height: 64),
  fallback: const Icon(MdiIcons.accountCircleOutline, size: 64),
)

// 2. Bare base64 in a list (benefits from the decode cache)
ListView.builder(
  itemCount: users.length,
  itemBuilder: (context, index) {
    final user = users[index];
    return LayrzImage(
      source: user.avatarBase64,
      width: 40,
      height: 40,
      fallback: LayrzAvatar.initials(nameText: user.name, size: 40),
    );
  },
)

// 3. SVG from a network URL (auto-detected)
LayrzImage(
  source: 'https://example.com/icon.svg',
  width: 64,
  height: 64,
)

// 4. Asset image, contained (never cropped)
LayrzImage(
  source: 'assets/images/logo.png',
  width: 200,
  height: 100,
  fit: .contain,
)
```

---

## Usage conventions

- Always supply `fallback` for any network- or base64-sourced image where failure is plausible (untrusted user upload, third-party CDN) — an empty blank area reads as a bug to the user.
- Prefer a `LayrzSkeleton` or a themed spinner for `placeholder`, not a raw `CircularProgressIndicator` (Material) or hardcoded color box.
- Set both `width` and `height` whenever the image sits in a fixed-size slot (avatar, thumbnail, icon) — leaving one `null` inside a flexible layout can cause unbounded-constraint layout errors.
- Don't manually branch on source format (`if (url.startsWith('http'))`) before calling `LayrzImage` — pass the raw string and let it detect the format itself.
