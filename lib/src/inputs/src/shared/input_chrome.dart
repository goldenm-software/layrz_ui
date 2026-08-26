import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'input_footer_slot.dart';
import 'input_slot.dart';
import 'input_style_spec.dart';

/// Comfortable (normal) density specification for input fields.
///
/// Encapsulates all dimensions that define the comfortable density mode:
/// padding (10px regular / 14px compact on all sides, or 6px regular / 10px
/// compact when [dense] is true), icon size (fontSize + 6px), text style
/// (body), and content height that accommodates both icons and text.
///
/// Padding and icon size scale on compact viewports (width < 960px) to improve touch targets:
/// - Padding: pd2 (10px) → pd3 (14px), or pd1 (6px) → pd2 (10px) when [dense]
/// - Icon size: grows proportionally with text content
/// - Text style remains body (16px) in both regular and compact viewports
///
/// This ensures input fields on mobile/narrow tablets have larger touch targets comparable
/// to button sizing (see DESIGN-103 for button compact sizing strategy).
class _InputComfortableSpec {
  final LayrzTokens tokens;
  final IconThemeData? iconTheme;
  final bool isCompact;
  final bool dense;

  _InputComfortableSpec(this.tokens, this.iconTheme, {required this.isCompact, required this.dense});

  /// The padding applied to all sides inside the input field.
  ///
  /// Returns 10px (pd2) on regular viewports and 14px (pd3) on compact viewports
  /// (width < 960px) to ensure adequate touch targets on mobile. When [dense] is
  /// true, each of those drops one spacing level: 6px (pd1) regular, 10px (pd2)
  /// compact.
  EdgeInsets get padding => dense
      ? (isCompact ? tokens.spacing.pd2 : tokens.spacing.pd1)
      : (isCompact ? tokens.spacing.pd3 : tokens.spacing.pd2);

  /// The size of icons in slots and state indicators.
  ///
  /// Scales proportionally with the text content. On compact viewports, if the font
  /// grows, the icon grows with it. Currently, since font stays at body (16px),
  /// icon size is 16 + 6 = 22px in both regular and compact viewports.
  double get iconSize => iconTheme?.size ?? (tokens.typography.body.fontSize ?? 16.0) + tokens.spacing.sp1;

  /// The text style for input hints and slot text.
  ///
  /// Always body (16px) in both regular and compact viewports. This is the largest
  /// sensible size for body text in an input field; title (20px) would be unusual.
  TextStyle get textStyle => tokens.typography.body;

  /// The text style for the editable value itself (EditableText.style).
  ///
  /// Always body (16px) in both regular and compact viewports.
  TextStyle get editableTextStyle => tokens.typography.body;

