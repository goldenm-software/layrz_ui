import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzRow] responsive breakpoint behavior.
///
/// Shows the same three columns at different widths to demonstrate how the
/// spans change across breakpoints.
@Preview(name: 'Breakpoints', size: Size(1000, 400), theme: layrzPreviewLightTheme)
Widget previewLayrzRowBreakpoints() {
  return _PreviewBreakpoints();
}

/// Helper widget displaying responsive breakpoint transitions.
class _PreviewBreakpoints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _WidthLabel('400px (xs band)'),
          SizedBox(
            width: 400,
            child: LayrzRow(
              children: [
                LayrzCol(xs: 12, sm: 6, md: 4, child: _ColoredColumn('Col 1')),
                LayrzCol(xs: 12, sm: 6, md: 4, child: _ColoredColumn('Col 2')),
                LayrzCol(xs: 12, sm: 12, md: 4, child: _ColoredColumn('Col 3')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _WidthLabel('700px (sm band)'),
          SizedBox(
            width: 700,
            child: LayrzRow(
              children: [
                LayrzCol(xs: 12, sm: 6, md: 4, child: _ColoredColumn('Col 1')),
                LayrzCol(xs: 12, sm: 6, md: 4, child: _ColoredColumn('Col 2')),
                LayrzCol(xs: 12, sm: 12, md: 4, child: _ColoredColumn('Col 3')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _WidthLabel('1000px (md band)'),
          SizedBox(
            width: 1000,
            child: LayrzRow(
              children: [
                LayrzCol(xs: 12, sm: 6, md: 4, child: _ColoredColumn('Col 1')),
                LayrzCol(xs: 12, sm: 6, md: 4, child: _ColoredColumn('Col 2')),
                LayrzCol(xs: 12, sm: 12, md: 4, child: _ColoredColumn('Col 3')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview of [LayrzRow] wrapping behavior.
///
/// Shows columns with spans that wrap into multiple visual rows at a fixed width.
@Preview(name: 'Wrapping', size: Size(800, 300), theme: layrzPreviewLightTheme)
Widget previewLayrzRowWrapping() {
  return _PreviewWrapping();
}

/// Helper widget displaying row wrapping at a fixed width.
class _PreviewWrapping extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 600,
        child: LayrzRow(
          children: [
            LayrzCol(xs: 6, child: _ColoredColumn('6')),
            LayrzCol(xs: 5, child: _ColoredColumn('5')),
            LayrzCol(xs: 4, child: _ColoredColumn('4')),
            LayrzCol(xs: 4, child: _ColoredColumn('4')),
            LayrzCol(xs: 4, child: _ColoredColumn('4')),
          ],
        ),
      ),
    );
  }
}

/// Preview of [LayrzRow] main-axis alignment.
///
/// Shows a short row of a single column with different [MainAxisAlignment] options.
@Preview(name: 'Alignment', size: Size(600, 400), theme: layrzPreviewLightTheme)
Widget previewLayrzRowAlignment() {
  return _PreviewAlignment();
}

/// Helper widget displaying main-axis alignment variations.
class _PreviewAlignment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 100,
          child: LayrzRow(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              LayrzCol(xs: 4, child: _ColoredColumn('start')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: LayrzRow(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayrzCol(xs: 4, child: _ColoredColumn('center')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: LayrzRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LayrzCol(xs: 3, child: _ColoredColumn('a')),
              LayrzCol(xs: 3, child: _ColoredColumn('b')),
              LayrzCol(xs: 3, child: _ColoredColumn('c')),
            ],
          ),
        ),
      ],
    );
  }
}

/// Preview of [LayrzConstrainedView].
///
/// Shows a constrained view centered within a wider container.
@Preview(name: 'Constrained View', size: Size(1000, 200), theme: layrzPreviewLightTheme)
Widget previewLayrzConstrainedView() {
  return _PreviewConstrainedView();
}

/// Helper widget displaying a constrained view centered in a wide container.
class _PreviewConstrainedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1000,
      child: LayrzConstrainedView(
        maxWidth: 600,
        spacing: 12,
        children: [
          _ColoredColumn('Child 1'),
          _ColoredColumn('Child 2'),
          _ColoredColumn('Child 3'),
        ],
      ),
    );
  }
}

/// A colored container used in previews to visualize grid cells.
class _ColoredColumn extends StatelessWidget {
  /// The label text displayed in the column.
  final String label;

  /// Creates a new [_ColoredColumn] with the given label.
  const _ColoredColumn(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF424242),
        ),
      ),
    );
  }
}

/// A label widget showing the preview's width context.
class _WidthLabel extends StatelessWidget {
  /// The label text.
  final String label;

  /// Creates a new [_WidthLabel] with the given text.
  const _WidthLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF616161),
        ),
      ),
    );
  }
}
