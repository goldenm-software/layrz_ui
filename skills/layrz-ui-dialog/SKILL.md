---
name: layrz-ui-dialog
description: Use LayrzDialog in a layrz_ui Flutter widget. Apply when presenting a focused, page-relative modal interruption — a centered, size-bounded panel behind a barrier, via LayrzDialog.show<T>() with title/content/actions slots or a child escape hatch, confirm/cancel flows, and canDismiss-gated dismissal.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values where applicable — `LayrzDialog` itself takes no enum parameters.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A page-relative interruption that must block or focus attention: confirm/cancel, delete confirmation, a small form, an informational notice.
- Use the `title`/`content`/`actions` slots for the overwhelmingly common "title + body + confirm/cancel" shape.
- Use the `child` escape hatch only for layouts those three slots cannot express — especially genuinely fill-height content (`Expanded`, `Flexible`, a bare `ListView`/`GridView`).
- **Do not use** for a surface that must adapt between dialog (wide) and bottom sheet (narrow) — use `LayrzResponsiveModal` instead, which composes this component.
- **Do not use** for a field-relative, non-modal overlay tethered to the widget that opened it — use `LayrzAnchoredPanel` instead; `LayrzDialog` always centers and always carries a barrier.
- **Do not use** to stack a second dialog while one is already open — this fails loudly with an assertion; dismiss the current one first.

---

## Minimal usage

```dart
final confirmed = await LayrzDialog.show<bool>(
  context,
  title: const Text('Delete item?'),
  content: const Text('This cannot be undone.'),
  actions: [
    LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.delete(labelText: 'Delete', onTap: () => Navigator.of(context).pop(true)),
  ],
);
```

---

## Key behaviors

- **`LayrzDialog` is a static-method surface — there is no widget to construct.** `LayrzDialog.show<T>()` pushes a route and returns `Future<T?>`, completing with whatever value is passed to `Navigator.pop`, or `null` if dismissed without one.
- **`child` and the `title`/`content`/`actions` slots are mutually exclusive** — supplying `child` together with any of the other three fires an assertion.
- **`canDismiss` defaults from `actions`, not to a fixed value:** `null` (default) infers `true` when `actions` is `null` (informational, nothing to lose) and `false` when `actions` is non-null (decision-bearing — must be answered, not escaped). It gates four routes together: barrier tap, Escape, the X icon, and the system/Android back gesture.
- **When `actions` is non-null and `canDismiss` stays `false`, the X close icon is not rendered at all** — not disabled, absent. The only way out is one of the dialog's own `actions`.
- **`showCloseIcon` is a separate, independent opt-out from `canDismiss`.** Defaults to `true`. Passing `false` suppresses only the X icon's render — barrier tap, Escape, and back-gesture dismissal still obey `canDismiss` untouched. Use it when your body already supplies its own close/cancel affordance that would otherwise collide with the X.
- **`content` receives unbounded height** from its internal scroll view — a fill-seeking child (`Expanded`, `Flexible`, a bare `ListView`/`GridView`) inside `content` throws. Give it an explicit height, set `shrinkWrap: true`, or switch to the `child` escape hatch instead.
- **`LayrzDialog.show` always pushes on the root navigator** — this is intrinsic, not configurable. There is no `useRootNavigator` parameter.
- Stacking a second `LayrzDialog` while one is open is unsupported and throws an assertion — dismiss the current one first.
- Focus is captured before the dialog opens and explicitly restored to the invoker on dismiss.

---

## Common patterns

```dart
// Informational, dismissible by default (no actions)
await LayrzDialog.show<void>(
  context,
  title: const Text('Sync complete'),
  content: const Text('All changes were saved.'),
);

// child escape hatch for fill-height / custom content
await LayrzDialog.show<void>(
  context,
  child: _buildCustomStepperContent(),
);

// Explicitly re-opening dismissal on a decision-bearing dialog
await LayrzDialog.show<bool>(
  context,
  title: const Text('Discard draft?'),
  content: const Text('Your changes have not been saved.'),
  canDismiss: true, // caller judges the stakes low enough
  actions: [
    LayrzButton.cancel(labelText: 'Keep editing', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.delete(labelText: 'Discard', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Suppressing the X because the body already has its own cancel affordance
await LayrzDialog.show<void>(
  context,
  showCloseIcon: false,
  child: _buildPickerBodyWithOwnCancelButton(),
);

// Content taller than maxHeight — scrolls internally
await LayrzDialog.show<void>(
  context,
  title: const Text('Release notes'),
  content: const Text(veryLongChangelog),
);

// A fill-height list inside content — give it an explicit height
await LayrzDialog.show<void>(
  context,
  title: const Text('Select an item'),
  content: SizedBox(
    height: 300,
    child: ListView(children: itemTiles),
  ),
);
```

---

## Usage conventions

- Always type `LayrzDialog.show<T>` with the value you expect back (`bool` for confirm/cancel, `void` for informational) and branch on `null` for "dismissed without answering".
- Prefer the `title`/`content`/`actions` slots over `child` whenever your layout is expressible that way — `child` gets no title row or action row for free.
- Never pass both `child` and any of `title`/`content`/`actions` — it asserts.
- For a dialog carrying `actions`, leave `canDismiss` unset unless you have deliberately judged the stakes low enough to allow a stray escape.
- Wrap fill-seeking widgets inside `content` with an explicit `SizedBox(height: ...)` or `shrinkWrap: true`, or switch to `child` — do not fight the unbounded-height constraint.
- Localize `title`/`content`/action labels via `LayrzUiL10n.of(context)` or your app's i18n layer — never hardcode strings.
