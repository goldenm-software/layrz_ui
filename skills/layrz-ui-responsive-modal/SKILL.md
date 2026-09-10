---
name: layrz-ui-responsive-modal
description: Use LayrzResponsiveModal in a layrz_ui Flutter widget. Apply when a modal should present as a LayrzDialog on wide viewports and a LayrzBottomSheet on narrow ones, chosen once at show() call time — avoids duplicating the dialog-vs-sheet breakpoint branch yourself.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.dialog`, `.sheet`) — never the fully-qualified form (`LayrzModalPresentation.dialog`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any modal that should read as a dialog on desktop-width viewports and a bottom sheet on narrow/mobile ones, without hand-writing that breakpoint branch yourself.
- Use the default (`isCompact` unset) to let it resolve from `context.isCompact` automatically.
- Pass `isCompact: true`/`false` to force one branch regardless of actual viewport — e.g. forcing the sheet's full-height scroll for a long option list even on a wide window.
- **Do not use** when you specifically need `LayrzDialog`'s structured `title`/`content` slots — this wrapper only exposes `builder` + `actions`; call `LayrzDialog.show` directly instead.
- **Do not use** expecting the presentation to re-evaluate on window resize — it is decided exactly once at `show()` call time and never changes for the life of the route. See Key behaviors.

---

## Minimal usage

```dart
final selected = await LayrzResponsiveModal.show<String>(
  context,
  semanticLabel: 'Choose an option.',
  builder: (context) => _buildOptionList(context),
);
// LayrzDialog at >= 960px viewport width, LayrzBottomSheet below it —
// decided once, at this call.
```

---

## Key behaviors

- **Presentation is resolved exactly once, at `show()` call time, and never re-evaluated.** There is no `LayoutBuilder`, no `MediaQuery` listener, nothing rebuilding across the breakpoint. A modal opened wide and then resized narrow stays on its original surface for the entire life of that route. This is deliberate — re-evaluating mid-route is itself unwanted behavior this component does not have.
- **`canDismiss` infers from `actions`**, mirroring `LayrzDialog.show`'s own rule: dismissible when `actions` is null/empty, not dismissible when `actions` is non-empty — computed once and forwarded to both branches identically.
- **`actions` is pinned below `builder`'s content on both branches.** On the sheet branch it forwards to `LayrzBottomSheet.show`'s own `actions`; on the dialog branch it is composed into `LayrzDialog.show`'s `child` (since `child` and `actions` are mutually exclusive on that method) alongside `builder`'s result.
- **There is no `title`/`content` parameter — only `builder` and `actions`.** This is a deliberate API limitation, not an oversight: the same `builder` result must serve both branches, and the sheet branch has no equivalent slotted shape to receive a separate `title`/`content`.
- **`showCloseIcon` only affects the dialog branch.** Forwarded verbatim to `LayrzDialog.show`; silently ignored when the sheet branch is chosen (the sheet has no close icon at all).
- Branch-specific parameters live in two config objects — `LayrzDialogConfig` (`maxWidth`, `maxHeight`) and `LayrzBottomSheetConfig` (`snapSizes`, `initialSize`, `minSize`, `maxSize`, `showDragHandle`, `scrollable`) — rather than one flattened parameter superset.
- Both branches always push on the root navigator — intrinsic to each underlying component, not something this wrapper configures.

---

## Common patterns

```dart
// Forcing the sheet even at a wide breakpoint (long option list)
await LayrzResponsiveModal.show<void>(
  context,
  isCompact: true,
  builder: (context) => _buildLongOptionList(context),
);

// Configuring both branches
await LayrzResponsiveModal.show<void>(
  context,
  builder: (context) => _buildDetail(context),
  dialog: const LayrzDialogConfig(maxWidth: 560, maxHeight: 720),
  sheet: const LayrzBottomSheetConfig(snapSizes: [0.4, 0.9]),
);

// Locking in with actions — dismissible defaults to false
await LayrzResponsiveModal.show<bool>(
  context,
  builder: (context) => const Text('Confirm this operation?'),
  actions: [
    LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.save(labelText: 'Confirm', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Suppressing the dialog branch's close icon
await LayrzResponsiveModal.show<void>(
  context,
  showCloseIcon: false,
  builder: (context) => _buildBodyWithOwnCancelButton(context),
);
```

---

## Usage conventions

- Always type `LayrzResponsiveModal.show<T>` with the expected return value and branch on `null` for "dismissed without answering", identically to `LayrzDialog.show`/`LayrzBottomSheet.show`.
- Never branch your own code on which surface was actually presented — the `Future<T?>` contract is identical either way.
- Reach for `LayrzDialog.show` directly only when you specifically need its structured `title`/`content` slots — otherwise prefer this wrapper so mobile users automatically get the sheet.
- Configure `dialog`/`sheet` only with the parameters relevant to their own branch — a caller configuring the dialog branch is never shown sheet-only parameters and vice versa.
- Do not expect a resize while the modal is open to change its surface — if the user rotates a device or resizes a window mid-route, the modal deliberately keeps its original presentation.
