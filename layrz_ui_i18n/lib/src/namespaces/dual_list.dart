import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Dual-List Input namespace to the i18n engine.
mixin LayrzUiI18nDualListMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String dualListSearch(String listName) =>
      i18n.t('dualList.search', {'name': listName});

  @override
  String get dualListToggleToSelected => i18n.t('dualList.toggleToSelected');

  @override
  String get dualListToggleToAvailable => i18n.t('dualList.toggleToAvailable');

  @override
  String get dualListAvailableListName => i18n.t('dualList.availableListName');

  @override
  String get dualListSelectedListName => i18n.t('dualList.selectedListName');
}
