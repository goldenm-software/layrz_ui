import 'package:flutter/widgets.dart';

import 'workspace_tab_bump_path.dart';

/// Paints a single, self-contained tab's browser-tab silhouette for
/// [LayrzWorkspaceTabs] — used for every INACTIVE tab in the strip (and,
/// via its [borderColor], for the keyboard-focus ring on any tab).
///
/// [LayrzWorkspaceTabChromePainter] draws a closed browser-tab shape: the
/// top-left and top-right corners curve *inward* (a normal rounded corner),
/// while the bottom-left and bottom-right corners flare *outward* into a
/// convex shoulder that widens as it sweeps down to the baseline — the same
/// [buildWorkspaceTabBumpPath] silhouette segment the active tab's bump uses
/// inside `LayrzWorkspaceSilhouettePainter`, so every tab in a strip (active
/// or inactive) traces the identical shape. Only fill colour and border
/// presence vary by state (active vs. inactive, hovered vs. not, focused vs.
/// not) — never the geometry.
///
/// The active tab is **not** painted by this class any more: it renders no
/// fill and no border of its own at all, because it is part of the single
/// unified [active tab + content card] silhouette painted once by
/// `LayrzWorkspaceSilhouettePainter`. An inactive tab, by contrast, is a
/// fully self-contained closed shape with its own recessed fill — it is not
/// connected to the card.
///
/// This painter reads no [BuildContext], theme, or tokens itself — per the
/// repo's `CustomPainter` convention (see `LayrzSelectionHandlePainter`),
/// every colour and dimension is supplied by the caller, which is
/// responsible for resolving them from `context.tokens`.
@immutable
class LayrzWorkspaceTabChromePainter extends CustomPainter {
  /// The fill colour painted inside the tab shape.
  final Color fillColor;

  /// The corner radius applied to the top-left and top-right corners.
  ///
  /// These curve inward, like an ordinary rounded rectangle corner. Must
  /// match `LayrzWorkspaceSilhouettePainter.tabTopRadius` so every tab in
  /// the strip shares one shape.
  final double topRadius;

  /// The size of the outward-flaring shoulder at the bottom-left and
  /// bottom-right corners.
  ///
  /// Unlike [topRadius], this does not round the corner inward — it
  /// controls how far the convex shoulder bulges outward and how tall the
  /// S-curve is before it meets the baseline, so the tab widens at its very
  /// bottom rather than narrowing. Pass `0` to fall back to a square
  /// bottom corner with no shoulder. Must match
  /// `LayrzWorkspaceSilhouettePainter.shoulderRadius` so every tab in the
  /// strip shares one shape.
  final double shoulderRadius;

  /// Optional stroke colour drawn along the shape's closed outline.
  ///
  /// When `null`, no stroke is drawn — the shape is fill-only. Used for the
  /// keyboard-focus ring; an inactive tab with no focus and no hover paints
  /// no border of its own otherwise.
  final Color? borderColor;

  /// The stroke width used when [borderColor] is non-null.
  final double borderWidth;

  /// Creates a new [LayrzWorkspaceTabChromePainter].
  ///
  /// Parameters:
  ///   - [fillColor]: the tab shape's fill colour.
  ///   - [topRadius]: inward corner radius for the top-left/top-right
  ///     corners.
  ///   - [shoulderRadius]: outward-flare size for the bottom-left/
  ///     bottom-right shoulders. Defaults to `0`.
  ///   - [borderColor]: optional outline stroke colour. Defaults to `null`
  ///     (no outline).
  ///   - [borderWidth]: outline stroke width, used only when [borderColor]
  ///     is non-null. Defaults to `1.0`.
  const LayrzWorkspaceTabChromePainter({
    required this.fillColor,
    required this.topRadius,
    this.shoulderRadius = 0.0,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// Builds this tab's closed outline as a [Path], by closing the shared
  /// [buildWorkspaceTabBumpPath] open bump segment across its own bottom
  /// edge — the same shape the active tab's bump traces, just sealed off
  /// rather than left open into a card below.
  Path _buildClosedPath(Size size) {
    final width = size.width;
    final height = size.height;
    return buildWorkspaceTabBumpPath(width: width, height: height, topRadius: topRadius, shoulderRadius: shoulderRadius)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildClosedPath(size);

    canvas.drawPath(path, Paint()..color = fillColor);

    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LayrzWorkspaceTabChromePainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.topRadius != topRadius ||
      oldDelegate.shoulderRadius != shoulderRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
