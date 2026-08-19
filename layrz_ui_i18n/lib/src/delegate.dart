import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'layrz_ui_i18n.dart';

/// Delegate for loading [LayrzUiI18n] instances.
///
/// Extends [LayrzUiL10nDelegate] to leverage its structure while providing
/// custom localization via [LayrzI18n]. The delegate is typed over [LayrzUiL10n]
/// (not [LayrzUiI18n]) so that `Localizations.of<LayrzUiL10n>()` correctly
/// resolves this delegate — if typed on the subclass, it would never be found
/// and all strings would fall back to English.
///
/// Register this delegate **before** the default [LayrzUiL10nDelegate] in
/// `LayrzApp.localizationsDelegates` so it takes precedence:
///
/// ```dart
/// final engine = LayrzI18n(languages: [...]);
/// await engine.load();
/// LayrzApp(
///   localizationsDelegates: [
///     LayrzUiI18nDelegate(engine),  // Your custom translations
///     const LayrzUiL10nDelegate(),  // English fallback
///   ],
///   // ...
/// )
/// ```
class LayrzUiI18nDelegate extends LayrzUiL10nDelegate {
  /// Creates a delegate that loads [LayrzUiI18n] for the given engine.
  ///
  /// Arguments:
  /// [i18n] is the [LayrzI18n] instance to delegate to.
  const LayrzUiI18nDelegate(this.i18n);

  /// The localization engine this delegate uses.
  ///
  /// Must have been initialized (via `load()`) before use, and provides
  /// `t()` and `tc()` methods for string lookup and pluralization.
  final LayrzI18n i18n;

  @override
  bool isSupported(Locale locale) {
    // Support all locales; the engine decides which ones it has translations for.
    // Unsupported locales will fall back to English via the default delegate.
    return true;
  }

  @override
  Future<LayrzUiL10n> load(Locale locale) {
    // Return LayrzUiI18n wrapping the pre-loaded engine.
    // Use SynchronousFuture so the first frame has strings without an async gap.
    return SynchronousFuture<LayrzUiL10n>(LayrzUiI18n(i18n: i18n));
  }

  @override
  bool shouldReload(LayrzUiL10nDelegate old) {
    // Reload only if the delegate instance changes.
    // In typical use, a single engine instance persists across locales,
    // so this returns false. If the engine instance changes, a new delegate
    // should be registered.
    return old is! LayrzUiI18nDelegate || i18n != old.i18n;
  }
}
