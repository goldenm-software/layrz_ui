import 'package:layrz_i18n/layrz_i18n.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Routes the Code Editor namespace to the i18n engine.
mixin LayrzUiI18nEditorMixin on LayrzUiL10n {
  /// The translation engine. Abstract here; supplied by [LayrzUiI18n].
  LayrzI18n get i18n;

  @override
  String get editorDocumentation => i18n.t('editor.documentation');

  @override
  String get editorLintError => i18n.t('editor.lintError');
}
