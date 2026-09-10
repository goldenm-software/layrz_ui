# LayrzAvatar — API Reference

Source: `lib/src/images/src/`
- `LayrzAvatar` class — `avatar.dart`
- `LayrzAvatarSource` sealed class + `LayrzAvatarUrl`/`LayrzAvatarBase64`/`LayrzAvatarIcon`/`LayrzAvatarEmoji` — `avatar_source.dart`

---

## Examples

```dart
// Default constructor with a URL source
LayrzAvatar(
  source: LayrzAvatarUrl('https://cdn.example.com/user.png'),
  nameText: 'Jane Smith', // fallback if the image fails to load conceptually; not auto-swapped on error
  size: 48,
)

// .image() named constructor
LayrzAvatar.image(
  imageSource: 'https://cdn.example.com/user.png',
  semanticLabel: "Jane Smith's profile photo",
  size: 56,
)

// Base64 source
LayrzAvatar(
  source: LayrzAvatarBase64('iVBORw0KGgoAAAANSUhEUg...'),
  size: 40,
)

// Icon via named constructor (IconData)
LayrzAvatar.icon(
  icon: MdiIcons.checkCircleOutline,
  size: 40,
  color: context.theme.tokens.colors.success,
)

// Icon via sealed source (MdiRemapIcon — stable name-keyed identity)
LayrzAvatar(
  source: LayrzAvatarIcon(someMdiRemapIcon),
  size: 40,
)

// Emoji
LayrzAvatar.emoji(emoji: '🎨', size: 48)

// Initials
LayrzAvatar.initials(
  nameText: 'Alice Johnson',
  size: 40,
  color: context.theme.tokens.colors.success,
)

// Fallback to initials (no source)
LayrzAvatar(source: null, nameText: 'Bob Brown')

// Custom elevation and radius
LayrzAvatar.initials(
  nameText: 'Circle Avatar',
  size: 40,
  borderRadius: 20, // size / 2 => renders a circle
  elevation: 2,
)
```

---

## Constructor

```dart
const LayrzAvatar({
  super.key,
  this.source,
  this.nameText,
  this.size = 40,
  this.color,
  this.borderRadius,
  this.elevation,
  this.semanticLabel,
}) : assert(elevation == null || elevation >= 0, 'Elevation must be non-negative'),
     assert(elevation == null || elevation <= 3, 'Elevation must be 0, 1, 2, or 3');
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `source` | `LayrzAvatarSource?` | `null` | Sealed source descriptor. `null` falls back to initials from `nameText`. |
| `nameText` | `String?` | `null` | Initials source when `source` is `null`. `null`/empty renders `"NA"`. |
| `size` | `double` | `40` | Width and height (always square). |
| `color` | `Color?` | `null` | Background fill for icon/initials avatars; `null` uses `tokens.colors.primary`. Ignored for images (always white background). |
| `borderRadius` | `double?` | `null` | `null` uses the `r3` token (16px). Values `>= size / 2` render a circle. |
| `elevation` | `double?` | `null` | `0`\|`1`\|`2`\|`3`; asserted in range. `null` uses the fixed `tokens.shadow.compact1`. `0` removes the shadow entirely. |
| `semanticLabel` | `String?` | `null` | Optional on this constructor and every named constructor except `.image()`. `null` emits no `Semantics` wrapper. |

---

## Factory constructors

### `.image()`

```dart
const LayrzAvatar.image({
  super.key,
  required String imageSource,
  required this.semanticLabel,
  this.size = 40,
  this.borderRadius,
  this.elevation,
})
```

| Property | Type | Notes |
|---|---|---|
| `imageSource` | `String` (required) | http(s) URL, `data:` URI, or bare base64 string. Routed through `LayrzImage`. |
| `semanticLabel` | `String` (**required** — unlike every other constructor) | Must describe the image content, e.g. `"Jane Smith's profile photo"`. |

Background is white. No `color` parameter (ignored for images).

### `.icon()`

```dart
const LayrzAvatar.icon({
  super.key,
  required IconData icon,
  this.size = 40,
  this.color,
  this.borderRadius,
  this.elevation,
  this.semanticLabel,
})
```

`icon` is a plain `IconData` here (contrast with the sealed `LayrzAvatarIcon` source, which wraps `MdiRemapIcon`). Icon renders at 70% of `size`. `color` defaults to `tokens.colors.primary`.

### `.emoji()`

```dart
const LayrzAvatar.emoji({
  super.key,
  required String emoji,
  this.size = 40,
  this.borderRadius,
  this.elevation,
  this.semanticLabel,
})
```

Background white. Emoji renders centered at 60% of `size`. No `color` parameter.

### `.initials()`

```dart
const LayrzAvatar.initials({
  super.key,
  required this.nameText,
  this.size = 40,
  this.color,
  this.borderRadius,
  this.elevation,
  this.semanticLabel,
})
```

`color` defaults to `tokens.colors.primary`.

---

## `LayrzAvatarSource` sealed hierarchy

| Type | Field | Notes |
|---|---|---|
| `LayrzAvatarUrl` | `final String url` | http(s) URL, data-URI, or bare base64. Routed through `LayrzImage`. |
| `LayrzAvatarBase64` | `final String base64` | Raw base64-encoded image string. Routed through `LayrzImage`. |
| `LayrzAvatarIcon` | `final MdiRemapIcon icon` | **Wraps `MdiRemapIcon`, not `IconData`.** `MdiRemapIcon.data` renders at 70% of `size`. Equality/hash compare by `icon.name` (the stable registry lookup key), not the whole object. |
| `LayrzAvatarEmoji` | `final String emoji` | Unicode emoji glyph, renders at 60% of `size` on white. |

Each variant is `final class` (not further subclassable) with `const` constructors, value `==`/`hashCode`, and a `copyWith({...})`. `LayrzAvatarSource` itself is `sealed` — exhaustive `switch` with no `default` needed.

---

## Behavior notes

- **Resolution order** (default constructor build): `source` (sealed type dispatch) wins when non-`null`; otherwise falls back to generated initials from `nameText`; both null/empty → `"NA"`.
- **Initials algorithm**: strip all non-alphanumeric chars → empty → `"NA"`; one char → that char; two+ → first two chars uppercased. Not Unicode-aware (combining characters, non-Latin scripts, ligatures each count as separate characters) — accepted limitation, not a bug.
- **Text contrast**: initials/icon text color is picked via a luminance heuristic against the background (`_pickTextColor`) — black on light backgrounds, white on dark.
- **Fixed shadow**: `tokens.shadow.compact1` (same ramp as `LayrzButton`) applies in every render mode; chosen because a soft low-offset shadow disappears at avatar sizes. `elevation: 0` is the only way to remove it.
- **No `layrz_sdk` dependency**: the sealed `LayrzAvatarSource` hierarchy is fully self-contained; convert from an SDK `Avatar` model in your own adapter code if migrating.
- **Image loading**: `.image()`/`LayrzAvatarUrl`/`LayrzAvatarBase64` all route through `LayrzImage`, which handles format detection, SVG, and base64 caching — see the `layrz-ui-image` skill.
