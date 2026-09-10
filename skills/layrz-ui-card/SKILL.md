---
name: layrz-ui-card
description: Use LayrzCard in a layrz_ui Flutter widget. Apply when wrapping content in an elevated surface container — five discrete elevation levels (1-5), optional background color override, and optional onTap interactivity with hover/press shadow feedback.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values where applicable — `LayrzCard` itself has no enum parameters (`elevation` is a plain `int`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any elevated content container: a dashboard tile, a grid item, a grouped section on a detail page.
- Use `onTap` when the card as a whole should navigate or trigger an action — the entire surface becomes tappable with hover/press shadow feedback.
- Pick `elevation` (1–5) for visual hierarchy: low elevation for cards at rest inside a list/grid, higher elevation for cards that need to stand out (e.g. a highlighted item, a card inside a dialog).
- **Do not use** for a dialog surface itself — cards are content containers, not modal chrome.
- **Do not use** for a single tappable action with an icon/label — use `LayrzButton` instead; `LayrzCard` is content-shaped, not action-shaped.
- **Do not use** with an outer `margin` — the card has none by design; own inter-card spacing with `LayrzRow`'s or `LayrzConstrainedView`'s `spacing` parameter instead of adding margin here.

---

## Minimal usage

```dart
LayrzCard(
  child: Text('Card content'),
)
```

---

## Key behaviors

- Padding is fixed at `tokens.spacing.sp3` (16lp) on all sides and border radius fixed at `tokens.radius.r3` (16lp) — neither is a constructor parameter.
- `elevation` must be an integer 1–5 inclusive — asserted at construction. Each level maps to a discrete shadow ramp (`tokens.shadow.elevation1`...`elevation5`), not a continuous scale.
- `onTap: null` (default) makes the card fully inert: no cursor change, no hover/press feedback, not focusable, not announced as a button.
- `onTap` non-null makes the card interactive: cursor becomes a pointer, hover/focus steps the shadow **up** one level (clamped at 5), press steps it **down** one level (clamped at 1). Geometry (size, padding, radius) never changes during interaction.
- `backgroundColor: null` (default) resolves to the design system's surface token — pass an explicit `Color` only to override it (e.g. a nested/secondary surface).
- The card has no outer margin by design — spacing between cards is the surrounding layout's responsibility.

---

## Common patterns

```dart
// 1. Static content card
LayrzCard(
  elevation: 1,
  child: Padding(
    padding: const EdgeInsets.all(4),
    child: Text('Read-only summary'),
  ),
)

// 2. Interactive card that navigates on tap
LayrzCard(
  elevation: 2,
  onTap: () => Navigator.of(context).push(...),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Tap me'),
      const SizedBox(height: 8),
      Text('Navigate on tap'),
    ],
  ),
)

// 3. Cards inside a responsive grid, spacing owned by LayrzRow
LayrzRow(
  spacing: 16,
  children: [
    LayrzCol(
      xs: 12,
      md: 6,
      child: LayrzCard(
        elevation: 1,
        onTap: () => onSelectFirst(),
        child: const SizedBox(height: 150, child: Text('Card 1')),
      ),
    ),
    LayrzCol(
      xs: 12,
      md: 6,
      child: LayrzCard(
        elevation: 1,
        onTap: () => onSelectSecond(),
        child: const SizedBox(height: 150, child: Text('Card 2')),
      ),
    ),
  ],
)

// 4. Higher elevation for a card inside a modal/dialog context
LayrzCard(
  elevation: 4,
  child: myDialogBody,
)
```

---

## Usage conventions

- Never pass a `margin`-equivalent wrapper for card-to-card spacing — use `LayrzRow`/`LayrzConstrainedView`'s `spacing` parameter, or an explicit `SizedBox`/`Gap` between cards you place manually.
- Keep `elevation` at 1 for ordinary at-rest content; reserve 4–5 for cards that sit inside an already-elevated context (dialogs, popovers) where they need to visually separate from that context.
- Only pass `onTap` when the entire card surface should be one tap target; if only part of the card is actionable (e.g. a button in the corner), leave `onTap` null and nest a `LayrzButton` inside instead — an interactive card and a nested tappable button both intercepting taps is a conflict to avoid.
- Guard async `onTap` callbacks: `if (context.mounted) callback.call();`
