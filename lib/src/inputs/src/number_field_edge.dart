import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Internal widget that renders the decrement control and optional prefix content for [LayrzNumberInput].
///
/// Composes the decrement button (−), a vertical divider, and the caller's prefix widget
/// into a single prefix slot. This widget handles the layout and interaction states for
/// the leading edge of the number field.
///
/// The decrement button is flat, glyph-only, and disabled when the field is at minimum,
/// read-only, or disabled. The divider is hairline width and uses the divider token color.
/// When prefix is null, only the control and divider are rendered.
class NumberFieldLeadingEdge extends StatelessWidget {
  /// Callback fired when the decrement button is tapped.
  ///
  /// Ignored if the button is disabled.
  final VoidCallback? onDecrement;

  /// Whether the decrement button should be disabled.
  final bool isDecrementDisabled;

  /// The optional prefix widget (e.g., "$" for currency).
  ///
  /// When null, only the control and divider are shown.
  final Widget? prefix;

  /// Callback fired when the prefix is tapped.
  ///
  /// Ignored if the field is disabled or if there is no prefix.
  final VoidCallback? onPrefixTap;

  /// Creates a new [NumberFieldLeadingEdge].
  const NumberFieldLeadingEdge({
    super.key,
    this.onDecrement,
    required this.isDecrementDisabled,
    this.prefix,
    this.onPrefixTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Wrap prefix with tap handler if provided and onPrefixTap is set
    final prefixWidget = prefix != null && onPrefixTap != null
        ? GestureDetector(
            onTap: onPrefixTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: prefix,
            ),
          )
        : prefix;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Decrement button (−)
        _DecrementButton(
          onTap: isDecrementDisabled ? null : onDecrement,
          isDisabled: isDecrementDisabled,
        ),

        // Divider between control and prefix/value
        _FieldDivider(tokens: tokens),

        // Optional prefix content
        if (prefixWidget != null) ...[prefixWidget],
      ],
    );
  }
}

/// Internal widget that renders the increment control and optional suffix content for [LayrzNumberInput].
///
/// Composes the caller's suffix widget, a vertical divider, and the increment button (+)
/// into a single suffix slot. This widget handles the layout and interaction states for
/// the trailing edge of the number field.
///
/// The increment button is flat, glyph-only, and disabled when the field is at maximum,
/// read-only, or disabled. The divider is hairline width and uses the divider token color.
/// When suffix is null, only the divider and control are rendered.
class NumberFieldTrailingEdge extends StatelessWidget {
  /// The optional suffix widget (e.g., "%" for percentage).
  ///
  /// When null, only the divider and control are shown.
  final Widget? suffix;

  /// Callback fired when the increment button is tapped.
  ///
  /// Ignored if the button is disabled.
  final VoidCallback? onIncrement;

  /// Whether the increment button should be disabled.
  final bool isIncrementDisabled;

  /// Callback fired when the suffix is tapped.
  ///
  /// Ignored if the field is disabled or if there is no suffix.
  final VoidCallback? onSuffixTap;

  /// Creates a new [NumberFieldTrailingEdge].
  const NumberFieldTrailingEdge({
    super.key,
    this.suffix,
    this.onIncrement,
    required this.isIncrementDisabled,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Wrap suffix with tap handler if provided and onSuffixTap is set
    final suffixWidget = suffix != null && onSuffixTap != null
        ? GestureDetector(
            onTap: onSuffixTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: suffix,
            ),
          )
        : suffix;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional suffix content
        if (suffixWidget != null) ...[suffixWidget],

        // Divider between value/suffix and control
        _FieldDivider(tokens: tokens),

        // Increment button (+)
        _IncrementButton(
          onTap: isIncrementDisabled ? null : onIncrement,
          isDisabled: isIncrementDisabled,
        ),
      ],
    );
  }
}

/// Flat decrement button for use inside [NumberFieldLeadingEdge].
///
/// Renders the glyph "−" as a tap target. When disabled, renders muted.
/// State changes affect color and cursor only per decision D15.
class _DecrementButton extends StatefulWidget {
  /// Callback fired when tapped (ignored if disabled).
  final VoidCallback? onTap;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// Creates a new [_DecrementButton].
  const _DecrementButton({
    this.onTap,
    required this.isDisabled,
  });

