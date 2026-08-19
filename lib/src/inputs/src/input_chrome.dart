import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'dashed_border_painter.dart';
import 'input_error_block.dart';
import 'input_slot.dart';
import 'input_style_spec.dart';

/// Library-private chrome widget that wraps an input field with label, border, and error handling.
///
/// This widget is intended for reuse across multiple input types (text, textarea, etc.)
/// and is not publicly exported.
class LayrzInputChrome extends StatelessWidget {
  /// The label text displayed above the input field.
  final String? labelText;

  /// Optional icon displayed before the label text.
  ///
  /// Rendered via [RichText] and inherits the label's colour and typography sizing.
  /// Ignored if [labelText] is null.
  final IconData? labelIcon;

  /// Hint text displayed as placeholder when the field is empty.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The prefix slot configuration.
  final LayrzInputPrefixSlot prefixSlot;

  /// The suffix slot configuration.
  final LayrzInputSuffixSlot suffixSlot;

  /// The widget being wrapped (the actual input field).
  final Widget child;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// The list of error messages to display.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// The current widget states (hover, focus, etc.).
  final Set<WidgetState> states;

  /// Optional shortcut text to display in the trailing edge.
  final String? shortcutText;

  /// Whether to hide the shortcut on mobile platforms.
  final bool hideShortcutOnMobile;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// The padding applied inside the input field.
  ///
  /// If provided, this padding is used as-is and [dense] is ignored.
  /// If null, padding is derived from tokens: sp8 all sides when normal,
  /// or sp8 horizontal with sp4 vertical when [dense] is true.
  ///
  /// Explicit padding takes precedence over [dense] to prevent silent geometry
  /// mutations when a caller provides an exact layout requirement.
  final EdgeInsets? padding;

  /// Whether the input field uses a compact (dense) layout.
  ///
  /// Ignored when [padding] is non-null.
  final bool dense;

  /// Creates a new [LayrzInputChrome] with the given properties.
  const LayrzInputChrome({
    super.key,
    required this.labelText,
    this.labelIcon,
    this.hintText,
    required this.isRequired,
    required this.prefixSlot,
    required this.suffixSlot,
    required this.child,
    required this.disabled,
    required this.readOnly,
    required this.errors,
    required this.hideDetails,
    required this.states,
    this.shortcutText,
    this.hideShortcutOnMobile = true,
    this.helpTitleText,
    this.helpContentText,
    this.padding,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasErrors = errors.isNotEmpty;
    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: readOnly,
    );

    // Compute padding: explicit caller value wins over dense mode
    final verticalPadding = dense ? tokens.spacing.sp4 : tokens.spacing.sp8;
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp8,
          vertical: verticalPadding,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        if (labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp8),
            child: RichText(
              text: TextSpan(
                children: [
                  if (labelIcon != null)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(right: tokens.spacing.sp6),
                        child: Icon(
                          labelIcon,
                          size: tokens.typography.label.fontSize,
                          color: tokens.colors.fg2,
                        ),
                      ),
                    ),
                  TextSpan(
                    text: labelText,
                    style: tokens.typography.label.copyWith(
                      color: tokens.colors.fg2,
                    ),
                  ),
                  if (isRequired)
                    TextSpan(
                      text: '*',
                      style: tokens.typography.label.copyWith(
                        color: tokens.colors.danger,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Input container with border
        Stack(
          children: [
            // Dashed border (only when isDashed is true)
            if (spec.isDashed)
              Positioned.fill(
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: spec.borderColor,
                    strokeWidth: spec.borderWidth,
                    borderRadius: BorderRadius.all(Radius.circular(tokens.radius.r10)),
                  ),
                ),
              ),

            // Main input container
            Container(
              decoration: BoxDecoration(
                color: spec.backgroundColor,
                border: spec.isDashed
                    ? null
                    : Border.all(
                        color: spec.borderColor,
                        width: spec.borderWidth,
                      ),
                borderRadius: BorderRadius.all(Radius.circular(tokens.radius.r10)),
              ),
              padding: resolvedPadding,
              child: Row(
                children: [
                  // Prefix slot
                  if (prefixSlot.hasContent) ...[
                    _buildSlotContent(
                      context: context,
                      slot: prefixSlot,
                      tokens: tokens,
                      spec: spec,
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],

                  // Child (the actual input field) with optional hint text overlay
                  Expanded(
                    child: DefaultTextStyle(
                      style: tokens.typography.body.copyWith(
                        color: spec.textColor,
                      ),
                      child: Stack(
                        children: [
                          if (hintText != null && hintText!.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                hintText!,
                                style: tokens.typography.body.copyWith(
                                  color: tokens.colors.fg3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          child,
                        ],
                      ),
                    ),
                  ),

                  // Error icon (appears if there are errors)
                  if (hasErrors) ...[
                    SizedBox(width: tokens.spacing.sp8),
                    Icon(
                      LayrzIcons.solarOutlineDangerTriangle,
                      size: 20,
                      color: tokens.colors.danger,
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],

                  // Shortcut badge (if provided and not hidden on mobile)
                  if (shortcutText != null &&
                      shortcutText!.isNotEmpty &&
                      !(hideShortcutOnMobile && _isMobile(context))) ...[
                    if (!hasErrors) SizedBox(width: tokens.spacing.sp8),
                    Text(
                      shortcutText!,
                      style: tokens.typography.label.copyWith(
                        color: tokens.colors.fg3,
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],

                  // Suffix slot (coexists with error icon if present)
                  if (suffixSlot.hasContent) ...[
                    if (!hasErrors) SizedBox(width: tokens.spacing.sp8),
                    _buildSlotContent(
                      context: context,
                      slot: suffixSlot,
                      tokens: tokens,
                      spec: spec,
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],

                  // Lock icon (only for read-only, never for disabled)
                  if (readOnly && !disabled) ...[
                    SizedBox(width: tokens.spacing.sp8),
                    Icon(
                      LayrzIcons.solarOutlineLockKeyhole,
                      size: 20,
                      color: spec.textColor,
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],

                  // Help affordance (if helpContentText is provided)
                  if (helpContentText != null && helpContentText!.isNotEmpty) ...[
                    SizedBox(width: tokens.spacing.sp8),
                    LayrzTooltip(
                      titleText: helpTitleText,
                      contentText: helpContentText,
                      child: Icon(
                        LayrzIcons.solarOutlineHelp,
                        size: 20,
                        color: tokens.colors.fg3,
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],
                ],
              ),
            ),
          ],
        ),

        // Error block
        LayrzInputErrorBlock(
          errors: errors,
          hideDetails: hideDetails,
        ),
      ],
    );
  }

  /// Builds the content of a slot (icon, widget, or text).
  Widget _buildSlotContent({
    required BuildContext context,
    required dynamic slot,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
  }) {
    final isPrefix = slot is LayrzInputPrefixSlot;
    final hasCallback = isPrefix ? slot.onTap != null : slot.onTap != null;

    Widget content;
    if (slot.icon != null) {
      content = Icon(
        slot.icon!,
        size: 20,
        color: spec.textColor,
      );
    } else if (slot.widget != null) {
      content = slot.widget!;
    } else if (slot.text != null) {
      content = Text(
        slot.text!,
        style: tokens.typography.body.copyWith(
          color: spec.textColor,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    if (!hasCallback || disabled) {
      return content;
    }

    return GestureDetector(
      onTap: disabled ? null : slot.onTap,
      child: content,
    );
  }

  /// Checks if the platform is mobile.
  bool _isMobile(BuildContext context) {
    return LayrzPlatform.isMobile;
  }
}
