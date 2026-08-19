import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'defaults/default_localizations.dart';

/// Delegate for loading [LayrzLocalizations] instances.
///
/// Follows the Flutter [LocalizationsDelegate] pattern. When registered in
/// `LayrzApp.localizationsDelegates`, it provides [LayrzLocalizations] to all
/// child widgets via `LayrzLocalizations.of(context)`.
///
/// The delegate always returns [LayrzDefaultLocalizations] (English). For
/// locale-specific strings, consumers can:
/// 1. Subclass [LayrzLocalizations] with locale-specific implementations.
/// 2. Create a custom delegate that returns the appropriate subclass for each locale.
/// 3. Register their custom delegate **before** this one in `localizationsDelegates`
///    so it takes precedence.
///
/// **Example: Custom locale support**
/// ```dart
/// class MyLocalizationsDelegate extends LocalizationsDelegate<LayrzLocalizations> {
///   @override
///   Future<LayrzLocalizations> load(Locale locale) async {
///     if (locale.languageCode == 'es') {
///       return MySpanishLocalizations();
///     }
///     return LayrzDefaultLocalizations();
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
class LayrzLocalizationsDelegate extends LocalizationsDelegate<LayrzLocalizations> {
  /// Creates a delegate for [LayrzLocalizations].
  const LayrzLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // The default English implementation supports any locale.
    // Custom delegates can override to narrow the range.
    return true;
  }

  @override
  Future<LayrzLocalizations> load(Locale locale) {
    // Return the default English implementation.
    // Custom delegates can override to return locale-specific instances.
    return SynchronousFuture<LayrzLocalizations>(
      LayrzDefaultLocalizations(),
    );
  }

  @override
  bool shouldReload(LayrzLocalizationsDelegate old) {
    // No reload needed; English defaults never change at runtime.
    return false;
  }
}
