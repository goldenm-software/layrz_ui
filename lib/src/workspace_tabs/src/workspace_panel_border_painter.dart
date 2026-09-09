import 'package:flutter/widgets.dart';

/// Paints the content panel's outline for [LayrzWorkspaceTabs], leaving a gap
/// in the top edge under the active tab and rounding that gap's edges
/// inward to meet the active tab's own outward-flaring shoulders — so the
/// panel's border and the active tab's chrome trace a single continuous
/// path with no seam between them.
///
/// The panel itself is an ordinary rounded rectangle (all four corners
/// rounded by [outerRadius]) **except** along the span
/// [activeTabLeft]–[activeTabRight] of its top edge, where instead of a
/// straight line the outline dips down into a mirrored pair of the tab
/// chrome's own shoulder curves (see `LayrzWorkspaceTabChromePainter`) and
/// then stops — that gap is where the active tab itself sits, already
/// borderless along its own bottom edge (`mergeBottom: true`), so the two
/// painters' open sub-paths abut exactly.
///
/// When [activeTabLeft] or [activeTabRight] is `null` (no tab is currently
/// active — e.g. a transient state while the caller updates its own data),
/// the panel falls back to an ordinary unbroken rounded-rectangle border.
///
/// This painter reads no [BuildContext], theme, or tokens itself — per the
/// repo's `CustomPainter` convention, every colour and dimension is supplied
/// by the caller, which resolves them from `context.tokens`.
@immutable
class LayrzWorkspacePanelBorderPainter extends CustomPainter {
  /// The panel's fill colour, painted behind its content.
  final Color fillColor;

  /// The corner radius applied to all four outer corners of the panel.
  final double outerRadius;

  /// The size of the shoulder curve carved into the top edge on either side
  /// of the active tab's span, mirroring
  /// `LayrzWorkspaceTabChromePainter.shoulderRadius` so the two shapes trace
  /// one continuous outline.
  final double shoulderRadius;

  /// The x-offset, in this painter's own local coordinates, of the active
  /// tab's left edge.
  ///
  /// `null` when no tab is currently active, in which case the panel draws
  /// an unbroken border with no gap.
  final double? activeTabLeft;

  /// The x-offset, in this painter's own local coordinates, of the active
  /// tab's right edge.
  ///
  /// `null` when no tab is currently active, in which case the panel draws
  /// an unbroken border with no gap.
  final double? activeTabRight;

  /// The border stroke colour.
  final Color borderColor;

  /// The border stroke width.
  final double borderWidth;

  /// Creates a new [LayrzWorkspacePanelBorderPainter].
  ///
  /// Parameters:
  ///   - [fillColor]: the panel's fill colour.
  ///   - [outerRadius]: corner radius for all four outer corners.
  ///   - [shoulderRadius]: the carve-out curve size where the top border
  ///     opens for the active tab; should match the tab chrome's own
  ///     `shoulderRadius`. Defaults to `0`.
  ///   - [activeTabLeft], [activeTabRight]: the active tab's x-span in this
  ///     painter's local coordinates. Both `null` draws an unbroken border.
  ///   - [borderColor]: the stroke colour.
  ///   - [borderWidth]: the stroke width. Defaults to `1.0`.
  const LayrzWorkspacePanelBorderPainter({
    required this.fillColor,
    required this.outerRadius,
    this.shoulderRadius = 0.0,
    this.activeTabLeft,
    this.activeTabRight,
    required this.borderColor,
    this.borderWidth = 1.0,
  });

  /// Builds the panel's fill shape: a plain rounded rectangle covering
  /// [size], regardless of where the active tab sits — the gap is a border
  /// stroke concern only, not a fill one, since the active tab's own chrome
  /// already paints over that span from above.
  Path _buildFillPath(Size size) {
    final radius = outerRadius.clamp(0.0, size.shortestSide / 2);
    return Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
  }

  /// Builds the stroked outline: the full rounded-rectangle perimeter when
  /// no tab is active, or the same perimeter with the top edge interrupted
  /// by the shoulder-carved gap under the active tab.
  Path _buildBorderPath(Size size) {
    final width = size.width;
    final height = size.height;
    final r = outerRadius.clamp(0.0, size.shortestSide / 2);
    final left = activeTabLeft;
    final right = activeTabRight;

    if (left == null || right == null) {
      return Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)));
    }

    // Clamp the gap span so the carved shoulders never cross the panel's
    // own rounded corners or each other, even if the active tab reports an
    // implausible span (e.g. during a transient layout pass).
    final sr = shoulderRadius.clamp(0.0, width / 2);
    final gapStart = left.clamp(r + sr, width - r - sr);
    final gapEnd = right.clamp(gapStart, width - r - sr);

    return Path()
      // Start just after the top-left corner, sweep right along the top
      // edge to where the active tab's left shoulder begins.
      ..moveTo(r, 0)
      ..lineTo(gapStart - sr, 0)
      // Mirror of the tab chrome's own bottom-left shoulder: curves down
      // and outward (in the panel's frame, "outward" means down into the
      // gap) then back up to the tab's baseline — meeting the tab's own
      // open border path with no seam.
      ..cubicTo(gapStart - sr, sr, gapStart - sr, sr, gapStart, sr)
      // Skip the gap itself — the active tab's own chrome renders here.
      ..moveTo(gapEnd, sr)
      ..cubicTo(gapEnd + sr, sr, gapEnd + sr, sr, gapEnd + sr, 0)
      // Continue right to the top-right corner.
      ..lineTo(width - r, 0)
      ..arcToPoint(Offset(width, r), radius: Radius.circular(r), clockwise: true)
      // Right edge down to the bottom-right corner.
      ..lineTo(width, height - r)
      ..arcToPoint(Offset(width - r, height), radius: Radius.circular(r), clockwise: true)
      // Bottom edge, right to left.
      ..lineTo(r, height)
      ..arcToPoint(Offset(0, height - r), radius: Radius.circular(r), clockwise: true)
      // Left edge up to the top-left corner.
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r), clockwise: true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_buildFillPath(size), Paint()..color = fillColor);
    canvas.drawPath(
      _buildBorderPath(size),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant LayrzWorkspacePanelBorderPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.outerRadius != outerRadius ||
      oldDelegate.shoulderRadius != shoulderRadius ||
      oldDelegate.activeTabLeft != activeTabLeft ||
      oldDelegate.activeTabRight != activeTabRight ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
