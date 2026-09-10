# LayrzCol — API Reference

Source: `lib/src/grid/src/col.dart`
- `LayrzCol` class

Breakpoint tokens: `lib/src/tokens/src/breakpoints.dart`
- `LayrzBreakpoint` enum
- `LayrzBreakpointTokens` class

Related: `LayrzRow` (`lib/src/grid/src/row.dart`, see the `layrz-ui-row` skill) — the parent that actually reads `spanAt` and lays columns out.

---

## Examples

```dart
// Cascade example: only xs/sm/md set
LayrzCol(
  xs: 12,
  sm: 6,
  md: 4,
  // lg inherits md's value (4) since not specified
  child: Text('Cascading column'),
)

// Full width everywhere (default)
LayrzCol(child: Text('Always full width'))

// Explicit span at every breakpoint
LayrzCol(xs: 12, sm: 8, md: 6, lg: 4, xl: 3, child: Widget())

// Reading the active band directly
final band = context.breakpoint; // LayrzBreakpoint.xs .. .xl

// Custom breakpoint thresholds via theme (app-level, not per-column)
LayrzThemeData(
  tokens: LayrzTokens(
    breakpoints: const LayrzBreakpointTokens(xs: 500, sm: 800, md: 1100, lg: 1600),
  ),
)
```

---

## Constructor

```dart
const LayrzCol({
  super.key,
  this.xs = 12,
  this.sm,
  this.md,
  this.lg,
  this.xl,
  required this.child,
}) : assert(xs > 0 && xs <= 12, 'xs must be between 1 and 12, got $xs'),
     assert(sm == null || (sm > 0 && sm <= 12), 'sm must be between 1 and 12, got $sm'),
     assert(md == null || (md > 0 && md <= 12), 'md must be between 1 and 12, got $md'),
     assert(lg == null || (lg > 0 && lg <= 12), 'lg must be between 1 and 12, got $lg'),
     assert(xl == null || (xl > 0 && xl <= 12), 'xl must be between 1 and 12, got $xl');
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `xs` | `int` | `12` | Span at the xs band (`< 600px`). The only span with a concrete non-null default. |
| `sm` | `int?` | `null` | Span at sm (`600–959px`). `null` cascades from `xs`. |
| `md` | `int?` | `null` | Span at md (`960–1263px`). `null` cascades from `sm`, then `xs`. |
| `lg` | `int?` | `null` | Span at lg (`1264–1903px`). `null` cascades from `md`, `sm`, then `xs`. |
| `xl` | `int?` | `null` | Span at xl (`≥ 1904px`). `null` cascades from `lg`, `md`, `sm`, then `xs`. |
| `child` | `Widget` | — | Required. The widget rendered in this column — `build()` returns it unchanged. |

---

## `spanAt` method

```dart
int spanAt(double width, LayrzBreakpointTokens breakpoints)
```

Resolves the effective span for a given viewport `width`, using `breakpoints.bandAt(width)` to pick the band, then the cascade rule:

| Band | Resolution |
|---|---|
| `xs` | `xs` |
| `sm` | `sm ?? xs` |
| `md` | `md ?? sm ?? xs` |
| `lg` | `lg ?? md ?? sm ?? xs` |
| `xl` | `xl ?? lg ?? md ?? sm ?? xs` |

Called by `LayrzRow` during its own layout pass, not typically called directly by consumer code.

---

## `LayrzBreakpoint` enum

| Value | Viewport width |
|---|---|
| `.xs` | `< 600` |
| `.sm` | `600` – `959` |
| `.md` | `960` – `1263` |
| `.lg` | `1264` – `1903` |
| `.xl` | `≥ 1904` |

---

## `LayrzBreakpointTokens` class

```dart
const LayrzBreakpointTokens({
  this.xs = 600.0,
  this.sm = 960.0,
  this.md = 1264.0,
  this.lg = 1904.0,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `xs` | `double` | `600.0` | Upper bound (exclusive) of the xs band; sm starts here. |
| `sm` | `double` | `960.0` | Upper bound (exclusive) of the sm band; md starts here. |
| `md` | `double` | `1264.0` | Upper bound (exclusive) of the md band; lg starts here. |
| `lg` | `double` | `1904.0` | Upper bound (exclusive) of the lg band; xl starts here. |

`bandAt(double width)` resolves the band: `width < xs` → `.xs`; `< sm` → `.sm`; `< md` → `.md`; `< lg` → `.lg`; else `.xl`. Must be supplied in strictly ascending order (`xs < sm < md < lg`) — not asserted; an out-of-order configuration produces undefined `bandAt` results. Has `copyWith({...})` and value `==`/`hashCode`.

---

## Behavior notes

- **`LayrzCol` has no layout logic of its own** — `build(BuildContext context) => child`. All sizing, wrapping, and spacing come from the parent `LayrzRow`, which reads `spanAt` per column during its own `LayoutBuilder` pass.
- **Migration from `layrz_theme`**: `ResponsiveCol` → `LayrzCol` (renamed, same semantics). `Sizes.col6` → plain `6`; `Sizes.full` → `12`. The `Sizes` enum was removed (decision D9) — spans are always plain `int`.
- **Custom breakpoints**: pass a custom `LayrzBreakpointTokens` via the app's theme (`LayrzTokens.breakpoints`) to shift band thresholds app-wide; every `LayrzCol`/`LayrzRow` picks up the change automatically since `spanAt` always receives the theme's tokens.
- **`context.breakpoint`** (from `lib/src/extensions/src/context.dart`) reads the current band directly from viewport width and the active theme's breakpoint tokens — use it for one-off conditional rendering outside a grid; use `context.isCompact` when the decision is truly binary (compact vs. wide) rather than band-specific.
