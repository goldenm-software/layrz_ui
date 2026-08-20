import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The right detail pane of the scaffold shell.
///
/// Shows the detail content built by [contentBuilder] when [opened] is non-null,
/// or an empty state otherwise.
class DetailPane<T> extends StatelessWidget {
  /// The currently opened item, or null.
  final T? opened;

  /// Callback to build the detail content.
  final Widget Function(BuildContext, T)? contentBuilder;

  /// Callback to close the detail pane.
  final VoidCallback? onClose;

  /// Whether the detail pane should show a back button.
  final bool showBack;

  /// Creates a new [DetailPane].
  ///
  /// - [opened]: The currently opened item, or null. Defaults to null.
  /// - [contentBuilder]: Callback to build the detail content, or null. Defaults to null.
  /// - [onClose]: Callback to close the detail pane, or null. Defaults to null.
  /// - [showBack]: Whether to show a back button. Defaults to false.
  const DetailPane({
    super.key,
    this.opened,
    this.contentBuilder,
    this.onClose,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      color: tokens.colors.surface,
      child: Column(
        children: [
          if (showBack)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tokens.colors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      MdiIcons.arrowLeft,
                      size: 20,
                      color: tokens.colors.fg1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Back",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: tokens.colors.fg1,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: opened == null
                ? _buildEmptyState(tokens)
                : SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: contentBuilder?.call(context, opened as T),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LayrzTokens tokens) {
    return Center(
      child: Text(
        "No item selected",
        style: TextStyle(fontSize: 13, color: tokens.colors.fg3),
      ),
    );
  }
}
