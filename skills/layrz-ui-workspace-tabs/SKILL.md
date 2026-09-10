---
name: layrz-ui-workspace-tabs
description: Use LayrzWorkspaceTabs in a layrz_ui Flutter widget. Apply when building a browser-style workspace — runtime open/close/reorder tabs, each tab owning its own content via LayrzWorkspaceTab.left/right, and an optional resizable two-pane split per tab.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A browser-style workspace: a connected tab strip *and* content panel where tabs open, close, and reorder at runtime, and each tab owns its own content.
- Use `LayrzWorkspaceTab.right` (non-null) to put a specific tab into a resizable two-pane split view (`left`/`right` side-by-side behind a draggable divider).
- **Do not use** for a fixed, author-defined tab set (no open/close/reorder) — use `LayrzTabView` instead; it is simpler and does not manage tab lifecycle.
- **Do not use** for the top-level app shell — use `LayrzLayout` instead.
- **This is a controlled widget** — the caller owns `tabs` and `activeId` as state; `LayrzWorkspaceTabs` renders them and reports events, it never mutates your list itself.

---

## Minimal usage

```dart
LayrzWorkspaceTabs(
  tabs: tabs,
  activeId: activeId,
  onTabSelected: (id) => setState(() => activeId = id),
)
```

---

## Key behaviors

- **Tab-owns-content model**: `LayrzWorkspaceTab.left` (required) and `.right` (optional) hold the tab's own content — the widget renders whichever tab is active directly, there is no separate body the caller renders and keys by id.
- **Expands to fill height** — builds a `Column` of `[strip, Expanded(panel)]`. Requires a bounded-height ancestor (a page body, a `Column`'s own `Expanded`), the same way a browser's own tab/content region fills its window.
- **Close (×) is controlled by two independent gates**: `onTabClosed == null` hides every tab's close affordance; a specific tab's own `closable: false` hides just that one, even while the rest of the strip remains closable.
- **`onNewTab == null` hides the (+) affordance entirely.**
- **`onReorder == null` disables drag-to-reorder** — tabs remain tappable but not draggable.
- **Split ratio is not persisted per tab** — it is a single value held by the widget's own state; switching the active tab away and back resets it to 50/50 (deliberate v1 scope).
- **Connected chrome**: the active tab and its content panel render as one continuous outlined shape (single silhouette painter) — not two separately-bordered pieces.

---

## Common patterns

```dart
// 1. Split view for one tab
LayrzWorkspaceTab(
  id: 'report-1',
  label: 'Q3 Report',
  left: ReportDocumentPane(),
  right: ReportNotesPane(),
)

// 2. A pinned, never-closable tab alongside closable ones
LayrzWorkspaceTabs(
  tabs: [
    LayrzWorkspaceTab(id: 'home', label: 'Home', closable: false, left: HomePane()),
    LayrzWorkspaceTab(id: 'doc-1', label: 'Report.pdf', left: DocumentPane(id: 'doc-1')),
  ],
  activeId: activeId,
  onTabSelected: (id) => setState(() => activeId = id),
  onTabClosed: (id) => setState(() => tabs.removeWhere((t) => t.id == id)),
)

// 3. Full open/close/new/reorder wiring
LayrzWorkspaceTabs(
  tabs: tabs,
  activeId: activeId,
  onTabSelected: (id) => setState(() => activeId = id),
  onTabClosed: (id) => setState(() {
    tabs = tabs.where((t) => t.id != id).toList();
    if (activeId == id && tabs.isNotEmpty) activeId = tabs.first.id;
  }),
  onNewTab: () => setState(() {
    final id = 'doc-${tabs.length}';
    tabs = [...tabs, LayrzWorkspaceTab(id: id, label: 'Untitled', left: const Placeholder())];
    activeId = id;
  }),
  onReorder: (oldIndex, newIndex) => setState(() {
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
  }),
)
```

---

## Usage conventions

- Always place `LayrzWorkspaceTabs` inside a bounded-height ancestor (e.g. `SizedBox.expand` in a full-screen page body) — an unbounded ancestor (a bare `SingleChildScrollView`) is a layout error the widget does not guard against.
- Never derive `LayrzWorkspaceTab.id` from `label` — a rename must not change identity, and two tabs may share a label without sharing an id.
- Use `LayrzWorkspaceTab.icon` as a favicon-equivalent (document-type or app icon), not a status indicator.
- Reach for `LayrzTabView` instead whenever the tab set is fixed at build time and never opened/closed/reordered by the user — it is the simpler, lower-overhead primitive for that case.
