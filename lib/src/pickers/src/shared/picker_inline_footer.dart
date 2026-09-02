import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'picker_drawer_footer.dart';

/// Renders `LayrzPickerDrawerFooter.build`'s Cancel/Clear/Save actions as an
/// equal-width [Row], for a picker surface's mobile [LayrzBottomSheet] path.
///
/// **Mobile-only, by design.** DESIGN-98 moved the desktop container from
/// composing this footer inline (which is what stranded it under short
/// content — see [LayrzEndDrawer]'s own class doc) to building the same
/// three buttons as [LayrzEndDrawer.show]'s `actions` parameter instead, so
/// they pin to the drawer's bottom edge. The mobile [LayrzBottomSheet]
/// container is explicitly out of scope for that fix, so every picker
/// surface still renders this widget inline as the last child of its own
/// scrolling body when hosted there — unchanged from the pre-DESIGN-98
/// behaviour, just factored out of eight near-identical `Row` blocks into one
/// shared widget.
class LayrzPickerInlineFooter extends StatelessWidget {
  /// Called when Cancel is pressed. Always shown.
  final VoidCallback onCancel;

  /// Called when Clear is pressed. When `null`, the Clear button is omitted
  /// entirely.
  final VoidCallback? onClear;

  /// Called when Save is pressed. `null` renders Save disabled rather than
  /// omitting it, so its position in the row never shifts.
  final VoidCallback? onSave;

  /// Creates a new [LayrzPickerInlineFooter].
  const LayrzPickerInlineFooter({
    super.key,
    required this.onCancel,
    this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final actions = LayrzPickerDrawerFooter.build(context, onCancel: onCancel, onClear: onClear, onSave: onSave);

    return Row(
      children: [
        for (final (i, action) in actions.indexed) ...[
          if (i > 0) SizedBox(width: tokens.spacing.sp2),
          Expanded(child: action),
        ],
      ],
    );
  }
}
