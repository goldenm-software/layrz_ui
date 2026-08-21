import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

/// A text selection action item displayed in the selection toolbar.
///
/// [LayrzSelectableAction] represents a single action (copy, cut, paste, select all, or custom)
/// that can appear in the text selection toolbar. Built-in actions are provided as static
/// constants and are deduplicated when placed in a Set.
///
/// **Built-in actions**:
/// - [copy] — copies selected text to clipboard
/// - [cut] — cuts selected text to clipboard
/// - [paste] — pastes clipboard text at cursor
/// - [selectAll] — selects all text in the field
///
/// **Custom actions** can be created via the public constructor by providing a label,
/// callback, and optional icon.
@immutable
class LayrzSelectableAction {
  /// Human-readable label for the action.
  final String Function(LayrzUiL10n l10n) label;

  /// Callback fired when the action is invoked.
  final VoidCallback onPressed;

  /// Optional icon to display with the action.
  final IconData? icon;

  /// The action type — one of `copy`, `cut`, `paste`, `selectAll`, or a unique string
  /// to distinguish custom actions. Exposed for testing.
  final String type;

  /// Creates a custom selectable action.
  ///
  /// Parameters:
  ///   - [label]: A function that accepts [LayrzUiL10n] and returns the localized action label.
  ///   - [onPressed]: Callback invoked when the action is tapped.
  ///   - [icon]: Optional [IconData] icon to display alongside the label.
  const LayrzSelectableAction({
    required this.label,
    required this.onPressed,
    this.icon,
  }) : type = 'custom';

  /// Private constructor for built-in actions.
  const LayrzSelectableAction._builtin({
    required this.label,
    required this.onPressed,
    required this.type,
    // ignore: unused_element_parameter
    this.icon,
  });

  static String _labelCopy(LayrzUiL10n l10n) => l10n.selectionCopy;
  static String _labelCut(LayrzUiL10n l10n) => l10n.selectionCut;
  static String _labelPaste(LayrzUiL10n l10n) => l10n.selectionPaste;
  static String _labelSelectAll(LayrzUiL10n l10n) => l10n.selectionSelectAll;

  static void _noOp() {}

  /// Built-in copy action — copies selected text to clipboard.
  ///
  /// The actual clipboard operation is handled by the toolbar implementation.
  static const LayrzSelectableAction copy = LayrzSelectableAction._builtin(
    label: _labelCopy,
    onPressed: _noOp,
    type: 'copy',
  );

  /// Built-in cut action — cuts selected text to clipboard.
  ///
  /// The actual clipboard operation is handled by the toolbar implementation.
  static const LayrzSelectableAction cut = LayrzSelectableAction._builtin(
    label: _labelCut,
    onPressed: _noOp,
    type: 'cut',
  );

  /// Built-in paste action — pastes clipboard text at cursor.
  ///
  /// The actual clipboard operation is handled by the toolbar implementation.
  static const LayrzSelectableAction paste = LayrzSelectableAction._builtin(
    label: _labelPaste,
    onPressed: _noOp,
    type: 'paste',
  );

  /// Built-in select all action — selects all text in the field.
  ///
  /// The actual selection operation is handled by the toolbar implementation.
  static const LayrzSelectableAction selectAll = LayrzSelectableAction._builtin(
    label: _labelSelectAll,
    onPressed: _noOp,
    type: 'selectAll',
  );

  /// The default set of all built-in actions.
  ///
  /// Built-in actions in this set are deduplicated by type equality.
  static final Set<LayrzSelectableAction> defaults = {
    LayrzSelectableAction.copy,
    LayrzSelectableAction.cut,
    LayrzSelectableAction.paste,
    LayrzSelectableAction.selectAll,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayrzSelectableAction && other.type == type;
  }

  @override
  int get hashCode => Object.hash(type, type);

  @override
  String toString() => 'LayrzSelectableAction($type)';
}
