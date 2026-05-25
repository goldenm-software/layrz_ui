# layrz_ui

A Material-free, Cupertino-free Flutter design system — the next generation of [layrz_theme](https://github.com/goldenm-software/layrz_theme).

Built exclusively on `package:flutter/widgets.dart`. No Material. No Cupertino.

> **AI-assisted code notice**
> This package was developed with AI assistance. If you run into any issue or unexpected behavior, feel free to open a Pull Request — contributions are always welcome!

---

## Why layrz_ui?

Flutter's Material and Cupertino layers are opinionated and heavyweight. `layrz_ui` decouples the Layrz design system from both, the same way Flutter itself separates `widgets` from `material` and `cupertino`. The result is a leaner dependency graph, full control over every pixel, and no unwanted platform chrome.

---

## Features

- `LayrzApp` / `LayrzApp.router` — drop-in replacement for `MaterialApp`, built on `WidgetsApp`
- `LayrzThemeData` — immutable design tokens (colors, typography, radii, icon theme)
- `LayrzTextTheme` — full text-style scale (displayLarge → labelSmall), mirrors Material naming for easy migration
- `LayrzTheme` — `InheritedWidget` for theme propagation, accessible via `context.theme`
- `LayrzThemeMode` — light / dark / system brightness selector (no Material dependency)
- `LayrzPlatform` — runtime platform enum with `isWeb`, `isMobile`, `isDesktop` helpers
- `LayrzColorExtensions` — hex serialization, contrast color, ARGB int conversion
- `LayrzContextExtensions` — `context.theme`, `context.isDark`, `context.titleStyle`, etc.
- Brand constants — Layrz colors, responsive grid breakpoints, animation durations

---

## Roadmap

- **Parity with `layrz_theme`** — full widget-by-widget port of every component in the latest release
- **New layout system** — a redesigned responsive layout engine built from scratch on `widgets.dart`
- **go_router only** — Navigator 1.0 support will be dropped; `go_router` will be the sole routing solution

---

## Installation

```yaml
dependencies:
  layrz_ui:
    git:
      url: https://github.com/goldenm-software/layrz_ui.git
      ref: main
```

> `layrz_ui` will be published to pub.dev once it reaches a stable release.

---

## Getting started

Replace `MaterialApp` with `LayrzApp` in your entry point:

```dart
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: 'My App',
      theme: LayrzThemeData.light(primaryColor: Color(0xFF001E60)),
      darkTheme: LayrzThemeData.dark(primaryColor: Color(0xFF001E60)),
      themeMode: LayrzThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

---

## Usage

### Accessing the theme

```dart
// via extension
final theme = context.theme;

// or directly
final theme = LayrzTheme.of(context);
```

### Reading design tokens

```dart
ColoredBox(
  color: theme.backgroundColor,
  child: Text(
    'Hello',
    style: theme.textTheme.titleLarge.copyWith(color: theme.primaryColor),
  ),
);
```

### Dark / light mode

```dart
if (context.isDark) {
  // dark branch
}
```

### Color utilities

```dart
final hex = const Color(0xFF001E60).toHex();        // '#001E60'
final color = LayrzColorExtensions.fromHex('#001E60');
final readable = brandColor.contrastColor;          // black or white
```

### Platform detection

```dart
if (LayrzPlatform.isDesktop) {
  // show sidebar
}
```

### Declarative routing (go_router, auto_route, etc.)

```dart
LayrzApp.router(
  routerConfig: myRouter,
  theme: LayrzThemeData.light(),
  darkTheme: LayrzThemeData.dark(),
  themeMode: LayrzThemeMode.system,
  title: 'My App',
)
```

---

## Constants

| Constant | Value | Description |
|---|---|---|
| `kPrimaryColor` | `#001E60` | Layrz primary brand color |
| `kAccentColor` | `#FF8200` | Layrz accent brand color |
| `kLightBackgroundColor` | `#FCFCFC` | Light theme scaffold background |
| `kDarkBackgroundColor` | `#282828` | Dark theme scaffold background |
| `kExtraSmallGrid` | `600` | xs breakpoint (logical px) |
| `kSmallGrid` | `960` | sm breakpoint |
| `kMediumGrid` | `1264` | md breakpoint |
| `kLargeGrid` | `1904` | lg breakpoint |
| `kHoverDuration` | `100ms` | Micro-interaction animation duration |
| `kPageTransitionDuration` | `250ms` | Page transition animation duration |

---

## Running the example

```bash
make run-linux
make run-android
make run-ios
make run-windows
make run-macos
```

---

## FAQ

### Why is this package called `layrz_ui`?

All packages developed by [Golden M / Layrz](https://layrz.com) are prefixed with `layrz_`. Check out our other packages on [pub.dev](https://pub.dev/publishers/goldenm.com/packages).

### Why does this library exist?

`layrz_theme` was built on Material Design 3 and served us well, but coupling the design system to Material means inheriting all of its opinions, weight, and constraints. `layrz_ui` is the clean break — same Layrz design language, zero Material dependency.

### Do you have other libraries?

Yes! You can find us on [PyPi](https://pypi.org/user/goldenm/) for Python, [RubyGems](https://rubygems.org/profiles/goldenm) for Ruby, [NPM (Golden M)](https://www.npmjs.com/~goldenm) / [NPM (Layrz)](https://www.npmjs.com/~layrz-software) for Node.js, and [pub.dev](https://pub.dev/publishers/goldenm.com/packages) for Dart/Flutter.

### Is this package free?

**Yes!** `layrz_ui` is free and open source under the MIT license. If you find it useful, star the [repository](https://github.com/goldenm-software/layrz_ui) — it helps a lot!

### Can I contribute?

**Absolutely!** Open a pull request or an issue on the [repository](https://github.com/goldenm-software/layrz_ui) and we'll be happy to review it.

### I have a question — how do I reach you?

Open an issue on the [repository](https://github.com/goldenm-software/layrz_ui) and we'll get back to you as soon as possible.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Who are we?

**Golden M** is a software and hardware development company working on innovative and disruptive technologies. For more information, contact us at [sales@goldenm.com](mailto:sales@goldenm.com) or via WhatsApp at [+(507) 6979-3073](https://wa.me/50769793073?text="From%20layrz_ui%20flutter%20library.%20Hello").
