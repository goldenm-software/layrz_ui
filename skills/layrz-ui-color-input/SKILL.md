---
name: layrz-ui-color-input
description: Use LayrzColorInput in a layrz_ui Flutter widget. Apply when adding a single-color selection field — swatch + hex anchor field that opens a Palette/Wheel picker surface, staged-with-Save commit, no Clear action.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any single-color selection field: brand accent color, tag color, chart series color, status color override.
- Supply `palette` (a `Set<Color>`) whenever the product has a fixed brand/semantic swatch set the user should pick from first — the Palette tab renders it as a grid.
- Omit `palette` (leave it `{}`) when there is no fixed set — the surface opens directly on the Wheel tab (HSV disc + brightness slider), since a Palette tab with nothing in it would just be a dead empty grid.
- **Do not use** for a boolean/enum status badge color you compute yourself — hardcode the design-token color instead of asking the user to pick it.
- **Do not use** for image/avatar upload — that is a file-picker concern outside this widget's scope.

---

## Minimal usage

```dart
LayrzColorInput(
  labelText: LayrzUiL10n.of(context).save,
  value: accentColor,
  onChanged: (value) {
    accentColor = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `value` (`Color`, required) is always the *committed* color — the field's swatch and hex readout mirror `value`, never an in-progress draft.
- **Staged-with-Save, not commit-on-tap.** Tapping a swatch, dragging the wheel disc, or a successful hex paste only updates the surface's own draft; `onChanged` fires exactly once, when the user presses **Save**. **Cancel** discards the draft. Escape and a barrier tap (tap outside the dialog/sheet) both behave like Cancel.
- **No Clear action** — a color field always has exactly one selected color; there is nothing to reset to "empty" independently of Cancel, so the actions row is Cancel/Save only.
- **Paste is a visible button, never an ambient clipboard read.** The surface never reads the clipboard on open, on tab switch, or on a timer — only when the user presses the labeled Paste button. A paste that fails to parse as `#RRGGBB`/`RRGGBB` is a silent no-op; the draft is left unchanged.
- Empty `palette` (the default `{}`) hides the Palette tab entirely and opens the surface on Wheel.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.
- `disabled: true` makes the field fully non-interactive; tapping it does nothing.
- Opens via a centered dialog at viewports `>= 960px` (`!context.isCompact`) or a bottom sheet below that — this is automatic, never branch on it yourself.

---

## Common patterns

```dart
// 1. With a caller-supplied brand palette
LayrzColorInput(
  labelText: LayrzUiL10n.of(context).save,
  value: tagColor,
  palette: const {
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF2196F3),
    Color(0xFFFFCA28),
  },
  errors: tagColorErrors,
  onChanged: (value) {
    tagColor = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. Wheel-only (no palette supplied)
LayrzColorInput(
  labelText: 'Chart series color',
  value: seriesColor,
  onChanged: (value) => setState(() => seriesColor = value),
)

// 3. Disabled, read-only display of a fixed color
LayrzColorInput(
  labelText: 'System color',
  value: systemColor,
  disabled: true,
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` when the string is a real product string.
- Pass `errors: <List<String>>` computed and owned by your own form validation — there is no `context.getErrors` in layrz_ui.
- Separate stacked inputs with `const SizedBox(height: 10)`.
- Since there is no Clear action, a "no color chosen yet" state must be modeled by the caller (e.g. a nullable field defaulting to a sentinel color before first save) — `value` itself is never null.
