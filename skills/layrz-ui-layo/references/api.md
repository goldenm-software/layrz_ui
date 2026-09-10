# Layo — API Reference

> **No wiki page exists for this component.** This reference is authored entirely from source doc comments (`lib/src/layo/src/*.dart`) — flag any future drift between this file and the code to the maintainer.

Source: `lib/src/layo/src/layo.dart`, `avatar_layo.dart`, `transitioned_layo.dart`, `transitioned_avatar_layo.dart`, `layo_controller.dart`, `layo_emotion.dart`, `layo_avatar_shape.dart`
- `Layo` class (`StatefulWidget`) — `layo.dart`
- `AvatarLayo` class (`StatelessWidget`) — `avatar_layo.dart`
- `TransitionedLayo` class (`StatefulWidget`) — `transitioned_layo.dart`
- `TransitionedAvatarLayo` class (`StatefulWidget`) — `transitioned_avatar_layo.dart`
- `LayoController` class (`ChangeNotifier`) — `layo_controller.dart`
- `LayoEmotion` enum (24 values) — `layo_emotion.dart`
- `LayoAvatarShape` enum — `layo_avatar_shape.dart`

---

## Examples

```dart
// Full mascot, size-automatic
const Layo(width: 240)

// Specific emotion, static (no idle animation)
const Layo(width: 120, emotion: .success, animate: false)

// Cropped avatar
const AvatarLayo(width: 40, emotion: .thinking)
const AvatarLayo(width: 48, shape: .roundedBox, emotion: .working)

// Controller-driven transitions
final controller = LayoController(initialEmotion: .mrLayo);
TransitionedLayo(controller: controller, width: 200)
TransitionedAvatarLayo(controller: controller, width: 48, shape: .circle)

controller.to(.success); // re-bases from wherever the mascot visually is now
```

---

## `Layo` constructor

