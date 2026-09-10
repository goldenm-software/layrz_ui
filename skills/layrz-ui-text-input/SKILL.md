---
name: layrz-ui-text-input
description: Use LayrzTextInput in a layrz_ui Flutter widget. Apply when adding any free-text form field — single-line entry, prefix/suffix icon or text slots, keyboard-shortcut badging, read-only picker-style fields, or as the base chrome another input composes.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.emailAddress`, `.done`) — never the fully-qualified form (`TextInputType.emailAddress`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any free-text single-line field: name, email, URL, phone, notes-title, search box.
- Read-only "picker" fields that open a selection surface on tap (`readOnly: true` + `onTap`) — this is how every layrz_ui date/color/select picker renders its anchor field.
- The base chrome for a composite/custom input you are building — compose `LayrzTextInput`, do not reimplement field chrome.
- **Do not use** for multiline prose or descriptions — use `LayrzTextAreaInput` instead.
- **Do not use** for numeric entry with step buttons — use `LayrzNumberInput` instead.
- **Do not use** for password entry — use `LayrzPasswordInput` (it composes this widget and adds the eye-toggle + strength meter).
- **Do not use** raw `EditableText`/`TextField`/`TextFormField` — those are Material-coupled or bypass the design system's chrome entirely.

---

## Minimal usage

```dart
LayrzTextInput(
  labelText: 'Name',
  errors: nameErrors,
  onChanged: (value) {
    name = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **`labelText` or `hintText` is mandatory** — at least one must be non-null (debug assertion). Both together are valid; neither alone is an error.
- **Slot exclusivity** — at most one of `prefixIcon` / `prefix` / `prefixText`; same rule for the suffix trio. Providing two asserts in debug mode.
- `disabled: true` blocks all input and taps; `readOnly: true` blocks editing but still fires `onTap` — this is how picker-style fields work.
- `errors` is a caller-owned `List<String>`, joined with `", "` into one line below the field on wide viewports (≥ 960px `md`+); below that, errors move into a tap-triggered tooltip anchored to the error icon, one per line. This is automatic — you never branch on viewport for it.
- `helperText` renders below the field but is **hidden whenever `errors` is non-empty** — errors always win.
- `dense: true` drops the internal padding one ramp (`pd2`→`pd1`); it is the only thing dense affects. There is no public `padding` override — `LayrzInputChrome` is frozen and owns this value.
- `controller`/`focusNode` are caller-owned when supplied (never disposed by the widget) or created-and-disposed internally when omitted.
- `showBorder: false` and `borderRadius` overrides exist for composite inputs (e.g. `LayrzNumberInput`) that need square corners when embedding this chrome inside their own bordered row — rarely needed directly.

---

## Common patterns

```dart
// 1. Required field with validation errors
LayrzTextInput(
  labelText: 'Username',
  isRequired: true,
  errors: username.isEmpty ? ['Username is required'] : [],
  onChanged: (value) {
    username = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. Read-only field that opens a picker
LayrzTextInput(
  labelText: 'Date',
  readOnly: true,
  controller: TextEditingController(text: selectedDate?.toString() ?? ''),
  onTap: () => showDatePicker(),
)

// 3. Prefix icon + suffix action (e.g. copy-to-clipboard)
LayrzTextInput(
  labelText: 'Share URL',
  prefixIcon: MdiIcons.linkVariant,
  suffixIcon: MdiIcons.contentCopy,
  onSuffixTap: () => copyToClipboard(url),
  errors: urlErrors,
  onChanged: (value) => url = value,
)

// 4. Search-style hint-only field (no label)
LayrzTextInput(
  hintText: 'Search…',
  prefixIcon: MdiIcons.magnify,
  onChanged: (value) => query = value,
)

// 5. Disabled field
LayrzTextInput(
  labelText: 'Locked field',
  disabled: true,
  controller: TextEditingController(text: 'Cannot edit this'),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller owns and computes the list.
- Localize `labelText`/`hintText`/`helperText` via `LayrzUiL10n.of(context)` when the string is a real product string; a plain literal is fine in examples and simple internal tools.
- Separate stacked inputs with `SizedBox(height: AppTokens... )` per the host app's spacing tokens, or a fixed `SizedBox(height: 10)` in layrz_ui-only contexts.
- Never add a border — `LayrzInputChrome` (frozen, see project `CLAUDE.md`) owns all border rendering; do not wrap this widget in a `DecoratedBox` for that purpose.
