---
name: layrz-ui-search-input
description: Use LayrzSearchInput in a layrz_ui Flutter widget. Apply when adding a debounced search field — .auto (responsive field/icon), .field (always inline), or .icon (magnifier button that opens an anchored panel) presentation modes.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.auto`, `.field`, `.icon`) — never the fully-qualified form (`LayrzSearchInputMode.auto`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A search box on a list/table toolbar, a page header, or any place the user types a query to filter results.
- Choose `mode` by **space and layout**:
  - `.auto` (default) — icon mode below 960px, field mode at or above it. Best default for responsive toolbars.
  - `.field` — always an inline field with magnifier prefix + clear suffix. Use in forms or when horizontal space is abundant.
  - `.icon` — always a collapsed magnifier button that opens an anchored panel. Use in dense toolbars where space is always constrained.
- **Do not use** for free-text entry that isn't a search query (name, notes, etc.) — use `LayrzTextInput` instead.
- **Do not use** for autocomplete against a fixed option list — use `LayrzComboBoxInput` instead.

---

## Minimal usage

```dart
LayrzSearchInput(
  onSearch: (query) {
    setState(() => searchQuery = query);
  },
)
```

---

## Key behaviors

- There is no `labelText` parameter at all — this field is never labeled the way other inputs are.
- `debounce` (default `300ms`) delays `onSearch`; pass `debounce: null` to fire on every keystroke instead.
- The clear ("×") affordance appears as soon as the field has text (works while typing, not only when seeded via `value`) and disappears once cleared.
- `readOnly: true` renders a lock affordance in the trailing icon cluster but does not affect the clear button, which is driven solely by whether the field has text.
- `mode: .icon` opens an anchored panel via `LayrzAnchoredPanel` on `preferredSide` (default `.right`) — flips to the opposite side if it doesn't fit, clamps into the overlay if neither does.
- Exposes `errors`, `helpTitleText`/`helpContentText` — additive beyond the layrz_theme mirror, since this composes `LayrzInputChrome` directly.

---

## Common patterns

```dart
// 1. Always-inline field mode
LayrzSearchInput(
  mode: .field,
  hintText: 'Search devices…',
  onSearch: (query) => filterDevices(query),
)

// 2. Always-icon mode for a dense toolbar
LayrzSearchInput(
  mode: .icon,
  onSearch: (query) => filterResults(query),
)

// 3. No debounce — fire on every keystroke
LayrzSearchInput(
  debounce: null,
  onSearch: (query) => liveFilter(query),
)

// 4. With validation error and help tooltip
LayrzSearchInput(
  errors: const ['Search failed — try again'],
  helpTitleText: 'Search',
  helpContentText: 'Matches device name, ID, or tag.',
  onSearch: (query) => search(query),
)

// 5. Constrained width in field mode
LayrzSearchInput(
  mode: .field,
  maxWidth: 320,
  onSearch: (query) => search(query),
)
```

---

## Form conventions

- Use `hintText` via `LayrzUiL10n.of(context)`-sourced strings when it needs to be non-default — otherwise it falls back to a localized "Search" string automatically.
- Pass `errors: [...]` for validation state — never `context.getErrors`.
- Prefer `.auto` unless the surrounding layout has a firm reason to pin one presentation.
- `preferredSide` only applies in icon mode (including `.auto` on a compact viewport) — ignored in field mode.
