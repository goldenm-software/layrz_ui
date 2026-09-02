import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_footer_slot.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Builds the bordered field row shared by every picker anchor in this
/// module: [LayrzInputChrome] (composed **directly**, per D63) plus a
/// trailing affordance icon rendered as an **external sibling** — never in
/// `prefixSlot`/`suffixSlot` — mirroring
/// `lib/src/inputs/src/duration/duration_input.dart`'s `_buildFieldRow`
/// almost exactly. See that file's own extensive comments for the
/// reasoning behind each individual choice reproduced here; this function
/// exists so all eight `Layrz*Input` widgets in this module share one
/// implementation of the row rather than each re-deriving it, while still
/// satisfying D63 (every input composes [LayrzInputChrome] directly — this
/// helper is not itself a widget another input "wraps").
///
/// **This function does not construct the whole anchor** — label and the
/// error/helper footer are the caller's responsibility (see the D63
/// skeleton in the implementation plan), because they are hoisted **outside**
/// this row so the chrome's own box stays exactly the anchor rect an
/// anchored panel/bottom sheet opens against.
///
/// [readOnly] is **always** `false` and `suppressReadOnlyLock` is always
/// `true` internally — trap 1 (never hardcode `readOnly: true` on a picker
/// anchor, since [LayrzInputStyleSpec.resolve] ranks `readOnly` above
/// `error` and would silently suppress the danger border).
Widget buildPickerFieldRow({
  required BuildContext context,
  required LayrzTokens tokens,
  required Widget contentChild,
  required Set<WidgetState> states,
  required List<String> errors,
  required bool disabled,
  required bool isRequired,
  String? hintText,
  TextEditingController? controller,
  bool dense = false,
  String? helpTitleText,
  String? helpContentText,
  required Widget affordanceIcon,
}) {
  final hasErrors = errors.isNotEmpty;

  // See trap 1 in the implementation plan / duration_input.dart's identical
  // comment: `readOnly` is hardcoded to `false` here (never forwarded from a
  // caller-set value) because a picker anchor's non-editability is a
  // behavioral fact, not something any of these widgets expose as a
  // caller-settable `readOnly` parameter.
  final spec = LayrzInputStyleSpec.resolve(states: states, tokens: tokens, hasErrors: hasErrors);

  // Trap 2: round the chrome's own outer-facing (left) corners -- the outer
  // Clip.antiAlias does not reshape the chrome's own square-cornered fill.
  final leftInnerR = Radius.circular(
    tokens.radius.innerRadiusValue(outerRadius: tokens.radius.r2, spacer: spec.borderWidth),
  );
  final chromeRadius = BorderRadius.only(topLeft: leftInnerR, bottomLeft: leftInnerR);

  return Container(
    decoration: BoxDecoration(
      color: spec.backgroundColor,
      border: Border.all(color: spec.borderColor, width: spec.borderWidth),
      borderRadius: tokens.radius.br2,
    ),
    clipBehavior: Clip.antiAlias,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayrzInputChrome(
              labelText: null,
              hintText: hintText,
              isRequired: isRequired,
              prefixSlot: const LayrzInputPrefixSlot(),
              suffixSlot: const LayrzInputSuffixSlot(),
              disabled: disabled,
              readOnly: false,
              errors: errors,
              hideDetails: true,
              states: states,
              suppressReadOnlyLock: true,
              controller: controller,
              dense: dense,
              helpTitleText: helpTitleText,
              helpContentText: helpContentText,
              borderRadius: chromeRadius,
              showBorder: false,
              // Trap 3: never wrap `child` in its own Padding -- the chrome
              // constrains it to a fixed content height and an inner Padding
              // eats into that box instead of adding visual breathing room.
              child: contentChild,
            ),
          ),
          affordanceIcon,
        ],
      ),
    ),
  );
}

/// Builds a picker anchor's affordance icon, dividing it from the chrome
/// with a vertical rule — the same visual treatment
/// `duration_input.dart`'s `_buildAffordanceIcon` uses, shared here so every
/// picker's identifying glyph reads consistently.
///
/// Rendered as an **external sibling** of the chrome (passed as
/// [buildPickerFieldRow]'s `affordanceIcon`), never in a chrome slot — this
/// is what resolves D63's open slot question without touching the frozen
/// chrome file: both `prefixSlot`/`suffixSlot` stay free for a caller.
///
/// Purely decorative: wrapped in [ExcludeSemantics] because the anchor's own
/// outer [Semantics] node (built by the caller) already carries the label
/// and enabled state.
Widget buildPickerAffordanceIcon({
  required LayrzTokens tokens,
  required LayrzInputStyleSpec spec,
  required bool hasErrors,
  required IconData icon,
}) {
  final dividerColor = hasErrors ? tokens.colors.danger : tokens.colors.divider.withValues(alpha: 0.3);

  return ExcludeSemantics(
    child: Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: dividerColor, width: tokens.border.stroke2),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
      child: Align(
        alignment: Alignment.center,
        child: Icon(icon, size: tokens.typography.body.fontSize, color: spec.textColor),
      ),
    ),
  );
}

/// Builds the label + field row + error footer column shared by every
/// picker anchor — the composition [LayrzDurationInput]'s
/// `_buildInteractiveField` implements, factored out here so all eight
/// `Layrz*Input` widgets share one implementation.
///
/// [fieldRow] is normally the result of [buildPickerFieldRow]. [onTap] is
/// `null` when the widget is disabled, so both the [Semantics] node and the
/// [GestureDetector] report no tap handler.
Widget buildPickerAnchorColumn({
  required BuildContext context,
  required LayrzTokens tokens,
  required String? labelText,
  required bool isRequired,
  required Widget fieldRow,
  required List<String> errors,
  required bool hideDetails,
  required TextEditingController? controller,
  required FocusNode focusNode,
  required VoidCallback? onTap,
  required bool disabled,
}) {
  return Semantics(
    label: labelText,
    button: true,
    enabled: !disabled,
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Trap 5: LayrzInputChrome never attaches a FocusNode itself -- it is
      // purely visual, so this Focus wrapper is what puts this anchor in the
      // focus tree at all.
      child: Focus(
        focusNode: focusNode,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (labelText != null)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
                child: ExcludeSemantics(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: labelText,
                          style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
                        ),
                        if (isRequired)
                          TextSpan(
                            text: '*',
                            style: tokens.typography.label.copyWith(color: tokens.colors.danger),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            fieldRow,
            LayrzInputFooterSlot(errors: errors, hideDetails: hideDetails, controller: controller),
          ],
        ),
      ),
    ),
  );
}
