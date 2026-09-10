# LayrzRadioInput&lt;T&gt; — API Reference

Source: `lib/src/inputs/src/radio/radio_input.dart` (+ `radio_option.dart`, `select/select_item.dart`)
- `LayrzRadioInput<T>` class — line 38
- `LayrzSelectItem<T>` class — see `select/select_item.dart` (shared with `LayrzSelectInput`)

---

## Examples

```dart
// Basic string radio group
LayrzRadioInput<String>(
  labelText: 'Payment method',
  items: const [
    LayrzSelectItem(value: 'card', child: Text('Card')),
    LayrzSelectItem(value: 'cash', child: Text('Cash')),
  ],
  value: paymentMethod,
  onChanged: (value) => setState(() => paymentMethod = value),
)

// Enum-typed radio group
LayrzRadioInput<Priority>(
  labelText: 'Priority',
  items: Priority.values
      .map((p) => LayrzSelectItem(value: p, child: Text(p.name)))
      .toList(),
  value: selectedPriority,
  onChanged: (value) => setState(() => selectedPriority = value),
)

// Custom column spans — 4 columns at every breakpoint
LayrzRadioInput<int>(
  labelText: 'Rating',
  xs: 3,
  sm: 3,
  md: 3,
  lg: 3,
  xl: 3,
  items: List.generate(4, (i) => LayrzSelectItem(value: i + 1, child: Text('${i + 1}'))),
  value: rating,
  onChanged: (value) => setState(() => rating = value),
)

// Disabled group
LayrzRadioInput<String>(
  labelText: 'Locked choice',
  items: const [LayrzSelectItem(value: 'a', child: Text('A'))],
  value: 'a',
  disabled: true,
)

// With errors
LayrzRadioInput<String>(
  labelText: 'Required choice',
  isRequired: true,
  items: options,
  value: selected,
  errors: const ['Please select an option'],
  onChanged: (value) => setState(() => selected = value),
)
```

---

## Constructor

```dart
const LayrzRadioInput({
  super.key,
  this.labelText,
  this.isRequired = false,
  required this.items,
  this.value,
  this.onChanged,
  this.disabled = false,
  this.errors = const [],
  this.hideDetails = false,
  this.xs = 12,
  this.sm = 6,
  this.md = 4,
  this.lg = 3,
  this.xl = 2,
}) : assert(xs > 0 && xs <= 12, 'xs must be between 1 and 12, got $xs'),
     assert(sm == null || (sm > 0 && sm <= 12), 'sm must be between 1 and 12, got $sm'),
     assert(md == null || (md > 0 && md <= 12), 'md must be between 1 and 12, got $md'),
     assert(lg == null || (lg > 0 && lg <= 12), 'lg must be between 1 and 12, got $lg'),
     assert(xl == null || (xl > 0 && xl <= 12), 'xl must be between 1 and 12, got $xl');
```

`items` with duplicate `value`s triggers a debug assertion inside the underlying `RadioGroup` at build time — not in this constructor.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Rendered above the grid. `null` renders no label. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `items` | `List<LayrzSelectItem<T>>` | **required** | Option list. `LayrzSelectItem.value` must be unique across items. |
| `value` | `T?` | `null` | Currently selected value. `null` or a non-matching value renders no option selected. |
| `onChanged` | `ValueChanged<T?>?` | `null` | Fires the selected item's value. Ignored when `disabled`. |
| `disabled` | `bool` | `false` | Grays out and disables every option; `onChanged` never fires. |
| `errors` | `List<String>` | `[]` | Rendered below the grid via the shared footer slot. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `xs` | `int` | `12` | Column span for `<600px`. Must be 1–12. |
| `sm` | `int?` | `6` | Column span for `600–959px`. `null` cascades to `xs`. |
| `md` | `int?` | `4` | Column span for `960–1263px`. `null` cascades to `sm`/`xs`. |
| `lg` | `int?` | `3` | Column span for `1264–1903px`. `null` cascades to `md`/`sm`/`xs`. |
| `xl` | `int?` | `2` | Column span for `≥1904px`. `null` cascades to `lg`/`md`/`sm`/`xs`. |

---

## Companion type: `LayrzSelectItem<T>`

```dart
const LayrzSelectItem({
  required this.value,
  required this.child,
  this.searchableStrings = const {},
});
```

| Field | Type | Notes |
|---|---|---|
| `value` | `T?` | The typed value handed back on selection. Nullable to support "none" entries. |
| `child` | `Widget` | **Required.** The option's only presentation — rendered as-is in the grid. Its own semantics (e.g. a plain `Text`'s implicit label) merge into the option's announced label. |
| `searchableStrings` | `Set<String>` | Ignored by `LayrzRadioInput` — no search in a radio group. Relevant only when the same item is reused with `LayrzSelectInput`. |

`LayrzSelectItem` also exposes `copyWith(...)` and a `matches(String query)` helper (unused by the radio group).

---

## Behavior notes

- **Interaction**: tapping an option's radio button or its label selects it and fires `onChanged`; tapping the currently-selected option again leaves it selected (no toggle-to-null); Arrow keys move focus within the group via the underlying `RadioGroup`.
- **Layout**: built on `LayrzRow`/`LayrzCol` — each item is wrapped in a `LayrzCol` with the resolved `xs`/`sm`/`md`/`lg`/`xl` spans, so the grid reflows per breakpoint the same way any other `LayrzRow` does.
- **Padding**: fixed internally at `tokens.spacing.pd2` (10px) around the group — not configurable. There is no `dense` flag (no chrome for it to act on).
- **Accessibility**: each option has `Semantics(inMutuallyExclusiveGroup: true, checked: ...)` announcing role and selected state; the group itself announces `labelText` as a container label. Selection is indicated by the filled radio dot, not colour alone (WCAG 1.4.1).
- **`RichText` trap**: `child`'s presentation is force-wrapped in an ambient `DefaultTextStyle`. `Text` and `Text.rich` inherit it; a raw `RichText` does not — its `TextSpan` paints with no colour if none is set explicitly, which the engine then renders solid white. Use `Text.rich`, never raw `RichText`, for multi-styled-run content.
