---
name: layrz-ui-skeleton
description: Use LayrzSkeleton in a layrz_ui Flutter widget. Apply when rendering a loading placeholder — compose LayrzSkeletonBox/LayrzSkeletonCircle/LayrzSkeletonLine into the shape of the real content, driven by one shared shimmer sweep, with reduced-motion support and a LayrzSkeletonBox.input preset.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. `LayrzSkeleton` and its shape primitives have no enum parameters — dimensions are plain `double`s.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A loading placeholder for content that hasn't arrived yet — a profile card, a list row, a form about to hydrate.
- `LayrzSkeleton` does **not** render any shape itself and cannot silhouette an arbitrary real widget automatically — you compose its `child` out of the three shape primitives (`LayrzSkeletonBox`, `LayrzSkeletonCircle`, `LayrzSkeletonLine`) in the same layout (`Row`/`Column`/nesting) the real content will eventually use.
- Use `LayrzSkeletonBox.input` specifically to stand in for a `LayrzTextInput`/similar field at its standard (non-dense, regular-viewport) height, instead of guessing dimensions by hand.
- **Do not use** for a spinner/indeterminate progress indicator with no known content shape — use a progress indicator widget instead.
- **Do not use** to wrap a real widget expecting it to be auto-silhouetted — there is no such mode; you must build the placeholder shape yourself.

---

## Minimal usage

```dart
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
```

---

## Key behaviors

- `LayrzSkeleton` owns exactly **one** shared shimmer `AnimationController`, exposed to every descendant primitive so the whole subtree shimmers in phase — there is no per-primitive drift.
- Each primitive honours its explicit `width`/`height`/`diameter` exactly — none imposes a minimum size. Get those dimensions to match the real content and the loading state occupies exactly the box the real content will occupy, so nothing jumps when it arrives.
- Used standalone (outside a `LayrzSkeleton` ancestor), a primitive still shimmers via its own self-owned fallback ticker — it renders sensibly in isolation (a catalog page, a unit test) rather than sitting static.
- Respects `MediaQuery.disableAnimationsOf` (reduced motion): when true, no `AnimationController` is created at all and the whole `child` renders as a static block. Re-evaluated on every rebuild, so toggling the OS setting live starts/stops the shimmer without remounting.
- The entire `child` subtree is wrapped once in `Semantics(label: 'Loading')` — a screen reader announces "Loading" exactly once for the whole placeholder, not once per shape primitive.

---

## Common patterns

```dart
// 1. Profile-card skeleton
LayrzSkeleton(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LayrzSkeletonCircle(diameter: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayrzSkeletonLine(width: 140, matchTextStyle: context.tokens.typography.title),
              const SizedBox(height: 6),
              const LayrzSkeletonLine(width: 200),
              const SizedBox(height: 12),
              const LayrzSkeletonBox(width: double.infinity, height: 80, borderRadius: 8),
            ],
          ),
        ),
      ],
    ),
  ),
)

// 2. Form-field loading state, matching LayrzInput's standard height
LayrzSkeleton(
  child: LayrzSkeletonBox.input(width: double.infinity),
)

// 3. Line matched to a real text style, so the placeholder's height agrees
LayrzSkeletonLine(width: 160, matchTextStyle: context.tokens.typography.body)

// 4. Conditional real-content-vs-skeleton swap
isLoading
    ? LayrzSkeleton(child: profileSkeletonTree)
    : ProfileCard(user: user)
```

---

## Usage conventions

- Match the skeleton's shape and dimensions to the real content it stands in for — a mismatched skeleton (wrong height, wrong width) causes a layout jump the moment real content replaces it.
- Prefer `matchTextStyle` over guessing a `height` on `LayrzSkeletonLine` whenever the real content is text with a known `TextStyle` — it derives the correct line-box height automatically.
- Reach for `LayrzSkeletonBox.input` for standard (non-dense, regular-viewport) input placeholders; fall back to the plain `LayrzSkeletonBox` constructor with an explicit `height` for dense or compact-viewport inputs, which the preset does not cover.
- Swap the whole skeleton tree out for real content in one conditional (`isLoading ? skeleton : realWidget`) rather than toggling visibility — a skeleton hidden-but-mounted still runs its shimmer ticker needlessly.
