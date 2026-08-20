import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// A constrained container that limits the width of its children and centers them horizontally.
///
/// [LayrzConstrainedView] wraps its children in a Column with a maximum width constraint,
/// centering the column horizontally within its parent. Children are laid out vertically
/// with optional spacing between them.
///
/// The alignment and sizing are deliberately fixed:
/// - **Vertical alignment**: [MainAxisAlignment.start] (top-aligned)
/// - **Horizontal alignment**: [CrossAxisAlignment.stretch] (full width of constraint)
/// - **Width**: clamped to [maxWidth], centered horizontally
/// - **Spacing**: applied between all children via [Column.spacing]
///
/// Callers needing different alignments should wrap the content in their own [Column]
/// or [Row] as a child, rather than passing multiple children to this widget.
///
/// This widget is useful for landing pages, article layouts, and forms where you want
/// to limit reading width while keeping the visual context of the full screen.
/// Nothing is clipped — overflow is not hidden, only constrained.
class LayrzConstrainedView extends StatelessWidget {
  /// The maximum width for the content, in logical pixels.
  ///
  /// The actual width will be the minimum of this value and the available parent width.
  /// Must be positive (> 0).
  final double maxWidth;

  /// The vertical spacing between children.
  ///
  /// If `null`, defaults to [LayrzTokens.spacing.sp2] (8.0).
  /// Set to 0 for no spacing.
  final double? spacing;

  /// The child widgets to display, laid out vertically.
  ///
  /// May be empty; renders as a zero-sized widget.
  final List<Widget> children;

  /// Creates a new [LayrzConstrainedView] with the given max width and children.
  ///
  /// The [maxWidth] parameter must be positive.
  /// All children are laid out vertically with optional spacing.
  const LayrzConstrainedView({
    super.key,
    required this.maxWidth,
    this.spacing,
    required this.children,
  }) : assert(maxWidth > 0, 'maxWidth must be positive, got $maxWidth');

  @override
  Widget build(BuildContext context) {
    final resolvedSpacing = spacing ?? context.tokens.spacing.sp2;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: resolvedSpacing,
          children: children,
        ),
      ),
    );
  }
}
