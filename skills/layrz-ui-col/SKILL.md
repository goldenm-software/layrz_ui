---
name: layrz-ui-col
description: Use LayrzCol in a layrz_ui Flutter widget. Apply when defining a single column's span (1–12) at each breakpoint inside a LayrzRow — cascading xs/sm/md/lg/xl spans resolved from viewport width.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Spans are plain `int` (1–12) — there is no `Sizes` enum to use dot-shorthand on.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Defining one child's responsive width inside a `LayrzRow`'s 12-column grid.
- Setting only the breakpoints where the span actually changes — unset breakpoints cascade downward from the next-smaller one you did set.
- **Do not use** outside a `LayrzRow` — `LayrzCol` has no layout logic of its own; it is a plain pass-through `StatelessWidget` (`build` just returns `child`) whose `spanAt` is read and applied by the parent `LayrzRow`. Rendered standalone, it behaves exactly like its `child` with no sizing effect.
- **Do not use** for a fixed pixel width regardless of viewport — a span is always a 1–12 fraction of the row's width; use a plain `SizedBox`/`ConstrainedBox` instead when you need an exact pixel width.

---

## Minimal usage

```dart
LayrzCol(
  xs: 12, // full width on mobile
  md: 6,  // half width from md upward
  child: Text('Responsive content'),
)
```

---

## Breakpoints

| Band | Viewport width | Typical device |
|---|---|---|
| `xs` | < 600 | Phones, small tablets (landscape) |
| `sm` | 600–959 | Tablets (portrait) |
| `md` | 960–1263 | Tablets (landscape), small desktops |
| `lg` | 1264–1903 | Large desktops |
| `xl` | ≥ 1904 | Extra-large displays |

Thresholds are themeable via `LayrzBreakpointTokens` (`lib/src/tokens/src/breakpoints.dart`) — each field is the **upper bound (exclusive) of the band below it** (`xs: 600` means the xs band is `< 600`). Read the active band anywhere with `context.breakpoint`; use `context.isCompact` (`true` for `xs`/`sm`, i.e. `< 960`) for the binary compact/wide layout decision instead of comparing bands manually.

---

## Key behaviors

- **`xs` is the only required-feeling span** — it defaults to `12` (full width) and every other band cascades from it when unset: `sm ?? xs`, `md ?? sm ?? xs`, `lg ?? md ?? sm ?? xs`, `xl ?? lg ?? md ?? sm ?? xs`.
- Setting only `md: 6` makes the column span 6 at `md`, `lg`, **and** `xl` — it "sticks" until a more specific breakpoint overrides it.
- Every span you do set must be an integer `1`–`12` inclusive — asserted at construction (debug builds), with a message naming the offending field.
- **Breakpoint selection is viewport-driven, not container-driven** — `spanAt` resolves against the *viewport* width the parent `LayrzRow` passes in, not any width local to the column itself. See the `layrz-ui-row` skill for the two-width rule this depends on.
- `LayrzCol` carries no key/identity requirement beyond the standard Flutter `Key` — unlike `LayrzColumn` in `LayrzTable`, there is no uniqueness constraint across a row's children.

---

## Common patterns

```dart
// 1. Cascading: only md set, sticks through lg/xl
LayrzCol(
  xs: 12,
  sm: 6,
  md: 4,
  // lg and xl both resolve to 4 (cascade from md)
  child: Sidebar(),
)

// 2. Full width on mobile, one-third on desktop
LayrzCol(xs: 12, md: 4, child: FilterPanel())

// 3. Reading the active breakpoint directly (outside LayrzRow)
if (context.breakpoint == .xs) {
  return MobileLayout();
}

// 4. isCompact for a binary decision instead of comparing bands
final columns = context.isCompact ? 1 : 3;
```

---

## Pitfalls

- **Setting a span outside 1–12 fails an assertion**, not a silent clamp — e.g. `LayrzCol(xs: 13, ...)` throws in debug builds with `'xs must be between 1 and 12, got 13'`.
- **Don't assume `md`/`lg`/`xl` default to `12` like `xs` does** — they default to `null`, meaning "cascade from the next-smaller set value." Only `xs` has a real default value of `12`.
- **`LayrzCol` outside a `LayrzRow` does nothing** — it is a transparent pass-through (`build(context) => child`). Its `xs`/`sm`/`md`/`lg`/`xl` fields are inert unless a `LayrzRow` ancestor reads them via `spanAt`.
- **A grid inside a narrow container on a wide screen does not select a narrower band** — since band selection is viewport-width-driven (see `layrz-ui-row`), don't expect `LayrzCol` spans to shrink automatically just because their container is narrow; that requires a deliberate `LayoutBuilder`/manual override instead.
- **`Sizes.col6`-style enum values do not exist in layrz_ui** — spans are plain `int` per the `layrz_theme` → `layrz_ui` migration (decision D9). Passing an enum value is a compile error, not a lint warning.