  @override
  State<_DecrementButton> createState() => _DecrementButtonState();
}

class _DecrementButtonState extends State<_DecrementButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Glyph color logic: disabled → fg4, hovered/pressed → primary, default → fg1
    Color getGlyphColor() {
      if (widget.isDisabled) {
        return tokens.colors.fg4;
      }
      if (_isPressed || _isHovered) {
        return tokens.colors.primary;
      }
      return tokens.colors.fg1;
    }

    // Background fill logic: disabled/rest → transparent, hovered → sf3, pressed → sf4
    Color getBackgroundColor() {
      if (widget.isDisabled) {
        return Color.fromARGB(0, 0, 0, 0);
      }
      if (_isPressed) {
        return tokens.colors.sf4;
      }
      if (_isHovered) {
        return tokens.colors.sf3;
      }
      return Color.fromARGB(0, 0, 0, 0);
    }

    final glyphColor = getGlyphColor();
    final backgroundColor = getBackgroundColor();

    return Semantics(
      label: 'Decrement',
      enabled: !widget.isDisabled,
      onTap: widget.isDisabled ? null : widget.onTap,
      child: MouseRegion(
        onEnter: widget.isDisabled ? null : (_) => setState(() => _isHovered = true),
        onExit: widget.isDisabled ? null : (_) => setState(() => _isHovered = false),
        cursor: widget.isDisabled ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 / 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(tokens.radius.r5),
                bottomLeft: Radius.circular(tokens.radius.r5),
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '−',
                style: tokens.typography.body.copyWith(
                  color: glyphColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat increment button for use inside [NumberFieldTrailingEdge].
///
/// Renders the glyph "+" as a tap target. When disabled, renders muted.
/// State changes affect color and cursor only per decision D15.
class _IncrementButton extends StatefulWidget {
  /// Callback fired when tapped (ignored if disabled).
  final VoidCallback? onTap;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// Creates a new [_IncrementButton].
  const _IncrementButton({
    this.onTap,
    required this.isDisabled,
  });

  @override
  State<_IncrementButton> createState() => _IncrementButtonState();
}

class _IncrementButtonState extends State<_IncrementButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Glyph color logic: disabled → fg4, hovered/pressed → primary, default → fg1
    Color getGlyphColor() {
      if (widget.isDisabled) {
        return tokens.colors.fg4;
      }
      if (_isPressed || _isHovered) {
        return tokens.colors.primary;
      }
      return tokens.colors.fg1;
    }

    // Background fill logic: disabled/rest → transparent, hovered → sf3, pressed → sf4
    Color getBackgroundColor() {
      if (widget.isDisabled) {
        return Color.fromARGB(0, 0, 0, 0);
      }
      if (_isPressed) {
        return tokens.colors.sf4;
      }
      if (_isHovered) {
        return tokens.colors.sf3;
      }
      return Color.fromARGB(0, 0, 0, 0);
    }

    final glyphColor = getGlyphColor();
    final backgroundColor = getBackgroundColor();

    return Semantics(
      label: 'Increment',
      enabled: !widget.isDisabled,
      onTap: widget.isDisabled ? null : widget.onTap,
      child: MouseRegion(
        onEnter: widget.isDisabled ? null : (_) => setState(() => _isHovered = true),
        onExit: widget.isDisabled ? null : (_) => setState(() => _isHovered = false),
        cursor: widget.isDisabled ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 / 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(tokens.radius.r5),
                bottomRight: Radius.circular(tokens.radius.r5),
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '+',
                style: tokens.typography.body.copyWith(
                  color: glyphColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hairline vertical divider used in number field edges.
///
/// Renders as a thin line using the divider token color.
class _FieldDivider extends StatelessWidget {
  /// The tokens for styling.
  final LayrzTokens tokens;

  /// Creates a new [_FieldDivider].
  const _FieldDivider({
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tokens.border.stroke1,
      child: ColoredBox(
        color: tokens.colors.divider,
      ),
    );
  }
}
