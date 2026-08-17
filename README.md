# layrz_ui

A Material-free, Cupertino-free Flutter design system — the next generation of [layrz_theme](https://github.com/goldenm-software/layrz_theme).

Built exclusively on `package:flutter/widgets.dart`. No Material. No Cupertino.

> **AI-assisted code notice**
> This package was developed with AI assistance. If you run into any issue or unexpected behavior, feel free to open a Pull Request — contributions are always welcome!

---

## Installation

Add layrz_ui to your `pubspec.yaml`:

```yaml
dependencies:
  layrz_ui:
    git:
      url: https://github.com/goldenm-software/layrz_ui.git
      ref: main
```

Then create your first app:

```dart
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/app.dart';
import 'package:layrz_ui/theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: 'My App',
      theme: LayrzThemeData.light(),
      home: const HomePage(),
    );
  }
}
```

For detailed setup, fonts, and routing, see [**Getting Started**](https://github.com/goldenm-software/layrz_ui/wiki/Getting-Started) in the wiki.

---

## Why layrz_ui?

Flutter's Material and Cupertino layers are opinionated and heavyweight. `layrz_ui` decouples the Layrz design system from both, the same way Flutter itself separates `widgets` from `material` and `cupertino`. The result is a leaner dependency graph, full control over every pixel, and no unwanted platform chrome.

---

## Features

- `LayrzApp` / `LayrzApp.router` — drop-in replacement for `MaterialApp`, built on `WidgetsApp`
- `LayrzThemeData` — immutable design tokens (colors, typography, radii, icon theme)
- `LayrzTextTheme` — five core text styles: `display`, `headline`, `title`, `body`, `label`
- `LayrzTheme` — `InheritedWidget` for theme propagation, accessible via `context.theme`
- `LayrzPlatform` — runtime platform enum with `isWeb`, `isMobile`, `isDesktop` helpers
- `LayrzColorExtensions` — hex serialization, contrast color, ARGB int conversion, opacity helpers
- `LayrzContextExtensions` — `context.theme`, `context.tokens`, `context.breakpoint`, `context.titleStyle`, etc.
- Brand constants — Layrz colors, animation durations

---

## Documentation

Complete guides, API references, and component documentation live in the [**GitHub Wiki**](https://github.com/goldenm-software/layrz_ui/wiki):

- **[Getting Started](https://github.com/goldenm-software/layrz_ui/wiki/Getting-Started)** — Add the dependency, set up `LayrzApp`, preload fonts, and build your first screen
- **[Theming](https://github.com/goldenm-software/layrz_ui/wiki/Theming)** — How the theme system works and how to access design values in widgets
- **[Design Tokens](https://github.com/goldenm-software/layrz_ui/wiki/Design-Tokens)** — Complete reference of all colors, typography, spacing, radius, shadows, borders, and motion tokens
- **[Platform and Extensions](https://github.com/goldenm-software/layrz_ui/wiki/Platform-And-Extensions)** — Platform detection and convenience utilities for colors and BuildContext
- **[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)** — Mapping of layrz_theme to layrz_ui components

---

## Roadmap

Live progress across milestones M1–M8 is tracked on the [Notion board](https://layrz.notion.site/3bf1a14cf90480c996cad105cdc60d80?v=3bf1a14cf90480118d09000c19185bd6).

- **Parity with `layrz_theme`** — full widget-by-widget port of every component in the latest release
- **New layout system** — a redesigned responsive layout engine built from scratch on `widgets.dart`
- **go_router only** — Navigator 1.0 support will be dropped; `go_router` will be the sole routing solution

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

All packages developed by [Layrz](https://layrz.com) are prefixed with `layrz_`. Check out our other packages on [pub.dev](https://pub.dev/publishers/layrz.com/packages).

### Why does this library exist?

`layrz_theme` was built on Material Design 3 and served us well, but coupling the design system to Material means inheriting all of its opinions, weight, and constraints. `layrz_ui` is the clean break — same Layrz design language, zero Material dependency.

### Do you have other libraries?

Yes! You can find us on [PyPi](https://pypi.org/user/goldenm/) for Python, [RubyGems](https://rubygems.org/profiles/goldenm) for Ruby, [NPM (Golden M)](https://www.npmjs.com/~goldenm) / [NPM (Layrz)](https://www.npmjs.com/~layrz-software) for Node.js, and [pub.dev (Golden M)](https://pub.dev/publishers/goldenm.com/packages) / [pub.dev (Layrz)](https://pub.dev/publishers/layrz.com/packages) for Dart/Flutter.

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
