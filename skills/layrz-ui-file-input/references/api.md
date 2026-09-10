# LayrzFileInput — API Reference

Source: `lib/src/file_input/src/file_input.dart`, `lib/src/file_input/src/file_input_result.dart`
- `LayrzFileInput` class (`StatefulWidget`)
- `LayrzFileInputResult` class (`@immutable`)

---

## Examples

```dart
// Single-file field
LayrzFileInput(
  labelText: 'Attachment',
  maxFiles: 1,
  value: files,
  onChanged: (result) => setState(() => files = result),
)

// Multi-file with extension + size constraints
LayrzFileInput(
  labelText: 'Supporting documents',
  hintText: 'Drop PDFs or images here',
  allowedExtensions: const ['pdf', 'png', 'jpg'],
  maxFileSizeBytes: 5 * 1024 * 1024,
  rejectionMessage: 'Only PDF or image files under 5 MB are allowed.',
  value: documents,
  onChanged: (result) => setState(() => documents = result),
  errors: documentErrors,
)

// Reading results
LayrzFileInput(
  onChanged: (result) {
    for (final file in result) {
      debugPrint('${file.name} (${file.mimeType}, ${file.size} bytes)');
      if (file.isImage) {
        // file.dataUri is directly usable as a LayrzImage.source
      }
    }
  },
)
```

---

## Constructor

```dart
const LayrzFileInput({
  super.key,
  this.value = const [],
  this.onChanged,
  this.maxFiles,
  this.allowedExtensions,
  this.maxFileSizeBytes,
  this.rejectionMessage,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.disabled = false,
  this.errors = const [],
  this.hideDetails = false,
  this.focusNode,
  this.height = 160,
});
```

No asserts — every combination of parameters is valid.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `List<LayrzFileInputResult>` | `[]` | Currently selected files. The field self-displays its own picks/drops via `onChanged`, mirroring `LayrzSelectInput`'s self-display convention. |
| `onChanged` | `void Function(List<LayrzFileInputResult>)?` | `null` | Called after a successful pick, drop, clear, or replace. Never called for a rejected file. |
| `maxFiles` | `int?` | `null` (unlimited) | `1` → a new pick/drop replaces `value` wholesale. Any other finite number → a pick/drop exceeding it is truncated to remaining capacity, silently (not surfaced via `rejectionMessage`). |
| `allowedExtensions` | `List<String>?` | `null` (any type) | Extensions without the leading dot (e.g. `['png', 'jpg']`). Applied to both the system picker (`FileType.custom`) and drag-and-drop. |
| `maxFileSizeBytes` | `int?` | `null` (no limit) | Maximum size, in bytes, per file. A file exceeding it is rejected with `rejectionMessage`. |
| `rejectionMessage` | `String?` | `null` (generic English message) | Message shown persistently on rejection. Not localized through `LayrzUiL10n` — pass an explicit string for localization. |
| `labelText` | `String?` | `null` | Label displayed above the box. |
| `hintText` | `String?` | `null` (generic English "Click to browse or drag files here") | Text shown inside the empty-state box. |
| `isRequired` | `bool` | `false` | Renders a trailing `*` marker; does not itself enforce required-ness. |
| `disabled` | `bool` | `false` | A disabled box does not open the picker on tap, does not accept drops, and its clear/replace affordances are not focusable. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the box via the shared footer slot. |
| `hideDetails` | `bool` | `false` | Whether to hide the error message block. |
| `focusNode` | `FocusNode?` | `null` | Focus node for the drop-zone box. `null` → created and disposed internally. |
| `height` | `double` | `160` | Fixed height of the box, regardless of state or file count — populated files scroll within it rather than growing the box (D15). |

---

## `LayrzFileInputResult`

```dart
@immutable
class LayrzFileInputResult {
  LayrzFileInputResult({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  int get size;         // == bytes.length
  bool get isImage;      // mimeType starts with 'image/'
  final String dataUri;  // computed eagerly at construction

  Uint8List toBytes();
  String toDataUri();
}
```

| Property/Method | Type | Notes |
|---|---|---|
| `name` | `String` | Original file name, including extension (e.g. `photo.png`). |
| `mimeType` | `String` | Resolved MIME type, inferred from extension via `mimeTypeForExtension` when the source doesn't supply one. |
| `bytes` | `Uint8List` | Raw, decoded file bytes. |
| `size` | `int` | `bytes.length`. |
| `isImage` | `bool` | Whether `mimeType` starts with `image/`. |
| `dataUri` | `String` | `data:<mimeType>;base64,<payload>` — computed once at construction. Directly usable as `LayrzImage.source`. |
| `toBytes()` | `Uint8List` | Explicit accessor equivalent to `bytes`. |
| `toDataUri()` | `String` | Explicit accessor equivalent to `dataUri`. |

Two results are equal when `name`, `mimeType`, and `bytes` content are all equal — `dataUri` is derived and never compared directly.

---

## MIME type helpers

Both top-level functions in `file_input_result.dart`:

| Function | Signature | Notes |
|---|---|---|
| `mimeTypeForExtension` | `String mimeTypeForExtension(String? extension)` | Resolves a lowercase extension (no leading dot) via `kFileExtensionMimeTypes`, falling back to `application/octet-stream`. |
| `isImageMimeType` | `bool isImageMimeType(String mimeType)` | Returns whether `mimeType` starts with `image/`. |

---

## Behavior notes

- **Four visual states** (`LayrzFileInputState`, resolved by `LayrzFileInputStyleSpec.resolve`): `empty` (no files, no hover), `hover` (pointer over the box, or keyboard focus), `dragging` (an active drag-and-drop over the box), `populated` (≥1 file accepted). Precedence: `disabled > error (errors.isNotEmpty || active rejection) > dragging > hover > populated > empty`. Transitions vary only color/border (D15) — `dragging`'s border is drawn at double width as the sole deliberate exception.
- **Click-to-browse.** The whole empty-state box is one tap/keyboard `Semantics(button: true)` target. Activating it opens `FilePicker.pickFile()` (when `maxFiles == 1`) or `FilePicker.pickFiles()` (constrained by `allowedExtensions`) otherwise.
- **Validation and rejection.** A rejected/oversized file surfaces `rejectionMessage` as persistent on-screen text below the box — not a toast, no auto-dismiss timer. A mixed batch is rejected as a whole (the first invalid file stops the entire commit).
- **Populated state rows.** Each accepted file renders with a thumbnail/icon preview, its name, and a keyboard-reachable clear button; an "Add more" row always follows, plus a "Clear all" row when more than one file is selected. Deliberately no single box-level `Semantics`/tap handler in this state — merging every row into one node would combine their announced labels incorrectly.
- **Label/errors outside the box.** Exactly like `LayrzSelectInput`/`LayrzComboBoxInput`/`LayrzDurationInput` — `labelText` is hoisted above, `errors` rendered below via `LayrzInputFooterSlot`, both outside the box's own chrome (this widget has no `LayrzInputChrome` to render them inside).
- **Not built on `LayrzInputChrome`.** Unlike every text-shaped field, `LayrzFileInput` is a box-shaped drop target with no cursor or text-editing concerns — it composes its own chrome from scratch, hand-rolled around `file_picker` + `desktop_drop`.
