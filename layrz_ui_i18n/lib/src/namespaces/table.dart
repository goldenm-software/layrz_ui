import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Table Paginator namespace to the i18n engine.
mixin LayrzUiI18nTableMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get tableRowsPerPage => i18n.t('table.rowsPerPage');

  @override
  String get tablePaginatorStart => i18n.t('table.paginator.start');

  @override
  String get tablePaginatorPrevious => i18n.t('table.paginator.previous');

  @override
  String get tablePaginatorNext => i18n.t('table.paginator.next');

  @override
  String get tablePaginatorEnd => i18n.t('table.paginator.end');

  @override
  String tablePaginatorShowing(int start, int end, int total) {
    return i18n.t('table.paginator.showing', {
      'start': start,
      'end': end,
      'total': total,
    });
  }

  @override
  String tablePaginatorShowingVerySmall(int showing, int total) {
    return i18n.t('table.paginator.showingVerySmall', {
      'showing': showing,
      'total': total,
    });
  }

  @override
  String get tablePaginatorAuto => i18n.t('table.paginator.auto');
}
