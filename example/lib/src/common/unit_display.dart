import 'package:flutter/widgets.dart';
import 'package:layrz_ui/extensions.dart';

/// A widget that displays design values in logical units with a hover tooltip showing physical pixels.
///
/// Renders a value as logical units (e.g., `16u`). On desktop hover, reveals the physical-pixel
/// equivalent for the current display (e.g., `16u = 32px @ 2.0x`). Automatically computes the
/// physical pixel count from [MediaQuery.devicePixelRatioOf].
///
/// The logical unit value is formatted to remove trailing `.0`, so 16.0 displays as `16u` rather
/// than `16.0u`. The physical pixel value is rounded to one decimal place for clarity.
class UnitDisplay extends StatefulWidget {
  /// Creates a new [UnitDisplay].
  ///
  /// The [value] is the logical pixel dimension to display. The [textStyle] parameter is optional;
  /// if not provided, the widget uses the current [BuildContext]'s token typography for label styling.
  const UnitDisplay({
    required this.value,
    this.textStyle,
    super.key,
  });

  /// The logical pixel value to display (e.g., 16, 8, 1904).
  final double value;

  /// Optional text style to apply to the display text.
  ///
  /// If not provided, the widget derives the style from context tokens.
  final TextStyle? textStyle;

  @override
  State<UnitDisplay> createState() => _UnitDisplayState();
}

class _UnitDisplayState extends State<UnitDisplay> {
  bool _isHovering = false;

  /// Formats a logical unit value for display, removing trailing `.0`.
  ///
  /// Examples: 16.0 → `16u`, 14.5 → `14.5u`.
  String _formatLogicalUnit(double value) {
    final str = value.toStringAsFixed(0);
    return '${str}u';
  }

  /// Formats a physical pixel value with one decimal place, removing trailing zeros.
  ///
  /// Examples: 32.0 → `32px`, 32.5 → `32.5px`, 32.123 → `32.1px`.
  String _formatPhysicalPixel(double value) {
    final str = value.toStringAsFixed(1);
    // Remove trailing .0 if present
    if (str.endsWith('.0')) {
      return '${str.substring(0, str.length - 2)}px';
    }
    return '${str}px';
  }

  /// Builds a tooltip showing the physical pixel equivalent of the logical unit value.
  Widget _buildTooltip(BuildContext context, String message) {
    final tokens = context.tokens;
    const tooltipPadding = 12.0;
    const tooltipRadius = 8.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: tooltipPadding,
        vertical: tooltipPadding / 2,
      ),
      decoration: BoxDecoration(
        color: tokens.colors.fg1,
        borderRadius: BorderRadius.circular(tooltipRadius),
      ),
      child: Text(
        message,
        style: tokens.typography.labelSmall.copyWith(
          color: tokens.colors.background,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final physicalPixels = widget.value * ratio;
    final logicalDisplay = _formatLogicalUnit(widget.value);
    final physicalDisplay = _formatPhysicalPixel(physicalPixels);
    final tooltipMessage = '$logicalDisplay = $physicalDisplay @ ${ratio.toStringAsFixed(1)}x';

    final textStyle = widget.textStyle ?? tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
      },
      onExit: (_) {
        setState(() => _isHovering = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(
            logicalDisplay,
            style: textStyle,
          ),
          if (_isHovering)
            Positioned(
              bottom: 24,
              left: 0,
              child: _buildTooltip(context, tooltipMessage),
            ),
        ],
      ),
    );
  }
}
