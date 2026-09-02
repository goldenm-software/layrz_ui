import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// Builds the shared Cancel/Clear/Save action list for every Save-carrying
/// picker surface hosted in [LayrzEndDrawer] (or, below `isCompact`,
/// [LayrzBottomSheet]).
///
/// **Order and styling are the maintainer's explicit ruling on DESIGN-46**,
/// verbatim: *"the action buttons below, it must be this order: cancel -
/// clear - save, save is the only .filled, the other should be .text."* His
/// screenshot showed the previous order (Clear, Cancel, Save) with all three
/// filled and full-width — this class is the single place that ordering and
/// styling is expressed, so every surface in the batch stays in sync rather
/// than each re-deriving it.
///
/// **Clear is visible only once a selection exists** — a reviewer
/// requirement carried over from the pre-drawer footers (see
/// `LayrzDateRangeSurface`/`LayrzMonthRangeSurface`'s identical
/// `if (_draft.anchor != null)` gate) and preserved here, not made
/// always-on. [onClear] is `null` to omit the button entirely.
///
/// **DESIGN-98: returns a `List<Widget>` for [LayrzEndDrawer]'s/
/// [LayrzBottomSheet]'s `actions` slot, not a composed [Row].** Before
/// DESIGN-98 this was a [StatelessWidget] rendering its own `Row`, placed as
/// an ordinary trailing child of the surface's scrolling body — which is
/// exactly why the maintainer's screenshot showed the footer stranded under
/// short content instead of pinned to the drawer's bottom edge. [build] hands
/// the same three buttons to the caller as a flat list instead, so they can
/// be passed straight through to `actions:` and pinned by the drawer/sheet
/// itself.
class LayrzPickerDrawerFooter {
  LayrzPickerDrawerFooter._();

  /// Builds the ordered Cancel/Clear/Save action widgets for a picker
  /// surface's `actions` slot.
  ///
  /// - [context]: used to resolve tokens and localized labels.
  /// - [onCancel]: called when Cancel is pressed. Always present.
  /// - [onClear]: called when Clear is pressed. When `null`, the Clear button
  ///   is omitted entirely — see the class doc's "Clear is visible only once
  ///   a selection exists" note.
  /// - [onSave]: called when Save is pressed. `null` when Save is not yet
  ///   reachable — this renders the Save button disabled rather than omitting
  ///   it, so its position in the row never shifts.
  static List<Widget> build(
    BuildContext context, {
    required VoidCallback onCancel,
    VoidCallback? onClear,
    required VoidCallback? onSave,
  }) {
    final l10n = context.l10n;

    return [
      LayrzButton.cancel(
        labelText: l10n.actionCancel,
        onTap: onCancel,
        style: LayrzButtonStyle.text,
      ),
      if (onClear != null)
        LayrzButton(
          labelText: l10n.pickerRangeReset,
          onTap: onClear,
          type: LayrzButtonType.warning,
          style: LayrzButtonStyle.text,
        ),
      LayrzButton.save(
        labelText: l10n.actionSave,
        onTap: onSave ?? () {},
        isDisabled: onSave == null,
      ),
    ];
  }
}