  /// The minimum content height to accommodate both icons and text without clipping.
  ///
  /// This is the maximum of [iconSize] and the text line height computed from [editableTextStyle].
  /// Content height is constant across interaction states per D15 (geometry invariance).
  double get contentHeight {
    final fontSize = editableTextStyle.fontSize ?? 16.0;
    final lineHeightMultiplier = editableTextStyle.height ?? 1.0;
    final textLineHeight = fontSize * lineHeightMultiplier;
    return textLineHeight > iconSize ? textLineHeight : iconSize;
  }
}

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

  /// Whether the field uses the dense density variant.
  ///
  /// When false (default), the internal padding is `tokens.spacing.pd3` (14px)
  /// on compact viewports and `tokens.spacing.pd2` (10px) on regular viewports.
  /// When true, each of those drops one spacing level: `tokens.spacing.pd2`
  /// (10px) on compact viewports and `tokens.spacing.pd1` (6px) on regular
  /// viewports. No other dimension (height, label sizing, typography, error
  /// block spacing) changes with this flag.
  final bool dense;

  /// Maximum length of the input text.
  ///
  /// If provided, a character counter is displayed below the field.
  final int? maxLength;

  /// Helper text displayed below the field.
  ///
  /// When [errors] is non-empty, errors take precedence and helper text is hidden.
  final String? helperText;

  /// Library-private: Whether the content box should expand with content (multiline).
  ///
  /// When false (default), the content box has a fixed height equal to a single line.
  /// When true, the content box grows vertically with the content, up to [_maxContentHeight].
  final bool _expandHeight;

  /// Library-private: Minimum height for the content box in expanded mode.
  ///
  /// Used only when [_expandHeight] is true. Defaults to the single-line height.
  final double? _minContentHeight;

  /// Library-private: Maximum height for the content box in expanded mode.
  ///
  /// Used only when [_expandHeight] is true. When the content exceeds this height,
  /// scrolling is enabled. If null, no maximum is enforced.
  final double? _maxContentHeight;

  /// Library-private: Whether to suppress the read-only lock icon.
  ///
  /// When true, the lock icon is not rendered even if [readOnly] is true.
  /// Used by picker-style inputs (select, multi-select, etc.) that want to be
  /// read-only but should display their own affordance (e.g., a dropdown chevron)
  /// instead of a lock icon.
  final bool _suppressReadOnlyLock;

  /// Optional border radius override for the input container.
  ///
  /// When null (default), the container uses the token radius from [LayrzTokens.radius.r2].
  /// When provided, applies the specified [BorderRadius] to the container's decoration.
  /// Used by composite inputs like [LayrzNumberInput] to render square corners when
  /// edge controls are present.
  final BorderRadius? borderRadius;

  /// Whether to display the border around the input container.
  ///
  /// When true (default), the container renders a border around the input field.
  /// When false, the border is not rendered; the caller is responsible for
  /// displaying a border elsewhere (e.g., in a composite control wrapper).
  /// The background fill and all other styling remains unchanged.
  final bool showBorder;

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
    this.dense = false,
    this.maxLength,
    this.helperText,
    bool expandHeight = false,
    double? minContentHeight,
    double? maxContentHeight,
    bool suppressReadOnlyLock = false,
    this.borderRadius,

    this.showBorder = true,
    // ignore: prefer_initializing_formals
  }) : _expandHeight = expandHeight,
       // ignore: prefer_initializing_formals
       _minContentHeight = minContentHeight,
       // ignore: prefer_initializing_formals
       _maxContentHeight = maxContentHeight,
       // ignore: prefer_initializing_formals
       _suppressReadOnlyLock = suppressReadOnlyLock;

  /// Library-private named constructor for variable-height content boxes (multiline use).
  ///
  /// Creates a chrome with content that grows vertically between [minContentHeight]
  /// and [maxContentHeight]. Intended for use by [LayrzTextAreaInput] and other
  /// multiline input widgets.
  const LayrzInputChrome.variableHeight({
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
    this.dense = false,
    this.maxLength,
    this.helperText,
    required double minContentHeight,
    double? maxContentHeight,
    bool suppressReadOnlyLock = false,
    this.borderRadius,

    this.showBorder = true,
    super.key,
    // ignore: prefer_initializing_formals
  }) : _expandHeight = true,
       // ignore: prefer_initializing_formals
       _minContentHeight = minContentHeight,
       // ignore: prefer_initializing_formals
       _maxContentHeight = maxContentHeight,
       // ignore: prefer_initializing_formals
       _suppressReadOnlyLock = suppressReadOnlyLock;

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

    // Comfortable density specification — all dimensions for field layout (responsive to viewport width)
    final density = _InputComfortableSpec(
      tokens,
      context.theme.iconTheme,
      isCompact: context.isCompact,
      dense: dense,
    );

    // Fixed content height to ensure field geometry is constant across states,
    // regardless of whether slots have icons. The height accommodates both
    // icons and the text line without clipping.
    final contentHeight = density.contentHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row (rendered when labelText is provided)
        if (labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
            child: ExcludeSemantics(
              child: SelectionContainer.disabled(
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
            ),
          ),

        // Input container with border
        Container(
          decoration: BoxDecoration(
            color: spec.backgroundColor,
            border: showBorder
                ? Border.all(
                    color: spec.borderColor,
                    width: spec.borderWidth,
                  )
                : null,
            borderRadius: borderRadius ?? tokens.radius.br2,
          ),
          padding: density.padding,
          child: _expandHeight
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: _minContentHeight ?? contentHeight,
                    maxHeight: _maxContentHeight ?? double.infinity,
                  ),
                  child: _buildRowContent(
                    context: context,
                    tokens: tokens,
                    spec: spec,
                    density: density,
                    contentHeight: contentHeight,
                    isMultiline: true,
                  ),
                )
              : SizedBox(
                  height: contentHeight,
                  child: _buildRowContent(
                    context: context,
                    tokens: tokens,
                    spec: spec,
                    density: density,
                    contentHeight: contentHeight,
                    isMultiline: false,
                  ),
                ),
        ),

        // Error block and character counter
        LayrzInputFooterSlot(
          errors: errors,
          hideDetails: hideDetails,
          maxLength: maxLength,
          controller: controller,
          helperText: helperText,
        ),
      ],
    );
  }

  /// Builds the Row containing prefix, child content, and trailing elements.
  ///
  /// This is extracted to avoid duplication between fixed-height and variable-height modes.
  /// The Row's [crossAxisAlignment] and hint/child alignments depend on whether the content
  /// box is multiline (variable-height) or single-line (fixed-height).
  ///
  /// In multiline mode ([isMultiline] = true):
  ///   - Hint and content align to the top-left so text starts at the top of the box
  ///   - Trailing elements align to the start of the Row (top)
  ///
  /// In single-line mode ([isMultiline] = false):
  ///   - Hint and content remain vertically centered
  ///   - Trailing elements align to the center of the Row
  Widget _buildRowContent({
    required BuildContext context,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required _InputComfortableSpec density,
    required double contentHeight,
    required bool isMultiline,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
          SizedBox(width: tokens.spacing.sp2),
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
                            alignment: isMultiline ? Alignment.topLeft : Alignment.centerLeft,
                            child: SelectionContainer.disabled(
                              child: Text(
                                hintText!,
                                style: density.textStyle.copyWith(
                                  color: tokens.colors.fg3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  )
                else if (hintText != null && hintText!.isNotEmpty && controller == null)
                  Align(
                    alignment: isMultiline ? Alignment.topLeft : Alignment.centerLeft,
                    child: SelectionContainer.disabled(
                      child: Text(
                        hintText!,
                        style: density.textStyle.copyWith(
                          color: tokens.colors.fg3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Align(
                  alignment: isMultiline ? Alignment.topCenter : Alignment.center,
                  child: child,
                ),
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
    required _InputComfortableSpec density,
  }) {
    final trailing = <Widget>[];

    // Canonical order: shortcut → suffix → lock → help → error (error always last)

    // Shortcut badge (leftmost, passive affordance)
    // Hidden on mobile platforms if hideShortcutOnMobile is true
    if (shortcutText != null && shortcutText!.isNotEmpty && !(hideShortcutOnMobile && LayrzPlatform.isMobile)) {
      trailing.add(
        Text(
          shortcutText!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    if (readOnly && !disabled && !_suppressReadOnlyLock) {
      trailing.add(
        Icon(
          MdiIcons.lockOutline,
          size: iconSize,
          color: tokens.colors.fg1,
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
          MdiIcons.alertOutline,
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
      SizedBox(width: tokens.spacing.sp2),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.spacing.sp2,
        children: trailing,
      ),
    ];
  }

  /// Builds the content of a slot (icon, widget, or text), and accounts for it in
  /// the semantics tree.
  ///
  /// Caller-supplied widgets are constrained to [contentHeight] to prevent them
  /// from changing field geometry. This ensures consistent height across all states.
  ///
  /// Per D64 ("name only when told"), every slot the chrome renders falls into one of
  /// four semantics categories — nothing is silent by accident:
  ///
  /// - **named**: [LayrzInputSlot.semanticLabel] is non-null. Gets its own
  ///   `Semantics(container: true, ...)` node, with `button: true` when also
  ///   interactive. `container: true` is mandatory here — the slot sits *inside* the
  ///   field's own `Semantics` ancestor (unlike `number_field_edge.dart`'s ± caps,
  ///   which sit outside it), so a bare `Semantics(button: true)` would be absorbed
  ///   into the field's node, making the text field itself announce as a button.
  /// - **decorative**: [LayrzInputSlot.isDecorative] is true, or the slot is a
  ///   non-interactive icon with no label (an `Icon` the chrome itself builds carries
  ///   no semantics of its own, so there is nothing to protect). Wrapped in
  ///   [ExcludeSemantics]. A non-interactive text slot is the one exception: its text
  ///   merges into the field's own accessible name by design (`'$'`, `'kg'`, `'@'`
  ///   belong there).
  /// - **pointer-only**: interactive ([LayrzInputSlot.onTap] non-null) but nobody
  ///   supplied a [LayrzInputSlot.semanticLabel]. Rendered and tappable, but
  ///   `excludeFromSemantics: true` on the underlying [GestureDetector] means it
  ///   contributes nothing to the semantics tree — the chrome does not infer or
  ///   invent a name the caller did not give it. See D64.
  /// - **the caller's own responsibility**: a non-interactive, unlabelled, non-decorative
  ///   *widget* slot is passed through untouched. The widget form is the one slot form
  ///   where the caller has a seam of their own — they may have already embedded a
  ///   `Semantics` node in what they passed to `prefix:`/`suffix:` (this is exactly what
  ///   the wiki's "pass a real, focusable, labelled control" contract depends on). The
  ///   chrome cannot see inside that subtree, so it must not guess "nothing there" and
  ///   silence it; only an explicit [LayrzInputSlot.isDecorative] authorizes exclusion.
  Widget _buildSlotContent({
    required BuildContext context,
    required LayrzInputSlot slot,
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required double contentHeight,
    required double iconSize,
    required _InputComfortableSpec density,
  }) {
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: density.textStyle.copyWith(
          color: spec.textColor,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    content = SelectionContainer.disabled(child: content);

    final isInteractive = slot.onTap != null && !disabled;

    if (isInteractive) {
      if (slot.semanticLabel != null) {
        // Named affordance: its own node, so its tap action never absorbs into the
        // field's. `container: true` is what creates that boundary — without it the
        // TEXT FIELD itself would announce as a button. See D64.
        return Semantics(
          container: true,
          button: true,
          enabled: true,
          label: slot.semanticLabel,
          child: _buildTappableSlot(onTap: slot.onTap!, child: content),
        );
      }
      // Pointer-only affordance: rendered and tappable, but contributes nothing to
      // the semantics tree. The chrome does not invent a name the caller did not
      // supply, and an anonymous tap action would otherwise merge onto the field's
      // own node. See D64.
      return _buildTappableSlot(
        onTap: slot.onTap!,
        excludeFromSemantics: true,
        child: content,
      );
    }

    if (slot.semanticLabel != null) {
      return Semantics(
        container: true, // ← MANDATORY. Without it the label is appended to the FIELD's name.
        label: slot.semanticLabel,
        child: content,
      );
    }

    // Text slots merge into the field's accessible name by design: '$', 'kg', '@'
    // belong in the field's name, not in a node of their own. See D64 / dossier §16.2.
    if (slot.text != null) {
      return content;
    }

    // Widget slots are the caller's own responsibility: the chrome did not build this
    // subtree and cannot see whether it already carries its own `Semantics` (e.g. a
    // focusable, labelled control passed per the wiki's documented contract). Passing
    // it through untouched is what makes that contract honourable -- excluding it here
    // would silence semantics the caller deliberately attached at their own call site.
    // Only an explicit `isDecorative: true` authorizes exclusion.
    if (slot.widget != null) {
      if (slot.isDecorative) {
        return ExcludeSemantics(child: content);
      }
      return content;
    }

    // Remaining case: an unnamed, non-interactive icon the chrome built itself. An
    // `Icon` carries no semantics of its own, so there is nothing to protect --
    // declared decorative and excluded, whether or not `isDecorative` was set. See D64.
    return ExcludeSemantics(child: content);
  }

  /// Wraps a tappable slot with cursor feedback and press-state opacity change.
  ///
  /// Provides [SystemMouseCursors.click] cursor to indicate interactivity and
  /// opacity feedback on press (no size/padding changes per D15).
  ///
  /// [excludeFromSemantics] is forwarded to the underlying [GestureDetector] — see
  /// [_TappableSlotWidget].
  Widget _buildTappableSlot({
    required VoidCallback onTap,
    required Widget child,
    bool excludeFromSemantics = false,
  }) {
    return _TappableSlotWidget(
      onTap: onTap,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

/// Stateful wrapper for a tappable slot that provides cursor and press-state feedback.
///
/// Combines [MouseRegion] (for cursor), [Listener] (for press detection),
/// and [GestureDetector] (for tap handling) with opacity feedback.
///
/// Deliberately owns no `Focus` and no `Semantics` of its own: per D64, `Semantics`
/// describes and `FocusNode` does, and this widget is purely visual. A named slot's
/// `Semantics` node is built by the caller (`_buildSlotContent`), sitting *above* this
/// widget, not inside it.
class _TappableSlotWidget extends StatefulWidget {
  /// Callback fired when the slot is tapped.
  final VoidCallback onTap;

  /// The content rendered inside the tappable area.
  final Widget child;

  /// Whether the underlying [GestureDetector] excludes itself (and its tap action)
  /// from the semantics tree.
  ///
  /// True for a pointer-only slot (interactive, no [LayrzInputSlot.semanticLabel]):
  /// the tap remains usable by touch/mouse but is not advertised to assistive
  /// technology, matching the house precedent at `tooltip.dart:555` and `:573`.
  final bool excludeFromSemantics;

  /// Creates a new [_TappableSlotWidget] with the given properties.
  const _TappableSlotWidget({
    required this.onTap,
    required this.child,
    this.excludeFromSemantics = false,
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
          excludeFromSemantics: widget.excludeFromSemantics,
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
              MdiIcons.helpCircleOutline,
              size: widget.iconSize,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
