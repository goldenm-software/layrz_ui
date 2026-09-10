# LayrzChip — API Reference

Source: `lib/src/chips/src/chip.dart`
- `LayrzChip` class
- `LayrzChipStyle` enum — `lib/src/chips/src/chip_style.dart`
- `LayrzChipType` enum — `lib/src/chips/src/chip_type.dart`

---

## Examples

```dart
// Basic chip, default filled/custom (falls back to primary)
LayrzChip(labelText: 'Flutter')

// Semantic type
LayrzChip(labelText: 'Active', type: .success)

// Outlined style with a delete affordance
LayrzChip(
  labelText: 'Remove me',
  onDelete: () => setState(() => labels.remove('Remove me')),
  type: .warning,
  style: .outlined,
)

// Custom color (type must be .custom)
LayrzChip(
  labelText: 'Custom Color',
  type: .custom,
  color: const Color(0xFF9C27B0),
  style: .filled,
)

// Measuring intrinsic width (used internally by LayrzChipGroup)
final chip = LayrzChip(labelText: 'Tag 1');
final width = chip.computeWidth(context);
```

---

## Constructor

```dart
const LayrzChip({
  super.key,
  required this.labelText,
  this.onDelete,
  this.style = LayrzChipStyle.filled,
  this.type = LayrzChipType.custom,
  this.color,
}) : assert(
       type == LayrzChipType.custom || color == null,
       'color applies only when type is LayrzChipType.custom.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | — | **Required.** Text label displayed in the chip. |
| `onDelete` | `VoidCallback?` | `null` | Called when the delete icon is tapped. When `null`, no delete icon is rendered. |
| `style` | `LayrzChipStyle` | `.filled` | Visual style — fill and border treatment. |
| `type` | `LayrzChipType` | `.custom` | Semantic type determining the accent color. |
| `color` | `Color?` | `null` | Explicit accent color override. Only honored when `type == .custom`; passing it with any other `type` throws an assertion error. |

---

## `LayrzChipStyle` enum

| Value | Background | Border | Content color |
|---|---|---|---|
| `.filled` | Solid accent color | None | Contrast color (readable against the solid fill) |
| `.outlined` | Transparent | Accent-colored, 1px (`hasBorder == true`) | Accent color |

---

## `LayrzChipType` enum

| Value | Token color | Use case |
|---|---|---|
| `.info` | `tokens.colors.info` | Neutral labels |
| `.success` | `tokens.colors.success` | Positive labels |
| `.warning` | `tokens.colors.warning` | Cautionary labels |
| `.danger` | `tokens.colors.danger` | Destructive/critical labels |
| `.context` | `tokens.colors.contextual` | Context-dependent labels |
| `.custom` | `color` param (fallback `tokens.colors.primary`) | **Default.** Explicit color override |

Accent resolution in source is `widget.type.colorToken(tokens) ?? widget.color ?? tokens.colors.primary` — `colorToken` returns non-null for every value except `.custom`, so in practice a non-custom `type` always wins over `color`, and `.custom` falls through to `color` (or primary).

---

## Static members

| Member | Signature | Notes |
|---|---|---|
| `computeWidth` | `double computeWidth(BuildContext context)` | Instance method (not static). Measures the intrinsic rendered width in logical pixels — label text width at `tokens.typography.label`, plus delete-icon space (`kLayrzChipIconSize` + `tokens.spacing.sp1`) when `onDelete` is set, plus horizontal padding (`tokens.spacing.sp2 * 2`). Used by `LayrzChipGroup` in `.compact` mode to determine overflow. |

---

## Behavior notes

- **No selection semantics**: chips never track a "selected"/"active" state. If the user needs to choose among options, use an input component (`LayrzSelectInput`, `LayrzMultiSelectInput`), not chips.
- **Only the delete icon is interactive**: hover, press, and focus feedback apply solely to the delete affordance (rendered as `MdiIcons.close` at `kLayrzChipIconSize`, 18.0lp). The chip body itself never responds to hover, press, or tap.
- **Fixed sizing**: height, padding (`tokens.spacing.sp2` horizontal, `tokens.spacing.sp1 / 2` vertical), and border radius (`tokens.radius.r1`) are not exposed as parameters — chips are intentionally compact and consistent.
- **Rounded box, not a pill**: the design system prefers `tokens.radius.r1` corners over a fully rounded `tokens.radius.full` shape, distinguishing `LayrzChip` from `LayrzBadge`.
- **Accessibility**: the label text carries its own `Semantics(label: labelText)`; the delete icon is wrapped in `Semantics(button: true, label: 'Delete $labelText')`.
