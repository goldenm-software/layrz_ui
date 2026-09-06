import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/color/color_wheel.dart';
import 'package:layrz_ui/src/pickers/src/color/color_wheel_painter.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzColorWheel — rendering', () {
    guardedTestWidgets('renders a CustomPaint disc plus a value/brightness slider', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorWheel(value: const Color(0xFF0000FF), onChanged: (_) {}),
      );

      expect(find.byType(LayrzColorWheel), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelDiscPainter),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter),
        findsOneWidget,
      );
    });

    guardedTestWidgets('honours a caller-supplied size', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorWheel(value: const Color(0xFF0000FF), onChanged: (_) {}, size: 160.0),
      );

      final box = tester.renderObject<RenderBox>(
        find.byWidgetPredicate((w) => w is SizedBox && w.width == 160.0 && w.height == 160.0).first,
      );
      expect(box.size, const Size(160.0, 160.0));
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorWheel(value: const Color(0xFF0000FF), onChanged: (_) {}),
      );

      expect(find.byType(LayrzColorWheel), findsOneWidget);
    });

    guardedTestWidgets('the marker painter reflects the current color hue/saturation/marker color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final color = HSVColor.fromAHSV(1.0, 120.0, 0.5, 0.75).toColor();

      await pumpThemed(
        tester,
        LayrzColorWheel(value: color, onChanged: (_) {}),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter),
      );
      final painter = customPaint.painter as LayrzColorWheelMarkerPainter;

      expect(painter.hue, closeTo(120.0, 0.5));
      expect(painter.saturation, closeTo(0.5, 0.01));
      expect(painter.markerColor, color);
    });

    guardedTestWidgets('the disc painter reflects the current value/brightness component', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final color = HSVColor.fromAHSV(1.0, 120.0, 0.5, 0.75).toColor();

      await pumpThemed(
        tester,
        LayrzColorWheel(value: color, onChanged: (_) {}),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelDiscPainter),
      );
      final painter = customPaint.painter as LayrzColorWheelDiscPainter;

      expect(painter.value, closeTo(0.75, 0.01));
    });

    guardedTestWidgets('the disc layer is wrapped in its own RepaintBoundary, isolated from the marker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorWheel(value: const Color(0xFF0000FF), onChanged: (_) {}),
      );

      final discPaint = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelDiscPainter);
      final boundaryAncestor = find.ancestor(of: discPaint, matching: find.byType(RepaintBoundary));

      expect(boundaryAncestor, findsWidgets);
    });

    guardedTestWidgets('dragging the marker does not repaint the disc layer (perf fix)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const wheelSize = 220.0;

      await pumpThemed(
        tester,
        LayrzColorWheel(value: const Color(0xFF0000FF), onChanged: (_) {}, size: wheelSize),
      );

      CustomPaint discPaintWidget() => tester.widget<CustomPaint>(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelDiscPainter),
      );
      final discPainterBefore = discPaintWidget().painter as LayrzColorWheelDiscPainter;

      final wheelFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter);
      final topLeft = tester.getTopLeft(wheelFinder);

      await tester.tapAt(topLeft + const Offset(wheelSize / 2 + 20, wheelSize / 2));
      await tester.pump();

      final discPainterAfter = discPaintWidget().painter as LayrzColorWheelDiscPainter;

      // shouldRepaint compares old vs new delegate -- a drag that only moved
      // the marker must produce a disc painter whose own shouldRepaint
      // returns false against the pre-drag one, proving the disc's inputs
      // (only `value`) were untouched by the marker-only change.
      expect(discPainterAfter.shouldRepaint(discPainterBefore), isFalse);
    });
  });

  group('LayrzColorWheel — disc gesture hit-testing (hue = angle, saturation = radius)', () {
    guardedTestWidgets('tapping the exact center reports saturation 0 (a near-white/grey result)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? reported;
      const wheelSize = 220.0;

      await pumpThemed(
        tester,
        LayrzColorWheel(
          value: const Color(0xFF0000FF),
          onChanged: (c) => reported = c,
          size: wheelSize,
        ),
      );

      final wheelFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter);
      final topLeft = tester.getTopLeft(wheelFinder);
      final center = topLeft + const Offset(wheelSize / 2, wheelSize / 2);

      await tester.tapAt(center);
      await tester.pump();

      expect(reported, isNotNull);
      expect(HSVColor.fromColor(reported!).saturation, closeTo(0.0, 0.02));
    });

    guardedTestWidgets('tapping the right edge of the disc reports hue ~0 degrees and saturation ~1', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? reported;
      const wheelSize = 220.0;

      await pumpThemed(
        tester,
        LayrzColorWheel(
          value: const Color(0xFF0000FF),
          onChanged: (c) => reported = c,
          size: wheelSize,
        ),
      );

      final wheelFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter);
      final topLeft = tester.getTopLeft(wheelFinder);
      // Just inside the outer edge, along the positive x-axis from center --
      // hue 0 per the painter's own angle convention (color_wheel_painter.dart).
      final rightEdge = topLeft + const Offset(wheelSize - 2, wheelSize / 2);

      await tester.tapAt(rightEdge);
      await tester.pump();

      expect(reported, isNotNull);
      final hsv = HSVColor.fromColor(reported!);
      expect(hsv.hue, closeTo(0.0, 5.0));
      expect(hsv.saturation, greaterThan(0.9));
    });

    guardedTestWidgets('tapping the bottom edge of the disc reports hue ~90 degrees', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? reported;
      const wheelSize = 220.0;

      await pumpThemed(
        tester,
        LayrzColorWheel(
          value: const Color(0xFF0000FF),
          onChanged: (c) => reported = c,
          size: wheelSize,
        ),
      );

      final wheelFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter);
      final topLeft = tester.getTopLeft(wheelFinder);
      // Straight down from center -- positive y in Flutter's coordinate
      // space, hue 90 per atan2(dy, dx) with dy > 0, dx == 0.
      final bottomEdge = topLeft + const Offset(wheelSize / 2, wheelSize - 2);

      await tester.tapAt(bottomEdge);
      await tester.pump();

      expect(reported, isNotNull);
      final hsv = HSVColor.fromColor(reported!);
      expect(hsv.hue, closeTo(90.0, 5.0));
    });

    guardedTestWidgets('a tap beyond the outer edge clamps saturation to 1.0, not an out-of-range value', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? reported;
      const wheelSize = 220.0;

      await pumpThemed(
        tester,
        LayrzColorWheel(
          value: const Color(0xFF0000FF),
          onChanged: (c) => reported = c,
          size: wheelSize,
        ),
      );

      final wheelFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter);
      final topLeft = tester.getTopLeft(wheelFinder);

      // Drag starting inside the disc (required so the gesture arena
      // recognizes it as belonging to this widget) then well outside its
      // outer edge -- saturation must clamp, not exceed 1.0 or throw.
      await tester.dragFrom(
        topLeft + const Offset(wheelSize / 2 + 10, wheelSize / 2),
        const Offset(500, 0),
      );
      await tester.pump();

      expect(reported, isNotNull);
      final hsv = HSVColor.fromColor(reported!);
      expect(hsv.saturation, lessThanOrEqualTo(1.0));
      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('preserves the current value/brightness component while dragging on the disc', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? reported;
      const wheelSize = 220.0;
      final seeded = HSVColor.fromAHSV(1.0, 200.0, 0.6, 0.4).toColor();

      await pumpThemed(
        tester,
        LayrzColorWheel(
          value: seeded,
          onChanged: (c) => reported = c,
          size: wheelSize,
        ),
      );

      final wheelFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayrzColorWheelMarkerPainter);
      final topLeft = tester.getTopLeft(wheelFinder);
      final center = topLeft + const Offset(wheelSize / 2, wheelSize / 2);

      await tester.tapAt(center + const Offset(30, 0));
      await tester.pump();

      expect(reported, isNotNull);
      expect(HSVColor.fromColor(reported!).value, closeTo(0.4, 0.01));
    });
  });

  group('LayrzColorWheel — value/brightness slider', () {
    guardedTestWidgets('dragging the slider changes value/brightness while preserving hue and saturation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? reported;
      final seeded = HSVColor.fromAHSV(1.0, 45.0, 0.8, 0.5).toColor();

      await pumpThemed(
        tester,
        LayrzColorWheel(value: seeded, onChanged: (c) => reported = c),
      );

      // The slider is the second GestureDetector composed by this widget
      // (the disc is the first) -- drag near its right edge to push value
      // toward 1.0.
      final sliderFinder = find.byType(GestureDetector).last;
      final topLeft = tester.getTopLeft(sliderFinder);
      final size = tester.getSize(sliderFinder);

      await tester.tapAt(topLeft + Offset(size.width - 4, size.height / 2));
      await tester.pump();

      expect(reported, isNotNull);
      final hsv = HSVColor.fromColor(reported!);
      expect(hsv.value, greaterThan(0.9));
      expect(hsv.hue, closeTo(45.0, 0.5));
      expect(hsv.saturation, closeTo(0.8, 0.01));
    });
  });
}
