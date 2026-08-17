import 'package:flutter/widgets.dart';
import 'package:layrz_ui/extensions.dart';

/// A labelled tile used to display a color or radius sample.
///
/// Displays a filled square or box with a given color/decoration and a label
/// below showing the token name and optional value. Text color automatically
/// adapts for contrast readability.
class ShowroomSwatch extends StatelessWidget {
  /// Creates a new [ShowroomSwatch].
  ///
  /// Either [color] or [decoration] must be provided, but not both.
  /// The tile size is controlled by the parent (typically a [Wrap] with spacing).
  ///
  /// The [label] is the token name (e.g., 'primary', 'r8'). The optional [value]
  /// is displayed on a second line (e.g., hex code, pixel value).
  const ShowroomSwatch({required this.label, this.color, this.decoration, this.value, super.key})
    : assert(
        (color != null && decoration == null) || (color == null && decoration != null),
        'Either color or decoration must be provided, but not both',
      );

  /// The token name label (e.g., 'primary', 'r12').
  final String label;

  /// The color to display in the swatch (if not using decoration).
  final Color? color;

  /// A custom [BoxDecoration] for the swatch (if not using a simple color).
  final BoxDecoration? decoration;

  /// Optional secondary label (e.g., hex code, pixel value).
  final String? value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Determine the fill color for text contrast calculation
    final fillColor = color ?? decoration?.color ?? tokens.colors.surface;

    // Auto-select text color based on contrast
    final textColor = fillColor.contrastColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swatch tile
        Container(
          width: 80,
          height: 80,
          decoration: decoration ?? BoxDecoration(color: color, borderRadius: BorderRadius.circular(tokens.radius.r8)),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: tokens.typography.label.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),

        // Label and value
        SizedBox(height: tokens.spacing.sp8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: tokens.typography.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (value != null) ...[
          SizedBox(height: tokens.spacing.sp4),
          Text(
            value!,
            textAlign: TextAlign.center,
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
