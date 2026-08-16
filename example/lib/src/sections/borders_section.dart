import 'package:flutter/widgets.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tokens.dart';

import '../common/showroom_section.dart';

/// Displays all border and stroke width tokens as visually distinct examples.
///
/// Shows the pre-built [BorderSide] objects (light, normal, thick) and the
/// base stroke width, each applied to a visible container so the stroke width
/// can be clearly compared.
Widget buildBordersSection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Borders & Strokes',
        description: 'Pre-built BorderSide tokens with consistent divider color',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pre-built border sides
            Text('Pre-Built BorderSide Tokens', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            Row(
              children: [
                Expanded(
                  child: _BorderSample(label: 'light', side: tokens.border.light),
                ),
                SizedBox(width: tokens.spacing.sp16),
                Expanded(
                  child: _BorderSample(label: 'normal', side: tokens.border.normal),
                ),
                SizedBox(width: tokens.spacing.sp16),
                Expanded(
                  child: _BorderSample(label: 'thick', side: tokens.border.thick),
                ),
              ],
            ),

            SizedBox(height: tokens.spacing.sp24),

            // Stroke width values
            Text('Stroke Width Values', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            Column(
              children: [
                _StrokeValueRow(label: 'base', width: tokens.border.base, tokens: tokens),
                SizedBox(height: tokens.spacing.sp12),
                _StrokeValueRow(label: 'stroke1', width: tokens.border.stroke1, tokens: tokens),
                SizedBox(height: tokens.spacing.sp12),
                _StrokeValueRow(label: 'stroke2', width: tokens.border.stroke2, tokens: tokens),
                SizedBox(height: tokens.spacing.sp12),
                _StrokeValueRow(label: 'stroke3', width: tokens.border.stroke3, tokens: tokens),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// A sample demonstrating a [BorderSide] with visual container.
class _BorderSample extends StatelessWidget {
  /// Creates a new [_BorderSample].
  const _BorderSample({required this.label, required this.side});

  /// The label for the border (e.g., 'light', 'normal').
  final String label;

  /// The [BorderSide] to demonstrate.
  final BorderSide side;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
        SizedBox(height: tokens.spacing.sp8),
        Container(
          height: tokens.spacing.sp48,
          decoration: BoxDecoration(
            color: tokens.colors.surface,
            border: Border(bottom: side),
          ),
        ),
        SizedBox(height: tokens.spacing.sp8),
        Text('${side.width} px', style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3, fontSize: 11)),
      ],
    );
  }
}

/// A row demonstrating a stroke width value with a horizontal line.
class _StrokeValueRow extends StatelessWidget {
  /// Creates a new [_StrokeValueRow].
  const _StrokeValueRow({required this.label, required this.width, required this.tokens});

  /// The label for the stroke value.
  final String label;

  /// The stroke width in pixels.
  final double width;

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: tokens.spacing.sp48,
          child: Text(label, style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
        ),
        Expanded(
          child: Container(height: width, color: tokens.colors.divider),
        ),
        SizedBox(width: tokens.spacing.sp8),
        SizedBox(
          width: tokens.spacing.sp48,
          child: Text(
            '${width.toStringAsFixed(1)} px',
            textAlign: TextAlign.right,
            style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3),
          ),
        ),
      ],
    );
  }
}
