import 'package:flutter/widgets.dart';

/// The horizontal space, in logical pixels, occupied by a single depth level's
/// indent guide inside [LayrzTreeIndentGuide].
const double kLayrzTreeIndentPerLevel = 20.0;

/// Draws vertical guide lines behind a tree row to visually connect a node to
/// its ancestor chain.
///
/// [LayrzTreeIndentGuide] renders one thin vertical line per ancestor level
/// (i.e. [depth] lines), each offset by [kLayrzTreeIndentPerLevel] logical
/// pixels, so a deeply nested row's lineage back to the root reads visually
/// without requiring a screen-reader user to count indentation — that
/// information is carried in parallel via each row's semantics (see
/// `tree_row.dart`), never by this painted guide alone.
///
/// This widget is purely decorative: it paints no interactive surface and
/// carries no semantics of its own (`ExcludeSemantics`-equivalent by simply
/// never attaching any), matching how markers are excluded from semantics in
/// `LayrzTimeline` and `LayrzStepper`.
class LayrzTreeIndentGuide extends StatelessWidget {
  /// Creates a [LayrzTreeIndentGuide].
  const LayrzTreeIndentGuide({
    required this.depth,
    required this.color,
    super.key,
  });

  /// The zero-based nesting depth of the row this guide is drawn for. A depth
  /// of `0` (a root node) renders no lines and no width.
  final int depth;

  /// The colour used to paint each vertical guide line.
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (depth == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: kLayrzTreeIndentPerLevel * depth,
      child: CustomPaint(
        painter: _TreeIndentGuidePainter(depth: depth, color: color),
      ),
    );
  }
}

class _TreeIndentGuidePainter extends CustomPainter {
  _TreeIndentGuidePainter({required this.depth, required this.color});

  final int depth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (var level = 0; level < depth; level++) {
      final x = kLayrzTreeIndentPerLevel * level + (kLayrzTreeIndentPerLevel / 2);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeIndentGuidePainter oldDelegate) =>
      oldDelegate.depth != depth || oldDelegate.color != color;
}
