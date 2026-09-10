# LayrzFindInPageHost — API Reference

Source: `lib/src/find_in_page/src/find_in_page_host.dart`, `lib/src/find_in_page/src/find_in_page_controller.dart`
- `LayrzFindInPageHost` class (`StatefulWidget`)
- `LayrzFindInPageHostState` class
- `LayrzFindInPageController` class (`ChangeNotifier`)

---

## Examples

```dart
// Installed automatically by LayrzApp — no direct construction needed.
LayrzApp(
  title: 'My App',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
)

// Opt out for a specific build
LayrzApp(
  title: 'My App',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  enableFindInPage: false,
)

// Drive it from application code
LayrzFindInPageHost.of(context).controller.open();
LayrzFindInPageHost.of(context).controller.close();
LayrzFindInPageHost.of(context).controller.toggle();
LayrzFindInPageHost.of(context).controller.setQuery('revenue');
LayrzFindInPageHost.of(context).controller.next();
LayrzFindInPageHost.of(context).controller.previous();

// Graceful lookup outside a guaranteed LayrzApp subtree
final host = LayrzFindInPageHost.maybeOf(context);
host?.controller.open();
```

---

## Constructor

```dart
const LayrzFindInPageHost({super.key, required this.child});
```

| Property | Type | Notes |
|---|---|---|
| `child` | `Widget` | **required.** The subtree this host wraps — the app's real content, sitting underneath the find bar and highlight overlay whenever find is open. |

Application code should not normally construct this directly — `LayrzApp` installs it automatically when `enableFindInPage` is `true` (the default).

---

## Static resolution

```dart
static LayrzFindInPageHostState of(BuildContext context);
static LayrzFindInPageHostState? maybeOf(BuildContext context);
```

`of` throws (via `assert`) if no ancestor `LayrzFindInPageHost` is found; `maybeOf` returns `null` instead. Both resolve by tree ancestry only (`dependOnInheritedWidgetOfExactType`) — no `GlobalKey` fallback.

---

## `LayrzFindInPageHostState`

```dart
class LayrzFindInPageHostState extends State<LayrzFindInPageHost> {
  final LayrzFindInPageController controller;
}
```

The `controller` is the imperative entry point for everything find-related.

---

## `LayrzFindInPageController` (ChangeNotifier)

| Member | Type | Notes |
|---|---|---|
| `isOpen` | `bool` (getter) | Whether find is currently open. `false` initially and after `close()`. |
| `query` | `String` (getter) | The current search query text. |
| `isSearching` | `bool` (getter) | Whether a search is in flight (debounce pending, or walked but not yet resolved). Drives the find bar's indeterminate progress line. |
| `matches` | `List<FindMatch>` (getter) | The most recent walk's results, in reading order, with the find bar's own matches already excluded. |
| `currentIndex` | `int` (getter) | Index into `matches` treated as "current". `-1` when there is no current match. |
| `highlights` | `List<MatchHighlight>` (getter) | Resolved highlight geometry for currently-visible matches. |
| `visibleMatches` | `List<FindMatch>` (getter) | Subset of `matches` currently on screen. |
| `excludeRect` | `Rect?` (getter) | The find bar's own on-screen rect, used to exclude its own matches from the walk. |
| `open()` | `void` | Acquires the `SemanticsHandle`, subscribes to the semantics tree, schedules an initial walk if `query` is already non-empty. No-op if already open. |
| `close()` | `void` | Cancels pending debounce, disposes the `SemanticsHandle`, clears matches/highlights/currentIndex instantly. **Does not clear `query`** (matches real browser Ctrl+F behavior). No-op if already closed. |
| `toggle()` | `void` | Opens if closed, closes if open — the target of the Ctrl/Cmd+F shortcut. |
| `setQuery(String newValue)` | `void` | Handles every keystroke from the query field. Clearing to empty/whitespace clears results **immediately** (no debounce); a non-empty value (re)starts a 300ms debounce (`kFindInPageQueryDebounce`). |
| `searchNow()` | `void` | Runs an immediate walk, bypassing any pending debounce — used by the find bar's Enter submit. |
| `next()` | `void` | Advances to the next match (wraps), requests scroll-into-view. |
| `previous()` | `void` | Cycles to the previous match (wraps), requests scroll-into-view. |
| `updateExcludeRect(Rect rect)` | `void` | Updates `excludeRect` — called by `LayrzFindInPageHost` on every layout the find bar undergoes. |

---

## Behavior notes

- **Idle cost.** The `SemanticsHandle` — the single most expensive resource involved, since holding one forces Flutter to build and maintain a full semantics tree app-wide — is held **only between `open()` and `close()`**, never for the app's whole lifetime. An app that never opens find pays zero semantics-tree cost.
- **Two-layer search.** Locating matches (`walkSemantics`, over the semantics tree) and resolving word-level highlight geometry (`findRenderTextSources` + `resolveWordHighlights`, over the render tree, restricted to visible matches) are two separate mechanisms, kept apart deliberately.
- **Self-exclusion is release-safe.** The find bar's own matches are excluded by measuring its actual on-screen rect (`RenderBox.localToGlobal`, available in every build mode) rather than a debug-only `debugSemantics` id lookup — any match whose center falls inside `excludeRect` is dropped before being exposed.
- **Ctrl/Cmd+F registration.** Via `LayrzShortcut.maybeOf` — deliberately `maybeOf`, not `.of` — modifier is `LogicalKeyboardKey.meta` on macOS, `.control` elsewhere (`LayrzPlatform.isMacOS`). Deregistered in `dispose`.
- **Web-only browser capture.** `installFindKeyCapture` additionally intercepts the browser's own native Ctrl+F on web, ahead of Flutter's own key handling — a no-op stub on every other platform.
- **In-page, not navigation.** Opening/closing find never pushes, pops, or otherwise touches a `Navigator` or router.
- **Material-free construction.** Built entirely on `StatefulWidget`/`State`, a private `InheritedWidget` (`_LayrzFindInPageScope`), `Overlay`/`OverlayEntry`, `CustomPaint` (the highlight layer), and `SemanticsOwner`/`SemanticsHandle` from `package:flutter/rendering.dart`.

---

## Related widgets

- **`LayrzFindBar`** — the floating UI this host shows/hides as `isOpen` changes. See the `layrz-ui-find-bar` skill.
- **`LayrzSearchable`** — the escape hatch for content invisible to the semantics walk. See the `layrz-ui-searchable` skill.
- **`LayrzShortcut`** — the Ctrl/Cmd+F key registration mechanism. See the `layrz-ui-shortcut` skill.
