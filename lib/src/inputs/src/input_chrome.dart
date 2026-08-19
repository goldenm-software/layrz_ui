import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

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

  /// The text editing controller for listening to text changes.
  ///
  /// Required for hint text visibility logic (hint visible only when field is empty).
  /// If null, the hint text is always shown when [hintText] is non-null.
  final TextEditingController? controller;

  /// The padding applied inside the input field.
  ///
  /// If provided, this padding is used as-is and [dense] is ignored.
  /// If null, padding is derived from tokens: sp10 horizontal and sp10 vertical when normal,
  /// or sp10 horizontal with sp6 vertical when [dense] is true.
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
    this.controller,
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
    final verticalPadding = dense ? tokens.spacing.sp6 : tokens.spacing.sp10;
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp10,
          vertical: verticalPadding,
        );

    // Fixed content height to ensure field geometry is constant across states,
    // regardless of whether slots have icons. Icons fit inside this height.
    // Falls back to icon theme size from context, or a token-derived default.
    final contentHeight =
        context.theme.iconTheme.size ??
        (tokens.typography.body.fontSize ?? 16.0) + tokens.spacing.sp4;

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
        Container(
          decoration: BoxDecoration(
            color: spec.backgroundColor,
            border: Border.all(
              color: spec.borderColor,
              width: spec.borderWidth,
            ),
            borderRadius: BorderRadius.all(Radius.circular(tokens.radius.r10)),
          ),
          padding: resolvedPadding,
          child: SizedBox(
            height: contentHeight,
            child: Row(
              children: [
                  // Prefix slot
                  if (prefixSlot.hasContent) ...[
                    _buildSlotContent(
                      context: context,
                      slot: prefixSlot,
                      tokens: tokens,
                      spec: spec,
                      contentHeight: contentHeight,
                    ),
                    SizedBox(width: tokens.spacing.sp8),
                  ],

                  // Child (the actual input field) with optional hint text overlay
                  Expanded(
                    child: DefaultTextStyle(
                      style: tokens.typography.body.copyWith(
                        fontSize: tokens.typography.title.fontSize,
                        color: spec.textColor,
                      ),
                      child: Stack(
                        children: [
                          if (hintText != null && hintText!.isNotEmpty && controller != null)
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: controller!,
                              builder: (context, value, _) => value.text.isEmpty
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        hintText!,
                                        style: tokens.typography.body.copyWith(
                                          fontSize: tokens.typography.title.fontSize,
                                          color: tokens.colors.fg3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            )
                          else if (hintText != null && hintText!.isNotEmpty && controller == null)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                hintText!,
                                style: tokens.typography.body.copyWith(
                                  fontSize: tokens.typography.title.fontSize,
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

                  // Trailing elements: error icon, shortcut, suffix, lock icon, help icon
                  ..._buildTrailingElements(
                    context: context,
                    tokens: tokens,
                    spec: spec,
                    contentHeight: contentHeight,
                  ),
              ],
            ),
            ),
          ),

        // Error block
        LayrzInputErrorBlock(
          errors: errors,
          hideDetails: hideDetails,
        ),
      ],
    );
  }

  /// Builds the trailing elements (error icon, shortcut, suffix, lock, help) with symmetric spacing.
  ///
  /// Returns a list that is empty if no trailing elements are present, or a list containing
  /// an inner gap spacer followed by a Row that collects all trailing widgets with
  /// inter-element spacing (but no outer spacers).
  List<Widget> _buildTrailingElements({
    required BuildContext context,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required double contentHeight,
  }) {
    final trailing = <Widget>[];
    final iconSize = context.theme.iconTheme.size ?? 20.0;

    // Error icon
    if (errors.isNotEmpty) {
      trailing.add(
        Icon(
          LayrzIcons.solarOutlineDangerTriangle,
          size: iconSize,
          color: tokens.colors.danger,
        ),
      );
    }

    // Shortcut badge
    if (shortcutText != null && shortcutText!.isNotEmpty && !(hideShortcutOnMobile && _isMobile(context))) {
      trailing.add(
        Text(
          shortcutText!,
          style: tokens.typography.label.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      );
    }

    // Suffix slot
    if (suffixSlot.hasContent) {
      trailing.add(
        _buildSlotContent(
          context: context,
          slot: suffixSlot,
          tokens: tokens,
          spec: spec,
          contentHeight: contentHeight,
        ),
      );
    }

    // Lock icon
    if (readOnly && !disabled) {
      trailing.add(
        Icon(
          LayrzIcons.solarOutlineLockKeyhole,
          size: iconSize,
          color: spec.textColor,
        ),
      );
    }

    // Help affordance
    if (helpContentText != null && helpContentText!.isNotEmpty) {
      trailing.add(
        LayrzTooltip(
          titleText: helpTitleText,
          contentText: helpContentText,
          child: Icon(
            LayrzIcons.solarOutlineHelp,
            size: iconSize,
            color: tokens.colors.fg3,
          ),
        ),
      );
    }

    // If no trailing elements, return empty list
    if (trailing.isEmpty) {
      return [];
    }

    // Return inner gap + row of trailing elements with inter-element spacing
    return [
      SizedBox(width: tokens.spacing.sp8),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.spacing.sp8,
        children: trailing,
      ),
    ];
  }

  /// Builds the content of a slot (icon, widget, or text).
  ///
  /// Caller-supplied widgets are constrained to [contentHeight] to prevent them
  /// from changing field geometry. This ensures consistent height across all states.
  Widget _buildSlotContent({
    required BuildContext context,
    required dynamic slot,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required double contentHeight,
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
      // Constrain caller-supplied widget to content height to prevent layout changes
      content = SizedBox(
        height: contentHeight,
        child: slot.widget,
      );
    } else if (slot.text != null) {
      content = Text(
        slot.text!,
        style: tokens.typography.body.copyWith(
          fontSize: tokens.typography.title.fontSize,
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
