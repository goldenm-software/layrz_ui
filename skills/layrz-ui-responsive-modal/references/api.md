# LayrzResponsiveModal — API Reference

Source: `lib/src/dialogs/src/responsive_modal.dart`
- `LayrzResponsiveModal` class (static-method surface; `LayrzResponsiveModal.show<T>()`)
- `LayrzDialogConfig` / `LayrzBottomSheetConfig` — branch-specific config objects, same file
- `lib/src/dialogs/src/modal_presentation.dart` — `LayrzModalPresentation` enum, `resolveLayrzModalPresentation`

**Note:** the wiki page's `show<T>()` signature block omits `actions` and `showCloseIcon` even though both are discussed at length in its own prose. The actual source constructor includes both as real parameters. This reference follows the source and includes them in the signature.

---

## Examples

```dart
// Default, viewport-driven
final selected = await LayrzResponsiveModal.show<String>(
  context,
  semanticLabel: 'Choose an option.',
  builder: (context) => _buildOptionList(context),
);

// Forcing the sheet at a wide breakpoint
await LayrzResponsiveModal.show<void>(
  context,
  isCompact: true,
  builder: (context) => _buildLongOptionList(context),
);

// Forcing the dialog on a narrow viewport
await LayrzResponsiveModal.show<void>(
  context,
  isCompact: false,
  builder: (context) => _buildQuickForm(context),
);

// Configuring both branches
await LayrzResponsiveModal.show<void>(
  context,
  builder: (context) => _buildDetail(context),
  dialog: const LayrzDialogConfig(maxWidth: 560, maxHeight: 720),
  sheet: const LayrzBottomSheetConfig(snapSizes: [0.4, 0.9]),
);

// Pinned actions row, locking in dismissibility
await LayrzResponsiveModal.show<bool>(
  context,
  builder: (context) => const Text('Confirm this operation?'),
  actions: [
    LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.save(labelText: 'Confirm', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Suppressing the dialog branch's close icon (sheet branch ignores this)
await LayrzResponsiveModal.show<void>(
  context,
  showCloseIcon: false,
  builder: (context) => _buildBodyWithOwnCancelButton(context),
);
```

---

## Constructor

```dart
static Future<T?> show<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  List<Widget>? actions,
  bool? isCompact,
  bool? canDismiss,
  String? semanticLabel,
  LayrzDialogConfig dialog = const LayrzDialogConfig(),
  LayrzBottomSheetConfig sheet = const LayrzBottomSheetConfig(),
  bool showCloseIcon = true,
})
```

```dart
@immutable
class LayrzDialogConfig {
  const LayrzDialogConfig({
    this.maxWidth = 480,
    this.maxHeight = 640,
  });
}

@immutable
class LayrzBottomSheetConfig {
  const LayrzBottomSheetConfig({
    this.snapSizes,
    this.initialSize = 0.5,
    this.minSize = 0.25,
    this.maxSize = 0.95,
    this.showDragHandle = true,
    this.scrollable = true,
  });
}
```

---

## Properties

### `LayrzResponsiveModal.show<T>`

