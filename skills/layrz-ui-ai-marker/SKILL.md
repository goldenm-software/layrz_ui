---
name: layrz-ui-ai-marker
description: Use LayrzAiMarker in a layrz_ui Flutter widget. Apply when disclosing that nearby content was generated or assisted by AI — a fixed-size animated sparkle badge, standalone or overlaid on a corner of another widget via LayrzAiMarker.wrap.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.topRight`, `.bottomLeft`) — never the fully-qualified form (`LayrzAiMarkerPosition.topRight`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any UI surface presenting AI-generated or AI-assisted content that legally requires disclosure: a chat bubble, a generated summary, an auto-filled field, an AI-suggested card.
- Use the bare `LayrzAiMarker()` constructor inline, standalone (e.g. next to a heading).
- Use `LayrzAiMarker.wrap(child:, position:)` to overlay the marker on a corner of another widget without affecting that widget's layout footprint.
- **Do not use** for a generic "new"/"beta" badge — use a plain badge/chip component instead; this marker's disclosure text is legally load-bearing and hardcoded to AI-generation semantics only.
- **Do not use** to convey a loading/busy state — its animation is a "twinkle", never a spinner; use `LayrzProgressBar` for that.

---

## Minimal usage

```dart
// Inline, standalone
const LayrzAiMarker()
```

```dart
// Overlaid on the corner of another widget
LayrzAiMarker.wrap(
  position: .topRight,
  child: LayrzCard(child: Text('This summary was written by AI.')),
)
```

---

## Key behaviors

- **There is no `text`/`label`/`tooltip`/`size` parameter, and none should ever be added.** The disclosure label (`LayrzUiL10n.aiGeneratedLabel`) and tooltip (`LayrzUiL10n.aiGeneratedTooltip`) always come from `LayrzUiL10n.of(context)` and are legally required to read identically everywhere. Localize by providing a `LayrzUiL10n` subclass — never by passing text to this widget.
- The container renders at one fixed 30×30 logical-pixel footprint. There is no way to resize it.
- Every marker carries both a mandatory `Semantics` label and a mandatory `LayrzTooltip` — both always present, never optional.
- **Known, accepted trade-off:** a sighted user who never triggers a screen reader and never hovers/long-presses sees only a bare sparkle with no visible text in the moment. This is deliberate, not a bug.
- Two independent, continuous animations — a staggered star "twinkle" burst and a slowly orbiting glow shadow — both switch off entirely under `MediaQuery.disableAnimationsOf(context)` (reduced motion), rendering a static, settled pose instead.
- `LayrzAiMarker.wrap`'s `isVisible: false` renders only `child` — no marker, no overlay, no disclosure semantics — while keeping the widget tree stable for a toggle.
- Unlike `LayrzBadge`, `child`'s semantics are **not** excluded or merged with the marker's in `.wrap` — both the marker's disclosure and the child's own content are announced independently, since they are two separate facts a screen reader user needs.

---

## Common patterns

```dart
// Standalone marker next to a section heading
Row(
  mainAxisSize: MainAxisSize.min,
  children: const [
    Text('AI Summary'),
    SizedBox(width: 8),
    LayrzAiMarker(),
  ],
)

// Overlaying a chat bubble, anchored top-left
LayrzAiMarker.wrap(
  position: .topLeft,
  child: ChatBubble(text: aiReply),
)

// Toggling disclosure based on content origin
LayrzAiMarker.wrap(
  isVisible: message.isAiGenerated,
  child: MessageCard(message: message),
)
```

---

## Usage conventions

- Never attempt to change the marker's size, star placement, or animation timing — these are internal, hand-tuned constants and are explicitly not public API.
- Never pass a `semanticsLabel`/`tooltip` override, even if one seems available in a similar widget elsewhere — `LayrzAiMarker` has no such parameter by design.
- Place `LayrzAiMarker.wrap` around the smallest widget that represents "this specific content is AI-generated" — do not wrap an entire page or unrelated container.
- When toggling `isVisible`, drive it from a real "was this AI-generated" flag on your data model — never leave it permanently `true` on content that might not be AI-generated.
