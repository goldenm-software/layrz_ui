---
name: layrz-ui-textarea-input
description: Use LayrzTextAreaInput in a layrz_ui Flutter widget. Apply when adding a multiline text field for notes, descriptions, or long-form comments — grows between minLines/maxLines then scrolls, with the same prefix/suffix and error contract as LayrzTextInput.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.newline`, `.sentences`) — never the fully-qualified form (`TextInputAction.newline`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Multiline prose: descriptions, notes, comments, free-form feedback fields.
- Any field where Enter should insert a newline, not submit the form.
- **Do not use** for single-line entry — use `LayrzTextInput` instead (this widget has no `obscureText` and is always multiline).
- **Do not use** for numeric entry — use `LayrzNumberInput` instead.
- `LayrzTextAreaInput` is a **distinct widget class**, not a `maxLines`-driven mode of `LayrzTextInput` — do not look for a `maxLines` parameter on `LayrzTextInput` to get this behavior.

---

## Minimal usage

```dart
LayrzTextAreaInput(
  labelText: 'Description',
  errors: descriptionErrors,
  onChanged: (value) {
    description = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- Grows from `minLines` (default 3) up to `maxLines` (default 10), then scrolls internally rather than continuing to grow. Both must be positive and `minLines` must not exceed `maxLines` (debug assertion).
- **Enter inserts a newline by default** — `textInputAction` defaults to `.newline`, not a submit action. There is no `onSubmit` callback on this widget (unlike `LayrzTextInput`); combine an explicit `.send`/`.done` action with your own Enter-key handling if you need submit-on-Enter.
- No `obscureText` parameter exists — this widget is never used for secrets.
- `maxLength` auto-appends a `LengthLimitingTextInputFormatter` and renders a character counter — there is no separate `showCharacterCount` flag.
- Same slot exclusivity, disposal contract, and error/helper precedence as `LayrzTextInput` — see that skill for the shared chrome contract.
- `dense: true` drops internal padding one ramp, identically on every viewport; no `padding` override exists (the chrome is frozen).

---

## Common patterns

```dart
// 1. Description field with a length cap
LayrzTextAreaInput(
  labelText: 'Description',
  maxLength: 500,
  errors: descriptionErrors,
  onChanged: (value) => description = value,
)

// 2. Short comment box (fewer lines than the default)
LayrzTextAreaInput(
  labelText: 'Comment',
  minLines: 2,
  maxLines: 4,
  onChanged: (value) => comment = value,
)

// 3. Required notes field with help affordance
LayrzTextAreaInput(
  labelText: 'Notes',
  isRequired: true,
  helpTitleText: 'What goes here?',
  helpContentText: 'Internal notes visible only to your team.',
  errors: notesErrors,
  onChanged: (value) => notes = value,
)

// 4. Read-only rendered notes
LayrzTextAreaInput(
  labelText: 'Change log',
  readOnly: true,
  controller: TextEditingController(text: changeLog),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Pass `errors: <List<String>>` computed by your own form validation — there is no `context.getErrors`.
- Set an explicit `maxLength` whenever the backing field has a real database/API limit, so the counter gives the user honest feedback.
- Localize `labelText`/`hintText`/`helperText` via `LayrzUiL10n.of(context)` for real product strings.
- Separate stacked inputs with consistent vertical spacing (e.g. `SizedBox(height: 10)`).
