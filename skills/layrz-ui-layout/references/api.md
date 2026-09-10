# LayrzLayout — API Reference

Source: `lib/src/layout/src/layout.dart`
- `LayrzLayout` class
- Companion: `layout_controller.dart` — `LayrzLayoutController`
- Companion: `navigator_item.dart` — sealed `LayrzNavigatorItem` → `LayrzNavigatorPage` / `LayrzNavigatorLabel`
- Companion: `notification_item.dart` — `LayrzNotificationItem`
- Companion: `presentation.dart` — `LayrzLayoutPresentation` enum + `resolveLayrzLayoutPresentation`

---

## Examples

```dart
// Basic sidebar layout
LayrzLayout(
  logo: 'assets/logo.png',
  body: const Placeholder(),
  items: [
    LayrzNavigatorLabel('Main'),
    LayrzNavigatorPage(
      id: 'home',
      labelText: 'Home',
      icon: MdiIcons.homeOutline,
      isSelected: currentPage == 'home',
      onTap: () => setState(() => currentPage = 'home'),
    ),
    LayrzNavigatorPage(
      id: 'settings',
      labelText: 'Settings',
      icon: MdiIcons.cogOutline,
      isSelected: currentPage == 'settings',
      onTap: () => setState(() => currentPage = 'settings'),
    ),
  ],
  userAvatar: LayrzAvatarUrl('https://example.com/avatar.png'),
  userName: 'Alice Johnson',
  userMenuItems: [
    LayrzDropdownEntry(labelText: 'Profile', onTap: showProfile),
    LayrzDropdownEntry(labelText: 'Logout', onTap: logout),
  ],
)

// With a count badge and a context menu on a page item
LayrzNavigatorPage(
  id: 'inbox',
  labelText: 'Inbox',
  icon: MdiIcons.inboxOutline,
  count: 12,
  isSelected: currentPage == 'inbox',
  onTap: () => setState(() => currentPage = 'inbox'),
  contextMenuActions: [
    LayrzContextMenuItem(labelText: 'Mark all read', onTap: markAllRead),
  ],
)

// A tinted section label
LayrzNavigatorLabel('Danger Zone', color: context.theme.tokens.colors.danger)
```

---

## Constructor

```dart
const LayrzLayout({
  super.key,
  required this.body,
  required this.items,
  required this.logo,
  this.userName,
  this.userAvatar,
  this.userMenuItems = const [],
  this.notifications = const [],
  this.onNotificationTap,
  this.backgroundColor,
  this.selectableContent = true,
  this.controller,
});
```

No compile-time asserts on `LayrzLayout` itself.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `body` | `Widget` | required | Main content. Right of the rail (expanded) or below the top bar (drawer). |
| `items` | `List<LayrzNavigatorItem>` | required | `LayrzNavigatorPage`/`LayrzNavigatorLabel` entries, rendered in order. |
| `logo` | `String` | required | Passed to `LayrzImage` — network URL, asset path, or base64 string. |
| `userName` | `String?` | `null` | Display name; also used to derive avatar-fallback initials. |
| `userAvatar` | `LayrzAvatarSource?` | `null` | `LayrzAvatarUrl` / `LayrzAvatarBase64` / `LayrzAvatarIcon` / `LayrzAvatarEmoji`. If null, initials are derived from `userName`. |
| `userMenuItems` | `List<LayrzDropdownItem>` | `[]` | Dropdown shown on tapping the user chrome. Empty ⇒ chrome is non-interactive, no chevron. |
| `notifications` | `List<LayrzNotificationItem>` | `[]` | Entries in the notifications panel. |
| `onNotificationTap` | `void Function(LayrzNotificationItem)?` | `null` | Fires on any notification tap, in addition to each item's own `onTap`. |
| `backgroundColor` | `Color?` | `null` (→ `tokens.colors.sf1`) | Layout background. |
| `selectableContent` | `bool` | `true` | Wraps `body` in a `SelectableRegion` with Copy-only toolbar. `false` removes the region entirely. |
| `controller` | `LayrzLayoutController?` | `null` | External controller for persisting rail scroll/notifications-open/search state. Caller-owned if non-null. |

**Notifications bell visibility**: hidden entirely when `notifications.isEmpty && onNotificationTap == null`.

**Removed parameters (do not use)**: `appTitle`, `labelColour`, `showSearch` are not part of the current API — there is no built-in search field above the nav items.

---

## `LayrzNavigatorItem` sealed hierarchy

### `LayrzNavigatorPage`

