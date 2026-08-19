import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Dynamic Avatar Types namespace to the i18n engine.
mixin LayrzUiI18nDynamicAvatarMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get dynamicAvatarTypesBASE64 => i18n.t('dynamicAvatar.types.BASE64');

  @override
  String get dynamicAvatarTypesNONEHint =>
      i18n.t('dynamicAvatar.types.NONEHint');

  @override
  String get dynamicAvatarTypesURLUrl => i18n.t('dynamicAvatar.types.URL');
}
