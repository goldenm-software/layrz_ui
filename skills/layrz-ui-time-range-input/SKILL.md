---
name: layrz-ui-time-range-input
description: Use LayrzTimeRangeInput in a layrz_ui Flutter widget. Apply when adding a start/end time-of-day field — two digital-clock digit-box clusters, in-panel Cancel/Save always-enabled commit, midnight-default endpoints.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any start/end time-of-day field with no date component: shift window, daily opening hours, quiet hours.
- **Do not use** for a single time — use `LayrzTimeInput` instead.
- **Do not use** when dates also matter for each endpoint — use `LayrzDateTimeRangeInput` instead.
- **Do not use** for an elapsed duration — that's a `Duration`, not two wall-clock readings.

---

## Minimal usage

```dart
LayrzTimeRangeInput(
  labelText: LayrzUiL10n.of(context).save,
  startValue: shiftStart,
  endValue: shiftEnd,
  onChanged: (start, end) {
    shiftStart = start;
    shiftEnd = end;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `startValue`/`endValue` are `LayrzTimeOfDay?`; `onChanged` reports a positional `(start, end)` pair.
- **In-panel Cancel/Save**, despite being built from two single-time clusters rather than a grid — the "one atomic value vs. multiple coordinated parts" rule applies: a start time and an end time are two coordinated parts.
- **Midnight is a valid value; Save is always reachable.** An unset `startValue`/`endValue` seeds its cluster to midnight (`00:00`); there is no gate requiring the user to have edited either cluster first. Saving untouched commits `00:00`–`00:00` as a genuine value — this replaces the old layrz_theme picker's `9:00`–`17:00` default with a different default pair, not a "nothing selected" state.
- No Clear action — the actions row is Cancel/Save only.
- Same digital-clock digit-box layout as `LayrzTimeInput`, rendered once for Start and once for End, each with its own optional AM/PM toggle in 12-hour mode.
- `end` being before `start` is **not** rejected by the widget — validate ordering yourself via `errors`.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.

---

## Common patterns

```dart
// 1. With seconds shown
LayrzTimeRangeInput(
  labelText: 'Shift window',
  startValue: shiftStart,
  endValue: shiftEnd,
  showSeconds: true,
  errors: shiftWindowErrors,
  onChanged: (start, end) {
    shiftStart = start;
    shiftEnd = end;
    if (context.mounted) onChanged.call();
  },
)

// 2. 12-hour clock
LayrzTimeRangeInput(
  labelText: 'Quiet hours',
  startValue: quietStart,
  endValue: quietEnd,
  use24HourFormat: false,
  onChanged: (start, end) => setState(() {
    quietStart = start;
    quietEnd = end;
  }),
)

// 3. Validating end-after-start yourself
LayrzTimeRangeInput(
  labelText: 'Opening hours',
  startValue: openStart,
  endValue: openEnd,
  errors: (openEnd != null && openStart != null && openEnd! < openStart!)
      ? [LayrzUiL10n.of(context).save]
      : const [],
  onChanged: (start, end) => setState(() {
    openStart = start;
    openEnd = end;
  }),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)`.
- Pass `errors: <List<String>>` computed and owned by your own form validation — whether `end` must be after `start` is entirely your responsibility.
- Separate stacked inputs with `const SizedBox(height: 10)`.
- Treat a saved `00:00`–`00:00` as a real user choice, not a sentinel — track "untouched" separately in your own form state if that distinction matters.
