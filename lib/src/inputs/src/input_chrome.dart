import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'input_density.dart';
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

  /// Maximum length of the input text.
  ///
  /// If provided, a character counter is displayed below the field.
  final int? maxLength;

  /// Creates a new [LayrzInputChrome] with the given properties.
  const LayrzInputChrome({
    super.key,
    required this.labelText,
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
    this.maxLength,
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

    // Centralized density specification — all dimensions that change with dense mode
    final density = InputDensitySpec(
      dense: dense,
      tokens: tokens,
      iconTheme: context.theme.iconTheme,
    );

    // Compute padding: explicit caller value wins over dense mode
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp10,
          vertical: density.verticalPadding,
        );

    // Fixed content height to ensure field geometry is constant across states,
    // regardless of whether slots have icons. Icons fit inside this height.
    final contentHeight = density.iconSize;

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
                    iconSize: density.iconSize,
                    density: density,
                  ),
                  SizedBox(width: tokens.spacing.sp8),
                ],

                // Child (the actual input field) with optional hint text overlay
                Expanded(
                  child: DefaultTextStyle(
                    style: density.textStyle.copyWith(
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
                                      style: density.textStyle.copyWith(
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
                              style: density.textStyle.copyWith(
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

                // Canonical order: shortcut → suffix → lock → help → error (error always last)
                ..._buildTrailingElements(
                  context: context,
                  tokens: tokens,
                  spec: spec,
                  contentHeight: contentHeight,
                  iconSize: density.iconSize,
                  density: density,
                ),
              ],
            ),
          ),
        ),

        // Error block and character counter
        LayrzInputErrorBlock(
          errors: errors,
          hideDetails: hideDetails,
          maxLength: maxLength,
          controller: controller,
        ),
      ],
    );
  }

  /// Builds the trailing elements in a fixed, canonical order.
  ///
  /// **Trailing cluster order (left to right)**:
  /// `[ shortcut badge ] [ suffix{icon|widget|text} ] [ lock icon ] [ help icon ] [ error icon ]`
  ///
  /// Rationale: the shortcut badge is a passive affordance so it sits furthest left; the caller's
  /// suffix comes next; then the state and meta icons group at the right, with the error icon
  /// unconditionally last so the user's eye always finds it in the same place.
  ///
  /// All elements are conditional; this method appends in this exact sequence. Every icon in the
  /// cluster uses the provided [iconSize] for visual consistency.
  ///
  /// Returns a list that is empty if no trailing elements are present, or a list containing
  /// an inner gap spacer followed by a Row that collects all trailing widgets with
  /// inter-element spacing (but no outer spacers).
  List<Widget> _buildTrailingElements({
    required BuildContext context,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required double contentHeight,
    required double iconSize,
    required InputDensitySpec density,
  }) {
    final trailing = <Widget>[];

    // Canonical order: shortcut → suffix → lock → help → error (error always last)

    // Shortcut badge (leftmost, passive affordance)
    // Hidden on mobile platforms if hideShortcutOnMobile is true
    if (shortcutText != null && shortcutText!.isNotEmpty && !(hideShortcutOnMobile && LayrzPlatform.isMobile)) {
      trailing.add(
        Text(
          shortcutText!,
          style: tokens.typography.label.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      );
    }

    // Suffix slot (after shortcut)
    if (suffixSlot.hasContent) {
      trailing.add(
        _buildSlotContent(
          context: context,
          slot: suffixSlot,
          tokens: tokens,
          spec: spec,
          contentHeight: contentHeight,
          iconSize: iconSize,
          density: density,
        ),
      );
    }

    // Lock icon (read-only state icon)
    if (readOnly && !disabled) {
      trailing.add(
        Icon(
          LayrzIcons.solarOutlineLockKeyhole,
          size: iconSize,
          color: spec.textColor,
        ),
      );
    }

    // Help affordance (meta icon) with help cursor and hover feedback
    if (helpContentText != null && helpContentText!.isNotEmpty) {
      trailing.add(
        _HelpAffordance(
          titleText: helpTitleText,
          contentText: helpContentText,
          iconSize: iconSize,
          iconColor: tokens.colors.fg3,
        ),
      );
    }

    // Error icon (always last/rightmost — error state is critical)
    if (errors.isNotEmpty) {
      trailing.add(
        Icon(
          LayrzIcons.solarOutlineDangerTriangle,
          size: iconSize,
          color: tokens.colors.danger,
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
  ///
  /// When [slot.onTap] is non-null and the field is not disabled, wraps the content
  /// in a [MouseRegion] with [SystemMouseCursors.click] cursor and hover/press opacity
  /// feedback (following D15: state changes only affect colour, opacity, shadow, cursor;
  /// never size, padding, margin, or scale).
  Widget _buildSlotContent({
    required BuildContext context,
    required dynamic slot,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required double contentHeight,
    required double iconSize,
    required InputDensitySpec density,
  }) {
    final hasCallback = slot.onTap != null;

    Widget content;
    if (slot.icon != null) {
      content = Icon(
        slot.icon!,
        size: iconSize,
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
        style: density.textStyle.copyWith(
          color: spec.textColor,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    if (!hasCallback || disabled) {
      return content;
    }

    // Tappable slot: wrap with cursor and press feedback (opacity only, per D15)
    return _buildTappableSlot(
      onTap: slot.onTap,
      child: content,
    );
  }

  /// Wraps a tappable slot with cursor feedback and press-state opacity change.
  ///
  /// Provides [SystemMouseCursors.click] cursor to indicate interactivity and
  /// opacity feedback on press (no size/padding changes per D15).
  Widget _buildTappableSlot({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return _TappableSlotWidget(
      onTap: onTap,
      child: child,
    );
  }
}

/// Stateful wrapper for a tappable slot that provides cursor and press-state feedback.
///
/// Combines [MouseRegion] (for cursor), [Listener] (for press detection),
/// and [GestureDetector] (for tap handling) with opacity feedback.
class _TappableSlotWidget extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TappableSlotWidget({
    required this.onTap,
    required this.child,
  });

  @override
  State<_TappableSlotWidget> createState() => _TappableSlotWidgetState();
}

class _TappableSlotWidgetState extends State<_TappableSlotWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onPointerUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onPointerCancel: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Opacity(
            opacity: _isPressed ? 0.7 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Stateful wrapper for the help affordance that shows a help tooltip with cursor feedback.
///
/// Provides [SystemMouseCursors.help] (the `?` cursor) to indicate help information,
/// and opacity feedback on hover/press (no size/padding changes per D15).
class _HelpAffordance extends StatefulWidget {
  final String? titleText;
  final String? contentText;
  final double iconSize;
  final Color iconColor;

  const _HelpAffordance({
    required this.titleText,
    required this.contentText,
    required this.iconSize,
    required this.iconColor,
  });

  @override
  State<_HelpAffordance> createState() => _HelpAffordanceState();
}

class _HelpAffordanceState extends State<_HelpAffordance> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.help,
      child: Listener(
        onPointerDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onPointerUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onPointerCancel: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        child: LayrzTooltip(
          titleText: widget.titleText,
          contentText: widget.contentText,
          child: Opacity(
            opacity: _isPressed ? 0.7 : 1.0,
            child: Icon(
              LayrzIcons.solarOutlineHelp,
              size: widget.iconSize,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
