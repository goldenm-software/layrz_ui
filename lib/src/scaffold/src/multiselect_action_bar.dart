import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// The standardized floating multiselect action bar shown by
/// [LayrzScaffoldShell] whenever the desktop table's own selection
/// (`LayrzTableController.selection`) is non-empty and the shell was given a
/// `multiselectActionsBuilder`.
///
/// This widget is pure presentation: [LayrzScaffoldShell] owns deciding
/// *when* the bar is visible (via an [OverlayEntry] it inserts into the root
/// [Overlay] — see that class's `_syncMultiselectOverlay`) and resolving the
/// count/label/clear strings; this widget only lays out the resolved values.
///
/// Anatomy, stacked in two rows: the top row holds the resolved count label
/// (e.g. "3 selected") on the leading edge and the shell-owned clear button
/// on the trailing edge; the bottom row holds the caller's own [actions],
/// full-width beneath the first row. The whole column sits inside a
/// floating, elevated surface matching the same shadow/radius/surface
/// treatment used by the snackbar and find-bar floating chrome elsewhere in
/// the design system, so the affordance reads as consistent with the rest of
/// the library rather than bespoke to this shell.
class LayrzScaffoldMultiselectBar extends StatelessWidget {
  /// The number of currently selected rows, used only to build the
  /// accessibility announcement — the visible text is [countLabel], already
  /// resolved by the caller.
  final int count;

  /// The already-resolved "N selected" label text.
  ///
  /// Resolution (caller copy vs. localized default vs. plain fallback) is the
  /// shell's responsibility; this widget renders exactly the string it is
  /// given.
  final String countLabel;

  /// The already-resolved label for the shell-owned clear-selection button.
  final String clearLabel;

  /// Called when the clear-selection button is activated.
  ///
  /// The shell wires this to `LayrzTableController.clearSelection()`, which
  /// empties the selection and, in turn, causes the shell to remove this bar
  /// on the next notification.
  final VoidCallback onClear;

  /// The caller-supplied action buttons, built from the current selection via
  /// `LayrzScaffoldShell.multiselectActionsBuilder`.
  ///
  /// Rendered as-is in a wrapping row beneath the count/clear row; each
  /// button carries its own `onTap` and semantics. When empty, the second
  /// row (and its spacing) is omitted entirely.
  final List<LayrzButton> actions;

  /// Creates a [LayrzScaffoldMultiselectBar].
  const LayrzScaffoldMultiselectBar({
    super.key,
    required this.count,
    required this.countLabel,
    required this.clearLabel,
    required this.onClear,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      container: true,
      liveRegion: true,
      label: countLabel,
      explicitChildNodes: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp2),
        decoration: BoxDecoration(
          color: tokens.colors.sf1,
          borderRadius: tokens.radius.br2,
          border: Border.all(color: tokens.colors.divider, width: 1),
          boxShadow: tokens.shadow.elevation3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(countLabel, style: tokens.typography.body.copyWith(color: tokens.colors.fg1)),
                  ),
                ),
                LayrzButton(
                  labelText: clearLabel,
                  style: LayrzButtonStyle.text,
                  type: LayrzButtonType.danger,
                  onTap: onClear,
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              SizedBox(height: tokens.spacing.sp2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: tokens.spacing.sp2,
                runSpacing: tokens.spacing.sp2,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
