# LayrzAccordion — API Reference

Source: `lib/src/accordion/src/accordion.dart`
- `LayrzAccordion` class (`StatefulWidget`)
- `lib/src/accordion/src/accordion_style_spec.dart` — `LayrzAccordionStyleSpec` (internal style resolution)

**Note:** the wiki page states this widget is built on the SDK `Expansible` primitive. The current source is hand-rolled directly on `AnimationController` + `CurvedAnimation` instead — `Expansible`'s own height-interpolation and state machine previously produced a janky body reveal, an inconsistent header/body border seam, and a shadow that did not track the reveal cleanly. This reference follows the source; the widget's public contract (controlled `expanded`, whole-header hit target, body absent while collapsed) is unchanged either way.

---

## Examples

```dart
// Basic controlled accordion
bool expanded = false;

LayrzAccordion(
  titleText: 'Shipping details',
  leadingIcon: MdiIcons.truckOutline,
  expanded: expanded,
  onExpansionChanged: (value) => setState(() => expanded = value),
  body: const Text('Delivered within 3–5 business days.'),
)

// Without a leading icon
LayrzAccordion(
  titleText: 'Terms and conditions',
  expanded: expanded,
  onExpansionChanged: (value) => setState(() => expanded = value),
  body: const Text('...'),
)

// Disabled (no onExpansionChanged)
LayrzAccordion(
  titleText: 'Coming soon',
  expanded: false,
  onExpansionChanged: null,
  body: const SizedBox.shrink(),
)
```

---

## Constructor

```dart
const LayrzAccordion({
  super.key,
  required this.titleText,
  required this.body,
  required this.expanded,
  this.onExpansionChanged,
  this.leadingIcon,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `titleText` | `String` | required | Title text displayed in the header. |
| `body` | `Widget` | required | Content revealed below the header while expanded. Only present in the tree while `expanded` is true or the reveal animation is still in flight — genuinely absent (not hidden) otherwise. |
| `expanded` | `bool` | required | Whether the panel is currently expanded. The single source of truth; `LayrzAccordion` never mutates it itself. |
| `onExpansionChanged` | `ValueChanged<bool>?` | `null` | Called with the new desired expansion state when the header is tapped or activated via keyboard (Space/Enter). When `null`, the header is disabled — no tap, no keyboard activation, no hover/press visuals, though label and expanded state are still announced. |
| `leadingIcon` | `IconData?` | `null` | Optional icon displayed before the title in the header. When `null`, no placeholder space is reserved for it. |

---

## Behavior notes

- **Single panel, not a group.** Group coordination (only one panel open at a time), nesting one accordion inside another's body, and a free-form header slot are all explicit v1 non-goals. A caller needing group behavior composes it externally, driving each instance's `expanded` from shared state (e.g. tracking an "open index").
- **Controlled, not stateful.** The only internal state is the animation position tracking toward `expanded`; there is no drift-prone internal toggle.
- **Whole-header hit target.** The entire header row (leading icon, title, chevron) is one `GestureDetector`/`Focus` target — not just the chevron. This is a hard requirement, since a chevron-only hit target is the most common real-world complaint about disclosure widgets.
- **Collapsed body is genuinely absent from the tree.** The body subtree is only built while the reveal animation is above `0.0` or mid-flight toward it; once fully collapsed and settled (`AnimationController.isDismissed`), it renders `SizedBox.shrink()` instead of an `Offstage`/hidden widget.
- **Motion.** The reveal always drives a single `CurvedAnimation` built from `LayrzMotionTokens.easingEmphasized` (`Curves.easeInOutCirc` by default) over `LayrzMotionTokens.dTransition` — never a hardcoded curve/duration. The header's own hover/press/focus color transition animates independently on the snappier `LayrzMotionTokens.dHover`, since that concern is unrelated to the expand/collapse timeline.
- **One continuous border around the whole panel, present only while collapsed.** A single outer shell wraps both header and body in one bordered `DecoratedBox` so the border traces one continuous rounded rectangle. Border and elevation shadow are mutually exclusive across the expand state — fully collapsed the border is full-alpha and the shadow invisible; fully expanded the shadow is full-strength and the border fully transparent; between the two, both cross-fade on the same progress. Corner radius on the outer shell is constant (`tokens.radius.r2`) in every expansion state.
- **Interaction states vary colour only** (decision D15) — never size, padding, or border width. The header's own height change on expand/collapse is the widget's function, not an interaction state, and is exempt from this rule.
- Keyboard activation: `Space` or `Enter` while the header has focus toggles the panel identically to a tap.
