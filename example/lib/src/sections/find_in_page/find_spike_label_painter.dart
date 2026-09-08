import 'package:flutter/widgets.dart';

/// A trivial [CustomPainter] drawing [text] as a single line — stands in for
/// arbitrary custom-painted content that carries no semantics of its own
/// unless explicitly wrapped in a [Semantics] widget by its caller, exactly
/// as `LayrzFindSpike`'s own usage does (see `find_spike.dart`) — the
/// stand-in for the escape hatch a future `LayrzSearchable` would formalize
/// for custom-painted content.
class FindSpikeLabelPainter extends CustomPainter {
  /// The text to draw.
  final String text;

  /// The text's paint color.
  final Color color;

  /// Creates a [FindSpikeLabelPainter].
  FindSpikeLabelPainter({required this.text, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    painter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant FindSpikeLabelPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.color != color;
  }
}
