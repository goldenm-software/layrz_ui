---
name: layrz-ui-bottom-sheet
description: Use LayrzBottomSheet in a layrz_ui Flutter widget. Apply when presenting content above the page as a modal or persistent draggable sheet — picker fallbacks on compact viewports, confirmation sheets with an actions row, or supplementary non-blocking panels.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any bottom-anchored modal or persistent surface: compact-viewport picker fallback, confirmation prompt, supplementary panel that coexists with the page.
- `LayrzBottomSheet` is a **static-method surface** — `LayrzBottomSheet.show<T>()` only. There is no widget to construct and no `State` to manage.
- Use `isPersistent: true` for non-blocking UI that stays open alongside the page (no barrier, page stays interactive).
- Use `actions` for a right-aligned button row pinned below the scrollable content — mirrors `LayrzDialog.show`'s `actions` slot.
- **Do not use** on a wide/desktop viewport for picker inputs — use `LayrzAnchoredPanel` instead; `LayrzSelectInput`/`LayrzDurationInput`/`LayrzComboBoxInput` already switch automatically via `context.isCompact`.
- **Do not use** for a centered, non-draggable confirmation — use `LayrzDialog.show` instead.

---

## Minimal usage

```dart
final selected = await LayrzBottomSheet.show<String>(
  context,
  semanticLabel: 'Choose an option. Press Escape to close.',
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: options
        .map((o) => LayrzTappable(onTap: () => Navigator.of(context).pop(o), child: Text(o)))
        .toList(),
  ),
);
```

---

## Key behaviors

- `show<T>()` returns `Future<T?>` — completes with whatever value the sheet's content passes to `Navigator.pop`, or `null` if dismissed without one.
- **Always pushes on the root navigator** (`Navigator.of(context, rootNavigator: true)`) — intrinsic, not caller-configurable. There is no `useRootNavigator` parameter (it was removed; only one value was ever correct).
- `semanticLabel` is **required for modal sheets** to get dialog route semantics — with no label, no dialog semantics are added at all (avoids an unlabeled focus trap). Ignored for persistent sheets.
- `canDismiss` (default `true`) gates the barrier tap, Escape, drag-to-dismiss, and the system/Android back gesture **together** — it does **not** infer `false` from `actions` being present (unlike `LayrzDialog.show`). Pass it explicitly.
- The drag handle (`showDragHandle: true`, default) still renders and still **resizes** the sheet even when `canDismiss: false` — only drag-past-the-end dismissal is disabled.
- Keyboard handling is automatic: the sheet shrinks to the space above the keyboard and pins there; closing the keyboard restores the exact prior size. No caller wiring needed.
- Set `scrollable: false` when `builder` returns its own `ListView`/`GridView` — otherwise a same-axis scrollable nested in the sheet's own `SingleChildScrollView` asserts on unbounded height.

---

## Common patterns

```dart
// 1. Persistent, non-blocking panel — no barrier, page stays interactive
LayrzBottomSheet.show<void>(
  context,
  isPersistent: true,
  builder: (context) => _buildSupplementaryPanel(),
);

// 2. Confirmation with an actions row
final confirmed = await LayrzBottomSheet.show<bool>(
  context,
  semanticLabel: 'Delete item? Press Escape to cancel.',
  builder: (context) => const Text('This cannot be undone.'),
  actions: [
    LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.delete(labelText: 'Delete', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// 3. Non-dismissible — answered only through actions
final confirmed = await LayrzBottomSheet.show<bool>(
  context,
  canDismiss: false,
  semanticLabel: 'Confirm the action.',
  builder: (context) => const Text('This action cannot be undone.'),
  actions: [
    LayrzButton.save(labelText: 'Confirm', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// 4. Caller-owned scrollable (own ListView)
LayrzBottomSheet.show<void>(
  context,
  scrollable: false,
  builder: (context) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => Text(items[i]),
  ),
);
```

---

## `isPersistent` × `canDismiss`

| | `canDismiss: true` (default) | `canDismiss: false` |
|---|---|---|
| `isPersistent: false` (modal) | Barrier tap, Escape, drag, back gesture all dismiss | Barrier still paints but does not handle taps; Escape/drag/back gesture blocked |
| `isPersistent: true` | No barrier; Escape, drag, back gesture dismiss | No barrier; Escape, drag, back gesture blocked — closes only via `actions`/`builder` content |

---

## Usage conventions

- Localize `semanticLabel` and any text inside `builder`/`actions` via `LayrzUiL10n.of(context).<key>` — never hardcode strings.
- Always supply `semanticLabel` for a modal (`isPersistent: false`) sheet — it is the only way screen readers get dialog-role announcement and exit-path guidance.
- Prefer the six `LayrzButton` semantic factories (`.save`, `.cancel`, `.delete`, …) inside `actions` — they encode this design system's icon/color conventions the same way they do everywhere else.
- Pass `canDismiss: false` deliberately, not by default — it is meant for flows that must be answered, not escaped; pair it with an `actions` row or a pop-triggering control inside `builder`.
- There is no close ("X") affordance on a sheet by design — don't try to add one; dismissal is swipe, barrier tap, Escape, or an explicit `actions`/`builder` control.
