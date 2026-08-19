import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'detail_header.dart';
import 'scaffold_item.dart';

/// Private detail pane widget.
class DetailPane extends StatelessWidget {
  /// The currently selected item, or null if no selection.
  final LayrzScaffoldItem? selectedItem;

  /// Builder function to create the detail widget for the selected item.
  /// When null, an empty state is displayed.
  final Widget Function(BuildContext)? contentBuilder;

  /// Callback fired when the back button is pressed.
  final VoidCallback onBack;

  /// Optional title to override the selected item's title in the detail header.
  final String? detailTitle;

  /// Optional subtitle to display in the detail header.
  final String? detailSubtitle;

  /// List of action widgets to display in the detail header.
  final List<Widget> detailActions;

  /// Whether to display the back button.
  final bool showBack;

  /// Creates a new [DetailPane].
  const DetailPane({
    super.key,
    required this.selectedItem,
    required this.contentBuilder,
    required this.onBack,
    required this.detailTitle,
    required this.detailSubtitle,
    required this.detailActions,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (selectedItem == null || contentBuilder == null) {
      return Container(
        color: t.colors.surface,
        child: const Center(
          child: Text('No item selected'),
        ),
      );
    }

    return Container(
      color: t.colors.surface,
      child: Flex(
        direction: Axis.vertical,
        children: [
          DetailHeader(
            title: detailTitle,
            subtitle: detailSubtitle,
            actions: detailActions,
            onBack: showBack ? onBack : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kLayrzScaffoldDetailBodyPadding),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kLayrzScaffoldDetailMaxWidth,
                    ),
                    child: contentBuilder!(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
