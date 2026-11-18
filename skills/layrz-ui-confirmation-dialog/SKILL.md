---
name: layrz-ui-confirmation-dialog
description: Use LayrzConfirmationDialog in a layrz_ui Flutter widget. Apply when an action needs a yes/no confirmation before running, above all every delete action (single or bulk, via LayrzConfirmationDialog.delete with l10n default texts and an item-name list), or any other confirm (lock, suspend, discard) via LayrzConfirmationDialog.show with a semantic confirm color, resolving to Future<bool>.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for enum values, e.g. `type: .warning`.

> **Full signatures and parameter reference:** read `references/api.md` in this skill's directory.

---

## When to use

- **Every delete action** (row action, detail pane, bulk selection): `LayrzConfirmationDialog.delete`.
- Any other action that must be confirmed before it runs (lock, suspend, discard, reset): `LayrzConfirmationDialog.show`.
- **Do not hand-roll** a `LayrzDialog.show<bool>` with two buttons for a confirmation; this is that dialog.
- **Do not use** for dialogs that collect input or show information; use `LayrzDialog` directly.

---

## Minimal usage

```dart
// Single delete, all texts from LayrzUiL10n
if (!await LayrzConfirmationDialog.delete(context, items: [user.name])) return;

// Bulk delete: plural title/description once items.length > 1
final ok = await LayrzConfirmationDialog.delete(context, items: selected.map((u) => u.name).toList());
```

---

## Key behaviors

- **Always resolves to `bool`, never `null`.** `true` only for the confirm button; the dismiss button, barrier tap, Escape, the X icon and the back gesture all resolve `false`.
- **Dismissible by default (`canDismiss: true`)**, unlike a plain `LayrzDialog` with actions. Escaping means "no", which is safe. Pass `canDismiss: false` to force an explicit choice (also hides the X).
- **`delete` defaults come from `context.l10n`**: `confirmationTitle`/`confirmationContent`, switching to `confirmationMultipleTitle`/`confirmationMultipleContent` when `items.length > 1`. Labels default to `confirmationConfirm`/`confirmationDismiss`. Consumers translate them through their `LayrzUiL10n` subclass (e.g. `confirmations.*` keys), so do not pass hardcoded strings just to localize.
- **`items` render comma-separated** under the description, in label size with title weight. Empty `items` renders no list.
- **Confirm color is `type`** (`LayrzButtonType`, default `success`). The dismiss button takes the opposite color: `success` when `type` is `danger` or `warning`, `danger` otherwise. `delete` uses `danger` + trash icon (same look as `LayrzButton.delete`).
- `title` is also the dialog's route semantics label.
- Pushes on the root navigator (inherited from `LayrzDialog`); buttons pop through a guard, so a double tap cannot pop the page underneath.

---

## Common patterns

```dart
// Delete with a custom, entity-specific title
final ok = await LayrzConfirmationDialog.delete(
  context,
  title: i18n.t('users.delete.single.title', {'name': user.name}),
  items: [user.name],
);
if (!ok || !context.mounted) return;
await notifier.delete([user.id]);

// Generic confirm with a warning color and icon
final suspend = await LayrzConfirmationDialog.show(
  context,
  title: i18n.t('users.actions.suspend.title'),
  description: i18n.t('users.actions.suspend.description'),
  confirmLabel: i18n.t('actions.suspend'),
  type: .warning,
  icon: MdiIcons.accountCancelOutline,
);

// Two-step confirmation: chain two calls
final confirmed = await LayrzConfirmationDialog.show(context, title: i18n.t('users.actions.confirmation')) &&
    context.mounted &&
    await LayrzConfirmationDialog.show(context, title: i18n.t('users.actions.confirmation2'));

// Extra body below the description
await LayrzConfirmationDialog.show(
  context,
  title: 'Reset settings?',
  description: 'These values will be restored:',
  content: const _ResetSummary(),
);
```

---

## Usage conventions

- Await the result and return early on `false`; check `context.mounted` before using `context` again.
- Prefer `delete` over `show(type: .danger)` for deletions so the copy and look stay uniform.
- Pass item display names, not ids, in `items`.
- There is no `steps` parameter; chain `show` calls for multi-step confirmation.
