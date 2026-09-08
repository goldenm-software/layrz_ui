# LayrzWorkspaceTabs — Design Spec (draft)

Status: **Draft for review** — not yet implemented. Raised by the commercial team; scoped with the maintainer.

## Context

The commercial team asked for a **browser-like tab** UI: a strip of tabs a user can open,
close, and reorder, on top of which the developer wires arbitrary content — the way browser
tabs manage documents/workspaces. This is a **workspace/document manager**, not a content
switcher.

This is deliberately a **separate component from `LayrzTabView`**. `LayrzTabView` is a
content switcher: a fixed, author-defined set of pill tabs that owns and swaps the body
below it. The two share the word "tab" and nothing else about their model:

| Concern | `LayrzTabView` | `LayrzWorkspaceTabs` |
|---|---|---|
| Tab set | Fixed, author-defined | Dynamic — user opens/closes |
| Close (×) per tab | No | Yes (core) |
| New-tab (+) | No | Yes (core) |
| Reorder (drag) | No | Yes (core) |
| Content ownership | Owns child, swaps it | **Dev wires content** (bar-only) |
| Shape | Rounded pills | Chrome-style connected tabs |

Forcing these behaviors onto `LayrzTabView` would blur its clean purpose. `LayrzWorkspaceTabs`
is net-new.

## Model — controlled, tab-bar-only

The widget manages **only the tab strip and active state**. It does **not** own or render the
body. The developer keeps the tab list + active id in their own state, renders the body from
the active id, and mutates the list in response to the widget's callbacks.

```
┌─────────────────────────────────────────────┐
│ [ Tab A ×][ Tab B ×][ Tab C ×]        [ + ] │   ← LayrzWorkspaceTabs (this widget)
├─────────────────────────────────────────────┤
│                                             │
│   content for the active tab                │   ← dev renders this from activeId
│                                             │
└─────────────────────────────────────────────┘
```

## Proposed API

```dart
/// A browser-style, controlled tab STRIP: the developer owns the tab list, the
/// active tab, and the content below; this widget renders the chrome-style tab
/// bar and emits selection / close / add / reorder events.
///
/// Not a content switcher — see [LayrzTabView] for the owns-its-content model.
class LayrzWorkspaceTabs extends StatelessWidget {
  /// The tabs to render, in display order.
  final List<LayrzWorkspaceTab> tabs;

  /// The id of the currently active tab. Must match one of [tabs]' ids.
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

  // (styling/overflow params TBD — see Open Questions)
}

/// A single tab descriptor in [LayrzWorkspaceTabs]. Carries identity + label
/// only — never content (content is the developer's, keyed by [id]).
@immutable
class LayrzWorkspaceTab {
  /// Stable unique identity — the value passed back through every callback and
  /// used to key the developer's content. Never derived from the label.
  final String id;

  /// The tab's visible label.
  final String label;

  /// Optional leading icon (e.g. a favicon-equivalent).
  final IconData? icon;

  /// Whether this specific tab shows a close (×) affordance. Defaults to true.
  /// A tab with `closable: false` never emits onTabClosed even when the widget
  /// has an onTabClosed handler (e.g. a pinned/home tab).
  final bool closable;
}
```

The `id`-based callback model (not index) keeps the developer's content mapping stable across
reorders and closes.

## Features — v1 scope (confirmed)

- **Close (×) per tab** — each closable tab shows a × on hover/always; emits `onTabClosed(id)`.
- **New-tab (+)** — a + affordance after the last tab; emits `onNewTab`.
- **Drag-to-reorder** — user drags a tab; emits `onReorder(oldIndex, newIndex)`.

Out of v1 (revisit later): overflow "more" menu (v1 uses a horizontal scroll strip), tab
context menus, middle-click-to-close, tab groups/pinning beyond `closable: false`.

## Visual — chrome-style connected tabs (confirmed)

The literal browser look: the **active tab connects to the content area** below it — rounded
top corners, its bottom edge merges into the panel so it reads as "part of" the content;
inactive tabs recede (a receded surface, slightly smaller/quieter). This needs custom
painting (a `CustomPainter` or carefully composed `ClipPath`/`DecoratedBox`) since the
connected-chrome shape isn't a plain rounded rectangle.

Tokens (Material-free, per repo rules — no hardcoded design values):
- Active tab fill: content-panel surface (`sf1`), so it visually continues into the body.
- Inactive tab fill: a receded surface (`sf2`/`sf3`), quieter foreground (`fg2`).
- The bar's own background behind the tabs: `sf2`/`divider` baseline.
- Corner radius from `tokens.radius`; spacing from `tokens.spacing`; hover/press per D15
  (color/opacity only, never geometry).
- Close × and new-tab + reuse existing icon rendering (widgets-layer `Icon`, as buttons do).

Interaction states obey D15: hover/press/active vary color/opacity/border only; the connected
shape and sizes stay stable.

## Accessibility

- Each tab: `Semantics(button: true, selected: id == activeId, label: <label>)`.
- Close ×: its own focusable, labeled affordance (e.g. "Close <label>").
- New-tab +: labeled ("New tab").
- Keyboard: arrow-key traversal between tabs, Enter/Space to activate; a close key
  affordance (e.g. Delete on a focused tab) is a nice-to-have — confirm during build.
- Reorder must remain operable without a mouse (keyboard reorder is a known hard problem;
  at minimum the list stays usable and reorder is an enhancement, not the only path).

## Module structure

New module `lib/src/workspace_tabs/`:
- `workspace_tabs.dart` — barrel (exports only).
- `src/workspace_tabs.dart` — `LayrzWorkspaceTabs`.
- `src/workspace_tab.dart` — `LayrzWorkspaceTab` descriptor.
- (likely) `src/workspace_tab_chrome_painter.dart` — the connected-chrome painting.
Root barrel `lib/layrz_ui.dart` exports `src/workspace_tabs/workspace_tabs.dart` alphabetically.

Wiki: `wiki/Widgets/LayrzWorkspaceTabs.md`, registered in `_Sidebar.md`, with a worked example
showing the dev owning the tab list + content and reacting to the four callbacks.

Example: a showcase page demonstrating open/close/reorder with real wired content.

## Open questions (resolve before build)

1. **Overflow**: horizontal scroll strip for v1 (confirmed out: "more" menu). Confirm scroll
   affordance styling (fade edges? scroll buttons?).
2. **Close-× visibility**: always shown, or only on hover / only on the active tab? (Chrome
   shows × on the active tab always and on others on hover.)
3. **New-tab position**: fixed after the last tab and scrolls with the strip, or pinned to the
   right edge of the bar regardless of scroll?
4. **Min/max tab width**: do tabs shrink as more open (Chrome-style), down to a min width,
   then scroll? Or fixed width + scroll immediately?
5. **Empty state**: what renders when `tabs` is empty (only the + )?
6. **Active-tab-closed behavior**: the widget emits `onTabClosed`; the dev decides the next
   active tab. Confirm the widget makes no active-tab assumption itself (it shouldn't —
   controlled model).

## Not in this batch

This is a **new feature from today's meeting**, independent of the in-flight EndDrawer→dialog
migration / time-picker redesign. It ships on its own branch after the current batch and the
maintainer's visual review settle.
