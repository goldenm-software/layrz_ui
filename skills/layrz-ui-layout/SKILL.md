---
name: layrz-ui-layout
description: Use LayrzLayout in a layrz_ui Flutter app. Apply when building the top-level app shell — navigation rail (expanded) / off-canvas drawer (compact), user chrome dropdown, notifications bell, or persisting rail/search/notification state via LayrzLayoutController.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.expanded`, `.drawer`) — never the fully-qualified form (`LayrzLayoutPresentation.expanded`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The single top-level application shell of a layrz_ui app: navigation, user identity chrome, notifications, and the main content area, in one locked design.
- Wrap the `body` of every authenticated/main page in `LayrzLayout` — it resolves its own presentation via `LayoutBuilder` constraints, so it also works nested inside a constrained container, not just full-screen.
- Pass an externally-owned `LayrzLayoutController` when the rail scroll offset, notifications-panel open state, or search query must survive navigation (a new page pushing a fresh `LayrzLayout`).
- **Do not use** for a list+detail split view — use `LayrzScaffoldShell` instead.
- **Do not use** to render a fixed, author-defined set of pill tabs — use `LayrzTabView` instead.
- **Do not use** `Scaffold`, `Drawer`, or any other Material navigation primitive — `LayrzLayout` is the only app shell allowed.

---

## Minimal usage

```dart
LayrzLayout(
  logo: 'assets/logo.png',
  body: const HomePage(),
  items: [
    LayrzNavigatorLabel('Main'),
    LayrzNavigatorPage(
      id: 'home',
      labelText: 'Home',
      icon: MdiIcons.homeOutline,
      isSelected: currentPage == 'home',
      onTap: () => setState(() => currentPage = 'home'),
    ),
  ],
)
```

---

## Key behaviors

- **Two presentations, container-driven, not viewport-driven**: `expanded` (178px fixed rail, md/lg/xl bands) and `drawer` (56px top bar + off-canvas drawer, xs/sm bands), resolved via `resolveLayrzLayoutPresentation` against `LayoutBuilder` constraints.
- **`items` is a flat, sealed list** — `LayrzNavigatorPage` (tappable, `isSelected` caller-owned) and `LayrzNavigatorLabel` (non-interactive section caption). No nested/tree navigation.
- **Consumer owns routing.** `LayrzLayout` never pushes routes itself; `LayrzNavigatorPage.onTap` and `isSelected` are entirely caller-driven.
- **Notifications bell is hidden entirely** when both `notifications` is empty AND `onNotificationTap` is null.
- **User chrome is only interactive when `userMenuItems` is non-empty** — an empty list renders no chevron and does nothing on tap.
- **Selectable body by default** (`selectableContent: true`) — wraps `body` in one `SelectableRegion` with a Copy-only toolbar. Set `false` to disable text selection entirely (not merely inert — the region is absent).
- **Keyboard resize is automatic, Scaffold-style** — the body and nav panel both shrink for the on-screen keyboard; there is no opt-out.
- **Controller ownership**: pass `controller: null` (default) and `LayrzLayout` creates/disposes its own `LayrzLayoutController`. Pass your own and you own its `dispose()` — the layout never disposes an externally-supplied controller.

---

## Presentations

| Presentation | Bands | Width | Chrome |
|---|---|---|---|
| Expanded | md, lg, xl | 178px fixed rail (`kLayrzLayoutRailWidth`) | Rail: user block, nav list, notifications footer |
| Drawer | xs, sm | 56px top bar (`kLayrzLayoutTopBarHeight`), 260px drawer (`kLayrzLayoutDrawerWidth`) | Top bar: logo, drawer trigger, notifications, user block |

---

## Common patterns

```dart
// 1. Persisting rail/notifications/search state across route pushes
class _ShellState extends State<AppShell> {
  final _layoutController = LayrzLayoutController();

  @override
  void dispose() {
    _layoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayrzLayout(
      controller: _layoutController,
      logo: 'assets/logo.png',
      items: navItems,
      body: currentPageBody,
    );
  }
}

// 2. Notifications + user menu
LayrzLayout(
  logo: 'assets/logo.png',
  body: const HomePage(),
  items: navItems,
  userName: 'Alice Johnson',
  userAvatar: LayrzAvatarUrl('https://example.com/avatar.png'),
  userMenuItems: [
    LayrzDropdownEntry(labelText: 'Profile', onTap: showProfile),
    LayrzDropdownEntry(labelText: 'Logout', onTap: logout),
  ],
  notifications: [
    LayrzNotificationItem(
      id: 'msg-1',
      title: 'New Messages',
      content: 'You have 3 unread messages.',
      onTap: viewMessages,
    ),
  ],
  onNotificationTap: (item) => debugPrint('Tapped ${item.id}'),
)

// 3. Disabling text selection
LayrzLayout(
  selectableContent: false,
  logo: 'assets/logo.png',
  items: navItems,
  body: currentPageBody,
)
```

---

## App setup conventions

- Exactly one `LayrzLayout` wraps each authenticated page's content; the `body` is the page's own content, not another `LayrzLayout`.
- Compute `isSelected` from your own route/page state on every rebuild — `LayrzLayout` never tracks selection itself.
- Prefer `LayrzNavigatorLabel` to group related `LayrzNavigatorPage` entries (e.g. "MAIN", "SETTINGS") rather than a flat unlabeled list.
- When nesting `LayrzLayout` under a router shell (e.g. go_router `ShellRoute`), remember it is container-driven — a narrow nested container renders `drawer` even on a wide screen.
- Never hardcode the rail/drawer/top-bar dimensions — they are fixed design constants (`kLayrzLayoutRailWidth`, `kLayrzLayoutDrawerWidth`, `kLayrzLayoutTopBarHeight`), not configurable per instance.
