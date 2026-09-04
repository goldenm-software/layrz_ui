import '../l10n.dart';

/// Concrete, English-only implementation of [LayrzUiL10n].
///
/// Installed automatically by [LayrzApp] when no localizations delegate is
/// provided, so the package works with zero configuration. All 151 keys use
/// their English defaults from the namespace mixins.
///
/// **Usage in LayrzApp** (implicit):
/// ```dart
/// LayrzApp(
///   home: MyHome(),
///   // LayrzUiL10nDefault is automatically used via LayrzUiL10nDelegate
/// )
/// ```
///
/// **Extending for locale-specific strings**:
/// ```dart
/// class MyLocalizations extends LayrzUiL10n {
///   @override
///   String get actionCancel => 'Mi Cancelar';  // Spanish
///   // All other keys inherit their English defaults
/// }
/// ```
class LayrzUiL10nDefault extends LayrzUiL10n {
  /// Creates the default English localizations.
  const LayrzUiL10nDefault();
}
