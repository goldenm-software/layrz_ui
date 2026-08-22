import 'package:flutter/widgets.dart';

import 'namespaces/actions.dart';
import 'namespaces/about.dart';
import 'namespaces/calendar.dart';
import 'namespaces/combobox.dart';
import 'namespaces/date_time_pickers.dart';
import 'namespaces/dual_list.dart';
import 'namespaces/dynamic_avatar.dart';
import 'namespaces/editor.dart';
import 'namespaces/files.dart';
import 'namespaces/helpers.dart';
import 'namespaces/inputs.dart';
import 'namespaces/map.dart';
import 'namespaces/notifications.dart';
import 'namespaces/password.dart';
import 'namespaces/required_fields.dart';
import 'namespaces/scaffold.dart';
import 'namespaces/select.dart';
import 'namespaces/selection.dart';
import 'namespaces/sheets.dart';
import 'namespaces/steppers.dart';
import 'namespaces/table.dart';
import 'namespaces/taskbar.dart';
import 'namespaces/weekdays.dart';

/// Abstract contract for all localized strings used throughout layrz_ui.
///
/// All 133 localization keys are declared as getters across 17 namespace mixins,
/// each providing an English default value. Components read localization via
/// [LayrzUiL10n.of] or the convenience extension [BuildContext.l10n]. When the
/// user changes locale, Flutter's `Localizations` system automatically rebuilds
/// dependents with the new strings.
///
/// **Why this shape**: Mixins carry implementations directly, so [LayrzUiL10n]
/// has no abstract members. This enables adapters (like `LayrzUiI18n` in
/// `layrz_i18n`) to extend [LayrzUiL10n] and override only the keys they need —
/// new keys added to layrz_ui inherit their English default instead of breaking
/// the adapter's build. Custom consumers can also extend and override individual
/// keys for locale-specific implementations.
///
/// **Access in components**:
/// ```dart
/// final l10n = LayrzUiL10n.of(context);
/// final cancelText = l10n.actionCancel;
/// // or via extension:
/// final cancelText = context.l10n.actionCancel;
/// ```
///
/// **Providing your own translations**:
///
/// Extend [LayrzUiL10n] and override only the members you need; anything not
/// overridden keeps its English default, so new keys added to layrz_ui never
/// break your subclass.
///
/// ```dart
/// class MyL10n extends LayrzUiL10n {
///   const MyL10n(this.engine);
///   final MyEngine engine;
///
///   @override
///   String get actionCancel => engine.translate('actions.cancel');
/// }
/// ```
///
/// Then register it with a delegate declared over [LayrzUiL10n] — **not** over
/// your subclass. [LocalizationsDelegate.type] is the key [Localizations] looks
/// up, so a delegate typed on the subclass is never found and every string
/// silently falls back to English.
///
/// ```dart
/// class MyL10nDelegate extends LocalizationsDelegate<LayrzUiL10n> {
///   const MyL10nDelegate(this.engine);
///   final MyEngine engine;
///
///   @override
///   bool isSupported(Locale locale) => true;
///
///   @override
///   Future<LayrzUiL10n> load(Locale locale) async => MyL10n(engine);
///
///   @override
///   bool shouldReload(MyL10nDelegate old) => false;
/// }
///
/// LayrzApp(localizationsDelegates: const [MyL10nDelegate(engine)], ...)
/// ```
///
/// Caller-supplied delegates take precedence: [LayrzApp] appends the default
/// last, and [Localizations] keeps the first delegate registered for a type.
/// The default remaining in the list is a deliberate fallback — if your
/// delegate's [LocalizationsDelegate.isSupported] returns false for a locale,
/// that locale degrades to English rather than throwing.
abstract class LayrzUiL10n
    with
        LayrzUiL10nActionsMixin,
        LayrzUiL10nAboutMixin,
        LayrzUiL10nCalendarMixin,
        LayrzUiL10nComboboxMixin,
        LayrzUiL10nDateTimePickersMixin,
        LayrzUiL10nDualListMixin,
        LayrzUiL10nDynamicAvatarMixin,
        LayrzUiL10nEditorMixin,
        LayrzUiL10nFilesMixin,
        LayrzUiL10nHelpersMixin,
        LayrzUiL10nInputsMixin,
        LayrzUiL10nMapMixin,
        LayrzUiL10nNotificationsMixin,
        LayrzUiL10nPasswordMixin,
        LayrzUiL10nRequiredFieldsMixin,
        LayrzUiL10nScaffoldMixin,
        LayrzUiL10nSelectMixin,
        LayrzUiL10nSelectionMixin,
        LayrzUiL10nSheetsMixin,
        LayrzUiL10nSteppersMixin,
        LayrzUiL10nTableMixin,
        LayrzUiL10nTaskbarMixin,
        LayrzUiL10nWeekdaysMixin {
  /// Creates an instance of [LayrzUiL10n].
  const LayrzUiL10n();

  /// Retrieves the [LayrzUiL10n] instance from the given context.
  ///
  /// This follows the standard Flutter pattern used by [Localizations.of].
  /// If no localization is available in the context tree, throws an error.
  ///
  /// **Throws**: [FlutterError] if [LayrzUiL10n] is not available.
  static LayrzUiL10n of(BuildContext context) {
    final l10n = Localizations.of<LayrzUiL10n>(context, LayrzUiL10n);
    if (l10n == null) {
      throw FlutterError(
        'LayrzUiL10n.of() called with a context that does not contain '
        'a LayrzUiL10n. Make sure LayrzApp is wrapping your widget tree, '
        'or manually provide a LayrzUiL10nDelegate in localizationsDelegates.',
      );
    }
    return l10n;
  }
}
