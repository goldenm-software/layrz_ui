---
name: layrz-ui-selectable-action
description: Use LayrzSelectableAction in a layrz_ui Flutter widget. Apply when customizing a text field's selection-toolbar actions — the four built-in static constants (copy/cut/paste/selectAll), custom actions via the public constructor, or suppressing the toolbar entirely with an empty Set.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Customizing which actions a `LayrzTextInput`'s (or another selection-toolbar-backed field's) context menu offers — pass a `Set<LayrzSelectableAction>` to the field's `actions` parameter.
- Adding an application-specific action (e.g. "Translate", "Share") alongside or instead of the built-ins.
- Suppressing the selection toolbar entirely by passing `const {}`.
- **Do not use** the class's built-ins as instance methods — they are `static const` fields (`LayrzSelectableAction.copy`, not `.copy()`). There are no `LayrzSelectableAction.copy()`/`.cut()` factory calls.
- **Do not use** `const` for a `Set` containing a custom action — a custom `LayrzSelectableAction` overrides `operator==` to dedupe only by identity, which makes a `const` instance unusable as a `Set` member at compile time; use `static final` instead.

---

## Minimal usage

```dart
// Restrict the toolbar to just Copy and a custom action
final shareAction = LayrzSelectableAction(
  label: (l10n) => 'Share',
  onPressed: () => shareSelection(),
);

LayrzTextInput(
  labelText: 'Message',
  actions: {shareAction, LayrzSelectableAction.copy},
)
```

---

## Key behaviors

- **Built-ins are `static const` fields, not factories.** `LayrzSelectableAction.copy`, `.cut`, `.paste`, `.selectAll` — reference them directly, never call them.
- **`actions: null`** (the field default) offers all four built-ins, filtered by field state. **`actions: const {}`** suppresses the toolbar entirely. A populated `Set` is intersected with what the field's state permits — e.g. an obscured field never offers copy/cut even if you included them.
- **Deduplication differs by kind.** Built-in actions dedupe by their `type` string (`'copy'`, `'cut'`, `'paste'`, `'selectAll'`) — only one of each ever shows. Custom actions dedupe only by reference identity (`type` is always `'custom'` for them) — two distinct custom instances with identical labels both show.
- **`const` custom actions don't compile.** Because `operator==` is overridden to compare by identity for custom actions, a `const LayrzSelectableAction(...)` literal cannot be placed in a `Set` at compile time. Declare it `static final` instead.
- **`label` is a function of `LayrzUiL10n`, not `BuildContext`.** `String Function(LayrzUiL10n l10n)` — resolve localized copy from the `l10n` parameter, not by capturing a `BuildContext`.
- `LayrzSelectableAction.defaults` is the `Set` of all four built-ins, for callers that want to start from the full set and remove one.

---

## Common patterns

```dart
// 1. Field with only the default built-in toolbar (no `actions` needed)
LayrzTextInput(labelText: 'Email')

// 2. Field with no toolbar at all
LayrzTextInput(
  labelText: 'Secret',
  actions: const {},
)

// 3. Custom action alongside a built-in
final shareAction = LayrzSelectableAction(
  label: (l10n) => 'Share',
  onPressed: () => shareSelection(),
);

LayrzTextInput(
  labelText: 'Message',
  actions: {shareAction, LayrzSelectableAction.copy},
)

// 4. Multiple custom actions — must be static final, not const
class MyFieldActions {
  static final translate = LayrzSelectableAction(
    label: (l10n) => 'Translate',
    onPressed: _translate,
  );
  static final email = LayrzSelectableAction(
    label: (l10n) => 'Email',
    onPressed: _emailText,
  );
}

LayrzTextInput(
  labelText: 'Text',
  actions: {
    MyFieldActions.translate,
    MyFieldActions.email,
    LayrzSelectableAction.copy,
    LayrzSelectableAction.selectAll,
  },
)
```

---

## Usage conventions

- Resolve localized labels via the `l10n` parameter the `label` function already receives — never call `LayrzUiL10n.of(context)` yourself inside it; the toolbar supplies it.
- Prefer `LayrzSelectableAction.defaults` plus a spread/removal over hand-listing all four built-ins when you only need to drop one (e.g. suppress `paste` on a display-only field that's otherwise selectable).
- Keep custom actions as `static final` fields on a class rather than constructing them inline in `build()` — building a new instance every rebuild changes their identity, and identity is exactly what dedupes them.
