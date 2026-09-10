---
name: layrz-ui-avatar
description: Use LayrzAvatar in a layrz_ui Flutter widget. Apply when rendering a static user/entity avatar — image (URL/base64) via .image(), icon via .icon(), emoji via .emoji(), or generated initials via .initials() / automatic fallback.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values where applicable — this widget has no enum parameters of its own.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any static user/entity avatar: profile photos, list-row leading avatars, comment authors.
- Use `.image()` for a known URL/base64 image with a required `semanticLabel`.
- Use `.icon()` for an icon-based avatar (e.g. a system/bot account).
- Use `.emoji()` for a Unicode-glyph avatar (e.g. a reaction or a playful placeholder).
- Use `.initials()`, or the default constructor with `source: null` and `nameText` set, when no image/icon/emoji is available — initials are generated automatically.
- **Do not use** for interactive avatar selection (upload flow) — use `LayrzDynamicAvatarInput` instead.
- **Do not use** for an editable/tappable avatar — wrap `LayrzAvatar` in a `GestureDetector` yourself; the widget has no `onTap`/`onLongPress` of its own.

---

## Minimal usage

```dart
LayrzAvatar.initials(
  nameText: user.fullName,
  size: 40,
)
```

---

## Key behaviors

- **Static display only** — no `onTap`, `onLongPress`, or any interaction callback. Wrap in `GestureDetector` if you need one.
- Resolution order on the default constructor: `source` (sealed `LayrzAvatarSource`) wins when non-null; otherwise falls back to initials from `nameText`; `nameText` null/empty renders `"NA"`.
- `LayrzAvatarSource` is sealed with four variants: `LayrzAvatarUrl`, `LayrzAvatarBase64`, `LayrzAvatarIcon`, `LayrzAvatarEmoji`.
- **`LayrzAvatarIcon` wraps an `MdiRemapIcon`, not a raw `IconData`** — it is the stable, name-keyed icon identity (`findMdiRemapIconByName` is the registry lookup). The `.icon()` **named constructor**, however, still takes `IconData` directly.
- `.image()`'s `semanticLabel` is **required** — every other constructor's `semanticLabel` is optional (no semantics wrapper emitted when omitted).
- The avatar is always a rounded box (`r3` token radius, 16px) unless `borderRadius` is set explicitly; a `borderRadius` at or above `size / 2` renders a circle.
- Every avatar carries a fixed `tokens.shadow.compact1` drop shadow (overridable only via `elevation: 0|1|2|3`) — this is intentional and not meant to be removed for most use cases.
- Initials algorithm strips non-alphanumeric characters, then: empty → `"NA"`, one char → that char, two+ → first two chars uppercased. Not Unicode-aware — accepted limitation.
- Background is white for image/emoji avatars (so transparency stays visible); primary token color by default for icon/initials avatars.

---

## Common patterns

```dart
// 1. Image avatar with required semantic label
LayrzAvatar.image(
  imageSource: user.avatarUrl,
  semanticLabel: "${user.fullName}'s profile photo",
  size: 48,
)

// 2. Icon avatar via the named constructor (plain IconData)
LayrzAvatar.icon(
  icon: MdiIcons.accountCircleOutline,
  size: 40,
  color: context.theme.tokens.colors.success,
)

// 3. Default constructor with a sealed LayrzAvatarSource (icon variant, MdiRemapIcon)
LayrzAvatar(
  source: LayrzAvatarIcon(myMdiRemapIcon),
  size: 40,
)

// 4. Emoji avatar
LayrzAvatar.emoji(emoji: '🎨', size: 48)

// 5. Fallback-to-initials (no source provided)
LayrzAvatar(
  source: null,
  nameText: user.fullName,
  size: 40,
)

// 6. Non-configurable interaction — wrap externally
GestureDetector(
  onTap: () => _openProfile(user),
  child: LayrzAvatar.initials(nameText: user.fullName),
)
```

---

## Usage conventions

- Always pass a real, descriptive `semanticLabel` to `.image()` (e.g. `"Jane Smith's profile photo"`) — never a generic `"image"`.
- Prefer `.initials()`/the fallback path over hardcoding a placeholder image asset when a user has not uploaded a photo.
- Don't pass both `source` and one of the named-constructor-only fields — use exactly one construction path per instance (default constructor + `source`, or a single named constructor).
- Keep `size` consistent within one list (e.g. a user table's leading avatar column) — the shadow and radius scale with `size`, so mixed sizes read as visually inconsistent rows.
- Leave `borderRadius`/`elevation` at their defaults unless the surrounding surface has a specific design reason to deviate — the fixed shadow and `r3` radius are the house baseline shared with `LayrzCard`/`LayrzAlert`.
