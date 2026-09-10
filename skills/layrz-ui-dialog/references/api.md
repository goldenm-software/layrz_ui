# LayrzDialog — API Reference

Source: `lib/src/dialogs/src/dialog.dart`
- `LayrzDialog` class (static-method surface; `LayrzDialog.show<T>()`)
- `LayrzDialogConfig` — see `lib/src/dialogs/src/responsive_modal.dart` (used by `LayrzResponsiveModal`)

**Note:** the wiki page at `wiki/Widgets/LayrzDialog.md` does not document `showCloseIcon` at all — the source has it as a real, independent constructor parameter (default `true`). This reference follows the source and includes it.

---

## Examples

```dart
// Confirm / cancel
final confirmed = await LayrzDialog.show<bool>(
  context,
  title: const Text('Delete item?'),
  content: const Text('This cannot be undone.'),
  actions: [
    LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.delete(labelText: 'Delete', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Informational — no actions, dismissible by default
await LayrzDialog.show<void>(
  context,
  title: const Text('Sync complete'),
  content: const Text('All changes were saved.'),
);

// The child escape hatch
await LayrzDialog.show<void>(
  context,
  child: _buildCustomStepperContent(),
);

// Explicitly overriding canDismiss to true alongside actions
await LayrzDialog.show<bool>(
  context,
  title: const Text('Discard draft?'),
  content: const Text('Your changes have not been saved.'),
  canDismiss: true,
  actions: [
    LayrzButton.cancel(labelText: 'Keep editing', onTap: () => Navigator.of(context).pop(false)),
    LayrzButton.delete(labelText: 'Discard', onTap: () => Navigator.of(context).pop(true)),
  ],
);

// Suppressing only the floating close icon
await LayrzDialog.show<void>(
  context,
  showCloseIcon: false,
  child: _buildPickerBodyWithOwnCancelButton(),
);

// Custom sizing
await LayrzDialog.show<void>(
  context,
  title: const Text('Preview'),
  content: const _LargePreview(),
  maxWidth: 720,
  maxHeight: 800,
);

// Semantic label for screen readers
await LayrzDialog.show<void>(
  context,
  semanticLabel: 'Export options',
  title: const Text('Export'),
  content: const _ExportForm(),
);
```

---

## Constructor

```dart
static Future<T?> show<T>(
  BuildContext context, {
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  Widget? child,
  bool? canDismiss,
  String? semanticLabel,
  double maxWidth = 480,
  double maxHeight = 640,
  bool showCloseIcon = true,
})
```

Debug assertions:
- `child == null || (title == null && content == null && actions == null)` — `child` is mutually exclusive with the three slots.
- Opening a second `LayrzDialog` while one is already the current route throws a `FlutterError` — stacking is not supported.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `context` | `BuildContext` | required | Build context to show the dialog from. Must contain a Navigator. |
| `title` | `Widget?` | `null` | Rendered in the title slot, above `content`. Typically a `Text`. |
| `content` | `Widget?` | `null` | Rendered in the body slot, below `title` and above `actions`. Sizes to content and scrolls internally past `maxHeight`. **Receives unbounded height** from its scroll view — a fill-seeking child throws (see Behavior notes). Wrapped in a `SelectableRegion` so text is selectable/copyable. |
| `actions` | `List<Widget>?` | `null` | Rendered in a row at the bottom, right-aligned with spacing between them. |
| `child` | `Widget?` | `null` | Escape hatch replacing the entire body — mainly for genuinely fill-height content `content` cannot express. Mutually exclusive with `title`/`content`/`actions` (asserted). Gets no title row or action row for free. |
| `canDismiss` | `bool?` | `null` | Whether the dialog can be dismissed by any route OTHER than its own `actions` — gates barrier tap, Escape, the X icon, and the back gesture together. `null` infers `true` when `actions == null`, `false` when `actions != null`. Explicit `true`/`false` always wins. |
| `semanticLabel` | `String?` | `null` | Optional semantic label for screen readers, announced alongside the barrier label. If omitted, no route semantics are added. |
| `maxWidth` | `double` | `480` | Maximum panel width in logical pixels. Also respects the viewport — a narrow window clamps below this regardless of value. |
| `maxHeight` | `double` | `640` | Maximum panel height in logical pixels. Content taller than this scrolls internally rather than growing the panel or overflowing. |
| `showCloseIcon` | `bool` | `true` | Whether to render the floating close ("X") affordance. `false` suppresses only its render — does NOT change dismissibility; barrier/Escape/back-gesture still obey `canDismiss`. Use when the body already supplies its own close/cancel affordance. |

