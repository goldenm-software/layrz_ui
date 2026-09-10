import 'package:flutter/widgets.dart';

/// Builds the shared "tab bump" open sub-path — the browser-tab silhouette
/// segment used both by an ordinary closed tab shape
/// ([LayrzWorkspaceTabChromePainter]) and by the active tab's bump spliced
/// into [LayrzWorkspaceSilhouettePainter]'s single unified outline.
///
/// This is the one place that shape is defined, so every tab in a
/// [LayrzWorkspaceTabs] strip — active or inactive — traces the exact same
/// silhouette: inward-rounded top corners of [topRadius], and
/// outward-flaring shoulders of [shoulderRadius] where the vertical sides
/// widen as they sweep down to meet the baseline (`y = height`). Only fill
/// colour, border presence, and whether the bottom edge is closed differ
/// between states — never this geometry.
///
/// Traced left-to-right starting at `(0, height)` (the baseline end of the
/// left shoulder) and ending at `(width, height)` (the baseline end of the
/// right shoulder), deliberately leaving the bottom edge itself unconnected
/// — the caller decides whether to treat that as an open border (the active
/// tab, merging into the panel) or to close it explicitly with `..lineTo`/
/// `..close()` (an ordinary inactive tab).
///
/// See also:
///   - [LayrzWorkspaceTabChromePainter], which closes this path's bottom
///     edge for its own full closed-shape fill, and uses this same open
///     path directly for an active tab's merged-bottom border.
///   - [LayrzWorkspaceSilhouettePainter], which translates this path into
///     its own combined [active tab + card] coordinate space and splices it
///     into the card's top edge.
Path buildWorkspaceTabBumpPath({
  required double width,
  required double height,
  required double topRadius,
  required double shoulderRadius,
}) {
  final tr = topRadius.clamp(0.0, width / 2).clamp(0.0, height);
  final sr = shoulderRadius.clamp(0.0, width / 2).clamp(0.0, height);

  return Path()
    // Start at the baseline end of the left shoulder.
    ..moveTo(0, height)
    // Left shoulder, sweeping up and outward from the baseline.
    ..cubicTo(-sr, height, -sr, height - sr, 0, height - sr)
    // Left edge, up to the top-left curve.
    ..lineTo(0, tr)
    // Top-left curve (inward).
    ..arcToPoint(Offset(tr, 0), radius: Radius.circular(tr), clockwise: true)
    // Top edge, left to right.
    ..lineTo(width - tr, 0)
    // Top-right curve (inward).
    ..arcToPoint(Offset(width, tr), radius: Radius.circular(tr), clockwise: true)
    // Right edge, down to the right shoulder.
    ..lineTo(width, height - sr)
    // Right shoulder, sweeping down and outward to the baseline.
    ..cubicTo(width + sr, height - sr, width + sr, height, width, height);
}
