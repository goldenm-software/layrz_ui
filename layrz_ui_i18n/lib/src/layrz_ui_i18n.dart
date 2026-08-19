import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'namespaces/about.dart';
import 'namespaces/actions.dart';
import 'namespaces/calendar.dart';
import 'namespaces/date_time_pickers.dart';
import 'namespaces/dual_list.dart';
import 'namespaces/dynamic_avatar.dart';
import 'namespaces/editor.dart';
import 'namespaces/files.dart';
import 'namespaces/helpers.dart';
import 'namespaces/map.dart';
import 'namespaces/notifications.dart';
import 'namespaces/password.dart';
import 'namespaces/required_fields.dart';
import 'namespaces/select.dart';
import 'namespaces/table.dart';
import 'namespaces/taskbar.dart';
import 'namespaces/weekdays.dart';

/// Adapter that implements [LayrzUiL10n] by delegating to a [LayrzI18n] engine.
///
/// Overrides all 133 members across 17 namespace mixins, mapping each to the
/// corresponding dotted-key lookup in the i18n engine. Organized by namespace
/// to match the order in [LayrzUiL10n] for navigability.
///
/// **Key naming**: All keys below are derived from member names following the
/// pattern: namespace from mixin name (lowercase, `-` stripped) + member name
/// with prefix removed and converted to camelCase nested structure.
/// For example: `actionCancel` → `'actions.cancel'`.
///
/// **CRITICAL**: The derived keys must be verified against the actual engine's
/// translation map before deployment. The engine uses `t()` for simple lookups,
/// `tc(String key, int? val)` for pluralization, and `t(key, args)` for
/// parameterized interpolation where `args` is `Map<String, dynamic>`.
class LayrzUiI18n extends LayrzUiL10n
    with
        LayrzUiI18nActionsMixin,
        LayrzUiI18nAboutMixin,
        LayrzUiI18nCalendarMixin,
        LayrzUiI18nDateTimePickersMixin,
        LayrzUiI18nDualListMixin,
        LayrzUiI18nDynamicAvatarMixin,
        LayrzUiI18nEditorMixin,
        LayrzUiI18nFilesMixin,
        LayrzUiI18nHelpersMixin,
        LayrzUiI18nMapMixin,
        LayrzUiI18nNotificationsMixin,
        LayrzUiI18nPasswordMixin,
        LayrzUiI18nRequiredFieldsMixin,
        LayrzUiI18nSelectMixin,
        LayrzUiI18nTableMixin,
        LayrzUiI18nTaskbarMixin,
        LayrzUiI18nWeekdaysMixin {
  /// Creates an adapter over the given i18n engine.
  ///
  /// Arguments:
  /// - [i18n] is the [LayrzI18n] instance to delegate to.
  const LayrzUiI18n({required this.i18n});

  /// The localization engine this adapter delegates to.
  ///
  /// Must provide `t()` for string lookups, `tc()` for plural lookups, and
  /// support `Map<String, dynamic>` arguments for interpolation.
  @override
  final LayrzI18n i18n;
}
