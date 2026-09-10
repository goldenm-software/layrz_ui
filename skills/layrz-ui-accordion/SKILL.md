---
name: layrz-ui-accordion
description: Use LayrzAccordion in a layrz_ui Flutter widget. Apply when rendering a single, controlled disclosure panel — a fixed leading-icon/title/chevron header, whole-header tap and keyboard activation, and a body that is only built while expanded.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values where applicable — this widget has no enum parameters of its own.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A single collapsible section: "Shipping details", "Advanced settings", an FAQ entry, an optional form section.
- Use when the panel's open/closed state is meaningful to your own view state (you own `expanded` and react to `onExpansionChanged`).
- **Do not use** for a group of panels where only one should stay open at a time — `LayrzAccordion` is a single panel with no group coordination; compose that coordination yourself by driving each instance's `expanded` from shared state.
- **Do not use** to nest one accordion inside another's `body` — this is an explicit v1 non-goal.
- **Do not use** for a fully custom header layout — the leading-icon/title/chevron shape is fixed; there is no free header slot.

---

## Minimal usage

```dart
bool _expanded = false;

LayrzAccordion(
  titleText: 'Shipping details',
  leadingIcon: MdiIcons.truckOutline,
  expanded: _expanded,
  onExpansionChanged: (value) => setState(() => _expanded = value),
  body: const Text('Delivered within 3–5 business days.'),
)
```

---

## Key behaviors

- **Controlled, not stateful.** `LayrzAccordion` holds no expansion state of its own beyond the animation position. `expanded` is the single source of truth; `onExpansionChanged` is the only way the widget asks the caller to change it. There is no internal toggle that can drift from what the caller believes is showing.
- **Whole-header hit target.** The entire header row — leading icon, title, and chevron alike — is a single tap and keyboard (Space/Enter) target, not just the chevron.
- **Collapsed body is genuinely absent from the tree**, not merely hidden. A screen reader walking the tree while collapsed never encounters the body's content. Once expanded (or mid-reveal), the body is built.
- `onExpansionChanged: null` disables the header entirely — no tap, no keyboard activation, no hover/press visuals — though its label and expanded state are still announced.
- `leadingIcon: null` lays out with just the title and trailing chevron; no placeholder space is reserved for a missing icon.
- Interaction states (hover, focus, press) vary only colour — never size, padding, or border width, per design system convention. The header's own height change on expand/collapse is the widget's function, not an interaction state, and is exempt from this rule.

---

## Common patterns

```dart
// Without a leading icon
LayrzAccordion(
  titleText: 'Terms and conditions',
  expanded: _termsExpanded,
  onExpansionChanged: (value) => setState(() => _termsExpanded = value),
  body: const Text('...long terms text...'),
)

// Disabled — no interaction, state still visible
LayrzAccordion(
  titleText: 'Coming soon',
  expanded: false,
  onExpansionChanged: null,
  body: const SizedBox.shrink(),
)

// A group of accordions where only one stays open (caller-composed)
class _FaqSection extends StatefulWidget {
  const _FaqSection();
  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < faqs.length; i++)
          LayrzAccordion(
            titleText: faqs[i].question,
            expanded: _openIndex == i,
            onExpansionChanged: (value) => setState(() => _openIndex = value ? i : null),
            body: Text(faqs[i].answer),
          ),
      ],
    );
  }
}
```

---

## Usage conventions

- Always drive `expanded` from your own state — never assume the widget remembers it across rebuilds.
- Guard async state changes the same way as any other controlled widget: update state synchronously inside `onExpansionChanged`.
- Keep `body` content lightweight when many accordions might be built in a list — since the body is fully absent when collapsed, there is no hidden-widget cost, but a very heavy body still costs a rebuild on every expand.
- For "only one open at a time" behavior, track the open index/id yourself and pass `expanded: openId == thisId` to each instance — do not look for a group API on this widget.
- Localize `titleText` via `LayrzUiL10n.of(context)` — never hardcode strings.
