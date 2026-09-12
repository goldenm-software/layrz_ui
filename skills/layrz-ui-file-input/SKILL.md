---
name: layrz-ui-file-input
description: "Use LayrzFileInput in a layrz_ui Flutter widget. Apply when adding a file upload field — click-to-browse (primary affordance) plus drag-and-drop, single (`maxFiles: 1`) or multi-file, extension/size validation with a persistent rejection message, and results as `List<LayrzFileInputResult>` with base64/data-URI conversion built in."
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any form field that lets the user attach one or more files — a document upload, an image attachment, a bulk-import field.
- Set `maxFiles: 1` for a single-file field — a new pick/drop then **replaces** the selection wholesale rather than appending.
- Constrain accepted types with `allowedExtensions` and/or size with `maxFileSizeBytes`; a violation surfaces `rejectionMessage` persistently below the box (not a toast).
- **Do not use** for an avatar/profile-photo picker with icon/emoji/URL alternatives — use `LayrzDynamicAvatarInput` instead.
- **Do not use** `LayrzInputChrome`-style styling assumptions on this widget — it is deliberately **not** built on the shared chrome (it's a box-shaped drop zone, not a text field), so there is no cursor, no text-editing concerns, and label/errors are composed outside the box the same way `LayrzSelectInput` does.

---

## Minimal usage

```dart
LayrzFileInput(
  labelText: 'Attachment',
  maxFiles: 1,
  value: files,
  errors: fileErrors,
  onChanged: (result) => setState(() => files = result),
)
```

---

## Key behaviors

- **Click-to-browse is the primary affordance** — the whole empty-state box is one tap/keyboard target that opens the system file picker. Drag-and-drop is additive, not the only path.
- **Self-displaying.** Picking or dropping a file updates the box's own display immediately via `onChanged`, whether or not the caller feeds the same value back on the next build — mirrors `LayrzSelectInput`'s self-display convention.
- **Four visual states** (empty/hover/dragging/populated), resolved by `LayrzFileInputStyleSpec`, varying only color/border — never size/padding, except `dragging`'s deliberately thicker border. State precedence: `disabled > error > dragging > hover > populated > empty`.
- **Rejections are persistent, not a toast.** A file failing `allowedExtensions`/`maxFileSizeBytes` surfaces `rejectionMessage` as on-screen text below the box that stays until the next successful pick/drop/clear — it never auto-dismisses on a timer.
- **A mixed batch is rejected as a whole.** The first invalid file in a multi-file drop/pick stops the entire batch from committing — nothing is silently dropped file-by-file (the one exception: exceeding `maxFiles` truncates the batch to remaining capacity, silently, since that's a quantity constraint rather than a per-file validation failure).
- **Label and errors render outside the box**, in an outer `Column` — exactly like `LayrzSelectInput`/`LayrzComboBoxInput`/`LayrzDurationInput`.
- `rejectionMessage` is **not localized** through `LayrzUiL10n` — pass an explicit string for a localized app; the built-in default is generic English.

---

## Common patterns

```dart
// 1. Single-file field
LayrzFileInput(
  labelText: 'Profile document',
  maxFiles: 1,
  value: files,
  onChanged: (result) => setState(() => files = result),
)

// 2. Multi-file with extension and size constraints
LayrzFileInput(
  labelText: 'Supporting documents',
  hintText: 'Drop PDFs or images here',
  allowedExtensions: const ['pdf', 'png', 'jpg'],
  maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
  rejectionMessage: 'Only PDF or image files under 5 MB are allowed.',
  value: documents,
  onChanged: (result) => setState(() => documents = result),
  errors: documentErrors,
)

// 3. Reading the result (image thumbnail, direct data URI)
LayrzFileInput(
  onChanged: (result) {
    for (final file in result) {
      if (file.isImage) {
        // file.dataUri is directly usable as a LayrzImage.source
      }
    }
  },
)
```

---

## Form conventions

- Pass `errors: [...]` (a `List<String>`) for validation state raised by your own form logic — this is separate from the widget's own internal `rejectionMessage` mechanism for pick/drop-time file validation.
- Set `isRequired: true` to render the trailing `*` marker; this widget does not itself enforce required-ness — pair it with your form's own submit-time validation.
- Use `maxFiles: 1` for any field conceptually single-valued; do not rely on the caller truncating a multi-file result down to one after the fact.
- `height` defaults to `160` and is fixed regardless of file count (per the design system's D15 interaction rule) — populated files scroll within the box rather than growing it; do not expect the box to expand to fit more files.
