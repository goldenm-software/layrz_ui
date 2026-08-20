import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'col.dart';

/// A responsive row layout widget that arranges [LayrzCol] children in a 12-column grid.
///
/// [LayrzRow] implements a greedy layout algorithm: columns are placed left-to-right,
/// and a new visual row is started when the sum of column spans would exceed 12.
///
/// The row respects two independent widths:
/// - **Layout width**: the row's own box width, used for pixel arithmetic when sizing children.
/// - **Breakpoint width**: always the viewport width from [MediaQuery.sizeOf], used to select spans.
///
/// This means a row inside a narrow container (e.g. a 400px sidebar) on a wide screen (e.g. 1920px)
/// will select wide-screen spans (lg/xl band) and divide its 400px width by those larger spans,
/// resulting in narrower individual columns. This is the standard CSS Grid / Bootstrap behavior.
class LayrzRow extends StatelessWidget {
  /// The columns to arrange in this row.
  ///
  /// Empty lists are valid and render as a zero-sized widget.
  /// The row uses a greedy algorithm to group columns into visual rows based on their spans.
  final List<LayrzCol> children;

  /// How to align columns along the main axis (horizontally) within each visual row.
  ///
  /// Defaults to [MainAxisAlignment.start].
  final MainAxisAlignment mainAxisAlignment;

  /// How to align columns along the cross axis (vertically) within each visual row.
  ///
  /// Defaults to [CrossAxisAlignment.start].
  ///
  /// **Important**: [CrossAxisAlignment.stretch] requires a bounded height from the parent.
  /// In an unbounded-height context (e.g., inside a `Column` without explicit height),
  /// using `.stretch` will throw a layout error. This is a caller opt-in, so the default
  /// [CrossAxisAlignment.start] is safe for all contexts.
  final CrossAxisAlignment crossAxisAlignment;

  /// The horizontal and vertical spacing between columns and between visual rows.
  ///
  /// If `null`, defaults to the base spacing value (8.0 pixels).
  /// Set to 0 for flush, adjacent columns.
  final double? spacing;

  /// Creates a new [LayrzRow] with the given children and layout parameters.
  ///
  /// The [children] list may be empty. All alignment and spacing parameters use sensible
  /// defaults that work for most layouts.
  const LayrzRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two-width rule:
        // layoutWidth: the row's own box width, used for pixel math to size children.
        // breakpointWidth: the viewport width, used to select which of xs/sm/md/lg/xl each column uses.
        // When a parent is unbounded horizontally, we clamp layoutWidth to the screen width
        // to prevent infinity from propagating into SizedBox calculations.
        final layoutWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;

        // Breakpoint width is always the viewport width. It typically differs from layoutWidth
        // when this row is inside a narrow container on a wide screen. Both widths are threaded
        // through the layout helpers — breakpointWidth selects the spans, layoutWidth divides the pixels.
        final breakpointWidth = MediaQuery.sizeOf(context).width;

        return _renderRows(
          context: context,
          breakpointWidth: breakpointWidth,
          layoutWidth: layoutWidth,
        );
      },
    );
  }

  /// Renders the visual rows of columns with the resolved widths.
  ///
  /// Groups [children] into visual rows using a greedy algorithm, then builds
  /// the column layout with proper spacing and alignment.
  Widget _renderRows({
    required BuildContext context,
    required double breakpointWidth,
    required double layoutWidth,
  }) {
    final resolvedSpacing = spacing ?? context.tokens.spacing.sp2;
    final breakpoints = context.tokens.breakpoints;

    // Greedy grouping: place columns left-to-right, starting a new row when
    // the sum of spans would exceed 12.
    final rows = <List<LayrzCol>>[];
    var currentRow = <LayrzCol>[];
    var currentSum = 0;

    for (final col in children) {
      final span = col.spanAt(breakpointWidth, breakpoints);
      if (currentSum + span > 12 && currentRow.isNotEmpty) {
        rows.add(currentRow);
        currentRow = [];
        currentSum = 0;
      }
      currentRow.add(col);
      currentSum += span;
    }
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
    }

    // Build the layout: outer Column with visual rows separated by spacing,
    // each row is an inner Row with columns spaced horizontally.
    final visualRows = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      visualRows.add(
        _buildVisualRow(
          context,
          row: row,
          breakpointWidth: breakpointWidth,
          layoutWidth: layoutWidth,
          resolvedSpacing: resolvedSpacing,
          breakpoints: breakpoints,
        ),
      );
      if (i < rows.length - 1) {
        visualRows.add(SizedBox(height: resolvedSpacing));
      }
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visualRows,
      ),
    );
  }

  /// Builds a single visual row (horizontal) of columns.
  ///
  /// Sizes each column proportionally based on its span relative to 12, accounting
  /// for inter-column spacing.
  Widget _buildVisualRow(
    BuildContext context, {
    required List<LayrzCol> row,
    required double breakpointWidth,
    required double layoutWidth,
    required double resolvedSpacing,
    required LayrzBreakpointTokens breakpoints,
  }) {
    final columnWidgets = <Widget>[];

    // Calculate available space for columns after accounting for inter-column gaps.
    // n columns have (n-1) gaps of size resolvedSpacing.
    final gapWidth = resolvedSpacing * (row.length - 1);
    final availableWidth = layoutWidth - gapWidth;

    for (var i = 0; i < row.length; i++) {
      final col = row[i];
      final span = col.spanAt(breakpointWidth, breakpoints);

      final colWidth = availableWidth * span / 12;

      columnWidgets.add(
        SizedBox(
          width: colWidth,
          child: col,
        ),
      );

      // Add spacing between columns, but not after the last one.
      if (i < row.length - 1) {
        columnWidgets.add(SizedBox(width: resolvedSpacing));
      }
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: columnWidgets,
    );
  }
}