| Property | Type | Default | Notes |
|---|---|---|---|
| `context` | `BuildContext` | required | Build context to show the modal from. Must contain a Navigator. |
| `builder` | `WidgetBuilder` | required | Builds the modal's content, receiving the surface's own context. For the dialog branch, composed into `LayrzDialog.show`'s `child` escape hatch (not `content` — preserves fill-height content like `Expanded`/`ListView`). |
| `actions` | `List<Widget>?` | `null` | Pinned below `builder`'s content on **both** branches. `null`/empty renders no row. Forwarded to `LayrzBottomSheet.show`'s `actions` on the sheet branch; composed into the dialog branch's `child` alongside `builder`'s result (since `LayrzDialog.show`'s own `actions` is mutually exclusive with `child`). |
| `isCompact` | `bool?` | `null` | Overrides which surface is chosen. `null` uses `context.isCompact` (`true` below 960px). `true` forces the sheet, `false` forces the dialog. |
| `canDismiss` | `bool?` | `null` | Whether the modal can be dismissed by any route other than an explicit action. `null` infers from `actions`: dismissible when `actions` is null/empty, not dismissible when non-empty. Computed once and forwarded to both branches. Explicit value always wins. |
| `semanticLabel` | `String?` | `null` | Forwarded to whichever branch is chosen. Must read equivalently regardless of surface. |
| `dialog` | `LayrzDialogConfig` | `const LayrzDialogConfig()` | Dialog-branch-only config (`maxWidth`, `maxHeight`). Ignored when the sheet branch is chosen. |
| `sheet` | `LayrzBottomSheetConfig` | `const LayrzBottomSheetConfig()` | Sheet-branch-only config (`snapSizes`, `initialSize`, `minSize`, `maxSize`, `showDragHandle`, `scrollable`). Ignored when the dialog branch is chosen. |
| `showCloseIcon` | `bool` | `true` | Forwarded verbatim to `LayrzDialog.show`'s own `showCloseIcon` on the dialog branch. **Silently ignored on the sheet branch**, which has no close icon at all. |

**Return contract:** `Future<T?>` — identical to both `LayrzDialog.show<T>()` and `LayrzBottomSheet.show<T>()`; `null` means dismissed without a value. Callers never need to branch on which surface was actually used.

### `LayrzDialogConfig`

| Property | Type | Default | Notes |
|---|---|---|---|
| `maxWidth` | `double` | `480` | Forwarded verbatim to `LayrzDialog.show`'s `maxWidth`. |
| `maxHeight` | `double` | `640` | Forwarded verbatim to `LayrzDialog.show`'s `maxHeight`. |

### `LayrzBottomSheetConfig`

| Property | Type | Default | Notes |
|---|---|---|---|
| `snapSizes` | `List<double>?` | `null` | Forwarded to `LayrzBottomSheet.show`'s `snapSizes`. `null` defaults to `[0.5, 0.95]` there. |
| `initialSize` | `double` | `0.5` | Fraction of screen height the sheet initially occupies. |
| `minSize` | `double` | `0.25` | Minimum fraction the sheet can be dragged down to. |
| `maxSize` | `double` | `0.95` | Maximum fraction the sheet can occupy. |
| `showDragHandle` | `bool` | `true` | Whether to render a visual drag handle above the content. |
| `scrollable` | `bool` | `true` | Whether the sheet wraps content in its own scroll view. Set `false` when the builder returns its own scrollable. |

---

## `LayrzModalPresentation` enum

| Value | Description |
|---|---|
| `.dialog` | Present as `LayrzDialog` — centered, size-bounded panel. |
| `.sheet` | Present as `LayrzBottomSheet` — drops in from the bottom edge, sized to viewport height. |

Deliberately not `LayrzLayoutPresentation` (`expanded`/`drawer`, navigation chrome) — a modal surface is a different concept and gets its own enum.

`resolveLayrzModalPresentation({required double width, required LayrzTokens tokens})` is the pure resolver function: `width < 960` (xs/sm bands) → `.sheet`; `width >= 960` (md/lg/xl bands) → `.dialog`. Fed **viewport** width, not container/constraint width — a modal is presented over the whole screen regardless of where `show()` was called from.

---

## Behavior notes

- **Decide-once rule.** Presentation is resolved exactly once, at `show()` call time, and never re-evaluated for the life of the route — no `LayoutBuilder`, no `MediaQuery` listener installed anywhere. A modal opened wide and resized narrow stays on its original surface. There is a shipped precedent for the bug class this avoids: v0.0.14 fixed a `setState()`/`markNeedsBuild() called during build` crash from a re-evaluate-on-resize design elsewhere in the codebase.
- **`canDismiss` inference is computed once, from this wrapper's own `actions`** — not from what either underlying branch happens to receive — and applied uniformly to both. This closes a real defect from an earlier revision where the dialog branch's `canDismiss` never actually locked in because `actions` was composed into `child` rather than forwarded to `LayrzDialog.show`'s own `actions` parameter.
- **The builder-vs-slots limitation is deliberate.** `LayrzDialog` offers `title`/`content`/`actions` slots plus `child`; this wrapper exposes only `builder` + `actions`, because the same `builder` result must serve both the dialog and sheet branches, and the sheet has no equivalent slotted shape. Call `LayrzDialog.show` directly when the structured slots matter more than responsive presentation.
- **Dialog branch composition.** `builder`'s result becomes `LayrzDialog.show`'s `child` (not `content`), wrapped with any `actions` in a `Column` (`Flexible` around the built content, not `Expanded`, so short content still shrink-wraps instead of always growing to `maxHeight`).
- **Sheet branch composition.** `builder` and `actions` forward directly to `LayrzBottomSheet.show`'s own same-named parameters, which already pin `actions` below the content.
- **Accessibility.** Both branches must announce equivalently — `semanticLabel` is forwarded verbatim to whichever branch is chosen, so a screen-reader user hears the same thing regardless of which breakpoint they were on.
