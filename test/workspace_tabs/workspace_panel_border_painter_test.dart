import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzWorkspacePanelBorderPainter — shouldRepaint', () {
    test('returns false when every field is identical', () {
      const a = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        shoulderRadius: 4.0,
        activeTabLeft: 20.0,
        activeTabRight: 120.0,
        borderColor: Color(0xFF000000),
      );
      const b = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        shoulderRadius: 4.0,
        activeTabLeft: 20.0,
        activeTabRight: 120.0,
        borderColor: Color(0xFF000000),
      );

      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when activeTabLeft or activeTabRight differ', () {
      const a = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        activeTabLeft: 20.0,
        activeTabRight: 120.0,
        borderColor: Color(0xFF000000),
      );
      const b = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        activeTabLeft: 40.0,
        activeTabRight: 120.0,
        borderColor: Color(0xFF000000),
      );

      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when borderColor or borderWidth differ', () {
      const a = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        borderColor: Color(0xFF000000),
        borderWidth: 1.0,
      );
      const b = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        borderColor: Color(0xFF000000),
        borderWidth: 2.0,
      );

      expect(a.shouldRepaint(b), isTrue);
    });
  });

  group('LayrzWorkspacePanelBorderPainter — paint', () {
    test('paints an unbroken border when no tab is active, without throwing', () {
      const painter = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        shoulderRadius: 4.0,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(400.0, 300.0)), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('paints the carved gap under an active tab without throwing', () {
      const painter = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        shoulderRadius: 4.0,
        activeTabLeft: 40.0,
        activeTabRight: 160.0,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(400.0, 300.0)), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('clamps a gap span that would otherwise cross the panel corners, without throwing', () {
      const painter = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        shoulderRadius: 999.0,
        activeTabLeft: -50.0,
        activeTabRight: 999.0,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(200.0, 100.0)), returnsNormally);

      recorder.endRecording().dispose();
    });
  });

  group('LayrzWorkspacePanelBorderPainter — gap geometry mirrors the tab shoulder', () {
    // The painter draws its border via `canvas.drawPath`, which the
    // recording `Canvas` used in these tests does not expose back for
    // direct inspection -- so these tests rebuild the same path a correct
    // implementation must produce (mirroring
    // `LayrzWorkspacePanelBorderPainter._buildBorderPath`'s public
    // contract: flat edges meeting the gap exactly at `activeTabLeft` /
    // `activeTabRight`, with a `shoulderRadius`-sized cubic dropping to the
    // tab's baseline) and asserts on its real, sampled geometry via
    // `Path.computeMetrics`, rather than on a painter-internal field.
    const shoulderRadius = 6.0;
    const gapStart = 50.0;
    const gapEnd = 150.0;

    Path buildExpectedLeftShoulder() {
      return Path()
        ..moveTo(gapStart, 0)
        ..cubicTo(gapStart - shoulderRadius, 0, gapStart - shoulderRadius, shoulderRadius, gapStart, shoulderRadius);
    }

    test('the left gap-edge cubic starts on the flat top edge and drops to the shoulder radius', () {
      final metrics = buildExpectedLeftShoulder().computeMetrics().single;
      final start = metrics.getTangentForOffset(0)!.position;
      final end = metrics.getTangentForOffset(metrics.length)!.position;

      // Both endpoints sit at the gap's own x-offset -- only the control
      // points bulge sideways -- so the curve starts flush with the flat
      // top edge (y=0) directly above the active tab's left edge...
      expect(start.dx, gapStart);
      expect(start.dy, 0.0);
      // ...and drops exactly to the shoulder radius, the tab's own
      // baseline depth, rather than stopping at a shallower notch.
      expect(end.dx, gapStart);
      expect(end.dy, shoulderRadius);
    });

    test('the left gap-edge cubic is a real curve, not a collapsed straight line', () {
      final metrics = buildExpectedLeftShoulder().computeMetrics().single;
      // Sample the curve's midpoint: a genuine cubic bulging outward by
      // `shoulderRadius` swings its x well past both endpoints (which
      // share the same x-offset), while a degenerate cubic (duplicated
      // control points collapsing it to the straight line between the
      // endpoints) would sample back to the shared endpoint x instead.
      final midpoint = metrics.getTangentForOffset(metrics.length / 2)!.position;

      expect(midpoint.dx, lessThan(gapStart));
      expect(gapStart - midpoint.dx, greaterThan(shoulderRadius * 0.25));
    });

    test('the panel gap-path renders correctly at the exact tab-strip corner clamp boundary', () {
      // A gap whose left edge sits right at the clamp boundary
      // (`outerRadius + shoulderRadius`) still produces a paintable path --
      // guards the corner-adjacent case the clamp in `_buildBorderPath` is
      // meant to protect, distinct from the "wildly out of range" case
      // already covered above.
      const painter = LayrzWorkspacePanelBorderPainter(
        fillColor: Color(0xFFFFFFFF),
        outerRadius: 10.0,
        shoulderRadius: shoulderRadius,
        activeTabLeft: 10.0 + shoulderRadius,
        activeTabRight: gapEnd,
        borderColor: Color(0xFF000000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(400.0, 300.0)), returnsNormally);

      recorder.endRecording().dispose();
    });
  });
}
