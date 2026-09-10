# LayrzDynamicAvatarInput — API Reference

Source: `lib/src/pickers/src/dynamic_avatar/dynamic_avatar_input.dart`
- `LayrzDynamicAvatarInput` class — line 62

Composed of: `LayrzIconInput`'s icon registry (`flutter_mdi_remap`), `LayrzEmojiInput`'s emoji source (`package:emojis`), and `LayrzFileInput` hosted inline for the Upload tab.

---

## Examples

```dart
// Minimal
LayrzDynamicAvatarInput(
  labelText: 'Avatar',
  hintText: 'Pick an avatar',
  value: avatar,
  onChanged: (value) => setState(() => avatar = value),
)

// Required with errors
LayrzDynamicAvatarInput(
  labelText: 'Profile picture',
  isRequired: true,
  value: avatar,
  errors: avatar == null ? ['Pick an avatar'] : const [],
  onChanged: (value) => setState(() => avatar = value),
)

// Rendering a persisted source elsewhere
LayrzAvatar(source: avatar, size: 40);

// Disabled, pre-filled with an emoji source
LayrzDynamicAvatarInput(
  labelText: 'Locked avatar',
  value: const LayrzAvatarEmoji('🦊'),
  disabled: true,
)
```

---

## Constructor

```dart
const LayrzDynamicAvatarInput({
  super.key,
  this.value,
  this.onChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(
       labelText != null || hintText != null,
       'At least one of labelText or hintText must be non-null.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `LayrzAvatarSource?` | `null` | The currently selected avatar source, or `null` for "no avatar". |
| `onChanged` | `ValueChanged<LayrzAvatarSource?>?` | `null` | Called on a commit from any of the four tabs, or the None/clear affordance. Carries `null` only from clear; every tab commit carries a non-null source. Never called on mount or for an untouched incoming `value`. |
| `labelText` | `String?` | `null` | The label text displayed above the tile. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Placeholder shown when the field is empty and no `labelText` describes it. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error message block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. Tapping the tile does nothing while disabled. |
| `controller` | `TextEditingController?` | `null` | Retained for API compatibility with the picker-anchor-row shape. Never attached to any rendered text field on this tile presentation. |
| `focusNode` | `FocusNode?` | `null` | The focus node the tile itself attaches to. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Retained for API compatibility. The tile has a single fixed size in every state, so this has **no visible effect**. |
| `helpTitleText` | `String?` | `null` | Retained for API compatibility. The tile presentation has no chrome to host a help tooltip, so this is accepted but **not rendered**. |
| `helpContentText` | `String?` | `null` | See `helpTitleText` — accepted but **not rendered**. |

There is no `enabledTypes`, `heightFactor`, or `maxHeight` parameter — the four tabs are always all present, and sizing goes through `LayrzResponsiveModal`'s own dialog/sheet configuration.

---

## `LayrzAvatarSource` sealed type

| Variant | Carries | Selected by tab |
|---|---|---|
| `LayrzAvatarUrl(String url)` | An `http(s)` URL, data-URI, or bare base64 string | URL |
| `LayrzAvatarBase64(String base64)` | A raw base64-encoded image string | Upload |
| `LayrzAvatarIcon(MdiRemapIcon icon)` | An `MdiRemapIcon` from the `flutter_mdi_remap` registry | Icon |
| `LayrzAvatarEmoji(String emoji)` | A Unicode emoji character (or grapheme sequence) | Emoji |

`null` means "no avatar" — there is no separate "none" variant in the sealed hierarchy. Because the hierarchy is `sealed`, an exhaustive `switch` over it gets a compile error if a new variant is ever added, rather than a silent fallthrough.

---

## Behavior notes

- **Closed presentation:** a 100px square tappable tile (`LayrzDynamicAvatarTile`), per explicit maintainer direction that this field's closed state should show the full avatar rather than a compact anchor row. Populated state renders the current selection via `LayrzAvatar` plus an independently tappable circular clear ("X") badge top-right. Empty state shows an "add avatar" affordance icon in place of a preview, with no clear badge.
- **Container:** the dialog (`LayrzDynamicAvatarSurface`) opens through `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below that (`initialSize: 0.75, maxSize: 0.95, snapSizes: [0.75, 0.95]`, `scrollable: false`). A single `LayrzPickerDialogHeader` sits above a `LayrzTabView` with four tabs: URL, Upload, Icon, Emoji.
- **One dialog, one header — not four nested pickers.** The Icon/Emoji tabs render their grids inline (the same shared grid primitive `LayrzIconInput`/`LayrzEmojiInput` use internally, with their own search/group-filter reimplemented locally), and the Upload tab hosts `LayrzFileInput` directly — none of the standalone input widgets are embedded wholesale, which would otherwise open nested dialogs.
- **Per-tab commit, no dialog-wide footer:**
  - Icon/Emoji: commit on tap, mirroring `LayrzIconInput`/`LayrzEmojiInput`'s own "picking IS the decision" contract.
  - URL: commits when the inline `LayrzTextInput` receives Enter/Done, not on every keystroke.
  - Upload: commits the moment `LayrzFileInput` emits a non-empty file list; an empty emission from its own clear affordance only resets that tile's local preview.
  - Every commit path closes the surface immediately via `LayrzModalRoute.popIfCurrent`.
- **Upload constraint:** `.gif`/`.png`/`.jpg` only, at most `1024 * 1024` bytes (1 MiB), `maxFiles: 1` — specific to this surface, not a change to `LayrzFileInput` itself.
- **Self-display:** the closed tile keeps its own `_displayedValue` synchronized with `value` (via `initState`/`didUpdateWidget`, and immediately via `setState` on a fresh commit or clear), so it reflects a freshly committed pick even before the caller feeds an updated `value` back in.
