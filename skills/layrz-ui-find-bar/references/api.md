# LayrzFindBar — API Reference

Source: `lib/src/find_in_page/src/find_bar.dart`
- `LayrzFindBar` class (`StatefulWidget`)

---

## Examples

```dart
// LayrzFindInPageHost builds this automatically — for reference only:
LayrzFindBar(
  controller: findInPageController,
  onClose: handleFindClose,
)
```

Application code reaches find via the host's controller instead:

```dart
LayrzFindInPageHost.of(context).controller.open();
```

---

## Constructor

```dart
const LayrzFindBar({
  super.key,
  required this.controller,
  required this.onClose,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `controller` | `LayrzFindInPageController` | **required** | The controller this bar reads state from and drives (query, matches, current index, searching state). |
| `onClose` | `VoidCallback` | **required** | Called when the bar's close button or a local Escape requests find be dismissed. The bar never calls `controller.close()` itself — `LayrzFindInPageHost` is the single place deciding everything "closing find" entails, including removing its own overlay entry. |

---

## Composition

| Element | Behavior |
|---|---|
| Query field | A `LayrzTextInput` (`hideDetails: true`) bound to `controller`. Every keystroke calls `controller.setQuery`; submitting (Enter) calls `controller.searchNow()`, bypassing the debounce. |
| Match counter | Live `"N of M"` text, `"0 of 0"` with no matches. |
| Previous button | `LayrzButtonStyle.textFab` icon button calling `controller.previous()`. Disabled when there are no matches. |
| Next button | Same, calling `controller.next()`. |
| Close button | Calls `widget.onClose` — never `controller.close()` directly. |
| Searching indicator | A thin (2.0px), indeterminate `LayrzProgressBar`, always reserved in layout; only its opacity animates between searching/settled states. |

---

## Local keyboard handling

Handled by a `Focus` wrapping the whole bar, scoped to this widget only — none of these register as app-wide shortcuts:

| Key | Action |
|---|---|
| Enter | `controller.next()` |
| Shift+Enter | `controller.previous()` |
| Escape | `widget.onClose` |

Any other key event returns `KeyEventResult.ignored` and keeps propagating normally.

---

## Behavior notes

- **Positioning is the host's job.** `LayrzFindInPageHost` builds this bar inside a root-`Overlay` `OverlayEntry`, pinned top-right (matching Chrome's own Ctrl+F convention), and measures its rect for self-exclusion from search results — this widget itself has no positioning logic of its own beyond sizing to its own content.
- **Responsive field width.** The bar computes its query field's width explicitly rather than letting a flexible child expand — targets a comfortable desktop default, shrinking down to a usability floor only when the bar's own available width is too narrow for the full control row; on an extremely tight viewport it accepts a small, deliberate overflow rather than shrinking the field further.
- **Auto-focus.** The query field auto-focuses on the bar's first frame after opening.
- **Material-free construction.** Built from `LayrzTextInput`, `LayrzButton` (`.textFab` style), `LayrzProgressBar` (custom/indeterminate type), `Focus`, and plain layout widgets (`Container`/`LayoutBuilder`/`Row`/`Column`).
- **Accessibility.** The match counter is real text, announced on every change — the primary channel conveying search progress. The decorative searching-indicator strip is `ExcludeSemantics`-wrapped since the counter already conveys progress. Previous/next/close are ordinary `LayrzButton`s with full keyboard/focus support.
