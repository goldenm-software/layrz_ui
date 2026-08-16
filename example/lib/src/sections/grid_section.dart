import 'package:flutter/widgets.dart';
import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/grid.dart';
import 'package:layrz_ui/tokens.dart';

import '../common/showroom_section.dart';

/// Displays responsive grid layout behavior with [LayrzRow], [LayrzCol], and [LayrzConstrainedView].
///
/// Demonstrates responsive column spans across breakpoints, live width/breakpoint readout,
/// wrapping behavior with uneven spans, and constrained view layouts.
Widget buildGridSection() {
  return Builder(
    builder: (context) {
      return const _GridSectionContent();
    },
  );
}

/// The content widget for the grid section.
///
/// Shows multiple demo subsections illustrating responsive grid behavior,
/// breakpoint transitions, wrapping, and constrained layouts.
class _GridSectionContent extends StatelessWidget {
  /// Creates a new [_GridSectionContent].
  const _GridSectionContent();

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
          // 1. Breakpoint readout
          _BreakpointReadout(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 2. Responsive columns demo
          _ResponsiveColumnsDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 3. Wrapping example
          _WrappingDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 4. Constrained view demo
          _ConstrainedViewDemo(tokens: tokens),

          SizedBox(height: tokens.spacing.sp32),

          // 5. useScreenWidth toggle demo
          _UseScreenWidthDemo(tokens: tokens),
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
        final breakpoint = _getBreakpointLabel(width);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Width & Breakpoint Readout', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            Text(
              'Resize the window to see breakpoints transition. The grid responds to viewport width.',
              style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp12),
            Container(
              decoration: tokens.shadow.elevation(elevation: 0),
              padding: EdgeInsets.all(tokens.spacing.sp16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spacing.sp8,
                children: [
                  Text(
                    'Viewport Width: ${width.toStringAsFixed(0)}px',
                    style: tokens.typography.labelMedium.copyWith(color: tokens.colors.fg1),
                  ),
                  Text(
                    'Active Breakpoint: $breakpoint',
                    style: tokens.typography.labelMedium.copyWith(color: tokens.colors.primary[500]),
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
  String _getBreakpointLabel(double width) {
    if (width < kExtraSmallGrid) return 'XS (< 600px)';
    if (width < kSmallGrid) return 'SM (600–959px)';
    if (width < kMediumGrid) return 'MD (960–1263px)';
    if (width < kLargeGrid) return 'LG (1264–1903px)';
    return 'XL (≥ 1904px)';
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
        Text('Responsive Columns (Varying Spans Per Breakpoint)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Each column has different span values (xs, sm, md, lg). Watch them reflow as viewport changes.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        LayrzRow(
          spacing: tokens.spacing.sp12,
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
        Text('Wrapping Example (Uneven Spans)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Five columns with spans [6, 5, 4, 4, 4] wrap into two visual rows. '
          'The greedy algorithm starts a new row when sum exceeds 12.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        LayrzRow(
          spacing: tokens.spacing.sp12,
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
        Text('Constrained View (max-width: 600px)', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'Content is centered horizontally and constrained to max-width. '
          'Useful for landing pages and article layouts.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.colors.divider, width: 1),
            borderRadius: BorderRadius.circular(tokens.radius.r8),
          ),
          padding: EdgeInsets.all(tokens.spacing.sp16),
          child: LayrzConstrainedView(
            maxWidth: 600,
            spacing: tokens.spacing.sp12,
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

/// Demonstrates the [useScreenWidth] toggle in [LayrzRow].
///
/// Shows a [LayrzRow] inside a deliberately narrow fixed-width container,
/// with a toggle to switch between layout-width and screen-width breakpoint selection.
/// This clarifies the difference between the two width modes.
class _UseScreenWidthDemo extends StatefulWidget {
  /// Creates a new [_UseScreenWidthDemo].
  const _UseScreenWidthDemo({required this.tokens});

  /// The design system tokens.
  final LayrzTokens tokens;

  @override
  State<_UseScreenWidthDemo> createState() => _UseScreenWidthDemoState();
}

/// State for [_UseScreenWidthDemo].
class _UseScreenWidthDemoState extends State<_UseScreenWidthDemo> {
  /// Whether to use screen width for breakpoint selection.
  bool _useScreenWidth = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('useScreenWidth Toggle', style: tokens.typography.titleMedium),
        SizedBox(height: tokens.spacing.sp12),
        Text(
          'This row is constrained to 300px width. Toggle to see how useScreenWidth changes '
          'breakpoint selection: when true, spans use screen width; when false, layout width.',
          style: tokens.typography.bodySmall.copyWith(color: tokens.colors.fg3),
        ),
        SizedBox(height: tokens.spacing.sp12),
        Row(
          spacing: tokens.spacing.sp12,
          children: [
            _ToggleButton(
              label: 'useScreenWidth: ${_useScreenWidth ? 'true' : 'false'}',
              isActive: _useScreenWidth,
              tokens: tokens,
              onToggle: () => setState(() => _useScreenWidth = !_useScreenWidth),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.colors.divider, width: 2),
            borderRadius: BorderRadius.circular(tokens.radius.r8),
          ),
          padding: EdgeInsets.all(tokens.spacing.sp8),
          child: SizedBox(
            width: 300,
            child: LayrzRow(
              useScreenWidth: _useScreenWidth,
              spacing: tokens.spacing.sp8,
              children: [
                LayrzCol(
                  xs: 12,
                  sm: 6,
                  md: 4,
                  child: _ColumnBox(label: '12/6/4', tokens: tokens, color: tokens.colors.primary[500]!),
                ),
                LayrzCol(
                  xs: 12,
                  sm: 6,
                  md: 4,
                  child: _ColumnBox(label: '12/6/4', tokens: tokens, color: tokens.colors.success[500]!),
                ),
                LayrzCol(
                  xs: 12,
                  sm: 6,
                  md: 4,
                  child: _ColumnBox(label: '12/6/4', tokens: tokens, color: tokens.colors.warning[500]!),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(tokens.radius.r8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: tokens.typography.labelMedium.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A simple toggle button for demonstration purposes.
///
/// Shows the current state and responds to taps to toggle a boolean flag.
class _ToggleButton extends StatelessWidget {
  /// Creates a new [_ToggleButton].
  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.tokens,
    required this.onToggle,
  });

  /// The label text displayed on the button.
  final String label;

  /// Whether the toggle is currently active.
  final bool isActive;

  /// The design system tokens.
  final LayrzTokens tokens;

  /// Callback when the button is tapped.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp16, vertical: tokens.spacing.sp12),
        decoration: BoxDecoration(
          color: isActive ? tokens.colors.primary[500] : tokens.colors.surface2,
          border: Border.all(color: tokens.colors.fg2, width: 1),
          borderRadius: BorderRadius.circular(tokens.radius.r8),
        ),
        child: Text(
          label,
          style: tokens.typography.labelMedium.copyWith(
            color: isActive ? tokens.colors.surface : tokens.colors.fg1,
          ),
        ),
      ),
    );
  }
}
