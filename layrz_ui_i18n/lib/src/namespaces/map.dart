import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Map Layer & Zoom namespace to the i18n engine.
mixin LayrzUiI18nMapMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get mapChangeLayer => i18n.t('map.changeLayer');

  @override
  String get mapZoomIn => i18n.t('map.zoomIn');

  @override
  String get mapZoomOut => i18n.t('map.zoomOut');
}
