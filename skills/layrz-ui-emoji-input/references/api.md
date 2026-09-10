# LayrzEmojiInput — API Reference

Source: `lib/src/pickers/src/emoji/emoji_input.dart`
- `LayrzEmojiInput` class — line 45

Emoji source: `package:emojis` (`Emoji`/`EmojiGroup`) — a pure-Dart package with no Material/Cupertino coupling.

---

## Examples

```dart
// Minimal
LayrzEmojiInput(
  labelText: 'Reaction',
  value: emoji,
  onChanged: (value) => setState(() => emoji = value),
)

// Required with errors
LayrzEmojiInput(
  labelText: 'Team emoji',
  isRequired: true,
  value: teamEmoji,
  errors: teamEmoji == null ? ['Pick a team emoji'] : const [],
  onChanged: (value) => setState(() => teamEmoji = value),
)

// Hint-only
LayrzEmojiInput(
  hintText: 'Add a reaction',
  value: reaction,
  onChanged: (value) => setState(() => reaction = value),
)

// Disabled, pre-filled
LayrzEmojiInput(
  labelText: 'Status',
  value: '✅',
  disabled: true,
)
```

---

## Constructor

```dart
const LayrzEmojiInput({
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
| `value` | `String?` | `null` | The currently selected emoji character, or `null` when nothing has been picked yet. |
| `onChanged` | `ValueChanged<String>?` | `null` | Called with the newly picked emoji character on commit (a tap in the surface). Never called with `null` — there is no Clear affordance. |
| `labelText` | `String?` | `null` | The label text displayed above the field. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Placeholder shown when the field is empty and no `labelText` describes it. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `controller` | `TextEditingController?` | `null` | The anchor field's text controller. Created and disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | The anchor field's focus node. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

---

## Behavior notes

- **Commit-on-tap — no Save row.** Tapping an emoji in the surface both fires `onChanged` and closes it immediately, via `LayrzModalRoute.popIfCurrent`. No `actions` list is passed to `LayrzResponsiveModal.show`, so Escape, a barrier tap, and the back gesture all close with no value picked — exactly like backing out without choosing. This is the sole picker in the module where the behavior is commit-on-tap rather than staged-with-Save (mirrors `LayrzSelectInput`'s single-value commit-on-tap contract).
- **Container:** opens through `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below that (`initialSize: 0.6, maxSize: 0.9, snapSizes: [0.6, 0.9]`, `scrollable: false` since the surface scrolls its own grid). Both carry a `LayrzPickerDialogHeader` (labelText as title, plus a close "X") above the search field and tabs.
- **Search:** matches case-insensitively against both `Emoji.shortName` and every entry in `Emoji.keywords`, narrowed within whichever group tab is currently selected.
- **Groups:** a scrollable `LayrzTabView` of "All emoji" plus one tab per `EmojiGroup`, in the source package's own declaration order. Each tab's content is a keyboard-navigable 8-column grid (arrow keys, Enter/Space to select), filtered by both the active tab's group and the search field.
- **No skin-tone variants.** `Emoji.modifiable`/`Emoji.modify` are never consulted — out of scope.
- **Self-display:** the closed field renders `value` directly (a bare character needs no formatting) — there is no separate formatted-summary cache, unlike the date-family pickers.
- **Value type rationale:** an emoji character is already a stable, portable, serializable value, unlike `LayrzIconInput`'s codepoint-unstable `IconData` — hence `String?` rather than a domain wrapper.
