---
name: layrz-ui-icon-input
description: Use LayrzIconInput in a layrz_ui Flutter widget. Apply when adding a field that lets the user pick a single Material Design icon from a ~7,447-entry registry — searchable, virtualized grid, commit-on-tap with no Save step.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A single-icon picker field, sourced from the `flutter_mdi_remap` Material Design Icons registry (~7,447 entries).
- Storing a stable, serializable icon reference — `value` is the icon's `'mdi-...'` name string, resolved back to a renderable icon via `findMdiRemapIconByName`.
- **Do not use** for a Unicode emoji — use `LayrzEmojiInput` instead.
- **Do not use** when the caller needs URL/upload/icon/emoji all as options for one field — use `LayrzDynamicAvatarInput` instead.

---

## Minimal usage

```dart
LayrzIconInput(
  labelText: 'Icon',
  hintText: 'Pick an icon',
  value: iconName,
  errors: iconErrors,
  onChanged: (value) {
    iconName = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Commit-on-tap — no Save row.** Tapping an icon in the surface both fires `onChanged` and closes the surface immediately. No draft, no Cancel/Save row.
- **No Clear affordance.** Escape/barrier tap/back close with no value picked, exactly like backing out.
- `onChanged` is **never called with `null`** — its type is `ValueChanged<String>?`, not nullable-argument.
- `value` is a stable `String?` `'mdi-...'` name (e.g. `'mdi-account'`), **not** an `IconData` and **not** an `MdiRemapIcon` — an `IconData` codepoint is not stable across package versions, only the registry name is.
- **Round-trip contract:** a name the caller feeds back in from persisted storage resolves correctly as long as `findMdiRemapIconByName` recognizes it. An unresolvable name falls back to the empty/hint display rather than crashing.
- The surface search matches case-insensitively against both `MdiRemapIcon.name` and `MdiRemapIcon.tags`; an empty query resolves to the full ~7,447-entry registry.
- The icon grid is virtualized (8 columns, 44×44px cells) — required at this item count, so never wrap the surface's own scrolling in an additional scroll container.
- `disabled: true` makes the field fully non-interactive.

---

## Common patterns

```dart
// 1. Required icon field
LayrzIconInput(
  labelText: 'Category icon',
  isRequired: true,
  value: categoryIconName,
  errors: categoryIconName == null ? ['Pick an icon'] : const [],
  onChanged: (value) => setState(() => categoryIconName = value),
)

// 2. Rendering a persisted icon name elsewhere (e.g. a summary card)
final icon = iconName == null ? null : findMdiRemapIconByName(iconName!);
if (icon != null) Icon(icon.data, size: 24);

// 3. Disabled, pre-filled
LayrzIconInput(
  labelText: 'Locked icon',
  value: 'mdi-lock',
  disabled: true,
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — there is no `context.getErrors` in layrz_ui; the caller computes and owns the list.
- Separate stacked inputs with `SizedBox(height: 10)` (or the host app's own spacing tokens).
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
- Always store and round-trip the `String` name, never a raw `IconData` — codepoints are not guaranteed stable across `flutter_material_design_icons` versions.
