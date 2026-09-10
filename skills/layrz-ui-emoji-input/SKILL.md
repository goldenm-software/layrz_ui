---
name: layrz-ui-emoji-input
description: Use LayrzEmojiInput in a layrz_ui Flutter widget. Apply when adding a field that lets the user pick a single Unicode emoji character — searchable, group-filterable, commit-on-tap with no Save step.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A single-emoji picker field: a reaction, a status indicator, a lightweight custom icon slot.
- Storing a portable, serializable string value — `value` is the raw emoji character, no domain wrapper type.
- **Do not use** for an MDI icon — use `LayrzIconInput` instead.
- **Do not use** when the caller needs URL/upload/icon/emoji all as options for one field — use `LayrzDynamicAvatarInput` instead.

---

## Minimal usage

```dart
LayrzEmojiInput(
  labelText: 'Reaction',
  value: emoji,
  errors: emojiErrors,
  onChanged: (value) {
    emoji = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Commit-on-tap — no Save row.** Unlike every other Save-gated picker in this module (date/time/month/color/multi-select), tapping an emoji in the surface both fires `onChanged` and closes the surface immediately. There is no draft, no Cancel/Save row.
- **No Clear affordance.** The only content-changing gesture is picking; Escape/barrier tap/back already cover "change nothing" by closing without calling `onChanged`.
- `onChanged` is **never called with `null`** — its type is `ValueChanged<String>?`, not nullable-argument.
- `value` is a raw `String?` emoji character (e.g. `'😀'`, `Emoji.char`) — already stable and portable, so there is no name-based indirection like `LayrzIconInput` needs.
- The surface renders a search field (matched against name and keywords) plus a scrollable tab strip: "All emoji" and one tab per emoji group (Smileys & Emotion, People & Body, Animals & Nature, Food & Drink, Travel & Places, Activities, Objects, Symbols, Flags, Component).
- **No skin-tone variants.** Every cell renders the base `Emoji.char` exactly as authored by the source package.
- `disabled: true` makes the field fully non-interactive.

---

## Common patterns

```dart
// 1. Required emoji field
LayrzEmojiInput(
  labelText: 'Team emoji',
  isRequired: true,
  value: teamEmoji,
  errors: teamEmoji == null ? ['Pick a team emoji'] : const [],
  onChanged: (value) => setState(() => teamEmoji = value),
)

// 2. Hint-only, no label
LayrzEmojiInput(
  hintText: 'Add a reaction',
  value: reaction,
  onChanged: (value) => setState(() => reaction = value),
)

// 3. Disabled, pre-filled
LayrzEmojiInput(
  labelText: 'Status',
  value: '✅',
  disabled: true,
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller computes and owns the list.
- Separate stacked inputs with `SizedBox(height: 10)` (or the host app's own spacing tokens).
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
