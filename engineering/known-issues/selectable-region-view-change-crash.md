# Known issue: `SelectableRegion` `_selectable == null` assert on view change (web)

**Status:** ✅ RESOLVED (2026-09-13). Fix confirmed live on web. The root cause and the fix are at the bottom under "Resolution"; the investigation history below is kept for the record. Five earlier fix attempts failed — do not re-try those approaches.
**Severity:** High — crashes the whole content pane (red screen) on navigation in the showroom and any consumer app using `LayrzLayout` with routed/animated content.
**Platform:** **Web only.** Never reproduced on Linux desktop. Gated behind the web rendering/transition path — `flutter test` (VM/DDC, `kIsWeb == false`) **cannot** reproduce it, so no automated test guards it.
**Reproduce:** In the example web app (`flutter run -d web-server --web-port 8080`), navigate **Tab View → Table → Text → Table**. The content pane goes red on a transition.

## The exception (identical across every repro)

```
Assertion failed: .../flutter/lib/src/widgets/selectable_region.dart:1919:12
_selectable == null
is not true
  building SelectableRegionSelectionStatusScope
  error-causing widget: SelectableRegion at lib/src/layout/src/layout.dart (the LayrzLayout body region)
stack (top frames):
  selectable_region.dart:1919  SelectableRegionState.add()          <- assert _selectable == null
  rendering/selection.dart:299 _updateSelectionRegistrarSubscription
  rendering/selection.dart:280 set registrar
  selection_container.dart:119 SelectionContainer initState         <- a NEW SelectionContainer mounting
  framework.dart              _firstBuild / mount / inflateWidget / updateChild
  inherited_notifier.dart:108 InheritedNotifier.update              <- drives the child re-inflation
  ... (framework update/rebuild chain) ...
  layout_builder.dart:270/333/447  _rebuildWithConstraints / layoutCallback / performLayout
  rendering/object.dart runLayoutCallback / flushLayout
  rendering/binding.dart drawFrame
```

## Confirmed mechanism (evidence-backed)

- `LayrzLayout` wraps its body in a single `SelectableRegion` (`lib/src/layout/src/layout.dart`, in `_buildExpanded` and `_buildDrawer`), built inside a `LayoutBuilder` (`build()`).
- `SelectableRegionState` is a **single-slot registrar**: `add()` asserts `_selectable == null` (`selectable_region.dart:1918-1919`); it holds exactly one `Selectable`.
- On a view change, an **`InheritedNotifier.update`** propagates through the tree and causes `updateChild` to **inflate a fresh `SelectionContainer`** (`initState → set registrar → add()`) at that slot **before** the outgoing container's `dispose → remove()` runs. The new `add()` sees `_selectable != null` → assert.
- The whole thing runs during the **layout phase** (`LayoutBuilder.performLayout → runLayoutCallback`), which is what makes it fire on web during the fade route transition.
- There are **no** `PlatformSelectableRegionContextMenu` / `BrowserContextMenu` / `_webContextMenuEnabled` / `Focus` frames — so it is **NOT** the browser-context-menu-flag mechanism (see attempt 1).

## Attempts that FAILED (do not repeat)

