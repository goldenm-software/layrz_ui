---
name: layrz-ui-month-range-input
description: Use LayrzMonthRangeInput in a layrz_ui Flutter widget. Apply when adding a multi-month selection field — supports arbitrary (non-contiguous) multi-select and consecutive (contiguous) range modes, mutually exclusive via `consecutive`.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Selecting several months at once — arbitrary (any set, any order) by default, or a contiguous span via `consecutive: true`.
- **This is the only picker in the pickers module where a non-contiguous selection is reachable.** Every other range widget (date, time, datetime) is contiguous-only.
- **Do not use** for a single month — use `LayrzMonthInput` instead.
- **Do not use** for a contiguous date span — use `LayrzDateRangeInput` instead.

---

## Minimal usage

```dart
// Arbitrary (default) mode
LayrzMonthRangeInput(
  labelText: 'Reporting months',
  arbitraryValue: months,
  errors: monthsErrors,
  onArbitraryChanged: (value) {
    months = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **`consecutive` selects the mode** — `false` (default) is arbitrary multi-select; `true` is a contiguous range, behaving like `LayrzDateRangeInput`'s endpoint-adjust state machine (empty → anchor → complete-with-auto-swap → re-tap adjusts an endpoint → interior tap rejected → outside tap extends the nearer endpoint).
- **Value/callback pair depends on mode.** Arbitrary mode uses `arbitraryValue` (`List<LayrzMonth>`) / `onArbitraryChanged`; consecutive mode uses `rangeValue` (`LayrzMonthRange?`) / `onRangeChanged`. Only the pair matching `consecutive` is meaningful — the other is ignored.
- **Staged with Save** — Cancel/Save live inside the panel, visible from the first frame, in both modes. Tapping months only updates the draft; `onChanged*` fires once, on Save. Involuntary close discards the draft; reopening always starts clean from `arbitraryValue`/`rangeValue`.
- `disabledMonths` is **ignored in consecutive mode** — it only applies to arbitrary mode.
- Visuals differ by mode: consecutive selections render as one flat continuous bar (no per-cell shape, matching `LayrzDateRangeInput`'s "no circles" convention); arbitrary selections keep individual filled, rounded pills per month, since there is no adjacency to draw a bar under.
- `arbitraryFormatter`/`rangeFormatter` fully override the summary text for their mode, taking precedence over `arbitraryPattern`/`rangePattern` (`strftime`-style, defaulting to `'%b %Y'` and `'%B %Y'` respectively).
- In arbitrary mode, the summary is a comma-joined list of formatted months; past 4 selected months it collapses to a localized count instead of listing every one.

---

## Common patterns

```dart
// 1. Consecutive (contiguous) range mode
LayrzMonthRangeInput(
  labelText: 'Fiscal quarter',
  consecutive: true,
  rangeValue: quarter,
  errors: quarterErrors,
  onRangeChanged: (value) {
    quarter = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. Arbitrary mode bounded to a year
LayrzMonthRangeInput(
  labelText: 'Closed months',
  arbitraryValue: closedMonths,
  minimum: LayrzMonth(year: 2026, month: 1),
  maximum: LayrzMonth(year: 2026, month: 12),
  onArbitraryChanged: (value) => setState(() => closedMonths = value),
)

// 3. Custom range pattern (abbreviated endpoints)
LayrzMonthRangeInput(
  labelText: 'Coverage period',
  consecutive: true,
  rangeValue: coverage,
  rangePattern: '%b %Y',
  onRangeChanged: (value) => setState(() => coverage = value),
)
```

---

## Form conventions

- Guard async `onArbitraryChanged`/`onRangeChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller computes and owns the list. Span-length limits ("max 6 months") are a caller validation concern, not a widget parameter.
- Separate stacked inputs with `SizedBox(height: 10)` (or the host app's own spacing tokens).
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
