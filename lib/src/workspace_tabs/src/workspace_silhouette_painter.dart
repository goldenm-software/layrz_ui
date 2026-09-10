import 'package:flutter/widgets.dart';

import 'workspace_tab_bump_path.dart';

/// Paints the single, unbroken outline (and matching single fill) of the
/// connected shape formed by a [LayrzWorkspaceTabs] active tab and its
/// content panel, read together as one silhouette — the browser-tab look,
/// where the active tab is a bump rising out of the top edge of an
/// otherwise ordinary rounded-rectangle card.
///
/// This is the single painter that replaces two previously-separate
/// strokes: the active tab's own open border (drawn in the strip) and the
/// panel's gap-carved border (drawn in the panel). Both of those painters
/// built geometrically-matching sub-paths designed to abut, but each was
/// stroked independently by a different [CustomPaint] in a different
/// widget subtree — two separate `drawPath` calls, each with its own
/// antialiased edge, which is exactly what leaves a hairline seam at the
/// join. [LayrzWorkspaceSilhouettePainter] instead builds **one** [Path]
/// tracing the whole silhouette and fills and strokes it **once**, so
/// there is nothing left to seam.
///
/// Coordinate space: this painter is sized to cover the active tab's full
/// vertical span *and* the panel below it, stacked so `y = 0` is the
/// active tab's own top edge and `y = tabHeight` is exactly the panel's
/// top edge (where the tab's bottom, left open, meets the panel). The
/// caller ([LayrzWorkspaceTabs]) is responsible for positioning a
/// same-sized [CustomPaint] at that combined rect — see its `Stack`
/// layering the strip, this overlay, and the panel.
///
/// The silhouette path is built as a single continuous winding:
/// top-left panel corner → along the panel's flat top edge → up the tab's
/// left shoulder → up the tab's left side → across the tab's rounded top →
/// down the tab's right side → down the tab's right shoulder → back onto
/// the panel's flat top edge → along to the top-right panel corner → down
/// the right edge → along the bottom edge → up the left edge → closing
/// back at the start. The active tab's own bottom (the span between its
/// two shoulders, at `y = tabHeight`) is never stroked — the path simply
/// passes through it as an interior seam-free join, exactly like the
/// panel fill and the tab fill are painted as one region with no line
/// between them.
///
/// This painter reads no [BuildContext], theme, or tokens itself — per the
/// repo's `CustomPainter` convention, every colour and dimension is
/// supplied by the caller, which resolves them from `context.tokens`.
@immutable
class LayrzWorkspaceSilhouettePainter extends CustomPainter {
  /// The fill colour shared by the active tab's interior and the panel's
  /// interior — painted as a single continuous region so no line can ever
  /// appear between them.
  final Color fillColor;

  /// The active tab's own top edge, in this painter's local y-coordinates.
  ///
  /// The painter's canvas starts above the tab (at the frame's inset), so the
  /// tab bump begins at `tabTop` rather than at `y = 0` — giving the tab's top
  /// border stroke room to paint without being clipped at the canvas edge.
  final double tabTop;

  /// The active tab band's bottom edge, in this painter's local
  /// y-coordinates: where the tab's open bottom joins the content card's top.
  final double tabHeight;

  /// The active tab's left edge, in this painter's local x-coordinates.
  ///
  /// `null` when no tab is currently active, in which case the silhouette
  /// degrades to a plain rounded-rectangle panel with no bump and no
  /// tab-band fill.
  final double? tabLeft;

  /// The active tab's right edge, in this painter's local x-coordinates.
  ///
  /// `null` when no tab is currently active — see [tabLeft].
  final double? tabRight;

  /// The corner radius applied to the tab bump's top-left and top-right
  /// corners (curving inward), mirroring
  /// `LayrzWorkspaceTabChromePainter.topRadius`.
  final double tabTopRadius;

  /// The size of the outward-flaring shoulder where the tab's vertical
  /// sides meet the panel's top edge, mirroring
  /// `LayrzWorkspaceTabChromePainter.shoulderRadius`.
  final double shoulderRadius;

  /// The corner radius applied to all four outer corners of the panel
  /// itself.
  final double panelRadius;

  /// The single stroke colour used for the whole silhouette outline.
  final Color borderColor;

  /// The single stroke width used for the whole silhouette outline.
  final double borderWidth;

  /// When `true`, only the border stroke is painted (no fill).
  ///
  /// The widget layers TWO instances of this painter: a fill-and-stroke copy
  /// *beneath* the tab strip (so the `sf1` fill sits behind the tab labels and
  /// content), and a stroke-only copy *above* the strip (so the active tab's
  /// border is never covered by an adjacent inactive tab's opaque fill). Both
  /// build the identical path, so the two strokes coincide exactly.
  final bool strokeOnly;

  /// Creates a new [LayrzWorkspaceSilhouettePainter].
  ///
  /// Parameters:
  ///   - [fillColor]: the fill shared by the tab and panel interiors.
  ///   - [tabHeight]: the active tab band's height, from this painter's
  ///     `y = 0` down to the panel's top edge.
  ///   - [tabLeft], [tabRight]: the active tab's x-span in this painter's
  ///     local coordinates. Both `null` draws an unbroken panel with no
  ///     bump.
  ///   - [tabTopRadius]: inward corner radius for the tab bump's top
  ///     corners.
  ///   - [shoulderRadius]: outward-flare size where the tab meets the
  ///     panel's top edge. Defaults to `0`.
  ///   - [panelRadius]: corner radius for the panel's own four corners.
  ///   - [borderColor]: the single stroke colour for the whole outline.
  ///   - [borderWidth]: the single stroke width for the whole outline.
  ///     Defaults to `1.0`.
  const LayrzWorkspaceSilhouettePainter({
    required this.fillColor,
    this.tabTop = 0.0,
    required this.tabHeight,
    this.tabLeft,
    this.tabRight,
    required this.tabTopRadius,
    this.shoulderRadius = 0.0,
    required this.panelRadius,
    required this.borderColor,
    this.borderWidth = 1.0,
    this.strokeOnly = false,
  });

