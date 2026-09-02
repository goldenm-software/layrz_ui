import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'picker_drawer_footer.dart';

/// Builds the single, reactive `actions` entry every Save-carrying picker
/// input passes to [LayrzEndDrawer.show] on desktop.
///
/// **Why one entry, not three.** [LayrzEndDrawer.show]'s `actions` parameter
/// is a plain `List<Widget>` captured once, at the moment `show` is called —
/// there is no ancestor rebuild boundary spanning both the drawer's `builder`
/// and its `actions` that a picker surface's live draft state (whether Save
/// is enabled, whether Clear should render at all) could hook into after the
/// fact. Wrapping the whole Cancel/Clear/Save row in one
/// [ValueListenableBuilder], driven by a [ValueNotifier] the surface writes
/// to on every draft mutation, sidesteps that: this single widget is the one
/// thing that needs to rebuild, and it owns its own internal spacing, so
/// Clear popping in and out of the row never leaves a stray gap the way three
/// independently-conditional list entries would.
///
/// Every one of the eight date-related inputs uses this exact pattern: a
/// [ValueNotifier] created in the input's `_openDesktopDrawer`, written to by
/// the surface's `onDraftChanged` callback via a [GlobalKey], and read here.
class LayrzPickerDrawerActions extends StatelessWidget {
  /// The surface's live draft state, updated on every mutation. `canSave`
  /// gates the Save button; `hasSelection` gates whether Clear renders at
  /// all.
  final ValueListenable<({bool canSave, bool hasSelection})> draftState;

  /// Called when Cancel is pressed. Always shown.
  final VoidCallback onCancel;

  /// Called when Clear is pressed, while `draftState.hasSelection` is `true`.
  /// Ignored (and the button omitted) while `hasSelection` is `false`.
  final VoidCallback onClear;

  /// Called when Save is pressed, while `draftState.canSave` is `true`. Save
  /// renders disabled, not omitted, while `canSave` is `false`.
  final VoidCallback onSave;

  /// Creates a new [LayrzPickerDrawerActions].
  const LayrzPickerDrawerActions({
    super.key,
    required this.draftState,
    required this.onCancel,
    required this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ValueListenableBuilder<({bool canSave, bool hasSelection})>(
      valueListenable: draftState,
      builder: (context, state, _) {
        final actions = LayrzPickerDrawerFooter.build(
          context,
          onCancel: onCancel,
          onClear: state.hasSelection ? onClear : null,
          onSave: state.canSave ? onSave : null,
        );

        // Each button is wrapped in Flexible (not left to size itself) so
        // three buttons -- Cancel/Clear/Save's longest combination -- never
        // overflow the drawer's own padded width (420px minus 2*sp3 padding
        // = 392px, per LayrzEndDrawer.width). Mirrors LayrzPickerInlineFooter's
        // identical Expanded-per-button layout, except Flexible rather than
        // Expanded: this row is NOT full-width like the mobile footer (it is
        // right-aligned like LayrzDialog's and LayrzBottomSheet's own action
        // rows), so each button should still size to its own label rather
        // than stretching to fill equal thirds of the row.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, action) in actions.indexed) ...[
              if (i > 0) SizedBox(width: tokens.spacing.sp2),
              Flexible(child: action),
            ],
          ],
        );
      },
    );
  }
}
