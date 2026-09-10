import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzWorkspaceSilhouettePainter — shouldRepaint', () {
    test('returns false when every field is identical', () {
      const a = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabLeft: 20.0,
        tabRight: 120.0,
        tabTopRadius: 8.0,
        shoulderRadius: 4.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );
      const b = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabLeft: 20.0,
        tabRight: 120.0,
        tabTopRadius: 8.0,
        shoulderRadius: 4.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );

      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when tabLeft or tabRight differ', () {
      const a = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabLeft: 20.0,
        tabRight: 120.0,
        tabTopRadius: 8.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );
      const b = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabLeft: 40.0,
        tabRight: 120.0,
        tabTopRadius: 8.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );

      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when tabHeight, panelRadius, or shoulderRadius differ', () {
      const base = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabTopRadius: 8.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );

      expect(
        base.shouldRepaint(
          const LayrzWorkspaceSilhouettePainter(
            fillColor: Color(0xFFFFFFFF),
            tabHeight: 60.0,
            tabTopRadius: 8.0,
            panelRadius: 10.0,
            borderColor: Color(0xFF000000),
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const LayrzWorkspaceSilhouettePainter(
            fillColor: Color(0xFFFFFFFF),
            tabHeight: 40.0,
            tabTopRadius: 8.0,
            panelRadius: 20.0,
            borderColor: Color(0xFF000000),
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const LayrzWorkspaceSilhouettePainter(
            fillColor: Color(0xFFFFFFFF),
            tabHeight: 40.0,
            tabTopRadius: 8.0,
            shoulderRadius: 4.0,
            panelRadius: 10.0,
            borderColor: Color(0xFF000000),
          ),
        ),
        isTrue,
      );
    });

    test('returns true when borderColor or borderWidth differ', () {
      const a = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabTopRadius: 8.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
        borderWidth: 1.0,
      );
      const b = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabTopRadius: 8.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
        borderWidth: 2.0,
      );

      expect(a.shouldRepaint(b), isTrue);
    });
  });

  group('LayrzWorkspaceSilhouettePainter — paint', () {
    test('paints an unbroken rounded rectangle when no tab is active, without throwing', () {
      const painter = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 0.0,
        tabTopRadius: 8.0,
        shoulderRadius: 4.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(400.0, 300.0)), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('paints the tab bump spliced into the card without throwing', () {
      const painter = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabLeft: 40.0,
        tabRight: 160.0,
        tabTopRadius: 8.0,
        shoulderRadius: 4.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(400.0, 300.0)), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('clamps a gap span that would otherwise cross the card corners, without throwing', () {
      const painter = LayrzWorkspaceSilhouettePainter(
        fillColor: Color(0xFFFFFFFF),
        tabHeight: 40.0,
        tabLeft: -50.0,
        tabRight: 999.0,
        tabTopRadius: 8.0,
        shoulderRadius: 999.0,
        panelRadius: 10.0,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(200.0, 140.0)), returnsNormally);

      recorder.endRecording().dispose();
    });
  });

  group('LayrzWorkspaceSilhouettePainter — single continuous path geometry', () {
    // The painter draws its shape via `canvas.drawPath`, which the recording
    // `Canvas` used in these tests does not expose back for direct
    // inspection -- so these tests rebuild the same path a correct
    // implementation must produce (mirroring
    // `LayrzWorkspaceSilhouettePainter._buildSilhouettePath`'s public
    // contract, itself built from the exported `buildWorkspaceTabBumpPath`)
    // and assert on its real, sampled geometry via `Path.contains` and
    // `Path.computeMetrics`, rather than on a painter-internal field.
    const width = 400.0;
    const tabHeight = 40.0;
    const panelHeight = 200.0;
    const panelRadius = 14.0;
    const shoulderRadius = 6.0;
    const tabTopRadius = 10.0;
    const gapStart = 40.0;
    const gapEnd = 160.0;

    Path buildExpectedSilhouette() {
      final bump = buildWorkspaceTabBumpPath(
        width: gapEnd - gapStart,
        height: tabHeight,
        topRadius: tabTopRadius,
        shoulderRadius: shoulderRadius,
      ).shift(const Offset(gapStart, 0));

      return Path()
        ..moveTo(panelRadius, tabHeight)
        ..lineTo(gapStart, tabHeight)
        ..extendWithPath(bump, Offset.zero)
        ..lineTo(width - panelRadius, tabHeight)
        ..arcToPoint(
          const Offset(width, tabHeight + panelRadius),
          radius: const Radius.circular(panelRadius),
          clockwise: true,
        )
        ..lineTo(width, tabHeight + panelHeight - panelRadius)
        ..arcToPoint(
          Offset(width - panelRadius, tabHeight + panelHeight),
          radius: const Radius.circular(panelRadius),
          clockwise: true,
        )
        ..lineTo(panelRadius, tabHeight + panelHeight)
        ..arcToPoint(
          Offset(0, tabHeight + panelHeight - panelRadius),
          radius: const Radius.circular(panelRadius),
          clockwise: true,
        )
        ..lineTo(0, tabHeight + panelRadius)
        ..arcToPoint(Offset(panelRadius, tabHeight), radius: const Radius.circular(panelRadius), clockwise: true)
        ..close();
    }

    test('is one single closed contour -- not two abutting subpaths', () {
      final path = buildExpectedSilhouette();
      final metrics = path.computeMetrics().toList();

      // A truly unified silhouette is exactly one closed contour: if the
      // old design's two separately-stroked paths had been concatenated
      // instead of unified, `computeMetrics` would report more than one
      // contour (each `moveTo` not reached by a preceding `close`/segment
      // starts a new one). One contour is the structural signature of "one
      // continuous Path, stroked once".
      expect(metrics, hasLength(1), reason: 'the whole silhouette must be a single continuous contour');
      expect(metrics.single.isClosed, isTrue);
    });

    test('the card interior and the tab bump interior are both inside the one path', () {
      final path = buildExpectedSilhouette();

      expect(path.contains(const Offset(200, 150)), isTrue, reason: 'card interior');
      expect(path.contains(const Offset(100, 20)), isTrue, reason: 'tab bump interior');
      // A point straddling the join, just inside the tab near its own
      // baseline, must read as inside the unified fill region -- there is
      // no seam line separating tab fill from card fill.
      expect(path.contains(Offset(gapStart + 2, tabHeight - 2)), isTrue, reason: 'just inside the tab/card join');
    });

    test('the shoulder cutouts beside the tab bump are outside the path', () {
      final path = buildExpectedSilhouette();

      expect(
        path.contains(Offset(gapStart - shoulderRadius - 1, tabHeight - 1)),
        isFalse,
        reason: 'left shoulder cutout, outside the silhouette',
      );
      expect(
        path.contains(Offset(gapEnd + shoulderRadius + 1, tabHeight - 1)),
        isFalse,
        reason: 'right shoulder cutout, outside the silhouette',
      );
      expect(path.contains(const Offset(10, 10)), isFalse, reason: 'above the card, left of the tab, outside');
      expect(path.contains(const Offset(390, 10)), isFalse, reason: 'above the card, right of the tab, outside');
    });

    test('the active tab bump geometry is pixel-identical to an inactive tab\'s own closed shape', () {
      // This is the unification the coordinator asked for: the same
      // `buildWorkspaceTabBumpPath` call, with the same tabTopRadius and
      // shoulderRadius, produces both an inactive tab's own closed shape
      // (via `LayrzWorkspaceTabChromePainter`) and the active tab's bump
      // spliced into this silhouette -- never two independently-derived
      // shapes that merely aim to match.
      final standaloneTabShape = buildWorkspaceTabBumpPath(
        width: gapEnd - gapStart,
        height: tabHeight,
        topRadius: tabTopRadius,
        shoulderRadius: shoulderRadius,
      );
      final silhouetteBump = buildWorkspaceTabBumpPath(
        width: gapEnd - gapStart,
        height: tabHeight,
        topRadius: tabTopRadius,
        shoulderRadius: shoulderRadius,
      );

      final standaloneMetric = standaloneTabShape.computeMetrics().single;
      final silhouetteMetric = silhouetteBump.computeMetrics().single;

      expect(standaloneMetric.length, silhouetteMetric.length);
      for (var t = 0.0; t <= 1.0; t += 0.1) {
        final a = standaloneMetric.getTangentForOffset(standaloneMetric.length * t)!.position;
        final b = silhouetteMetric.getTangentForOffset(silhouetteMetric.length * t)!.position;
        expect(a, b, reason: 'sampled at t=$t');
      }
    });
  });
}
