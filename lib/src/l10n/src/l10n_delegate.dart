import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'l10n.dart';
import 'defaults/default_l10n.dart';

/// Delegate for loading [LayrzUiL10n] instances.
///
/// Follows the Flutter [LocalizationsDelegate] pattern. When registered in
/// `LayrzApp.localizationsDelegates`, it provides [LayrzUiL10n] to all
/// child widgets via `LayrzUiL10n.of(context)`.
///
/// The delegate always returns [LayrzUiL10nDefault] (English). For
/// locale-specific strings, consumers can:
/// 1. Subclass [LayrzUiL10n] with locale-specific implementations.
/// 2. Create a custom delegate that returns the appropriate subclass for each locale.
/// 3. Register their custom delegate **before** this one in `localizationsDelegates`
///    so it takes precedence.
///
/// **Example: Custom locale support**
/// ```dart
/// class MyLocalizationsDelegate extends LocalizationsDelegate<LayrzUiL10n> {
///   @override
///   Future<LayrzUiL10n> load(Locale locale) async {
///     if (locale.languageCode == 'es') {
///       return MySpanishLocalizations();
///     }
///     return LayrzUiL10nDefault();
///   }
///
///   @override
///   bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);
///
///   @override
///   bool shouldReload(MyLocalizationsDelegate old) => false;
/// }
///
/// // Register it:
/// LayrzApp(
///   localizationsDelegates: [MyLocalizationsDelegate()],
///   // ...
/// )
/// ```
class LayrzUiL10nDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  /// Creates a delegate for [LayrzUiL10n].
  const LayrzUiL10nDelegate();

  @override
  bool isSupported(Locale locale) {
    // The default English implementation supports any locale.
    // Custom delegates can override to narrow the range.
    return true;
  }

  @override
  Future<LayrzUiL10n> load(Locale locale) {
    // Return the default English implementation.
    // Custom delegates can override to return locale-specific instances.
    return SynchronousFuture<LayrzUiL10n>(
      LayrzUiL10nDefault(),
    );
  }

  @override
  bool shouldReload(LayrzUiL10nDelegate old) {
    // No reload needed; English defaults never change at runtime.
    return false;
  }
}