**Return contract:** `Future<T?>` — completes with the value passed to `Navigator.pop` inside the dialog, or `null` if dismissed without one (barrier tap, Escape, or a close action that pops with no value).

---

## Behavior notes

- **Structure: slots plus an escape hatch.** The `title`/`content`/`actions` shape covers "title + body + confirm/cancel" — the overwhelming majority of consumers. `child` is the outlier escape hatch; mixing the two is refused by assertion since it would be ambiguous which one governs layout.
- **`canDismiss`'s four gated routes:** barrier tap outside the panel, the Escape key, the X close icon, and the system/Android back gesture. This parameter used to be named `barrierDismissible` and governed only the barrier; it was renamed and broadened specifically so a decision-bearing dialog cannot be half-escaped through a route someone forgot to gate.
- **The X close affordance** is built from `LayrzTappable` directly, not a `LayrzButton` (it's a bare dismiss affordance, not a labeled action). When `title` is supplied, it sits at the trailing edge of the title row; without a title (including the `child` escape hatch), it floats over the panel's top-right corner. A caller using `child` should leave a little top-right clearance since the icon paints on top via a `Stack`.
- **Dismissal always goes through `LayrzModalRoute.popIfCurrent(context)`** — a shared guard (with `LayrzBottomSheet`) against a release-only data-loss bug: a fast second tap on the barrier during the exit transition could otherwise pop the route *underneath* the dialog silently. `isCurrent` is checked immediately before popping, so a rapid double-tap becomes a no-op instead of a second pop.
- **Stacking is not permitted in v1.** Opening a second `LayrzDialog` while one is open throws a `FlutterError` rather than silently compounding two barriers into one darker layer. Dismiss the current dialog first.
- **Always the root navigator.** `LayrzDialog.show` always pushes via `Navigator.of(context, rootNavigator: true)` — intrinsic, not configurable. A dialog shown from inside a nested navigator (e.g. a `go_router` `ShellRoute`) would otherwise land inside that page's own subtree instead of covering the whole screen.
- **The `content` slot's unbounded height.** `content` sits inside a `SingleChildScrollView`, which is what lets text-sized content scroll past `maxHeight` — but it also means anything inside `content` that tries to fill available space (`Expanded`, `Flexible`, a bare `ListView`/`GridView`) throws, since there is no bound to fill. Fixes, in order of preference: give the child an explicit height (`SizedBox(height: 300, child: ListView(...))`), set `shrinkWrap: true`, or use `child` instead for content that genuinely needs to fill the panel.
- **Accessibility.** Focus is captured (via a post-frame callback) before the dialog's own focus node requests focus, and restored to the previously-focused node on dispose — guarded on `FocusNode.canRequestFocus` in case that node was independently disposed while the dialog was open. The barrier label comes from `context.l10n.dialogsBarrierLabel`. `semanticLabel`, when supplied, wraps the panel in `Semantics(scopesRoute: true, namesRoute: true, explicitChildNodes: true)`. Reduce motion pins the fade/scale transition to its end value instead of animating.
- **Sizing.** Bounded by `maxWidth`/`maxHeight` and the viewport itself — a narrow window clamps below `maxWidth` regardless of the value passed.
