import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// The shared Cancel/Clear/Save action row for every Save-carrying picker
/// surface hosted in [LayrzPickerDrawer] (or, below `isCompact`,
/// [LayrzBottomSheet]).
///
/// **Order and styling are the maintainer's explicit ruling on DESIGN-46**,
/// verbatim: *"the action buttons below, it must be this order: cancel -
/// clear - save, save is the only .filled, the other should be .text."* His
/// screenshot showed the previous order (Clear, Cancel, Save) with all three
/// filled and full-width — this widget is the single place that ordering and
/// styling is expressed, so every surface in the batch stays in sync rather
/// than each re-deriving it.
///
/// **Clear is visible only once a selection exists** — a reviewer
/// requirement carried over from the pre-drawer footers (see
/// `LayrzDateRangeSurface`/`LayrzMonthRangeSurface`'s identical
/// `if (_draft.anchor != null)` gate) and preserved here, not made
/// always-on. [onClear] is `null` to omit the button entirely.
class LayrzPickerDrawerFooter extends StatelessWidget {
  /// Called when Cancel is pressed. Always shown.
  final VoidCallback onCancel;

  /// Called when Clear is pressed. When `null`, the Clear button is omitted
  /// entirely — see the class doc's "Clear is visible only once a selection
  /// exists" note.
  final VoidCallback? onClear;

  /// Called when Save is pressed. `null` when Save is not yet reachable —
  /// this renders the Save button disabled rather than omitting it, so its
  /// position in the row never shifts.
  final VoidCallback? onSave;

  /// Creates a new [LayrzPickerDrawerFooter].
  const LayrzPickerDrawerFooter({
    super.key,
    required this.onCancel,
    this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: LayrzButton.cancel(
            labelText: l10n.actionCancel,
            onTap: onCancel,
            style: LayrzButtonStyle.text,
          ),
        ),
        if (onClear != null) ...[
          SizedBox(width: tokens.spacing.sp2),
          Expanded(
            child: LayrzButton(
              labelText: l10n.pickerRangeReset,
              onTap: onClear,
              type: LayrzButtonType.warning,
              style: LayrzButtonStyle.text,
            ),
          ),
        ],
        SizedBox(width: tokens.spacing.sp2),
        Expanded(
          child: LayrzButton.save(
            labelText: l10n.actionSave,
            onTap: onSave ?? () {},
            isDisabled: onSave == null,
          ),
        ),
      ],
    );
  }
}
