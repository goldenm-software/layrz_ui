import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// Renders the "use '&lt;typed&gt;'" affordance shown at the top of
/// [LayrzComboBoxInput]'s desktop panel when the user has typed text that does
/// not exactly match any existing option.
///
/// **Why this exists (Q4).** [LayrzComboBoxInput] stays `String`-based and keeps
/// permitting free-form values (see [LayrzComboBoxInput.allowFreeForm]), but a
/// typed value that never matches anything used to commit only implicitly --
/// on blur or Enter, with no visible confirmation of what was about to be
/// committed. This row makes that act explicit and visible: it appears only
/// while there is something to confirm, and committing it always requires an
/// explicit tap or Enter on the row itself -- never an implicit commit on
/// dismiss.
///
/// **Why it is placed first, directly under the input (structural, not just
/// visual).** [LayrzComboBoxPanelContent] always builds this row immediately
/// after the input and before the filtered option list, for three reasons:
/// it sits adjacent to the text it echoes, so the eye travels input →
/// confirmation with nothing in between; it holds a stable position while the
/// filtered list below changes length on every keystroke (a last-position row
/// would move under the user's finger/cursor on every keystroke); and it can
/// never be scrolled out of reach at the bottom of a long option list.
class LayrzComboBoxCustomValueRow extends StatelessWidget {
  /// The text currently typed into the panel's input.
  ///
  /// Rendered verbatim inside the row's label (`Use "$typedText"`). The
  /// caller is responsible for only building this row when [typedText] is
  /// non-empty and does not exactly match an existing option -- this widget
  /// itself applies no such filtering.
  final String typedText;

  /// Called when the row is committed, via an explicit tap or Enter key.
  ///
  /// Invoked with [typedText] unchanged. Never called implicitly (e.g. on
  /// blur or panel dismiss) -- only this row's own gesture and the owning
  /// [LayrzComboBoxInput]'s Enter-key handling call it.
  final ValueChanged<String> onCommit;

  /// Whether this row is currently highlighted, e.g. via arrow-key navigation.
  ///
  /// Mirrors the highlight treatment [OptionItem] applies to a highlighted
  /// option, so the row reads as part of the same navigable list.
  final bool isHighlighted;

  /// Creates a new [LayrzComboBoxCustomValueRow].
  const LayrzComboBoxCustomValueRow({
    super.key,
    required this.typedText,
    required this.onCommit,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Deliberately not routed through `LayrzUiL10n`: this row's copy is new
    // surface introduced by this unit, and adding a key means registering a
    // new getter on the `LayrzUiL10nComboboxMixin` namespace file and, in
    // turn, on `l10n.dart` -- neither of which is in this unit's file list
    // (see the plan: `lib/src/inputs/inputs.dart` and other cross-cutting
    // shared files are out of scope, reported rather than edited silently).
    // A plain literal keeps this row inside the unit's boundary; wiring it
    // through localization is left for whoever owns that file next.
    final label = 'Use "$typedText"';

    return Semantics(
      button: true,
      label: label,
      child: LayrzTappable(
        onTap: () => onCommit(typedText),
        color: isHighlighted ? tokens.colors.sf2 : const Color(0x00000000),
        hoverColor: tokens.colors.sf2,
        pressedColor: tokens.colors.sf3,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spacing.sp2,
            horizontal: tokens.spacing.sp3,
          ),
          child: Row(
            children: [
              Icon(
                MdiIcons.plusCircleOutline,
                size: tokens.typography.body.fontSize,
                color: tokens.colors.primary,
              ),
              SizedBox(width: tokens.spacing.sp2),
              Expanded(
                // Excluded from semantics: the outer `Semantics(label: label)`
                // already carries this row's full accessible name -- without
                // this, `Text.rich`'s own text semantics would merge upward
                // too, doubling the announced label (observed directly: a
                // semantics assertion failed with the label repeated twice).
                child: ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Use "',
                          style: tokens.typography.body.copyWith(color: tokens.colors.fg1),
                        ),
                        TextSpan(
                          text: typedText,
                          style: tokens.typography.body.copyWith(
                            color: tokens.colors.fg1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '"',
                          style: tokens.typography.body.copyWith(color: tokens.colors.fg1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
