import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Select Input namespace to the i18n engine.
mixin LayrzUiI18nSelectMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get selectSearch => i18n.t('select.search');

  @override
  String get selectEmpty => i18n.t('select.empty');

  @override
  String get selectSelectAll => i18n.t('select.selectAll');

  @override
  String get selectUnselectAll => i18n.t('select.unselectAll');

  @override
  String get selectUnselect => i18n.t('select.unselect');
}
