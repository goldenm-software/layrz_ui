# LayrzWorkspaceTabs — API Reference

Source: `lib/src/workspace_tabs/src/workspace_tabs.dart`
- `LayrzWorkspaceTabs` class
- Companion: `workspace_tab.dart` — `LayrzWorkspaceTab`
- Companion: `workspace_split_view.dart` — `LayrzWorkspaceSplitView`, `kLayrzWorkspaceSplitMinPaneExtent`
- Companion: `workspace_panel.dart` — `LayrzWorkspacePanel`
- Companion: `workspace_tab_strip.dart`, `workspace_tab_chrome_painter.dart`, `workspace_silhouette_painter.dart` — internal chrome/painting

---

## Examples

```dart
// Full-screen host with open/close/new/reorder wired up
class WorkspaceExample extends StatefulWidget {
  @override
  State<WorkspaceExample> createState() => _WorkspaceExampleState();
}

class _WorkspaceExampleState extends State<WorkspaceExample> {
  List<LayrzWorkspaceTab> _tabs = [
    LayrzWorkspaceTab(id: 'home', label: 'Home', closable: false, left: const HomePane()),
    LayrzWorkspaceTab(
      id: 'doc-1',
      label: 'Report.pdf',
      icon: MdiIcons.fileOutline,
      left: const ReportDocumentPane(),
      right: const ReportNotesPane(), // non-null right -> split view
    ),
  ];
  String _activeId = 'home';

  @override
  Widget build(BuildContext context) {
    // LayrzWorkspaceTabs expands its panel to fill available height, so it
    // expects a bounded-height ancestor -- here, the page body itself.
    return SizedBox.expand(
      child: LayrzWorkspaceTabs(
        tabs: _tabs,
        activeId: _activeId,
        onTabSelected: (id) => setState(() => _activeId = id),
        onTabClosed: (id) => setState(() {
          _tabs = _tabs.where((t) => t.id != id).toList();
          if (_activeId == id && _tabs.isNotEmpty) _activeId = _tabs.first.id;
        }),
        onNewTab: () => setState(() {
          final id = 'doc-${_tabs.length}';
          _tabs = [..._tabs, LayrzWorkspaceTab(id: id, label: 'Untitled', left: const Placeholder())];
          _activeId = id;
        }),
        onReorder: (oldIndex, newIndex) => setState(() {
          final tab = _tabs.removeAt(oldIndex);
          _tabs.insert(newIndex, tab);
        }),
      ),
    );
  }
}
```

---

## Constructor

```dart
const LayrzWorkspaceTabs({
  super.key,
  required this.tabs,
  required this.activeId,
  required this.onTabSelected,
  this.onTabClosed,
  this.onNewTab,
  this.onReorder,
});
```

No compile-time asserts on `LayrzWorkspaceTabs` itself.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `tabs` | `List<LayrzWorkspaceTab>` | required | Tabs in display order. |
| `activeId` | `String` | required | Id of the active tab. If it matches none of `tabs`, no tab renders active and the panel is empty with an unbroken border. |
| `onTabSelected` | `ValueChanged<String>` | required | Fires on tap or Enter/Space on the focused tab. |
| `onTabClosed` | `ValueChanged<String>?` | `null` | `null` hides every tab's close (×) affordance regardless of each tab's own `closable`. |
| `onNewTab` | `VoidCallback?` | `null` | `null` hides the new-tab (+) affordance entirely. |
| `onReorder` | `void Function(int oldIndex, int newIndex)?` | `null` | `null` disables drag-to-reorder — tabs stay tappable, not draggable. |

---

## `LayrzWorkspaceTab`

```dart
const LayrzWorkspaceTab({
  required this.id,
  required this.label,
  required this.left,
  this.icon,
  this.closable = true,
  this.right,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | Stable identity, passed back through every callback. Never derive from `label`. |
| `label` | `String` | required | Visible tab label. |
| `left` | `Widget` | required | Primary content pane, rendered whenever this tab is active. |
| `icon` | `IconData?` | `null` | Optional leading icon, favicon-equivalent. |
| `closable` | `bool` | `true` | `false` ⇒ this tab never shows a close affordance and never emits `onTabClosed`, even when the strip's handler is set. |
| `right` | `Widget?` | `null` | Non-null puts this tab into split view (`left`/`right` side-by-side behind a resizable divider). `null` ⇒ `left` fills the panel alone. |

`isSplit` getter: `right != null`. Has `copyWith` (cannot clear `right` back to `null` — construct a new instance for that), `==`/`hashCode` over all six fields.

---

## `LayrzWorkspaceSplitView`

```dart
const LayrzWorkspaceSplitView({
  super.key,
  required this.left,
  required this.right,
  required this.ratio,
  required this.onRatioChanged,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `left` | `Widget` | required | Start (left-hand) pane. |
| `right` | `Widget` | required | End (right-hand) pane. |
| `ratio` | `double` | required | Fraction (0.0–1.0) of width given to `left`. Controlled — the caller persists and feeds this back. |
| `onRatioChanged` | `ValueChanged<double>` | required | Fires continuously during drag, already clamped. |

`kLayrzWorkspaceSplitMinPaneExtent = 160.0` — neither pane may shrink below this; every drag delta is clamped on both sides before `onRatioChanged` fires.

---

## Companion widgets

- **`LayrzWorkspacePanel`** — renders the active tab's `left` alone, or `left`/`right` in a `LayrzWorkspaceSplitView` when `right` is non-null. Clips content to the connected card's rounded shape. Not typically constructed directly — `LayrzWorkspaceTabs` builds it internally.
- **`LayrzWorkspaceTabStrip`**, **`LayrzWorkspaceTabChromePainter`**, **`LayrzWorkspaceSilhouettePainter`** — internal chrome/painting pieces that together produce the browser-tab silhouette; not part of the public API surface consumers construct directly.

---

## Behavior notes

- **Connected border**: a single `LayrzWorkspaceSilhouettePainter` traces the whole `[active tab bump + card]` outline as one continuous `Path`, filled once with `sf1` and stroked once with `tokens.colors.primary` at 1.5px. Painted twice — once beneath the strip (fill+stroke) and once above it (stroke-only) — so an adjacent inactive tab's opaque fill never crops the active tab's border.
- **No outward shoulder** (`shoulderRadius: 0`) — tab sides run straight down to meet the card's top edge; an earlier flared-shoulder design produced an awkward "ear" and was dropped.
- **Split ratio scope**: a single value on `LayrzWorkspaceTabs`' own state, not persisted per tab id — switching tabs away and back resets to 50/50. Per-tab ratio memory is a deliberate future enhancement, not shipped.
- **Keyboard navigation**: Left/Right arrow moves a focus highlight between tabs without activating them; Enter/Space activates the focused tab.
- **Accessibility**: each tab is `Semantics(button: true, selected: ...)`; close (×) and new-tab (+) are independently labeled and focusable; the split divider is `Semantics(slider: true, label: 'Resize split', value: '<n>%', onIncrease, onDecrease)`.
- **Labels are not selectable body text** — wrapped in `SelectionContainer.disabled`.
- **v1 scope limits**: overflow beyond the strip's width scrolls horizontally (no overflow menu); no context menu; no middle-click-to-close; no tab groups/pinning beyond `closable`.
- **Breaking change from the original bar-only design**: `left` is a required field on every `LayrzWorkspaceTab` — a caller migrating from a version that rendered its own external body must move that content into `left`/`right`.
