import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Taskbar namespace to the i18n engine.
mixin LayrzUiI18nTaskbarMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get taskbarAbout => i18n.t('taskbar.about');

  @override
  String get taskbarToggleTheme => i18n.t('taskbar.toggleTheme');

  @override
  String get taskbarSettings => i18n.t('taskbar.settings');

  @override
  String get taskbarProfile => i18n.t('taskbar.profile');

  @override
  String get taskbarSignOut => i18n.t('taskbar.signOut');
}
