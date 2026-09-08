import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// The title row every picker surface renders at the top of its own
/// [LayrzResponsiveModal.show] builder content.
///
/// **Why this exists.** Every picker under `lib/src/pickers/` and the three
/// combo/select/duration inputs under `lib/src/inputs/` used to open through
/// `LayrzEndDrawer`, which supplied a title bar for free. The migration to
/// `LayrzResponsiveModal.show` dropped that bar entirely — `show`'s own
/// `builder` has no title slot (see its own doc comment: a single `builder`
/// result must describe content usable on both the dialog and the sheet
/// branch, so there is nowhere for a separate title parameter to plug in) —
/// leaving every migrated picker with no visible heading at all. This widget
/// is composed **inside** each surface's own builder content instead, at the
/// very top, so it becomes part of the one widget both branches render.
///
/// **The row is always present, at a fixed height, whether or not
/// [labelText] is supplied.** When [labelText] is `null` or empty, the title
/// side renders an empty [SizedBox] rather than collapsing the row — a
/// picker's header must never make its content jump depending on whether a
/// caller happened to pass a label, so only the *text* is conditional, never
/// the row itself.
///
/// **The close ("X") button always renders** and pops the hosting modal via
/// [LayrzModalRoute.popIfCurrent] — the same double-pop-safe guard every
/// other Cancel/Escape/barrier-tap dismissal route in this design system
/// uses (see that method's own doc for the release-only bug it fixes).
/// Visually it mirrors `LayrzDialog`'s own internal close affordance
/// (`dialog.dart`'s `_DialogCloseButton`) exactly — same [LayrzTappable]
/// wrapping, same icon, same size — so a picker's in-content header X reads
/// as the same control as the dialog's own floating X would have, even
/// though every picker now opens with `showCloseIcon: false` and relies on
/// this header's X instead (see that parameter's own doc on `LayrzDialog.show`
/// for why a second, floating X would otherwise collide with a picker's own
/// top-right chrome, e.g. a calendar's next-month chevron).
///
/// [onClose] is deliberately a required callback, not a hardcoded
/// `Navigator.pop` — see [LayrzPickerDrawerActions]'s own "Callbacks receive
/// this widget's own `context`" doc for why a closure built at the call
/// site's own `_openPicker` method must not be used directly: that method's
/// `context` sits **outside** the modal's route, so
/// [LayrzModalRoute.popIfCurrent] on it would resolve the wrong route and
/// silently no-op forever. Every call site below passes
/// `() => LayrzModalRoute.popIfCurrent(context)` using the [BuildContext]
/// this widget's own `build` receives, which is genuinely inside the pushed
/// route.
class LayrzPickerDialogHeader extends StatelessWidget {
  /// The picker's own title text, normally the field's `labelText`.
  ///
  /// `null` or empty renders an empty title slot rather than collapsing the
  /// row — see this class's own doc for why the row's height must never
  /// depend on whether this is supplied.
  final String? labelText;

  /// Called when the close ("X") button is tapped.
  ///
  /// Callers pass `() => LayrzModalRoute.popIfCurrent(context)` using the
  /// [BuildContext] their own builder was handed — see this class's own doc
  /// for why the outer `_openPicker` method's context must not be captured
  /// here instead.
  final VoidCallback onClose;

  /// An optional widget rendered between the title and the close button,
  /// filling the remaining row width via an [Expanded].
  ///
  /// **Added for the Select/MultiSelect/ComboBox surfaces' inline search
  /// field** (title | dense search | X), so those three pickers no longer
  /// need a second, separate search row below the header. `null` (the
  /// default) renders the title's own [Expanded] exactly as before this
  /// parameter existed — every other picker under `lib/src/pickers/` and
  /// `lib/src/inputs/` leaves this unset and is therefore visually
  /// unaffected by its addition.
  ///
  /// When non-null, [labelText] keeps its own natural (unexpanded) width
  /// instead of stretching to fill the row — see [build] for how the two
  /// [Expanded] slots divide the row once this is supplied.
  final Widget? middleSlot;

  /// Creates a new [LayrzPickerDialogHeader].
  const LayrzPickerDialogHeader({
    super.key,
    required this.labelText,
    required this.onClose,
    this.middleSlot,
  });

  /// The close button's hit target side length, in logical pixels. Mirrors
  /// `_DialogCloseButton.tapTargetSize` (`dialog.dart`) so the two controls
  /// read as visually identical.
  static const double _tapTargetSize = 28;

  /// The close icon's own size, in logical pixels. Mirrors
  /// `_DialogCloseButton.iconSize` (`dialog.dart`).
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = labelText;
    final hasLabel = label != null && label.isNotEmpty;
    final slot = middleSlot;

    final titleWidget = hasLabel
        ? Text(
            label,
            style: tokens.typography.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Unchanged shape when `middleSlot` is null (every other picker):
          // the title alone fills the row via `Expanded`. When a middle slot
          // is supplied, the title keeps its own natural width instead, so
          // the slot's own `Expanded` gets the remaining space.
          slot == null ? Expanded(child: titleWidget) : titleWidget,
          if (slot != null) ...[
            SizedBox(width: tokens.spacing.sp2),
            Expanded(child: slot),
          ],
          SizedBox(width: tokens.spacing.sp2),
          Semantics(
            button: true,
            label: context.l10n.dialogsCloseButtonLabel,
            excludeSemantics: true,
            child: LayrzTappable(
              onTap: onClose,
              borderRadius: tokens.radius.br1,
              child: SizedBox(
                width: _tapTargetSize,
                height: _tapTargetSize,
                child: Icon(
                  MdiIcons.close,
                  size: _iconSize,
                  color: tokens.colors.fg3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
