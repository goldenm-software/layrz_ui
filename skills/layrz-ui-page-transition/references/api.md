# LayrzPageTransitions — API Reference

Source: `lib/src/transitions/src/page_transitions.dart`, `lib/src/transitions/src/transition_type.dart`, `lib/src/transitions/src/transition_builder.dart`
- `LayrzPageTransitions` class (`abstract final`, static-only namespace) — `page_transitions.dart`
- `LayrzTransitionType` enum — `transition_type.dart`
- `LayrzTransitionBuilder` typedef — `transition_builder.dart`

---

## Examples

```dart
// PageRouteBuilder (imperative Navigator)
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const DetailPage(),
    transitionsBuilder: LayrzPageTransitions.slide,
    transitionDuration: LayrzPageTransitions.durationOf(context),
  ),
);

// go_router's CustomTransitionPage
GoRoute(
  path: '/detail',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const DetailPage(),
    transitionsBuilder: LayrzPageTransitions.scale,
    transitionDuration: LayrzPageTransitions.durationOf(context),
  ),
);

// Resolving from a LayrzTransitionType value (e.g. a user setting)
final builder = LayrzPageTransitions.resolve(LayrzTransitionType.rotation);

// No transition
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const DetailPage(),
    transitionsBuilder: LayrzPageTransitions.none,
    transitionDuration: Duration.zero,
  ),
);
```

---

## `LayrzPageTransitions` (static namespace, never instantiated)

```dart
abstract final class LayrzPageTransitions {
  static Widget fade(BuildContext, Animation<double>, Animation<double>, Widget);
  static Widget slide(BuildContext, Animation<double>, Animation<double>, Widget);
  static Widget scale(BuildContext, Animation<double>, Animation<double>, Widget);
  static Widget rotation(BuildContext, Animation<double>, Animation<double>, Widget);
  static Widget none(BuildContext, Animation<double>, Animation<double>, Widget);
  static Duration durationOf(BuildContext context);
  static LayrzTransitionBuilder resolve(LayrzTransitionType type);
}
```

| Member | Signature | Notes |
|---|---|---|
| `fade` | `LayrzTransitionBuilder` | `FadeTransition(opacity: animation, child: child)`. The recommended default; `secondaryAnimation` unused. |
| `slide` | `LayrzTransitionBuilder` | Incoming page slides from the trailing edge (`Directionality`-aware for RTL); outgoing stays fixed. Animated via `Tween<Offset>` + `CurvedAnimation` (`tokens.motion.easingEnter`). |
| `scale` | `LayrzTransitionBuilder` | `ScaleTransition` (`0.92` → `1.0`) composed with `FadeTransition` (`0.0` → `1.0`), both curved by `tokens.motion.easingEnter`. |
| `rotation` | `LayrzTransitionBuilder` | `RotationTransition` (`-0.02` turn → `0.0`) composed with `FadeTransition`, curved by `tokens.motion.easingEnter`. |
| `none` | `LayrzTransitionBuilder` | Returns `child` unwrapped, unconditionally — `context`/`animation`/`secondaryAnimation` accepted only to satisfy the signature. Every other builder delegates here under reduced motion. |
| `durationOf` | `static Duration durationOf(BuildContext context)` | Returns `context.tokens.motion.dPageTransition` (250ms by default) — the route-level duration a builder itself cannot set. |
| `resolve` | `static LayrzTransitionBuilder resolve(LayrzTransitionType type)` | Maps a `LayrzTransitionType` value to its matching static builder via an exhaustive `switch`. |

Every builder (except `none`) checks `MediaQuery.disableAnimationsOf(context)` first and delegates to `none` when `true`, so reduced motion is honored uniformly regardless of which builder was chosen. This check runs once per builder invocation (a route push/pop), not per frame.

---

## `LayrzTransitionType` enum

```dart
enum LayrzTransitionType { fade, slide, scale, rotation, none }
```

| Value | Maps to | Notes |
|---|---|---|
| `.fade` | `LayrzPageTransitions.fade` | The design system's default when no other transition is specified. |
| `.slide` | `LayrzPageTransitions.slide` | |
| `.scale` | `LayrzPageTransitions.scale` | |
| `.rotation` | `LayrzPageTransitions.rotation` | |
| `.none` | `LayrzPageTransitions.none` | Also what every transition collapses to under `MediaQuery.disableAnimationsOf`. |

Exists for callers who need a serializable/comparable handle on "which transition" — e.g. a single app-wide setting — rather than holding a function reference directly. `LayrzPageTransitions` remains the primary API for direct, fixed-at-the-call-site use.

---

## `LayrzTransitionBuilder` typedef

```dart
typedef LayrzTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);
```

Matches both `PageRouteBuilder.transitionsBuilder` and go_router's `CustomTransitionPage.transitionsBuilder` exactly — a function built against this typedef is assignable to either call site with zero adapter code and zero new dependencies.

| Parameter | Role |
|---|---|
| `context` | The outgoing route's `BuildContext` — used to read ambient state like `MediaQuery.disableAnimationsOf`. |
| `animation` | Drives the incoming route's transition, `0.0` → `1.0` as it becomes current. |
| `secondaryAnimation` | Drives this route's own transition when a route pushed on top of it starts/finishes its own transition — unused by every builder in this class. |
| `child` | The page content to wrap. |

---

## Behavior notes

- **No `go_router` dependency in this package.** `layrz_ui` never imports `go_router` (only `example/` does) — `LayrzTransitionBuilder`'s typedef shape, not a `go_router`-specific type, is what makes it usable at both call sites.
- **`durationOf` exists because a builder can't set its own route duration.** `PageRouteBuilder.transitionDuration`/`CustomTransitionPage.transitionDuration` are route-level parameters, resolved separately from the transition function itself.
- **`go_router` convenience wrapper lives outside this package.** A `LayrzTransitionPage<T>` (a `CustomTransitionPage<T>` pre-wired with one of these builders, plus named constructors per transition) is provided by the separate `layrz_ui_extensions` package — not part of `layrz_ui` itself, since `layrz_ui` has no `go_router` dependency to build such a type against.
