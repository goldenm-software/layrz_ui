# LayrzSkeleton — API Reference

Source: `lib/src/skeleton/src/skeleton.dart`
- `LayrzSkeleton` class
- `LayrzSkeletonBox` companion — `lib/src/skeleton/src/skeleton_box.dart`
- `LayrzSkeletonCircle` companion — `lib/src/skeleton/src/skeleton_circle.dart`
- `LayrzSkeletonLine` companion — `lib/src/skeleton/src/skeleton_line.dart`

---

## Examples

```dart
// Basic composed skeleton
LayrzSkeleton(
  child: Row(
    children: [
      const LayrzSkeletonCircle(diameter: 40),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LayrzSkeletonLine(width: 120),
          SizedBox(height: 6),
          LayrzSkeletonLine(width: 80),
        ],
      ),
    ],
  ),
)

// Box with rounded corners, e.g. standing in for an image
const LayrzSkeletonBox(width: double.infinity, height: 80, borderRadius: 8)

// Input-preset box
LayrzSkeletonBox.input(width: double.infinity)

// Circle, e.g. an avatar
const LayrzSkeletonCircle(diameter: 48)

// Line matched to a known text style
LayrzSkeletonLine(width: 140, matchTextStyle: context.tokens.typography.title)

// Line with an explicit height (overrides matchTextStyle if both given)
const LayrzSkeletonLine(width: 200, height: 16)

// Standalone primitive, no LayrzSkeleton ancestor (self-owned fallback ticker)
const LayrzSkeletonBox(width: 120, height: 40)
```

---

## Constructor

### `LayrzSkeleton`

```dart
const LayrzSkeleton({super.key, required this.child});
```

### `LayrzSkeletonBox`

```dart
const LayrzSkeletonBox({
  super.key,
  required this.width,
  required this.height,
  this.borderRadius = 0.0,
});

const LayrzSkeletonBox.input({
  super.key,
  required this.width,
  double? borderRadius,
}) : height = kLayrzSkeletonInputHeight,           // 43.0
     borderRadius = borderRadius ?? kLayrzSkeletonInputRadius; // 10.0
```

### `LayrzSkeletonCircle`

```dart
const LayrzSkeletonCircle({super.key, required this.diameter});
```

### `LayrzSkeletonLine`

```dart
const LayrzSkeletonLine({
  super.key,
  required this.width,
  this.height,
  this.matchTextStyle,
  this.borderRadius = kDefaultLayrzSkeletonLineRadius, // 4.0
});
```

No constructor asserts on any of these four types.

---

## Properties

### `LayrzSkeleton`

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | — | **Required.** The tree of skeleton shape primitives the caller composes into the shape of the real widget being loaded. Its composition is entirely up to the caller — nothing is inferred. |

### `LayrzSkeletonBox`

| Property | Type | Default | Notes |
|---|---|---|---|
| `width` | `double` | — | **Required.** Box width in logical pixels, honored exactly (no minimum imposed). |
| `height` | `double` | — | **Required** on the default constructor; fixed to `kLayrzSkeletonInputHeight` (43.0) on `.input`. |
| `borderRadius` | `double` | `0.0` | Corner radius, in logical pixels. On `.input`, defaults to `kLayrzSkeletonInputRadius` (10.0) when not overridden. |

### `LayrzSkeletonCircle`

| Property | Type | Default | Notes |
|---|---|---|---|
| `diameter` | `double` | — | **Required.** Both width and height of the circle, in logical pixels. |

### `LayrzSkeletonLine`

| Property | Type | Default | Notes |
|---|---|---|---|
| `width` | `double` | — | **Required.** Line width in logical pixels. |
| `height` | `double?` | `null` | Explicit height. Takes precedence over `matchTextStyle` when both are supplied. Falls back to `kDefaultLayrzSkeletonLineHeight` (12.0) when both `height` and `matchTextStyle` are null. |
| `matchTextStyle` | `TextStyle?` | `null` | A `TextStyle` to derive the line's height from (`fontSize * (style.height ?? 1.2) + 0.5`), matching the real text's line-box height it stands in for. Ignored when `height` is explicitly set. |
| `borderRadius` | `double` | `kDefaultLayrzSkeletonLineRadius` (4.0) | Corner radius — softer/pill-leaning by default, unlike `LayrzSkeletonBox`'s sharp-corner default. |

---

## Companion widgets

`LayrzSkeletonBox`, `LayrzSkeletonCircle`, and `LayrzSkeletonLine` are the three shape primitives exported alongside `LayrzSkeleton` from the `skeleton` barrel (`lib/src/skeleton/skeleton.dart`). They are always used as descendants inside `LayrzSkeleton.child`, but each also works standalone (outside any `LayrzSkeleton` ancestor) via a self-owned fallback shimmer ticker (`LayrzSkeletonShimmerBox`), so a single primitive renders sensibly in isolation — a widget catalog page, a unit test — without needing a wrapping `LayrzSkeleton`.

### `LayrzSkeletonBox.input` — known limitation

The preset's fixed `height` (43.0) matches only the **non-dense, regular-viewport** (≥ 960px) `LayrzInput` chrome. It does **not** cover the dense variant (~35lp tall) or the compact-viewport variant (~51lp tall) — use the default `LayrzSkeletonBox` constructor with an explicit `height` for those.

---

## Behavior notes

- **One shared shimmer**: `LayrzSkeleton` owns exactly one `AnimationController` (duration `tokens.motion.dIndeterminate`, repeating) and exposes it to descendants via `LayrzSkeletonScope`, an `InheritedWidget`. Every primitive inside `child` shimmers in phase — there is no per-primitive drift, since only one ticker drives the whole subtree.
- **Reduced motion**: when `MediaQuery.disableAnimationsOf(context)` is true, `LayrzSkeleton` creates no `AnimationController` at all — `child` renders as a static block, no scheduled frames. This is re-evaluated on every `didChangeDependencies`/`didUpdateWidget`, so an OS-level toggle mid-session starts or stops the sweep live, no remount required.
- **No-reflow guarantee**: `LayrzSkeleton` imposes no sizing of its own — it defers entirely to `child`'s intrinsic size. Every shape primitive honors its explicit dimensions exactly (no minimum, no clamp), so getting those dimensions to match the real content guarantees no layout jump when the real content replaces the skeleton.
- **Semantics**: the whole `child` subtree is wrapped in `ExcludeSemantics`, then in one outer `Semantics(label: 'Loading', container: true)` — a screen reader announces "Loading" exactly once for the entire placeholder, not once per shape primitive inside it.
- **Antialiasing fix**: each shape's fill paints without antialiasing so its edge agrees exactly with the shimmer's `ShaderMask` mask edge — this is what eliminates a hairline seam that would otherwise appear on every shape (box, circle, line).