1. **Refcounted browser-context-menu suppressor** (committed as `0e804b9`, `lib/src/context_menu/src/browser_context_menu_suppressor.dart`). Addresses a *different* trigger of the same assert — the `_webContextMenuEnabled` flag flip (upstream flutter/flutter#186459) — which is real but NOT this crash (no such frames in the trace). **Kept in the tree as independent hardening; decide at push time whether to keep/reword/drop.** Does not fix this bug.
2. **`GlobalKey` on the `SelectableRegion`.** A prior analysis showed a key on our widget can't reach Flutter's private inner `Focus` child slot. Not applied.
3. **`KeyedSubtree(GlobalKey)` around the region's child (`widget.body`).** Moved the crash to "only the first view change" — a `GlobalKey` reparent during the transition itself triggers re-registration. Worse, not better.
4. **Stable `SelectionContainer(delegate: StaticSelectionContainerDelegate())` inserted as the region's child** (aggregating, multi-tolerant delegate). Theory: the body's transient containers register against our order-tolerant delegate, not the region's single slot. `StaticSelectionContainerDelegate` is public + importable from `package:flutter/widgets.dart` and its `add()` only forbids duplicates. Still crashed identically — the re-inflated container still registers against the region's single slot, one level up.
5. **Hoist the region construction out of the `LayoutBuilder`** (build `bodyWidget` once in `build()`, pass into `_buildExpanded`/`_buildDrawer`). Theory: the `LayoutBuilder` no longer reconstructs the region each layout pass. Still crashed identically — the re-inflation originates from the `InheritedNotifier.update`/`updateChild` regardless of where the region widget is constructed.

## What the failures collectively tell us

Every fix operating on *our* widget construction/keying failed identically. The re-inflation is driven by an `InheritedNotifier.update` forcing `updateChild` to inflate a fresh `SelectionContainer` (element not reconciled) during the layout phase. The trigger is **at/above** the point our code controls, in the framework's element-reconciliation during a web route transition with a `SelectableRegion` under a `LayoutBuilder`.

**Never actually gathered (next investigator start here):** *which* `InheritedNotifier` is in the stack. It was assumed to be go_router's `Router`/route inherited widget but never confirmed via the live widget inspector. Identify it first.

## Related upstream Flutter issues (this is a known problem area)

- `SelectableRegion` + background page / navigation layout asserts:
  - https://github.com/flutter/flutter/issues/119776 (`hasSize` assert in `SelectableRegion` within a background page)
  - https://github.com/flutter/flutter/issues/119772 (`debugNeedsLayout` assert in background page under `SelectableRegion`)
  - https://github.com/flutter/flutter/issues/123378 (`SelectableRegion` null-check crash)
- Different-but-adjacent trigger of the SAME assert line (the context-menu flag flip): https://github.com/flutter/flutter/issues/186459

## Suggested next directions (unverified)

- **Identify the `InheritedNotifier`** via the live widget inspector during a transition; the fix likely belongs at that boundary, not in `LayrzLayout`'s region construction.
- **Minimal standalone repro** (`SelectableRegion` + `LayoutBuilder` + `InheritedNotifier`/route swap, web) to prove a fix in isolation before touching `LayrzLayout`.
- Consider whether the region should sit **outside** the routed/animated subtree entirely (structural change; would alter whole-body selection scope — a maintainer decision) or whether this needs an upstream Flutter fix / a framework-level workaround (e.g. a custom registrar that tolerates re-add ordering by wrapping `SelectableRegionState`, which the single-slot `add()` assert currently forbids).

## Constraint that shaped every attempt

Whole-body text selection (one `SelectableRegion` around the entire `LayrzLayout` body, zero consumer code) is a headline layrz_ui feature and **must be preserved** — the maintainer ruled out moving the region into individual pages (which would make selection per-page).

---

## Resolution (2026-09-13)

**True root cause.** `SelectableRegionState.build()` reads `BrowserContextMenu.enabled`
(`selectable_region.dart:1953-1968`) on **every build** to decide whether to wrap its child in
`PlatformSelectableRegionContextMenu`. When that **process-wide flag changes value** during a
navigation rebuild, the region's own internal `SelectionContainer` element is re-inflated
(`initState → add()`) before the outgoing one is removed → the single-slot
`assert(_selectable == null)` (`:1919`). This is the *only* SDK path to that assert for the region's
own container — which is why every fix operating on our widget/keying/child-container (attempts 2–5)
failed: they were all downstream of the flag flip.

Why the flag flips: `BrowserContextMenu.enabled` defaults to `true`; anything that toggles it (the
old per-widget suppressor thrash of attempt 1, or simply it being `true` and Flutter's own web
handling) makes the region wrap/unwrap across a transition.

**The fix.** Keep `BrowserContextMenu.enabled` **constant for the app's lifetime** by disabling the
browser's native context menu **once, in `main()`, awaited, before `runApp`**:

```dart
if (kIsWeb) {
  await BrowserContextMenu.disableContextMenu();
}
```

It must live in `main()` and be awaited because `disableContextMenu()` is **asynchronous** — its
`enabled` getter only flips after a platform-channel round-trip. Doing it inside `LayrzApp` would
either lose the race (build runs the same frame, flag still `true`) or force `LayrzApp` to block
during widget construction, slowing every app's startup for a concern that belongs in `main()`.

**What the library now does:**
- `LayrzLayout.build()` carries a debug-only assert —
  `assert(!(kIsWeb && selectableContent && BrowserContextMenu.enabled), …)` — a *reminder* that the
  `main()` step was missed, not the fix itself.
- `LayrzApp`'s docs, the README, and the wiki (`Getting-Started`, `LayrzApp`, `LayrzLayout`) document
  the required `main()` call.
- The example already did this (`example/lib/main.dart`, in the `Future.wait` at startup).

**On the earlier attempts:** the context-menu refcount suppressor (commit `0e804b9`) addresses a
*different* trigger of the same assert (the `_webContextMenuEnabled` flip via per-widget
suppression, upstream #186459) and is independent hardening; keep/reword/drop is a separate call.
Attempts 2–5 were reverted.
