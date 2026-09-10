# LayrzDateTimeSteppedInput — API Reference

**There is no `LayrzDateTimeSteppedInput` class in this codebase.** Do not search for one under `lib/src/pickers/`; it does not exist.

Source of truth: `lib/src/pickers/src/datetime/datetime_input.dart` (`LayrzDateTimeInput`) and `lib/src/pickers/src/datetime/datetime_presentation.dart` (`LayrzDateTimeInputPresentation`).

---

## What actually happened (DESIGN-49 → DESIGN-98)

`layrz_theme` had two distinct pickers:
- `ThemedDateTimePicker` — tabbed date/time selection.
- `ThemedDateTimeSteppedPicker` — calendar first, then a separate time dialog.

DESIGN-49 collapsed both into a single `LayrzDateTimeInput`, distinguishing them via a `presentation: LayrzDateTimeInputPresentation` parameter (`.tabbed` / `.stepped`). DESIGN-98 then made that parameter **fully inert**: `LayrzDateTimeSurface` accepts but ignores it. Today, `LayrzDateTimeInput` always renders the same `LayrzTabView` ("Date" / "Time" tabs) surface described in the `layrz-ui-datetime-input` skill, regardless of which `presentation` value (or none) is passed.

`LayrzDateTimeInputPresentation` itself is kept as a source-compatible enum (not deleted) purely so an existing caller passing `presentation:` explicitly does not hit a breaking removal with no migration signal — see that enum's own class doc.

---

## Migration example

```dart
// Old (layrz_theme):
ThemedDateTimeSteppedPicker(
  value: appointment,
  onChanged: (value) => setState(() => appointment = value),
)

// New (layrz_ui) — presentation omitted, it would do nothing anyway:
LayrzDateTimeInput(
  labelText: 'Appointment',
  value: appointment,
  onChanged: (value) => setState(() => appointment = value),
)
```

---

## Full API

See `layrz-ui-datetime-input`'s `references/api.md` for the complete `LayrzDateTimeInput` constructor, properties table, and the `LayrzDateTimeInputPresentation` enum table (documented there as deprecated/inert, with both values listed).

## Discrepancy note (wiki vs. source, resolved by code)

The wiki page `LayrzDateTimeSteppedInput.md` is written as a redirect stub, which this skill matches. However, an earlier draft of that page's framing ("To get the old stepped behavior, use `presentation: .stepped`") could be misread as implying `.stepped` still produces different visible behavior from `.tabbed`. **Source is unambiguous that it does not** — `LayrzDateTimeInputPresentation`'s own class doc states "neither is read by `LayrzDateTimeSurface` any longer" and "there is no remaining tab strip or step sequence to select between." This reference follows source: passing `.stepped` is accepted for compile-time compatibility only and has no runtime effect.
