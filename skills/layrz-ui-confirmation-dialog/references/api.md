# LayrzConfirmationDialog: API Reference

Source: `lib/src/dialogs/src/confirmation_dialog.dart`
- `LayrzConfirmationDialog` class (static-method surface; built on `LayrzDialog.show<bool>`)

---

## `show`

```dart
static Future<bool> show(
  BuildContext context, {
  required String title,
  String? description,
  Widget? content,
  String? confirmLabel,
  String? dismissLabel,
  LayrzButtonType type = LayrzButtonType.success,
  IconData? icon,
  bool canDismiss = true,
})
```

| Parameter | Default | Meaning |
|---|---|---|
| `title` | required | The question; title row and route semantics label. |
| `description` | `null` | Supporting text, first in the body (`typography.body`). |
| `content` | `null` | Extra body widget below `description`. |
| `confirmLabel` | `l10n.confirmationConfirm` | Confirm button label. |
| `dismissLabel` | `l10n.confirmationDismiss` | Dismiss button label. |
| `type` | `success` | Confirm button color. Dismiss gets `success` if `type` is `danger`/`warning`, else `danger`. |
| `icon` | `null` | Leading icon of the confirm button. |
| `canDismiss` | `true` | Whether barrier, Escape, X and back may close it (resolving `false`). `false` also hides the X. |

---

## `delete`

```dart
static Future<bool> delete(
  BuildContext context, {
  String? title,
  String? description,
  List<String> items = const [],
  String? confirmLabel,
  String? dismissLabel,
})
```

| Parameter | Default | Meaning |
|---|---|---|
| `title` | `l10n.confirmationTitle`, or `confirmationMultipleTitle` when `items.length > 1` | Dialog title. |
| `description` | `l10n.confirmationContent`, or `confirmationMultipleContent` when `items.length > 1` | Body text. |
| `items` | `[]` | Display names, rendered comma-separated below the description. |
| `confirmLabel` | `l10n.confirmationConfirm` | Confirm label. |
| `dismissLabel` | `l10n.confirmationDismiss` | Dismiss label. |

Confirm button: `type: danger`, icon `MdiIcons.trashCanOutline` (same look as `LayrzButton.delete`). Dismiss: `success`. Always dismissible.

---

## Return value

`true` only when the confirm button is tapped. Dismiss button, barrier, Escape, X and back gesture resolve `false`.
