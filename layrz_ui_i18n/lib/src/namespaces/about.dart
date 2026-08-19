import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the About & Copyright namespace to the i18n engine.
mixin LayrzUiI18nAboutMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get aboutSearch => i18n.t('about.search');

  @override
  String get copyrightPoweredBy => i18n.t('about.poweredBy');

  @override
  String get copyrightPlatformOS => i18n.t('about.platformOS');
}
