---
name: layrz-ui-datetime-stepped-input
description: Use LayrzDateTimeInput (not a separate stepped widget) in a layrz_ui Flutter widget. Apply when migrating ThemedDateTimeSteppedPicker call sites — there is no LayrzDateTimeSteppedInput class and the stepped presentation is deprecated and has no visible effect.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory, and the sibling `layrz-ui-datetime-input` skill for the full widget contract.

---

## There is no `LayrzDateTimeSteppedInput` class

**This is the single most important fact in this skill.** `layrz_theme`'s `ThemedDateTimeSteppedPicker` (calendar first, then a separate time dialog) was collapsed into `LayrzDateTimeInput` under DESIGN-49/DESIGN-98. Do not create, look for, or generate a `LayrzDateTimeSteppedInput` widget — it does not exist in `lib/src/pickers/`.

## When to use

- Any call site migrating from `ThemedDateTimeSteppedPicker` — replace it with `LayrzDateTimeInput` directly (see `layrz-ui-datetime-input` skill for the full API).
- **Do not** write `presentation: LayrzDateTimeInputPresentation.stepped` expecting the old two-screen "pick date, then a separate time dialog appears" flow — the parameter compiles but is **`@Deprecated` and fully inert as of DESIGN-98**. Both `.tabbed` and `.stepped` render the exact same Date/Time tab surface.
- For the actual surface layout and commit model (Date/Time tabs, midnight-default time, Save gated on the date part alone), see the `layrz-ui-datetime-input` skill — this skill exists only to redirect a stepped-picker migration to the right widget.

---

## Minimal usage

```dart
// Correct migration — presentation omitted entirely
LayrzDateTimeInput(
  labelText: LayrzUiL10n.of(context).save,
  value: appointment,
  onChanged: (value) {
    appointment = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `LayrzDateTimeInputPresentation.stepped` and `.tabbed` are functionally identical today — neither changes the rendered surface. Passing either is safe but has zero effect; omitting `presentation` entirely produces the same result.
- Do not gate any UI logic on `presentation`'s value — it is read by nothing.
- The commit model (Cancel/Save, midnight-default time, Save gated on the date part) is identical regardless of which `presentation` value is passed.

---

## Common patterns

```dart
// Migrating an old call site — just drop `presentation`
// Before (layrz_theme):
//   ThemedDateTimeSteppedPicker(value: v, onChanged: onChanged)
// After (layrz_ui):
LayrzDateTimeInput(
  labelText: 'Appointment',
  value: appointment,
  onChanged: (value) => setState(() => appointment = value),
)
```

---

## Form conventions

- Do not pass `presentation` on new call sites; it exists purely for source-compatibility with old migration code, not because it changes behavior.
- Follow `layrz-ui-datetime-input`'s form conventions for everything else — localization via `LayrzUiL10n.of(context)`, caller-owned `errors: List<String>`, `if (context.mounted)` guards on async callbacks.
