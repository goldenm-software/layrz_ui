import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'selectable_action.dart';

/// A Material-free text selection toolbar displaying action buttons.
///
/// [LayrzSelectionToolbar] renders a horizontal list of action buttons for text selection
/// operations (copy, cut, paste, select all, and custom actions). The toolbar
/// is styled using design system tokens and positioned via [Offset] anchors.
///
/// **Usage** typically occurs via [EditableText.contextMenuBuilder], which provides
/// the toolbar anchor positions and selection state. The toolbar is NOT positioned
/// automatically; the caller (TextSelectionOverlay) is responsible for wrapping it
/// in a [Positioned] widget or similar layout mechanism.
class LayrzSelectionToolbar extends StatelessWidget {
  /// The set of actions to display as buttons in the toolbar.
  final Set<LayrzSelectableAction> actions;

  /// The anchor offset where the toolbar should be positioned above the selection.
  final Offset anchorAbove;

  /// The anchor offset where the toolbar should be positioned below the selection.
  /// Used when there is not enough space above to render the toolbar.
  final Offset? anchorBelow;

  /// Design system tokens for colors, spacing, radius, and typography.
  final LayrzTokens tokens;

  /// Callback to invoke when a button action is pressed.
  final Function(String actionType) onActionPressed;

  /// Creates a new [LayrzSelectionToolbar].
  ///
  /// Parameters:
  ///   - [key]: Optional widget key for identification.
  ///   - [actions]: The set of action buttons to display.
  ///   - [anchorAbove]: The offset where the toolbar should appear above the selection.
  ///   - [anchorBelow]: The offset where the toolbar should appear below the selection if needed.
  ///   - [tokens]: Design system tokens for styling.
  ///   - [onActionPressed]: Callback invoked with the action type when a button is pressed.
  const LayrzSelectionToolbar({
    super.key,
    required this.actions,
    required this.anchorAbove,
    this.anchorBelow,
    required this.tokens,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final sortedActions = actions.toList()..sort((a, b) => a.type.compareTo(b.type));

    return Container(
      decoration: BoxDecoration(
        color: tokens.colors.sf1,
        borderRadius: BorderRadius.all(Radius.circular(tokens.radius.r2)),
        boxShadow: tokens.shadow.elevation1,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.sp2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in sortedActions)
                _buildActionButton(
                  context: context,
                  action: action,
                  label: action.label(l10n),
                  onPressed: () => onActionPressed(action.type),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required LayrzSelectableAction action,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.sp3,
            vertical: tokens.spacing.sp2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.icon != null)
                Icon(
                  action.icon,
                  size: 18.0,
                  color: tokens.colors.fg1,
                ),
              if (action.icon != null) SizedBox(width: tokens.spacing.sp2),
              Text(
                label,
                style: tokens.typography.label.copyWith(
                  color: tokens.colors.fg1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
