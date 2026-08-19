import '../localizations.dart';
import 'actions.dart';
import 'about.dart';
import 'calendar.dart';
import 'date_time_pickers.dart';
import 'dual_list.dart';
import 'dynamic_avatar.dart';
import 'editor.dart';
import 'files.dart';
import 'helpers.dart';
import 'map.dart';
import 'notifications.dart';
import 'password.dart';
import 'required_fields.dart';
import 'select.dart';
import 'table.dart';
import 'taskbar.dart';
import 'weekdays.dart';

/// English default implementation of [LayrzLocalizations].
///
/// Provides all 133 localization keys in English. This is the default
/// implementation used when no custom localization is provided; it ensures
/// the design system works out-of-the-box with zero configuration.
///
/// **Usage in LayrzApp**:
/// ```dart
/// LayrzApp(
///   home: MyHome(),
///   // LayrzDefaultLocalizations is automatically used via its delegate
/// )
/// ```
///
/// **Custom implementation**:
/// ```dart
/// class MyLocalizations extends LayrzLocalizations
///     with LayrzDefaultActionsLocalizations, LayrzDefaultAboutLocalizations, /* ... */ {
///   @override
///   String get actionCancel => 'My Custom Cancel';
///   // Override only what differs; inherit English defaults for the rest
/// }
/// ```
class LayrzDefaultLocalizations extends LayrzLocalizations
    with
        LayrzDefaultActionsLocalizations,
        LayrzDefaultAboutLocalizations,
        LayrzDefaultCalendarLocalizations,
        LayrzDefaultDateTimePickersLocalizations,
        LayrzDefaultDualListLocalizations,
        LayrzDefaultDynamicAvatarLocalizations,
        LayrzDefaultEditorLocalizations,
        LayrzDefaultFilesLocalizations,
        LayrzDefaultHelpersLocalizations,
        LayrzDefaultMapLocalizations,
        LayrzDefaultNotificationsLocalizations,
        LayrzDefaultPasswordLocalizations,
        LayrzDefaultRequiredFieldsLocalizations,
        LayrzDefaultSelectLocalizations,
        LayrzDefaultTableLocalizations,
        LayrzDefaultTaskbarLocalizations,
        LayrzDefaultWeekdaysLocalizations {
  /// Creates an English default localization instance.
  LayrzDefaultLocalizations();

  /// Static instance for efficient reuse.
  static final LayrzDefaultLocalizations _instance = LayrzDefaultLocalizations._();

  /// Private constructor for singleton.
  LayrzDefaultLocalizations._();

  /// Retrieves the singleton instance.
  factory LayrzDefaultLocalizations.instance() => _instance;
}
