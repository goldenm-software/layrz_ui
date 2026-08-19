/// Localization module — user-visible strings throughout layrz_ui.
///
/// The [LayrzLocalizations] abstract contract declares all 133 strings needed
/// by design system components, organized by namespace. [LayrzDefaultLocalizations]
/// provides English text; consumers can subclass to provide locale-specific
/// implementations or adapt from layrz_models if present.
///
/// Components read localization via [LayrzLocalizations.of], which follows
/// Flutter's standard pattern. Automatic locale rebuilds via [Localizations].
///
/// **Quick start**:
/// ```dart
/// // In a widget
/// final cancelText = LayrzLocalizations.of(context).actionCancel;
/// // or via extension:
/// final cancelText = context.localizations.actionCancel;
/// ```
library;

export 'src/delegate.dart';
export 'src/localizations.dart';
export 'src/defaults/default_localizations.dart';