```dart
const LayrzNavigatorPage({
  required this.id,
  required this.labelText,
  this.icon,
  this.count,
  this.onTap,
  this.isSelected = false,
  this.contextMenuActions = const [],
});
```

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | Stable identifier passed to callbacks. Does NOT determine selection. |
| `labelText` | `String` | required | Display label. |
| `icon` | `IconData?` | `null` | Rendered at label font size (14px). |
| `count` | `int?` | `null` | Trailing badge. |
| `onTap` | `VoidCallback?` | `null` | Tap handler. |
| `isSelected` | `bool` | `false` | Caller-owned; determines highlight. |
| `contextMenuActions` | `List<LayrzContextMenuItem>` | `[]` | Right-click (desktop/web) / long-press (touch) menu. Empty ⇒ no context menu. |

Has `==`/`hashCode`/`copyWith`.

### `LayrzNavigatorLabel`

```dart
const LayrzNavigatorLabel(this.labelText, {this.color});
```

| Field | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required (positional) | Section caption text. |
| `color` | `Color?` | `null` (→ `primary` at tonal opacity) | Tints the label band. |

Has `==`/`hashCode`/`copyWith`.

---

## `LayrzNotificationItem`

```dart
const LayrzNotificationItem({
  required this.id,
  required this.title,
  required this.content,
  this.icon,
  this.onTap,
});
```

| Field | Type | Default | Notes |
|---|---|---|---|
| `id` | `String` | required | Uniqueness key. |
| `title` | `String` | required | Primary heading. |
| `content` | `String` | required | Body text below `title`. |
| `icon` | `IconData?` | `null` | Optional leading icon. |
| `onTap` | `VoidCallback?` | `null` | Panel stays open after tap unless the callback dismisses it. |

Has `==`/`hashCode`/`copyWith`.

---

## `LayrzLayoutController extends ChangeNotifier`

```dart
LayrzLayoutController({
  bool notificationsOpen = false,
  String searchQuery = '',
});
```

| Member | Signature | Notes |
|---|---|---|
| `railScrollController` | `ScrollController get` | Owned by the controller; created in constructor, disposed in `dispose()`. |
| `railScrollOffset` | `double get` | Last known scroll offset, persisted independent of the currently-attached scrollable. Default `0.0`. |
| `restoreRailScroll()` | `void` | Jumps the (possibly freshly-attached) scrollable back to `railScrollOffset`. No-op if already correct or unattached. |
| `notificationsOpen` | `bool get` | Whether the notifications panel is open. |
| `setNotificationsOpen(bool open)` | `void` | No-op (no notify) if unchanged. |
| `toggleNotifications()` | `void` | Toggles `notificationsOpen`. |
| `searchQuery` | `String get` | Current search text (empty = no filter). |
| `setSearchQuery(String query)` | `void` | No-op (no notify) if unchanged. |
| `dispose()` | `void` | Disposes the internal `ScrollController` too. Caller-owned if this controller was externally supplied to `LayrzLayout`. |

---

## `LayrzLayoutPresentation` enum

| Value | Bands | Description |
|---|---|---|
| `.expanded` | md, lg, xl | 178px fixed nav rail beside the body. |
| `.drawer` | xs, sm | 56px top bar + off-canvas drawer. |

`resolveLayrzLayoutPresentation({required double width, required LayrzTokens tokens})` resolves the band via `tokens.breakpoints.bandAt(width)` — container-driven (from `LayoutBuilder` constraints), never `MediaQuery`/viewport-driven.

---

## Static / design constants

| Constant | Value | Notes |
|---|---|---|
| `kLayrzLayoutRailWidth` | `178.0` | Expanded presentation's fixed rail width. |
| `kLayrzLayoutDrawerWidth` | `260.0` | Drawer presentation's off-canvas width. |
| `kLayrzLayoutTopBarHeight` | `56.0` | Drawer presentation's top bar height. |

---

## Behavior notes

- **Keyboard handling is unconditional and Scaffold-style**: the body's available height is reduced by `MediaQuery.viewInsetsOf(context).bottom`, and that inset is zeroed for the body's own subtree — there is no opt-out flag. The page body is not made scrollable automatically; whether it scrolls remains the consumer's responsibility.
- **Text selection scope**: `selectableContent: true` wraps only the layout's `body`; overlays (dialogs, bottom sheets, menus, tooltips) mounted into the app `Overlay` are outside the region regardless.
- **Selection controls differ by platform**: touch platforms (`LayrzPlatform.isTouchOS`) get `LayrzTextSelectionControls` (handles + long-press magnifier); other platforms get an inert `emptyTextSelectionControls` (no handles/default toolbar), since the custom Copy-only toolbar builder is wired unconditionally either way.
- **Controller lifecycle mirrors `LayrzTableController`**: `LayrzLayout` disposes a controller it created internally; it never disposes one you passed in via `controller`.
- **Drawer rail scroll is not automatically persistent** without a controller — the drawer's `SingleChildScrollView` is rebuilt from scratch on every rebuild of the drawer branch; `LayrzLayoutController.restoreRailScroll()` is what re-anchors it, called automatically by `LayrzLayout` whenever an external or internal controller is attached.