```dart
const Layo({
  this.width,
  this.animate = true,
  this.emotion = LayoEmotion.mrLayo,
  super.key,
});

static const double _aspectRatio = 500 / 833; // fixed, not a parameter
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `width` | `double?` | `null` | `null` → fills parent width, derives height from the fixed 500:833 aspect ratio (requires a bounded parent width). Set explicitly in an unbounded context (e.g. a scrolling `Column`) — `AspectRatio` throws otherwise. |
| `animate` | `bool` | `true` | Plays `emotion`-appropriate idle animations, further gated by `TickerMode` (paused off-screen) and `MediaQuery.disableAnimations` (reduced motion) automatically. `false` forces the static look unconditionally. `.dead`'s resting drooped antenna is a static pose either way — only its recurring twitch is suppressed. |
| `emotion` | `LayoEmotion` | `.mrLayo` | Which face renders. See the enum table below. |

---

## `AvatarLayo` constructor

```dart
const AvatarLayo({
  this.shape = LayoAvatarShape.circle,
  this.emotion = LayoEmotion.mrLayo,
  this.width,
  this.animate = true,
  super.key,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `shape` | `LayoAvatarShape` | `.circle` | Silhouette the avatar clips to — applies to background fill, ring, and clip boundary alike. |
| `emotion` | `LayoEmotion` | `.mrLayo` | Passed through to the inner `Layo`; also resolves the fixed background/ring colors via `avatarBackgroundFor`/`avatarRingFor`. |
| `width` | `double?` | `null` | `null` → fills parent width (via an inner `AspectRatio` of `1.0`); always square regardless of `Layo`'s own body proportions. |
| `animate` | `bool` | `true` | Passed straight through to the inner `Layo`. |

Composition: an inner `Layo`, rendered **larger than the avatar frame** and shifted upward inside an `OverflowBox`, then clipped to `shape` via `ClipRRect` — a portrait crop of the head/antenna/upper shoulders, the rest cropped away. Border color and width are fixed, not parameters.

---

## `LayoAvatarShape` enum

| Value | Shape |
|---|---|
| `.circle` | Full circle — corner radius always exactly half the side length. Default; matches the reference mailer avatar. |
| `.roundedBox` | Rounded-corner square — moderate radius proportional to size, boxier than `.circle`. |

---

## `TransitionedLayo` constructor

```dart
const TransitionedLayo({
  required this.controller,
  this.initialEmotion = LayoEmotion.mrLayo,
  this.width,
  this.animate = true,
  super.key,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `controller` | `LayoController` | **required** | The controller whose `to()` calls this widget listens to and animates. Disposal is caller-owned — this widget never disposes it. |
| `initialEmotion` | `LayoEmotion` | `.mrLayo` | Used only for the very first frame, before `controller` has been read — in practice this widget reads `controller.target` on `initState`, so this matters only if the fallback should differ from the controller's own starting emotion. |
| `width` | `double?` | `null` | Same sizing contract as `Layo.width`. |
| `animate` | `bool` | `true` | Gates whether transitions crossfade (~280ms) vs. hard-cut, and is forwarded to every inner `Layo` for its own idle animations. `MediaQuery.disableAnimations` forces a hard cut regardless. |

---

## `TransitionedAvatarLayo` constructor

```dart
const TransitionedAvatarLayo({
  required this.controller,
  this.shape = LayoAvatarShape.circle,
  this.initialEmotion = LayoEmotion.mrLayo,
  this.width,
  this.animate = true,
  super.key,
});
```

Same parameters as `TransitionedLayo` plus `shape` (`LayoAvatarShape`, default `.circle`, same role as `AvatarLayo.shape`) — this widget additionally lerps its own background/ring color across the transition, alongside the inner `TransitionedLayo`'s face crossfade.

---

## `LayoController` (ChangeNotifier)

```dart
class LayoController extends ChangeNotifier {
  LayoController({LayoEmotion initialEmotion = LayoEmotion.mrLayo});

  LayoEmotion get from;
  LayoEmotion get target;

  void to(LayoEmotion emotion);
  void reportCurrent(LayoEmotion emotion);
}
```

| Member | Notes |
|---|---|
| `initialEmotion` (constructor param) | Starting emotion — `from`, `target`, and the internal "currently visible" estimate all start here. |
| `from` (getter) | The emotion the current/most-recent transition started from. |
| `target` (getter) | The emotion this controller currently targets. |
| `to(emotion)` | **The only mutating method.** No-op if `emotion == target`. Otherwise re-bases: `from` becomes wherever the mascot visually is right now (per `reportCurrent`), `target` becomes `emotion`, listeners notified. **Deliberately no queue** — a re-base discards whatever an in-flight transition was headed toward. |
| `reportCurrent(emotion)` | Called by `TransitionedLayo` on every animation frame during a transition (and once more when it settles) to report the actually-visible emotion — this is what a re-basing `to()` call reads as its new `from`. A caller never attaching a `TransitionedLayo` (e.g. in a test) can simply never call this. |

**Architecture note**: mirrors `LayrzStepperController`/`LayrzButtonController` in spirit — the controller owns only intent/state, no `AnimationController`/vsync of its own; `TransitionedLayo` owns the ticker and drives the actual `0..1` progress.

---

## `LayoEmotion` enum (24 values)

Every value shares the same base artwork (body, face shadow, screen, ears, head shell) and the bow-tie (worn by all except `comandante`, `christmas`, `party`). Differs in antenna-tip color, screen glyph(s), and idle animation.

| Value | Antenna color | Idle animation |
|---|---|---|
| `mrLayo` (default) | Blue | Periodic two-eye blink |
| `question` | Grey | "?" wiggle (replaces blink) |
| `sleep` | Grey | Staggered "zzz" opacity fade |
| `dead` | Grey | Recurring "failed twitch" (antenna rests drooped always; no antenna pulse) |
| `love` | Bright red | "Heartbeat" double-thump scale pulse (heart eyes + antenna dot, looping) |
| `angry` | Crimson | Jittered "furrow + tremble" burst |
| `alert` | Orange | Snappy top-widening attention pulse on both "!" glyphs, looping |
| `layo404` | Grey | Occasional glitch/flicker (opacity + jitter) |
| `idea` | Yellow | Continuous glow-pulse + occasional "insight" flash |
| `comandante` | **No antenna** | Periodic right-eye-only wink (Chávez-style); no bow-tie; wears a beret overlay + chest ribbon rack |
| `money` | Green | `$`-eye shimmer + looping "rain of bills" background layer |
| `thinking` | Blue (unchanged) | Looping thought-connector-circle sequence |
| `listening` | Teal | Looping independently-bouncing equalizer bars |
| `sad` | Grey | Tear-drip (more frequent than blink: 1.5-2.5s vs 3-6s) |
| `success` | Green | Check-mark stroke draw-in + pop/bounce settle, on appearance and replay |
| `excited` | Yellow | Continuous star-eye twinkle + energetic bounce, looping |
| `searching` | Blue (unchanged) | Looping side-to-side magnifier scan |
| `working` | Amber | Looping counter-rotating gear pair |
| `wink` | Blue (unchanged) | Periodic right-eye-only wink (independent of `comandante`'s) |
| `mindBlown` | Magenta | Continuous spiral-eye spin + jittered "pop" burst |
| `smug` | Blue (unchanged) | Subtle jittered lid/smirk-raise pulse |
| `cool` | Blue (unchanged) | Jittered gleam sweep on sunglasses lens (more frequent: 1.5-3s); wears sunglasses overlay |
| `christmas` | Festive red; **no antenna** | Looping snowfall background + pom-pom sway; also plays `mrLayo`'s blink; wears Santa hat overlay + body sweater overlay; no bow-tie |
| `party` | Festive pink (`kPartyPink`); **no antenna** | Looping confetti background + pom-pom bob; also plays `mrLayo`'s blink; wears party-hat overlay; **keeps** the bow-tie (colored pink) |

`comandante`, `christmas`, and `party` are the only three emotions with **no antenna at all** — an overlay (beret / Santa hat / party hat) sits exactly where the antenna would.

---

## Avatar background/ring palette (`avatar_layo.dart`)

Fixed, not overridable — grouped by hue family:

| Color | Emotions |
|---|---|
| Blue (`ARGB(255,27,52,108)`) | `mrLayo`, `question`, `searching`, `thinking`, `wink`, `smug`, `cool` |
| Teal (`0xFF0E7C77`) | `listening` |
| Orange (`0xFFF57C00`) | `alert` |
| Yellow (`0xFFF5B800`) | `excited`, `idea` |
| Grey (`0xFF8A8A8A`) | `sleep`, `dead`, `sad`, `layo404` |
| Purple (`0xFF7B1FA2`) | `mindBlown` |
| Green (`0xFF1B7A3D`) | `christmas`, `money`, `success` |
| Deep dark red (`0xFF7A1620`) | `comandante`, `love`, `angry` |
| Brown (`0xFF6B4423`) | `working` |
| Party pink (`0xFFD81B8C`) | `party` |

The ring color is each background darkened by `Color.lerp(..., black, 0.35)` (`_kAvatarRingDarkenFactor`). The `switch` mapping emotion → background is exhaustive with no `default` arm — adding a new `LayoEmotion` forces a compile error here until a color is assigned.

---

## Behavior notes

- **Name has no `Layrz` prefix, deliberately** — `Layo` is a brand asset, not a themeable UI primitive (decision D11 in `engineering/decisions.md`).
- **Pure `CustomPainter`.** No bundled image or SVG asset anywhere — every frame is traced/painted procedurally by `LayoPainter`.
- **Repaint isolation.** Every idle animation feeds a single `AnimatedBuilder` wrapping only the `CustomPaint` — an animating `Layo` repaints just its own paint layer every frame; no ancestor rebuilds, no `setState` for animation ticks.
- **Off-screen pause.** Looping animations pause (and blink/twitch/etc. timers cancel) whenever `TickerMode.valuesOf` reports `enabled: false` for the context — e.g. scrolled out of view in a list.
- **Jittered scheduling.** Every recurring one-shot animation (blink, twitch, burst, glitch, flash, wink, tear, etc.) uses a per-instance randomized interval (typically 3-6s, `sad`/`cool` faster) so multiple `Layo` instances on screen never fire in unison.
