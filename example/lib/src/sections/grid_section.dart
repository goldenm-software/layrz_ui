import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';
import '../common/unit_display.dart';

/// The content widget for the grid section.
///
/// Shows multiple demo subsections illustrating responsive grid behavior,
/// breakpoint transitions, wrapping, and constrained layouts.
class GridSection extends StatelessWidget {
  /// Creates a new [GridSection].
  const GridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Responsive Grid',
      description:
          'Material-free responsive layout with 12-column grid, breakpoint-driven spans, and constrained views',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit explanation
          Container(
            decoration: BoxDecoration(
              color: tokens.colors.surface2,
              borderRadius: tokens.radius.br2,
              border: Border.all(color: tokens.colors.divider, width: 1),
            ),
            padding: EdgeInsets.all(tokens.spacing.sp3),
            margin: EdgeInsets.only(bottom: tokens.spacing.sp3),
            child: Text(
              'All values are shown in logical units (u). Flutter measures layout in device-independent logical pixels, not physical device pixels. '
              'Hover over any value to see its physical-pixel equivalent on the current display.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
          ),

          // 1. Breakpoint readout
          _BreakpointReadout(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          // 2. Responsive columns demo
          _ResponsiveColumnsDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          // 3. Wrapping example
          _WrappingDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp5),

          // 4. Constrained view demo
          _ConstrainedViewDemo(tokens: tokens),
        ],
      ),
    );
  }
}

