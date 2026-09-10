---
name: layrz-ui-page-transition
description: Use LayrzPageTransitions in a layrz_ui Flutter widget. Apply when wiring page-transition animations for `PageRouteBuilder.transitionsBuilder` (imperative Navigator) or go_router's `CustomTransitionPage.transitionsBuilder` — the .fade (default)/.slide/.scale/.rotation/.none static builders, `LayrzTransitionType` for a serializable choice, and `durationOf(context)` for the matching route duration.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.fade`, `.slide`) — never the fully-qualified form (`LayrzTransitionType.fade`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Wiring any route's transition animation — both Flutter's imperative `Navigator` (`PageRouteBuilder.transitionsBuilder`) and go_router (`CustomTransitionPage.transitionsBuilder`) accept the exact same function shape these builders provide.
- Selecting a transition from a single app-wide setting via `LayrzTransitionType` + `LayrzPageTransitions.resolve(type)`, rather than switching on builder functions directly.
- **Do not use** `LayrzPageTransitions` members as instance methods — the class is `abstract final` and never instantiated; every member is `static`.
- **Do not hardcode a transition duration** — always pair a chosen builder with `LayrzPageTransitions.durationOf(context)` for `transitionDuration`, or the route will silently drift from the curve the builder itself uses.
- **Do not use** for anything other than the transitions module — `layrz_ui` intentionally has no `go_router` dependency; wiring a `LayrzTransitionPage` convenience type for go_router lives in the separate `layrz_ui_extensions` package, not here.

---

## Minimal usage

```dart
// Imperative Navigator
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const DetailPage(),
    transitionsBuilder: LayrzPageTransitions.fade,
    transitionDuration: LayrzPageTransitions.durationOf(context),
  ),
);
```

---

## Key behaviors

- **`.fade` is the recommended default** for callers who haven't chosen a transition — also `LayrzTransitionType.fade`'s designated meaning.
- **Every builder honors reduced motion identically.** Each checks `MediaQuery.disableAnimationsOf(context)` first and delegates to `.none` when it reports `true` — this check runs once per route push/pop, not per frame, so it costs nothing meaningful.
- **A builder cannot set the route's own duration** — `transitionDuration` is a parameter of the route (`PageRouteBuilder`/`CustomTransitionPage`), not of the transition function. Always pass `LayrzPageTransitions.durationOf(context)` (resolves to `tokens.motion.dPageTransition`, 250ms) alongside whichever builder is chosen.
- **No `go_router` dependency in this package.** `LayrzTransitionBuilder` is a plain typedef structurally identical to both `PageRouteBuilder.transitionsBuilder` and go_router's `CustomTransitionPage.transitionsBuilder` — a function built against it is assignable to either call site with zero adapter code.
- `secondaryAnimation` is unused by every builder here (`.fade`/`.slide`/`.scale`/`.rotation`) — the incoming page's own animation is sufficient to read as one crossfade/slide/etc.

---

## Common patterns

```dart
// 1. go_router's CustomTransitionPage
GoRoute(
  path: '/detail',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const DetailPage(),
    transitionsBuilder: LayrzPageTransitions.scale,
    transitionDuration: LayrzPageTransitions.durationOf(context),
  ),
);

// 2. App-wide setting resolved via LayrzTransitionType
final builder = LayrzPageTransitions.resolve(settings.transitionType);
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const DetailPage(),
    transitionsBuilder: builder,
    transitionDuration: LayrzPageTransitions.durationOf(context),
  ),
);

// 3. No transition at all (instant navigation)
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const DetailPage(),
    transitionsBuilder: LayrzPageTransitions.none,
    transitionDuration: Duration.zero,
  ),
);
```

---

## Builder & `LayrzTransitionType` reference

| Builder | Enum value | Effect |
|---|---|---|
| `.fade` | `.fade` (default) | `FadeTransition` — incoming page fades in as outgoing fades out. |
| `.slide` | `.slide` | Incoming page slides in from the trailing edge (RTL-aware via `Directionality`); outgoing stays fixed beneath. |
| `.scale` | `.scale` | Incoming page scales `0.92` → `1.0` while fading in. |
| `.rotation` | `.rotation` | Incoming page rotates `-0.02` turn → `0.0` (a subtle settle) while fading in. |
| `.none` | `.none` | `child` returned unwrapped — appears instantly. Every other builder delegates here under reduced motion. |

---

## Usage conventions

- Always pair a chosen builder with `LayrzPageTransitions.durationOf(context)` — never hardcode `Duration(milliseconds: 250)` or any other literal; the token can change independently of this literal value.
- Prefer `LayrzPageTransitions.resolve(type)` over a manual `switch` on `LayrzTransitionType` whenever the transition is a runtime value (a user-configurable setting) rather than fixed at the call site.
- Reach for `.none` explicitly (with `transitionDuration: Duration.zero`) rather than omitting a `transitionsBuilder` entirely when instant navigation is deliberate — it documents the intent and stays consistent with the reduced-motion fallback every other builder uses.