  /// Builds the single continuous [Path] tracing the whole silhouette: the
  /// panel's rounded-rectangle perimeter with the active tab's bump
  /// spliced into its top edge.
  ///
  /// The tab-bump segment itself is not re-derived here — it is built by
  /// the exact same [buildWorkspaceTabBumpPath] function an inactive tab's
  /// own [LayrzWorkspaceTabChromePainter] uses, translated into place at
  /// `(gapStart, 0)`. That is what guarantees the active tab's silhouette
  /// bump and every inactive tab's own closed shape are pixel-identical —
  /// one shared geometry definition, never two hand-derived paths that
  /// merely aim to match.
  ///
  /// Used for both the fill (so the tab and panel interiors are one
  /// region) and the stroke (so the whole outline is drawn with a single
  /// `drawPath` call). When [tabLeft] or [tabRight] is `null`, this
  /// degrades to a plain rounded rectangle covering just the panel band
  /// (`y >= tabHeight`), matching the "no active tab" fallback the
  /// previous two-painter design also had.
  Path _buildSilhouettePath(Size size) {
    // The stroke is centred on the path, so a path drawn at the canvas's very
    // edges would paint half its width off-canvas and be clipped there --
    // making the left/right/bottom edges look thinner than the tab area,
    // which sits inset from the canvas. Inset the whole silhouette by half
    // the stroke width so the entire outline stays inside the canvas and is
    // painted at a consistent width all the way around.
    final inset = borderWidth / 2;
    final l = inset;
    final r = size.width - inset;
    // The tab bump's top sits at `tabTop`, which is already inset from the
    // canvas top by the frame's own `sp1` band, so it needs no extra inset --
    // its top border has room to paint. Guard against it landing above the
    // half-stroke inset anyway.
    final t = tabTop.clamp(inset, size.height);
    final b = size.height - inset;
    final width = r - l;
    final bumpHeight = tabHeight - t;
    final panelTop = tabHeight;
    final panelHeight = b - panelTop;
    final pr = panelRadius.clamp(0.0, panelHeight.clamp(0.0, width) / 2);

    final tabLeftV = tabLeft;
    final tabRightV = tabRight;
    if (tabLeftV == null || tabRightV == null) {
      return Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(l, panelTop, r, b), Radius.circular(pr)));
    }

    final sr = shoulderRadius.clamp(0.0, ((width / 2) - pr).clamp(0.0, width / 2));
    final gapStart = tabLeftV.clamp(l + pr + sr, r - pr - sr);
    final gapEnd = tabRightV.clamp(gapStart, r - pr - sr);

    final bump = buildWorkspaceTabBumpPath(
      width: gapEnd - gapStart,
      height: bumpHeight,
      topRadius: tabTopRadius,
      shoulderRadius: shoulderRadius,
    ).shift(Offset(gapStart, t));

    return Path()
      // Start just after the panel's top-left corner, on its flat top
      // edge, and sweep right to where the tab's left shoulder begins.
      ..moveTo(l + pr, panelTop)
      ..lineTo(gapStart, panelTop)
      // Splice in the shared tab-bump segment: up the left shoulder, up
      // the left side, across the rounded top, down the right side, down
      // the right shoulder -- ending back on the panel's flat top edge at
      // `gapEnd`. `extendWithPath` continues the *current* path with
      // `bump`'s contours without starting a new subpath, so this remains
      // one unbroken path end to end.
      ..extendWithPath(bump, Offset.zero)
      // Continue right along the panel's top edge to its top-right corner.
      ..lineTo(r - pr, panelTop)
      ..arcToPoint(Offset(r, panelTop + pr), radius: Radius.circular(pr), clockwise: true)
      // Right edge down to the bottom-right corner.
      ..lineTo(r, b - pr)
      ..arcToPoint(Offset(r - pr, b), radius: Radius.circular(pr), clockwise: true)
      // Bottom edge, right to left.
      ..lineTo(l + pr, b)
      ..arcToPoint(Offset(l, b - pr), radius: Radius.circular(pr), clockwise: true)
      // Left edge up to the top-left corner.
      ..lineTo(l, panelTop + pr)
      ..arcToPoint(Offset(l + pr, panelTop), radius: Radius.circular(pr), clockwise: true)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildSilhouettePath(size);

    if (!strokeOnly) {
      canvas.drawPath(path, Paint()..color = fillColor);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant LayrzWorkspaceSilhouettePainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.tabTop != tabTop ||
      oldDelegate.tabHeight != tabHeight ||
      oldDelegate.tabLeft != tabLeft ||
      oldDelegate.tabRight != tabRight ||
      oldDelegate.tabTopRadius != tabTopRadius ||
      oldDelegate.shoulderRadius != shoulderRadius ||
      oldDelegate.panelRadius != panelRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.strokeOnly != strokeOnly;
}
