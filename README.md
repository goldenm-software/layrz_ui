<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/goldenm-software/layrz_ui/main/layrz-ui-logo-white.png">
    <img alt="Layrz" src="https://raw.githubusercontent.com/goldenm-software/layrz_ui/main/layrz-ui-logo.png" width="360">
  </picture>
</p>

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
  layrz_ui: ^1.0.0
```

Then create your first app:

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

## Kotlin Gradle Plugin warning

`layrz_ui` depends on `desktop_drop` and `file_picker`, whose Android plugin modules apply the
Kotlin Gradle Plugin (KGP) themselves. On AGP 9+, this triggers Flutter's KGP deprecation warning
in your app's build output — something like *"plugins that apply Kotlin Gradle Plugin (KGP):
desktop_drop, file_picker"*.

Set `android.builtInKotlin=true` (alongside `android.newDsl=false`) in your app's
`android/gradle.properties` regardless — it's still the correct fix for `file_picker`, and it makes
`desktop_drop`'s own Kotlin setup defer to AGP's built-in Kotlin at build time instead of applying
KGP itself.

```properties
android.builtInKotlin=true
android.newDsl=false
```

**This silences the warning for `file_picker`, but not for `desktop_drop`.** Flutter detects KGP
usage with a static text scan of each plugin's `build.gradle` — it greps the raw file for
`apply plugin: 'kotlin-android'` rather than checking whether that line actually runs. `desktop_drop`
0.8.4's `build.gradle` still contains that line, guarded behind a condition that `builtInKotlin=true`
makes false — so the plugin is *never applied* at build time, but the text is still there for the
scan to match. The warning is cosmetic on the current toolchain: the build succeeds either way, and
nothing you set in `gradle.properties` or clear from the Gradle cache can remove a string that lives
in `desktop_drop`'s own file. It will stop appearing once `desktop_drop` upstream ships a version
whose `build.gradle` no longer contains that legacy line.

---

## Running the example

```bash
make run-linux
make run-android
make run-ios
make run-windows
make run-macos
```

> **Note — Linux desktop renderer:** Flutter 3.47 defaults to the Impeller renderer on Linux
> desktop, whose general path antialiasing is unfinished ([flutter/flutter#183959](https://github.com/flutter/flutter/issues/183959)).
> Curve-heavy `CustomPainter` output — the `Layo` mascot, the progress bar — renders with aliased /
> stair-stepped edges as a result. The example app already forces the Skia renderer on Linux to
> avoid this. If you run into aliased curves in your own Linux desktop app, force Skia too:
> `flutter run --no-enable-impeller` in dev, or `fl_dart_project_set_enable_impeller(project, FALSE);`
> in `linux/runner/my_application.cc` for release builds. Web (CanvasKit) and mobile are
> unaffected; whether other Impeller desktop targets (macOS, Windows) show the same aliasing is not
> yet verified. The shapes themselves are correct — this is an engine-level rendering limitation,
> not a geometry bug. See `engineering/decisions.md` (D77) for details.

---

## FAQ

### Is `layrz_ui` the same as `layrz_theme`? Should I use one or the other?

They are **two different packages** solving the same job in two different ways — `layrz_ui` is the successor, and new projects should use it.

`layrz_theme` is built **on top of Material Design 3**. Every widget it ships wraps a Material widget, and every app that uses it pulls in `package:flutter/material.dart`. That was a reasonable foundation, but it means inheriting all of Material's opinions, weight, and behavior — theme resolution, ink ripples, implicit `MaterialApp`/`Scaffold` scaffolding, and a large transitive dependency surface — even for parts of your UI that never wanted to look or behave like Material.

`layrz_ui` is a **clean break**. It is built exclusively on `package:flutter/widgets.dart` and `dart:ui` — **no Material, no Cupertino, anywhere.** It re-implements the entire Layrz design language from primitives (`DecoratedBox`, `CustomPaint`, `GestureDetector`, `RichText`), the same way Flutter itself keeps `widgets` separate from `material` and `cupertino`. The design token system (`LayrzTokens` — colors, typography, spacing, radius, shadow, border, motion) drives every component, so you change one token and the whole system follows.

**Why choose `layrz_ui` over `layrz_theme`:**

- **No platform framework coupling** — your widget tree contains only what you put in it. No Material or Cupertino chrome leaks in, and the dependency graph is leaner.
- **Full visual control** — every pixel is yours. Components read their look from `LayrzTokens`, not from an opaque Material `ThemeData`.
- **Consistent, semantic theming** — one primary, plus semantic `danger`/`success`/`warning`/`info` colors used the same way everywhere.
- **Responsive by design** — breakpoint tokens and `context.isCompact` give every component the same compact/wide decision, so layouts adapt consistently.
- **Accessible by default** — every visual component ships with semantics, so assistive technology is a first-class concern, not an afterthought.
- **Same design language, cleaner foundation** — `layrz_ui` does the same jobs as `layrz_theme` with none of the Material baggage. It is the drop-in replacement Layrz projects should migrate to.

`layrz_theme` remains available for existing apps, but it is no longer where new design-system work happens. **New projects should start on `layrz_ui`; existing `layrz_theme` apps should plan to migrate.**

### Why create a new library instead of updating `layrz_theme`?

Pretty simple: `layrz_theme` is built around Material 3, so changing the design means fighting the design system underneath it. Every adjustment has to work *with* Material's assumptions rather than around them, which makes even small changes complex and awkward, and often produces results that don't look quite the way we wanted. Building a design system from scratch — as `layrz_ui` does, straight on `package:flutter/widgets.dart` — meant we owned every decision. The result is cleaner, more efficient, and exactly what we set out to build.

### Why is this package called `layrz_ui`?

All packages developed by [Layrz](https://layrz.com) are prefixed with `layrz_`. Check out our other packages on [pub.dev](https://pub.dev/publishers/layrz.com/packages).

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
