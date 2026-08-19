import 'package:flutter/widgets.dart';

import 'contract/actions.dart';
import 'contract/about.dart';
import 'contract/calendar.dart';
import 'contract/date_time_pickers.dart';
import 'contract/dual_list.dart';
import 'contract/dynamic_avatar.dart';
import 'contract/editor.dart';
import 'contract/files.dart';
import 'contract/helpers.dart';
import 'contract/map.dart';
import 'contract/notifications.dart';
import 'contract/password.dart';
import 'contract/required_fields.dart';
import 'contract/select.dart';
import 'contract/table.dart';
import 'contract/taskbar.dart';
import 'contract/weekdays.dart';

/// Abstract contract for all localized strings used throughout layrz_ui.
///
/// All components read localization via [LayrzLocalizations.of] or
/// the convenience extension [BuildContext.localizations]. When the user
/// changes locale, Flutter's `Localizations` system automatically rebuilds
/// dependents with the new strings.
///
/// **Access in components**:
/// ```dart
/// final localizations = LayrzLocalizations.of(context);
/// final cancelText = localizations.actionCancel;
/// // or via extension:
/// final cancelText = context.localizations.actionCancel;
/// ```
///
/// **Implementing a custom subclass**:
/// ```dart
/// class MyLocalizations extends LayrzLocalizations {
///   @override
///   String get actionCancel => 'My Cancel Text';
///   // ... implement all other members
/// }
/// ```
///
/// **Dynamic keys**: For runtime-constructed keys (e.g., `dynamicAvatarTypes${type}`),
/// use the [t] method:
/// ```dart
/// final typeLabel = localizations.t('dynamicAvatarTypes$type');
/// ```
abstract class LayrzLocalizations
    implements
        LayrzActionsLocalizations,
        LayrzAboutLocalizations,
        LayrzCalendarLocalizations,
        LayrzDateTimePickersLocalizations,
        LayrzDualListLocalizations,
        LayrzDynamicAvatarLocalizations,
        LayrzEditorLocalizations,
        LayrzFilesLocalizations,
        LayrzHelpersLocalizations,
        LayrzMapLocalizations,
        LayrzNotificationsLocalizations,
        LayrzPasswordLocalizations,
        LayrzRequiredFieldsLocalizations,
        LayrzSelectLocalizations,
        LayrzTableLocalizations,
        LayrzTaskbarLocalizations,
        LayrzWeekdaysLocalizations {
  /// Escape hatch for dynamic/runtime-constructed localization keys.
  ///
  /// Used for keys that cannot be declared as fixed abstract members because
  /// they are constructed at runtime from data values (e.g., field types,
  /// avatar types, actions).
  ///
  /// **Pattern examples**:
  /// - `dynamicAvatarTypes${type}` — custom avatar types
  /// - `requiredFieldsTypes${field}` — field type labels
  /// - `requiredFieldsActions${action}` — action variant labels
  ///
  /// When a key is not recognized, the default implementation returns the
  /// key unchanged. Subclasses may override to provide actual translations
  /// for dynamic keys.
  String t(String key) => key;

  /// Retrieves the [LayrzLocalizations] instance from the given context.
  ///
  /// This follows the standard Flutter pattern used by [Localizations.of].
  /// If no localization is available in the context tree, throws an error.
  ///
  /// **Throws**: [FlutterError] if [LayrzLocalizations] is not available.
  static LayrzLocalizations of(BuildContext context) {
    final localizations = Localizations.of<LayrzLocalizations>(context, LayrzLocalizations);
    if (localizations == null) {
      throw FlutterError(
        'LayrzLocalizations.of() called with a context that does not contain '
        'a LayrzLocalizations. Make sure LayrzApp is wrapping your widget tree, '
        'or manually provide a LayrzLocalizationsDelegate in localizationsDelegates.',
      );
    }
    return localizations;
  }
}
