import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import 'dialog.dart';

/// A ready-made yes/no confirmation built on [LayrzDialog].
///
/// Every entry point resolves to a plain `Future<bool>`: `true` only when the
/// confirm button is tapped, `false` for the dismiss button, a barrier tap,
/// Escape, the close ("X") icon or the back gesture. Callers never handle
/// `null`.
///
/// - [show] is the generic base: any title, description, body, labels and a
///   semantic [LayrzButtonType] for the confirm button.
/// - [delete] is the destructive preset every delete action should use. Its
///   texts default to the `confirmation*` strings of [LayrzUiL10n], switching
///   to the plural variants when more than one item is listed.
///
/// A two-step confirmation (asking twice before a sensitive change) is two
/// chained calls:
///
/// ```dart
/// final ok = await LayrzConfirmationDialog.show(context, title: first) &&
///     context.mounted &&
///     await LayrzConfirmationDialog.show(context, title: second);
/// ```
///
/// **Example usage**:
/// ```dart
/// if (!await LayrzConfirmationDialog.delete(context, items: [user.name])) return;
/// ```
class LayrzConfirmationDialog {
  LayrzConfirmationDialog._();

  /// Shows a confirmation dialog and resolves to whether the user confirmed.
  ///
  /// - [context]: the [BuildContext] used to find the root navigator and the
  ///   theme and localizations.
  /// - [title]: the question asked, rendered in the dialog's title row and used
  ///   as the dialog's route semantics label.
  /// - [description]: optional supporting text rendered first in the body.
  /// - [content]: optional extra body widget rendered below [description].
  /// - [confirmLabel]: the confirm button label. Defaults to
  ///   [LayrzUiL10n.confirmationConfirm].
  /// - [dismissLabel]: the dismiss button label. Defaults to
  ///   [LayrzUiL10n.confirmationDismiss].
  /// - [type]: the semantic color of the confirm button. Defaults to
  ///   [LayrzButtonType.success]. The dismiss button takes the opposite color:
  ///   [LayrzButtonType.success] when [type] is [LayrzButtonType.danger] or
  ///   [LayrzButtonType.warning], [LayrzButtonType.danger] otherwise.
  /// - [icon]: optional leading icon of the confirm button.
  /// - [canDismiss]: whether the barrier, Escape, the close icon and the back
  ///   gesture may close the dialog (resolving `false`). Defaults to `true`,
  ///   since escaping a confirmation is the safe answer. Pass `false` to force
  ///   an explicit choice.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? description,
    Widget? content,
    String? confirmLabel,
    String? dismissLabel,
    LayrzButtonType type = LayrzButtonType.success,
    IconData? icon,
    bool canDismiss = true,
  }) async {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final dismissType = switch (type) {
      LayrzButtonType.danger || LayrzButtonType.warning => LayrzButtonType.success,
      _ => LayrzButtonType.danger,
    };

    final result = await LayrzDialog.show<bool>(
      context,
      title: Text(title),
      semanticLabel: title,
      canDismiss: canDismiss,
      content: description == null && content == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) Text(description, style: tokens.typography.body),
                if (description != null && content != null) tokens.spacing.sb2v,
                ?content,
              ],
            ),
      actions: [
        Builder(
          builder: (context) => LayrzButton(
            labelText: dismissLabel ?? l10n.confirmationDismiss,
            type: dismissType,
            onTap: () => LayrzModalRoute.popIfCurrent<bool>(context, false),
          ),
        ),
        Builder(
          builder: (context) => LayrzButton(
            labelText: confirmLabel ?? l10n.confirmationConfirm,
            icon: icon,
            type: type,
            onTap: () => LayrzModalRoute.popIfCurrent<bool>(context, true),
          ),
        ),
      ],
    );
    return result ?? false;
  }

  /// Asks the user to confirm a deletion and resolves to whether they confirmed.
  ///
  /// The confirm button matches [LayrzButton.delete] (danger, trash icon) and
  /// the dismiss button is [LayrzButtonType.success].
  ///
  /// - [context]: the [BuildContext] used to find the root navigator and the
  ///   theme and localizations.
  /// - [title]: overrides the default title, which is
  ///   [LayrzUiL10n.confirmationTitle], or
  ///   [LayrzUiL10n.confirmationMultipleTitle] when [items] has more than one
  ///   entry.
  /// - [description]: overrides the default description, which is
  ///   [LayrzUiL10n.confirmationContent], or
  ///   [LayrzUiL10n.confirmationMultipleContent] when [items] has more than one
  ///   entry.
  /// - [items]: display names of what is being deleted, rendered comma-separated
  ///   below the description. Empty (the default) renders no list.
  /// - [confirmLabel]: overrides the confirm label
  ///   ([LayrzUiL10n.confirmationConfirm]).
  /// - [dismissLabel]: overrides the dismiss label
  ///   ([LayrzUiL10n.confirmationDismiss]).
  static Future<bool> delete(
    BuildContext context, {
    String? title,
    String? description,
    List<String> items = const [],
    String? confirmLabel,
    String? dismissLabel,
  }) {
    final l10n = context.l10n;
    final typography = context.tokens.typography;
    final isMultiple = items.length > 1;

    return show(
      context,
      title: title ?? (isMultiple ? l10n.confirmationMultipleTitle : l10n.confirmationTitle),
      description: description ?? (isMultiple ? l10n.confirmationMultipleContent : l10n.confirmationContent),
      content: items.isEmpty
          ? null
          : Text(
              items.join(', '),
              style: typography.label.copyWith(
                fontWeight: typography.title.fontWeight,
                fontFeatures: typography.title.fontFeatures,
                fontVariations: typography.title.fontVariations,
              ),
            ),
      confirmLabel: confirmLabel,
      dismissLabel: dismissLabel,
      type: LayrzButtonType.danger,
      icon: MdiIcons.trashCanOutline,
    );
  }
}
