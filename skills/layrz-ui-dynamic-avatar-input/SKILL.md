---
name: layrz-ui-dynamic-avatar-input
description: Use LayrzDynamicAvatarInput in a layrz_ui Flutter widget. Apply when adding a flexible avatar field that lets the user choose a source from URL, image Upload, MDI Icon, or Emoji tabs in one tabbed dialog, presented as a tappable 100px avatar tile.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any avatar/profile-image field where the value can come from more than one source — a hosted image URL, an uploaded file, an MDI icon, or an emoji.
- **Do not use** for an icon-only field — use `LayrzIconInput` instead.
- **Do not use** for an emoji-only field — use `LayrzEmojiInput` instead.
- **Do not use** for a plain image upload with no alternative source types — use `LayrzFileInput` instead.
- To **render** a persisted `LayrzAvatarSource` elsewhere (a summary card, a list row), pass it to `LayrzAvatar` directly — this input only edits the value.

---

## Minimal usage

```dart
LayrzDynamicAvatarInput(
  labelText: 'Avatar',
  hintText: 'Pick an avatar',
  value: avatar,
  errors: avatarErrors,
  onChanged: (value) {
    avatar = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Closed state is a 100px tappable avatar tile**, not a compact field row — it previews the current selection via `LayrzAvatar`, unlike every other picker in this module. An "add avatar" icon shows when `value` is `null`.
- **A populated tile carries its own independently tappable clear ("X") badge** top-right, separate from the tile's own "open dialog" tap target; tapping it calls `onChanged(null)`.
- `value`/`onChanged` are typed `LayrzAvatarSource?` — the same sealed type `LayrzAvatar` renders. `null` means "no avatar"; there is no separate "none" variant.
- **Four tabs are always fixed** — URL, Upload, Icon, Emoji. There is no `enabledTypes` parameter to restrict the set.
- **Commit behavior differs per tab**, and every commit closes the dialog immediately (no dialog-wide Save/Cancel footer):
  - Icon/Emoji commit on tap.
  - URL commits on submit (Enter/Done).
  - Upload commits the moment `LayrzFileInput` emits a non-empty file — clearing that tile's local preview is not forwarded as a commit.
- A None/clear affordance renders beneath the header on every tab; tapping it calls `onChanged(null)` and closes the dialog.
- Opening selects the tab matching the current `value`'s variant (`LayrzAvatarUrl`/`LayrzAvatarBase64`/`LayrzAvatarIcon`/`LayrzAvatarEmoji` → URL/Upload/Icon/Emoji); `null` opens on the URL tab.
- The Upload tab is constrained tighter than `LayrzFileInput`'s own defaults: `.gif`/`.png`/`.jpg` only, at most 1 MiB, `maxFiles: 1`.
- `dense`, `helpTitleText`, `helpContentText`, and `controller` are accepted for API compatibility with the picker-anchor-row shape but have **no visible effect** on this tile presentation.

---

## Common patterns

```dart
// 1. Required avatar field
LayrzDynamicAvatarInput(
  labelText: 'Profile picture',
  isRequired: true,
  value: avatar,
  errors: avatar == null ? ['Pick an avatar'] : const [],
  onChanged: (value) => setState(() => avatar = value),
)

// 2. Rendering a persisted source elsewhere (e.g. a summary card)
LayrzAvatar(source: avatar, size: 40);

// 3. Disabled, pre-filled
LayrzDynamicAvatarInput(
  labelText: 'Locked avatar',
  value: const LayrzAvatarEmoji('🦊'),
  disabled: true,
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller computes and owns the list.
- Because the tile presentation renders no chrome for `helpTitleText`/`helpContentText`, put help copy near the field via your own layout instead of relying on this widget's tooltip parameters.
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
