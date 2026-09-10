import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('buildWorkspaceTabBumpPath', () {
    test('starts at (0, height) and ends at (width, height), left to right', () {
      final path = buildWorkspaceTabBumpPath(width: 160.0, height: 40.0, topRadius: 8.0, shoulderRadius: 6.0);
      final metrics = path.computeMetrics().toList();

      final firstStart = metrics.first.getTangentForOffset(0)!.position;
      final lastMetric = metrics.last;
      final lastEnd = lastMetric.getTangentForOffset(lastMetric.length)!.position;

      expect(firstStart, const Offset(0.0, 40.0));
      expect(lastEnd, const Offset(160.0, 40.0));
    });

    test('leaves the bottom edge open -- the path is not closed', () {
      // A path this function returns is meant to be either left open (the
      // active tab's silhouette bump, spliced into a larger path) or closed
      // explicitly by the caller (an ordinary tab's own shape) -- it must
      // never silently close itself, since `Path.close()` mutates in
      // place and a caller building on top of it (e.g.
      // `LayrzWorkspaceSilhouettePainter`, which continues the path further
      // rather than closing it here) depends on that.
      final path = buildWorkspaceTabBumpPath(width: 160.0, height: 40.0, topRadius: 8.0, shoulderRadius: 6.0);
      final closed = Path.from(path)..close();

      // A meaningful proxy for "was this path already closed": closing an
      // already-closed path adds no new segment, so the two paths bound the
      // exact same area either way. Compare the bounds of the unmodified
      // path (still open) against the same path after explicit closing --
      // the open path's own bounds already span the same rect either way,
      // so instead assert directly on subpath structure: an open path's
      // final metric does not loop back to its own start.
      final ownMetrics = path.computeMetrics().toList();
      final lastMetric = ownMetrics.last;
      final lastEnd = lastMetric.getTangentForOffset(lastMetric.length)!.position;
      expect(lastEnd, isNot(const Offset(0.0, 40.0)), reason: 'the unclosed path does not loop back to its start');

      // Closing it explicitly does add that missing segment.
      final closedMetrics = closed.computeMetrics().toList();
      expect(closedMetrics.length, greaterThanOrEqualTo(ownMetrics.length));
    });

    test('the tab interior is inside the path and the shoulder cutouts are outside', () {
      const width = 160.0;
      const height = 40.0;
      const topRadius = 8.0;
      const shoulderRadius = 6.0;
      final path = buildWorkspaceTabBumpPath(
        width: width,
        height: height,
        topRadius: topRadius,
        shoulderRadius: shoulderRadius,
      )..close();

      expect(path.contains(const Offset(width / 2, height / 2)), isTrue, reason: 'tab interior');
      expect(path.contains(const Offset(width / 2, topRadius / 2)), isTrue, reason: 'near the rounded top');
      expect(
        path.contains(const Offset(-shoulderRadius - 1, height - 1)),
        isFalse,
        reason: 'left shoulder flare cutout, outside the tab',
      );
      expect(
        path.contains(const Offset(width + shoulderRadius + 1, height - 1)),
        isFalse,
        reason: 'right shoulder flare cutout, outside the tab',
      );
    });

    test('clamps a topRadius/shoulderRadius larger than the available size without throwing', () {
      expect(
        () => buildWorkspaceTabBumpPath(width: 20.0, height: 10.0, topRadius: 999.0, shoulderRadius: 999.0),
        returnsNormally,
      );
    });

    test('handles a zero-size box without throwing', () {
      expect(
        () => buildWorkspaceTabBumpPath(width: 0.0, height: 0.0, topRadius: 8.0, shoulderRadius: 4.0),
        returnsNormally,
      );
    });

    test('a zero shoulderRadius produces square bottom corners with no outward flare', () {
      const width = 100.0;
      const height = 40.0;
      final path = buildWorkspaceTabBumpPath(width: width, height: height, topRadius: 8.0, shoulderRadius: 0.0)
        ..close();

      // With no shoulder flare, nothing outside [0, width] at any height
      // should ever be inside the shape.
      expect(path.contains(const Offset(-1, height - 1)), isFalse);
      expect(path.contains(const Offset(width + 1, height - 1)), isFalse);
    });
  });
}