/// Displays the current viewport width and active breakpoint band.
///
/// Uses [LayoutBuilder] and [MediaQuery] to show live updates as the window resizes.
/// This helps users understand how the grid responds to viewport changes.
class _BreakpointReadout extends StatelessWidget {
  /// Creates a new [_BreakpointReadout].
  const _BreakpointReadout({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.sizeOf(context).width;
        final breakpoint = _getBreakpointLabel(width, tokens.breakpoints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Width & Breakpoint Readout', style: tokens.typography.title),
            SizedBox(height: tokens.spacing.sp3),
            Text(
              'Resize the window to see breakpoints transition. The grid responds to viewport width.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            Container(
              decoration: tokens.shadow.elevation(elevation: 0),
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spacing.sp2,
                children: [
                  Row(
                    children: [
                      Text(
                        'Viewport Width: ',
                        style: tokens.typography.label.copyWith(color: tokens.colors.fg1),
                      ),
                      UnitDisplay(
                        value: width,
                        textStyle: tokens.typography.label.copyWith(color: tokens.colors.fg1),
                      ),
                    ],
                  ),
                  Text(
                    'Active Breakpoint: $breakpoint',
                    style: tokens.typography.label.copyWith(color: tokens.colors.primary[500]),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Returns a human-readable breakpoint label for the given width.
  String _getBreakpointLabel(double width, LayrzBreakpointTokens breakpoints) {
    if (width < breakpoints.xs) return 'XS (< ${breakpoints.xs.toInt()}u)';
    if (width < breakpoints.sm) return 'SM (${breakpoints.xs.toInt()}–${(breakpoints.sm - 1).toInt()}u)';
    if (width < breakpoints.md) return 'MD (${breakpoints.sm.toInt()}–${(breakpoints.md - 1).toInt()}u)';
    if (width < breakpoints.lg) return 'LG (${breakpoints.md.toInt()}–${(breakpoints.lg - 1).toInt()}u)';
    return 'XL (≥ ${breakpoints.lg.toInt()}u)';
  }
}

/// Demonstrates responsive column spans that change across breakpoints.
///
/// Shows four columns with different span configurations for each breakpoint.
/// As the viewport width changes, columns reflow to show the responsive behavior.
class _ResponsiveColumnsDemo extends StatelessWidget {
  /// Creates a new [_ResponsiveColumnsDemo].
  const _ResponsiveColumnsDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Responsive Columns (Varying Spans Per Breakpoint)', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Each column has different span values (xs, sm, md, lg). Watch them reflow as viewport changes.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              sm: 6,
              md: 4,
              lg: 3,
              child: _ColumnBox(label: '12/6/4/3', tokens: tokens, color: tokens.colors.primary[500]!),
            ),
            LayrzCol(
              xs: 12,
              sm: 6,
              md: 4,
              lg: 3,
              child: _ColumnBox(label: '12/6/4/3', tokens: tokens, color: tokens.colors.success[500]!),
            ),
            LayrzCol(
              xs: 12,
              sm: 6,
              md: 4,
              lg: 3,
              child: _ColumnBox(label: '12/6/4/3', tokens: tokens, color: tokens.colors.warning[500]!),
            ),
            LayrzCol(
              xs: 12,
              sm: 6,
              md: 4,
              lg: 3,
              child: _ColumnBox(label: '12/6/4/3', tokens: tokens, color: tokens.colors.danger[500]!),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates row wrapping with uneven column spans.
///
/// Shows how columns wrap into multiple visual rows when spans exceed 12.
/// Five columns with uneven spans (6, 5, 4, 4, 4) wrap into two rows.
class _WrappingDemo extends StatelessWidget {
  /// Creates a new [_WrappingDemo].
  const _WrappingDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wrapping Example (Uneven Spans)', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Five columns with spans [6, 5, 4, 4, 4] wrap into two visual rows. '
          'The greedy algorithm starts a new row when sum exceeds 12.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 6,
              child: _ColumnBox(label: 'span: 6', tokens: tokens, color: tokens.colors.primary[600]!),
            ),
            LayrzCol(
              xs: 5,
              child: _ColumnBox(label: 'span: 5', tokens: tokens, color: tokens.colors.primary[500]!),
            ),
            LayrzCol(
              xs: 4,
              child: _ColumnBox(label: 'span: 4', tokens: tokens, color: tokens.colors.primary[400]!),
            ),
            LayrzCol(
              xs: 4,
              child: _ColumnBox(label: 'span: 4', tokens: tokens, color: tokens.colors.primary[400]!),
            ),
            LayrzCol(
              xs: 4,
              child: _ColumnBox(label: 'span: 4', tokens: tokens, color: tokens.colors.primary[400]!),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates [LayrzConstrainedView] centering and max-width clamping.
///
/// Shows a constrained view with a visible max-width boundary, demonstrating
/// how content is centered horizontally and width-limited.
class _ConstrainedViewDemo extends StatelessWidget {
  /// Creates a new [_ConstrainedViewDemo].
  const _ConstrainedViewDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Constrained View (max-width: 600u)', style: tokens.typography.title),
        SizedBox(height: tokens.spacing.sp3),
        Text(
          'Content is centered horizontally and constrained to max-width. '
          'Useful for landing pages and article layouts.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp3),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.colors.divider, width: 1),
            borderRadius: tokens.radius.br2,
          ),
          padding: EdgeInsets.all(tokens.spacing.sp3),
          child: LayrzConstrainedView(
            maxWidth: 600,
            spacing: tokens.spacing.sp3,
            children: [
              _ColumnBox(label: 'Child 1', tokens: tokens, color: tokens.colors.primary[500]!),
              _ColumnBox(label: 'Child 2', tokens: tokens, color: tokens.colors.success[500]!),
              _ColumnBox(label: 'Child 3', tokens: tokens, color: tokens.colors.warning[500]!),
            ],
          ),
        ),
      ],
    );
  }
}

/// A colored container box used to visualize grid cells in the demo.
///
/// Displays a label inside a colored background with border and rounded corners.
class _ColumnBox extends StatelessWidget {
  /// Creates a new [_ColumnBox].
  const _ColumnBox({
    required this.label,
    required this.tokens,
    required this.color,
  });

  /// The label text displayed in the box.
  final String label;

  /// The design system tokens.
  final LayrzTokens tokens;

  /// The fill color for the box.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
        borderRadius: tokens.radius.br2,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: tokens.typography.label.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}
