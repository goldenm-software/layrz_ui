/// Localization module — user-visible strings throughout layrz_ui.
///
/// The [LayrzUiL10n] abstract contract declares all 133 strings needed
/// by design system components, organized by namespace. [LayrzUiL10nDefault]
/// provides English text; consumers can subclass to provide locale-specific
/// implementations or adapt from layrz_models if present.
///
/// Components read localization via [LayrzUiL10n.of], which follows
/// Flutter's standard pattern. Automatic locale rebuilds via [Localizations].
///
/// **Quick start**:
/// ```dart
/// // In a widget
/// final cancelText = LayrzUiL10n.of(context).actionCancel;
/// // or via extension:
/// final cancelText = context.l10n.actionCancel;
/// ```
library;

export 'src/l10n_delegate.dart';
export 'src/l10n.dart';
export 'src/defaults/default_l10n.dart';
