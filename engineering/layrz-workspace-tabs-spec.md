# LayrzWorkspaceTabs — Design Spec

Status: **Implemented (v2 — tab-owns-content).** This supersedes the original bar-only design
below; see [Revision history](#revision-history) for what changed and why.

## Context

The commercial team asked for a **browser-like tab** UI: a strip of tabs a user can open,
close, and reorder, on top of which the tab's own content renders — the way browser tabs
manage documents/workspaces. This is a **workspace/document manager**, not a content switcher.

This is deliberately a **separate component from `LayrzTabView`**. `LayrzTabView` is a
content switcher: a fixed, author-defined set of pill tabs that owns and swaps the body
below it. The two share the word "tab" and nothing else about their model:

| Concern | `LayrzTabView` | `LayrzWorkspaceTabs` |
|---|---|---|
| Tab set | Fixed, author-defined | Dynamic — user opens/closes |
| Close (×) per tab | No | Yes (core) |
| New-tab (+) | No | Yes (core) |
| Reorder (drag) | No | Yes (core) |
| Content ownership | Owns child, swaps it | **Each tab owns its own content** |
| Split view | No | Yes, per tab (`left`/`right`) |
| Shape | Rounded pills | Chrome-style connected tabs + connected panel |

Forcing these behaviors onto `LayrzTabView` would blur its clean purpose. `LayrzWorkspaceTabs`
is net-new.

## Model — tab-owns-content, connected strip + panel

The widget renders **both** the tab strip and the content panel for the active tab, as one
connected piece. Each `LayrzWorkspaceTab` now carries its own content through two named
slots:

- `left` (`Widget`, required) — the tab's primary content pane.
- `right` (`Widget?`, optional) — when non-null, the tab is in **split view**: `left` and
  `right` render side-by-side behind a resizable divider. When `null`, `left` fills the panel
  alone.

```
┌─────────────────────────────────────────────┐
│ [ Tab A ×][ Tab B ×][ Tab C ×]        [ + ] │   ← tab strip
├──────────╮                          ╭────────┤   ← the active tab's shoulders curve
│          ╰──────────────────────────╯        │     down into the panel's top border,
│                                               │     which opens under the active tab
│   tab.left            │  tab.right           │   ← split view (when tab.right != null)
│                        ↕ resizable divider    │
└─────────────────────────────────────────────┘
```

The active tab's chrome and the panel's border trace **one continuous outline** with no
seam: the tab's bottom edge is borderless (`mergeBottom: true` on
`LayrzWorkspaceTabChromePainter`) and the panel's top border is carved open across the same
x-span, with both edges curving through a shared `shoulderRadius` — see
[Connected border](#connected-border) below.

## API

```dart
/// The connected strip-and-panel workspace widget.
class LayrzWorkspaceTabs extends StatefulWidget {
  /// The tabs to render, in display order.
  final List<LayrzWorkspaceTab> tabs;

  /// The id of the currently active tab. Must match one of `tabs`' ids.
  final String activeId;

  /// Called with a tab's id when the user activates it.
  final ValueChanged<String> onTabSelected;

  /// Called with a tab's id when the user presses its close (×) affordance.
  /// Null hides every tab's close button (no tab is closable).
  final ValueChanged<String>? onTabClosed;

  /// Called when the user presses the new-tab (+) affordance. Null hides it.
  final VoidCallback? onNewTab;

  /// Called with (oldIndex, newIndex) when the user drags a tab to reorder.
  /// Null disables drag-to-reorder.
  final void Function(int oldIndex, int newIndex)? onReorder;
}

/// A single tab descriptor in [LayrzWorkspaceTabs] — now owns its own content.
@immutable
class LayrzWorkspaceTab {
  /// Stable unique identity — the value passed back through every callback.
  final String id;

  /// The tab's visible label.
  final String label;

  /// Optional leading icon (e.g. a favicon-equivalent).
  final IconData? icon;

  /// Whether this specific tab shows a close (×) affordance. Defaults to true.
  final bool closable;

  /// The tab's primary content pane. REQUIRED.
  final Widget left;

  /// An optional secondary pane. Non-null puts the tab into split view.
  final Widget? right;
}
```

The `id`-based callback model (not index) keeps tab identity stable across reorders and
closes, and is used internally to reset per-active-tab UI state (the split ratio) on switch.

## Features — v1 scope (confirmed, implemented)

- **Close (×) per tab** — each closable tab shows a × always visible; emits `onTabClosed(id)`.
- **New-tab (+)** — a + affordance after the last tab; emits `onNewTab`.
- **Drag-to-reorder** — user drags a tab; emits `onReorder(oldIndex, newIndex)`.
- **Connected content panel** — the active tab's `left`/`right` render below the strip, in a
  bordered panel whose border visually merges with the active tab's own chrome.
- **Resizable split view** — a tab with `right != null` shows both panes side-by-side behind
  a draggable divider, clamped to a minimum pane extent
  (`kLayrzWorkspaceSplitMinPaneExtent`, 160px).

Out of v1 (revisit later): overflow "more" menu (v1 uses a horizontal scroll strip), tab
context menus, middle-click-to-close, tab groups/pinning beyond `closable: false`, per-tab
persisted split ratio (see [Split ratio scope](#split-ratio-scope)).

## Connected border

`LayrzWorkspaceTabChromePainter` (unchanged from the prior revision) paints each tab with
outward-flaring bottom shoulders (`shoulderRadius`) and, for the active tab, omits its bottom
edge from the stroked outline (`mergeBottom: true`) so no seam is drawn where it meets the
panel.

The panel itself is painted by the new `LayrzWorkspacePanelBorderPainter`: an otherwise
ordinary rounded rectangle (`tokens.radius.r3` on all four corners) whose **top edge is
interrupted** across the active tab's x-span. Instead of a straight line there, the outline
dips into a mirrored pair of the tab's own shoulder curves (sized off the same
`shoulderRadius`, `tokens.radius.r1`) and stops — that gap is exactly where the active tab's
own open (`mergeBottom`) border already ends, so the two painters' sub-paths abut with no
visible seam.

`LayrzWorkspaceTabs` resolves the active tab's on-screen span via a `RenderBox` lookup (the
tab strip reports the active tab's global `Rect` after every layout pass; the orchestrating
widget translates it into the panel's own local x-coordinates) and feeds it to the panel as
`activeTabLeft`/`activeTabRight`. When no tab is active, the panel falls back to an unbroken
border.

## Split view

`LayrzWorkspaceSplitView` renders `left` and `right` side-by-side, separated by a draggable
vertical divider (`Listener`-based, pointer drag — not a Material `Slider`). Dragging updates
a controlled `ratio` (fraction of width given to `left`) via `onRatioChanged`, clamped every
frame so neither pane crosses `kLayrzWorkspaceSplitMinPaneExtent`.

### Split ratio scope

**The split ratio is a single value held by `LayrzWorkspaceTabs`' own `State`, not persisted
per tab id.** Switching the active tab away and back resets the ratio to the default 50/50.
This was a deliberate v1 scope choice — per-tab ratio memory (e.g. a `Map<String, double>`
keyed by tab id) is a straightforward future enhancement, left out to keep the initial
surface area small. Document this scope choice to callers who need per-tab memory: they can
wrap `LayrzWorkspaceTabs` and rebuild it with a fresh key or drive their own persisted map at
the `right`/`left` content level if they need the ratio itself to survive a tab switch.

## Full-screen / expanding layout

`LayrzWorkspaceTabs` builds `Column(children: [strip, Expanded(panel)])` — the strip takes
its intrinsic height and the panel expands to fill whatever height remains. It is designed
to sit inside a bounded-height ancestor (typically a full page body), the same way a
browser's own tab/content region fills its window. An unbounded-height ancestor (e.g. a bare
`SingleChildScrollView`) is the caller's responsibility to avoid, exactly as for any other
`Expanded`-based widget.

## Accessibility

- Each tab: `Semantics(button: true, selected: id == activeId, label: <label>)`.
- Close ×: its own focusable, labeled affordance ("Close <label>").
- New-tab +: labeled ("New tab").
- Split divider: `Semantics(slider: true, label: 'Resize split', value: '<n>%', onIncrease,
  onDecrease)` — an adjustable control, not an inert line.
- Keyboard: arrow-key traversal between tabs, Enter/Space to activate.
- Reorder must remain operable without a mouse (keyboard reorder is a known hard problem;
  at minimum the list stays usable and reorder is an enhancement, not the only path).

## Module structure

Module `lib/src/workspace_tabs/`:
- `workspace_tabs.dart` — barrel (exports only).
- `src/workspace_tabs.dart` — `LayrzWorkspaceTabs`, the thin strip+panel orchestrator.
- `src/workspace_tab.dart` — `LayrzWorkspaceTab` descriptor (now with `left`/`right`).
- `src/workspace_tab_strip.dart` — `LayrzWorkspaceTabStrip`, the scrollable tab strip
  (selection, close, reorder, keyboard traversal) — extracted from the orchestrator to keep
  each file under the repo's file-size guidance.
- `src/workspace_tab_item.dart` — a single tab's chrome + label + close ×.
- `src/workspace_tab_chrome_painter.dart` — the connected-tab-chrome painting.
- `src/workspace_panel.dart` — `LayrzWorkspacePanel`, the connected content panel.
- `src/workspace_panel_border_painter.dart` — the panel's gap-carving border painter.
- `src/workspace_split_view.dart` — `LayrzWorkspaceSplitView`, the resizable two-pane split.
- `src/workspace_new_tab_button.dart` — the pinned (+) affordance.

Root barrel `lib/layrz_ui.dart` exports `src/workspace_tabs/workspace_tabs.dart` alphabetically
(unchanged — no new root-level export needed since only `LayrzWorkspaceTab` was already a
public root-exported type and the rest ride the same module barrel).

Wiki: `wiki/Widgets/LayrzWorkspaceTabs.md`, registered in `_Sidebar.md`, updated for the new
slots, panel, split, and divider.

## Revision history

**v2 (this revision) — tab-owns-content.** The original v1 design (below, kept for context)
was bar-only: the widget rendered only the strip, and the developer rendered the active
tab's body externally, keyed by id. This redesign moves content ownership onto
`LayrzWorkspaceTab` itself (`left`/`right`) and makes `LayrzWorkspaceTabs` render the
connected content panel, because:

1. The bar-only model required every caller to hand-roll the exact same "look up the active
   tab, render its body, key it so state survives a switch" boilerplate the widget could
   own instead.
2. The commercial ask evolved to include split-pane document views (a report next to its
   notes, a file tree next to a preview) — a first-class feature that only makes sense once
   the widget renders the panel it can put a divider inside of.
3. The connected-chrome visual (v1's tab shape merging into the panel below) only reads as
   "merged" when the widget draws both halves of the seam; a caller-rendered panel could
   never guarantee its own top border lined up with the tab's shoulders.

**Breaking change**: `LayrzWorkspaceTab.left` is a new required field — every existing
construction of `LayrzWorkspaceTab` must add it. `LayrzWorkspaceTabs` no longer expects the
caller to render a body alongside it; doing so is now redundant with the widget's own panel.

---

## v1 spec (superseded, kept for context)

The rest of this document is the original v1 design record, describing the bar-only model
that shipped before this revision. It is retained for history; do not treat it as current
behaviour — see the sections above for what's actually implemented.

### v1 model — controlled, tab-bar-only

The widget managed **only the tab strip and active state**. It did **not** own or render the
body. The developer kept the tab list + active id in their own state, rendered the body from
the active id, and mutated the list in response to the widget's callbacks.

```
┌─────────────────────────────────────────────┐
│ [ Tab A ×][ Tab B ×][ Tab C ×]        [ + ] │   ← LayrzWorkspaceTabs (this widget)
├─────────────────────────────────────────────┤
│                                             │
│   content for the active tab                │   ← dev renders this from activeId
│                                             │
└─────────────────────────────────────────────┘
```

### v1 proposed API (as originally drafted)

```dart
class LayrzWorkspaceTabs extends StatelessWidget {
  final List<LayrzWorkspaceTab> tabs;
  final String activeId;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<String>? onTabClosed;
  final VoidCallback? onNewTab;
  final void Function(int oldIndex, int newIndex)? onReorder;
}

@immutable
class LayrzWorkspaceTab {
  final String id;
  final String label;
  final IconData? icon;
  final bool closable;
}
```

Note the original draft had `LayrzWorkspaceTabs` as a `StatelessWidget`; the implementation
shipped (both v1 and this v2) as a `StatefulWidget`, since drag-reorder, keyboard focus
traversal, and (in v2) the split ratio all need to live somewhere.
