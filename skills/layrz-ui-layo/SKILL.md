---
name: layrz-ui-layo
description: Use Layo in a layrz_ui Flutter widget. Apply when rendering the "MrLayo" brand mascot — 24 LayoEmotion faces with per-emotion idle animation, AvatarLayo for a cropped portrait frame, TransitionedLayo/TransitionedAvatarLayo for a controller-driven emotion crossfade via LayoController, all pure CustomPainter with zero image/SVG assets.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.mrLayo`, `.circle`) — never the fully-qualified form (`LayoEmotion.mrLayo`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Rendering the Layrz brand mascot — an empty state, a success/error illustration, a chat/assistant avatar, an onboarding screen.
- Use `Layo` for the full-body mascot; use `AvatarLayo` when framing it as a cropped, bordered portrait (chat avatar, profile slot).
- Use `TransitionedLayo`/`TransitionedAvatarLayo` + `LayoController` when the emotion changes over time in response to app state (e.g. reacting to a live event stream) and should crossfade rather than snap.
- **Do not use** `Layo`/`AvatarLayo` for a one-off emotion swap that should animate — swap to the `TransitionedLayo`/`TransitionedAvatarLayo` pair for that; plain `Layo`/`AvatarLayo` rebuild with a hard cut if `emotion` changes directly.
- **Do not use** the `Layrz`-prefixed naming convention when referring to this widget in code or docs — it is deliberately named `Layo`, without the `Layrz` prefix, because it's a brand asset rather than a themeable UI primitive (decision D11).
- **Do not use** for a generic "no data" icon — `Layo` is a specific brand mascot with per-emotion identity; reach for a plain `MdiIcons` glyph for a neutral empty state instead.

---

## Minimal usage

```dart
const Layo(width: 200)
```

---

## Key behaviors

- **Size-automatic.** With no `width`, `Layo` fills the parent's width and derives height from its fixed 500:833 aspect ratio — requires a bounded parent width (a `SizedBox`, `Expanded` in a `Row`, a sized grid cell). In an unbounded context (e.g. inside a scrolling `Column`), pass an explicit `width`.
- **`AvatarLayo` is always square (1:1)**, unlike `Layo` itself — it shows a head-and-shoulders **crop** of the mascot (an oversized inner `Layo`, shifted up, clipped to `shape`), not the whole body.
- **Background and ring are fixed per `emotion`**, not parameters — `avatarBackgroundFor`/`avatarRingFor` derive both from a small fixed palette keyed to emotion families. There is no way to override an avatar's color from outside.
- **Idle animations are `emotion`-specific and automatic** — 24 different animation sets (blink, wink, heartbeat, gear rotation, snowfall, confetti, etc.), gated by `animate` (default `true`), further suppressed automatically by `TickerMode` (off-screen) and `MediaQuery.disableAnimations` (reduced motion) with zero caller effort.
- **`LayoController.to(emotion)` re-bases, never queues.** Calling `to` while a transition is in flight discards whatever it was headed toward and re-directs from wherever the mascot visually is right now — there is no `queue`/`enqueue` method, deliberately: a mascot reacting to live state should always race toward the *latest* truth.
- Calling `to` with the value `target` already holds is a no-op — no transition starts, no listener notified.

---

## Common patterns

```dart
// 1. Static mascot, default face
const Layo(width: 240)

// 2. A specific emotion, no idle animation (e.g. exported/printed view)
const Layo(width: 120, emotion: .success, animate: false)

// 3. Cropped avatar for a chat message
const AvatarLayo(width: 40, emotion: .thinking)

// 4. Rounded-box avatar shape instead of circle
const AvatarLayo(width: 48, shape: .roundedBox, emotion: .working)

// 5. Controller-driven emotion transitions (e.g. reacting to live events)
final controller = LayoController(initialEmotion: .mrLayo);

TransitionedLayo(controller: controller, width: 200)

// elsewhere, in response to app state:
controller.to(.success);
```

---

## `LayoEmotion` quick reference

24 values, each sharing the same base artwork (body, screen, ears, head shell) and differing in screen glyph(s), antenna-tip color, and idle animation:

`mrLayo` (default) · `question` · `sleep` · `dead` · `love` · `angry` · `alert` · `layo404` · `idea` · `comandante` · `money` · `thinking` · `listening` · `sad` · `success` · `excited` · `searching` · `working` · `wink` · `mindBlown` · `smug` · `cool` · `christmas` · `party`

`comandante`, `christmas`, and `party` have **no antenna at all** (an overlay — beret, Santa hat, party hat — sits where the antenna would). See `references/api.md` for the per-value animation and color breakdown.

---

## Usage conventions

- Never construct a `LayoController` inline inside `build()` — it must be a stable, long-lived object (a `State` field, disposed by the caller) exactly like `LayrzButtonController`/`LayrzStepperController`.
- Prefer `TransitionedLayo`/`TransitionedAvatarLayo` over manually rebuilding a plain `Layo`/`AvatarLayo` with a new `emotion` whenever the emotion genuinely represents changing app state the user should perceive as a transition, not a fresh screen.
- Leave `animate: true` (the default) in almost every case — only pass `false` for a deliberately static context (a printed/exported view, a test golden).
- This widget is not documented in the GitHub wiki — treat `lib/src/layo/src/*.dart`'s doc comments as the sole source of truth, and flag any drift you notice back to the maintainer rather than assuming wiki parity exists.
