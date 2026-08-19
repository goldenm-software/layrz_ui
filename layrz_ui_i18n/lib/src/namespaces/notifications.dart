import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Notifications namespace to the i18n engine.
mixin LayrzUiI18nNotificationsMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get notificationsEmpty => i18n.t('notifications.empty');
}
