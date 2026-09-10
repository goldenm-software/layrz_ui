# LayrzSelectableAction — API Reference

Source: `lib/src/selection/src/selectable_action.dart`
- `LayrzSelectableAction` class (`@immutable`)

---

## Examples

```dart
// Built-ins — static const fields, never called as methods
LayrzSelectableAction.copy
LayrzSelectableAction.cut
LayrzSelectableAction.paste
LayrzSelectableAction.selectAll

// All built-ins as a Set
LayrzSelectableAction.defaults // {copy, cut, paste, selectAll}

// Custom action
final shareAction = LayrzSelectableAction(
  label: (l10n) => 'Share',
  onPressed: () => shareSelection(),
  icon: MdiIcons.shareVariant,
);

// Field wiring
LayrzTextInput(
  labelText: 'Message',
  actions: {shareAction, LayrzSelectableAction.copy},
)

// Suppress the toolbar entirely
LayrzTextInput(
  labelText: 'Secret',
  actions: const {},
)
```

---

## Constructor

```dart
const LayrzSelectableAction({
  required this.label,
  required this.onPressed,
  this.icon,
}) : type = _customType; // 'custom'
```

There is also a private `LayrzSelectableAction._builtin({...})` constructor used only by the four static built-in fields — not callable from outside this file.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `label` | `String Function(LayrzUiL10n l10n)` | **required** | Returns the localized label text, given the ambient `LayrzUiL10n`. |
| `onPressed` | `VoidCallback` | **required** | Callback fired when the action is invoked. |
| `icon` | `IconData?` | `null` | Optional icon shown alongside the label in the toolbar. |
| `type` | `String` (getter, effectively) | `'custom'` for user-constructed actions | Exposed for testing/dedup logic. Built-ins carry `'copy'`/`'cut'`/`'paste'`/`'selectAll'`. |

---

## Static built-ins

| Member | Type | `type` value |
|---|---|---|
| `LayrzSelectableAction.copy` | `static const LayrzSelectableAction` | `'copy'` |
| `LayrzSelectableAction.cut` | `static const LayrzSelectableAction` | `'cut'` |
| `LayrzSelectableAction.paste` | `static const LayrzSelectableAction` | `'paste'` |
| `LayrzSelectableAction.selectAll` | `static const LayrzSelectableAction` | `'selectAll'` |
| `LayrzSelectableAction.defaults` | `static final Set<LayrzSelectableAction>` | All four above |

Each built-in's `onPressed` is a no-op (`_noOp`) — the actual clipboard/selection operation is handled by the toolbar implementation (`LayrzSelectionToolbar`/the hosting field), not by the action object itself.

---

## Equality and hashing

```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  if (other is! LayrzSelectableAction) return false;
  if (type == _customType || other.type == _customType) return false;
  return other.type == type;
}

@override
int get hashCode => type == _customType ? identityHashCode(this) : type.hashCode;
```

- **Built-in actions** (`type != 'custom'`) dedupe by `type` equality — two references to the same built-in are always equal.
- **Custom actions** (`type == 'custom'`) dedupe only by reference identity — never equal to another distinct custom instance, even with an identical label/callback.

**Consequence:** a `const` `Set` literal containing a custom `LayrzSelectableAction` does not compile, because the overridden `hashCode`/`==` make it unusable as a compile-time constant set member. Declare custom actions as `static final` instead of `const`.

---

## Filtering by field state

When a `Set<LayrzSelectableAction>` is supplied to a hosting field, it is automatically intersected with what the field's own state permits — this filtering happens inside the field, transparently:

```
Provided:   {copy, cut, selectAll}
obscureText: true  → effectively {selectAll}   (copy, cut removed)
readOnly: true      → effectively {copy, selectAll} (cut removed; paste was already absent)
```

The caller supplies the set they want; the field silently removes what it cannot support.

---

## Behavior notes

- **`actions: null`** on the hosting field offers all four built-ins, filtered by field state. **`actions: const {}`** suppresses the toolbar entirely.
- **Page-wide selection** (outside input fields, under a `SelectableRegion`) offers a hardcoded copy-only toolbar and does not use this class at all.
- **Localization** is driven by `label`'s `LayrzUiL10n` parameter — the built-ins resolve to `l10n.selectionCopy`/`selectionCut`/`selectionPaste`/`selectionSelectAll`.
