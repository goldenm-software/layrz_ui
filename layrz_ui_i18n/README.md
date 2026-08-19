# layrz_ui_i18n

An i18n adapter binding `layrz_ui`'s localization contract to the `layrz_i18n` translation engine.

> **AI-assisted code notice**
> This package was developed with AI assistance. If you run into any issue or unexpected behavior, feel free to open a Pull Request — contributions are always welcome!

---

## What is layrz_ui_i18n?

`layrz_ui` declares a complete localization contract (`LayrzUiL10n`) with 133 English strings covering all user-facing text in the design system. However, **`layrz_ui` itself has no dependency on any i18n package** — that decoupling is intentional. It allows the design system to remain lightweight and lets apps choose their own localization strategy.

`layrz_ui_i18n` bridges this gap by providing an adapter that routes `LayrzUiL10n` lookups through the `layrz_i18n` translation engine. Once registered, every `layrz_ui` component automatically picks up your translations.

---

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  layrz_ui: ^0.0.1 # Both needs to have the same version
  layrz_ui_i18n: ^0.0.1 # Both needs to have the same version
```

---

## Usage

1. Initialize the `layrz_i18n` engine with your translation data:

```dart
import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui_i18n/layrz_ui_i18n.dart';

void main() async {
  final i18n = LayrzI18n(languages: [
    'en', 'es', 'pt',  // or your supported locales
  ]);
  await i18n.load();
  
  runApp(MyApp(i18n: i18n));
}
```

2. Register `LayrzUiI18nDelegate` in your app before the default English fallback:

```dart
class MyApp extends StatelessWidget {
  final LayrzI18n i18n;
  const MyApp({required this.i18n});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: 'My App',
      theme: LayrzThemeData.light(),
      localizationsDelegates: [
        LayrzUiI18nDelegate(i18n),      // Your custom translations
        const LayrzUiL10nDelegate(),    // English fallback
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('es'),
        const Locale('pt'),
      ],
      home: const HomePage(),
    );
  }
}
```

3. That's it. Every `layrz_ui` component reading `context.l10n` now automatically uses your translations.

---

## Important: The Delegate Type Requirement

When implementing a custom localization delegate, **you must type it over `LayrzUiL10n`, not a subclass**.

```dart
// ✅ CORRECT
class MyDelegate extends LocalizationsDelegate<LayrzUiL10n> { ... }

// ❌ WRONG
class MyDelegate extends LocalizationsDelegate<LayrzUiI18n> { ... }
```

Why? Flutter's `Localizations.of<T>()` looks up delegates by their `type` parameter. If you type a delegate over a subclass, the resolver never finds it — it only looks for `LocalizationsDelegate<LayrzUiL10n>`. The result is silent fallback to English with no error message.

`LayrzUiI18nDelegate` follows this rule: it extends `LayrzUiL10nDelegate` and is typed over the base `LayrzUiL10n`, not `LayrzUiI18n`.

---

## Translation Keys

All 133 keys follow a dotted namespace pattern derived from the contract member names:

- Actions: `'actions.cancel'`, `'actions.save'`, `'actions.reset'`, `'actions.search'`, `'actions.lint'`, `'actions.run'`
- Confirmations: `'confirmations.title'`, `'confirmations.content'`, `'confirmations.confirm'`, `'confirmations.dismiss'`, `'confirmations.multipleTitle'`, `'confirmations.multipleContent'`
- About: `'about.search'`, `'about.poweredBy'`, `'about.platformOS'`
- Calendar: `'calendar.yearBack'`, `'calendar.yearNext'`, `'calendar.monthBack'`, `'calendar.monthNext'`, `'calendar.today'`, `'calendar.monthShort'`, and eleven month names
- Date-time pickers: `'dateTimePickers.from'`, `'dateTimePickers.to'`, `'dateTimePickers.selectDate'`, etc.
- And 13 more namespaces covering dual lists, dynamic avatars, editors, files, helpers, maps, notifications, passwords, required fields, select inputs, tables, taskbars, and weekdays

**Important**: These keys are **derived from member names and have not been verified against live translation data**. The implementation is correct; the key names follow a consistent pattern. You must validate that your `layrz_i18n` engine has entries for all 133 keys before deployment.

**Pluralization**: Eight duration-related keys use the `tc()` method for singular/plural selection. The translation engine must provide these in `' | '`-separated format:

```
'helpers.duration.days': '1 day | %count% days'
'helpers.duration.hours': '1 hour | %count% hours'
// ... and six more duration keys
```

---

## Partial Translation

You don't need to translate all 133 keys. Any key not present in the translation engine falls back to whatever `layrz_i18n`'s default behavior is (typically the key name or English). Moreover, any key not overridden in `LayrzUiI18n` inherits its English default from `LayrzUiL10n`, so new keys added to `layrz_ui` in future releases will continue to work without requiring your adapter to be updated.

---

## No Dependency Between layrz_ui and layrz_i18n

This architecture keeps the two packages independent:

- `layrz_ui` is purely a design system with no translation engine dependency
- `layrz_i18n` is a general-purpose translation tool with no UI dependency
- `layrz_ui_i18n` is a thin adapter that bridges them

This means:
- Apps using `layrz_ui` without i18n requirements have zero overhead
- Apps using different translation engines can build their own adapters
- Both packages can evolve and release independently

---

## Documentation

For complete guides on `layrz_ui`, see the [GitHub Wiki](https://github.com/goldenm-software/layrz_ui/wiki):

- **[Getting Started](https://github.com/goldenm-software/layrz_ui/wiki/Getting-Started)** — Set up `LayrzApp` and preload fonts
- **[Theming](https://github.com/goldenm-software/layrz_ui/wiki/Theming)** — Access design tokens in your widgets
- **[Design Tokens](https://github.com/goldenm-software/layrz_ui/wiki/Design-Tokens)** — Complete reference of colors, typography, spacing, and more
- **[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)** — Browse all available components

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Who are we?

**Golden M** is a software and hardware development company working on innovative and disruptive technologies. For more information, contact us at [sales@goldenm.com](mailto:sales@goldenm.com) or via WhatsApp at [+(507) 6979-3073](https://wa.me/50769793073?text="From%20layrz_ui_i18n%20flutter%20library.%20Hello").
