import 'package:flutter/widgets.dart';

import 'layo_painter.dart';

/// The static "MrLayo" brand mascot, rendered entirely with [CustomPainter] —
/// no bundled image or SVG asset.
///
/// This is deliberately named `Layo`, without the `Layrz` prefix used by the
/// rest of this design system's components: it is a brand asset rather than
/// a themeable UI primitive (see decision D11 in `engineering/decisions.md`).
///
/// Phase 1 draws only the single, static, awake face traced from the
/// reference artwork — no animation and no emotion variants. Those are
/// tracked as later phases of DESIGN-67 and are intentionally out of scope
/// here.
///
/// [Layo] is size-automatic: it fills whatever width its parent provides and
/// derives its height from the mascot's fixed [_aspectRatio], so it drops
/// into an [Expanded], a grid cell, or any other bounded box and keeps the
/// original artwork's proportions. When the parent imposes no width bound
/// (for example inside a scrolling [Column]), pass an explicit [width].
class Layo extends StatelessWidget {
  /// Creates a new [Layo] mascot graphic.
  ///
  /// The [width] parameter is optional. When null, [Layo] expands to fill
  /// the width its parent provides and derives its height from the fixed
  /// 500:833 aspect ratio of the original artwork — this requires the parent
  /// to impose a bounded width (e.g. a [SizedBox], an [Expanded] inside a
  /// [Row], or a sized grid cell). When the parent provides no width bound
  /// (for example inside a scrolling [Column] or [Row] with no constraint on
  /// the relevant axis), [AspectRatio] throws, so supply an explicit [width]
  /// in that context instead. Height is always derived from the aspect ratio
  /// and can never be set independently.
  const Layo({this.width, super.key});

  /// Optional explicit width in logical pixels.
  ///
  /// When null, [Layo] fills the width its parent provides and derives
  /// height from the fixed 500:833 aspect ratio; provide it when [Layo] sits
  /// in an unbounded context (e.g. inside a scrolling [Column]) where the
  /// parent imposes no width.
  final double? width;

  /// The mascot artwork's fixed width:height aspect ratio, traced from the
  /// original 500×833 reference resource (`mr-layo.png`).
  static const double _aspectRatio = 500 / 833;

  @override
  Widget build(BuildContext context) {
    final aspect = AspectRatio(
      aspectRatio: _aspectRatio,
      child: const CustomPaint(
        painter: LayoPainter(),
        size: Size.infinite,
      ),
    );

    final explicitWidth = width;
    if (explicitWidth != null) {
      return SizedBox(width: explicitWidth, child: aspect);
    }
    return aspect;
  }
}
