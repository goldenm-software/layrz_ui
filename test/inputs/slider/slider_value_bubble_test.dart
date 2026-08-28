import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzSliderValueBubble', () {
    guardedTestWidgets('renders the given text', (tester) async {
      final tokens = LayrzTokens.light();
      await pumpThemed(
        tester,
        LayrzSliderValueBubble(
          text: '42',
          color: tokens.colors.fg1,
          textColor: tokens.colors.sf1,
          tokens: tokens,
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    guardedTestWidgets('applies the given fill colour to the painted background', (tester) async {
      final tokens = LayrzTokens.light();
      const fill = Color(0xFF123456);
      const textColor = Color(0xFFABCDEF);

      await pumpThemed(
        tester,
        LayrzSliderValueBubble(
          text: '7',
          color: fill,
          textColor: textColor,
          tokens: tokens,
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
      final painter = customPaint.painter as LayrzSliderBubblePainter;
      expect(painter.color, fill);

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, textColor);
    });

    guardedTestWidgets('applies the r1 radius token and compact2 shadow from tokens', (tester) async {
      final tokens = LayrzTokens.light();
      await pumpThemed(
        tester,
        LayrzSliderValueBubble(
          text: '1',
          color: tokens.colors.fg1,
          textColor: tokens.colors.sf1,
          tokens: tokens,
        ),
      );

      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
      final painter = customPaint.painter as LayrzSliderBubblePainter;
      expect(painter.radius, tokens.radius.r1);
      expect(painter.shadows, tokens.shadow.compact2);
      expect(painter.shadows, isNotEmpty);
    });

    guardedTestWidgets('reserves tailHeight of extra bottom space beyond the text content', (tester) async {
      final tokens = LayrzTokens.light();
      final key = GlobalKey();

      await pumpThemed(
        tester,
        SizedBox(
          key: key,
          child: LayrzSliderValueBubble(
            text: '45.14',
            color: tokens.colors.fg1,
            textColor: tokens.colors.sf1,
            tokens: tokens,
          ),
        ),
      );

      final size = (key.currentContext!.findRenderObject() as RenderBox).size;
      // The overall widget must be taller than just the vertical padding +
      // text -- the extra height is the reserved tail strip.
      expect(size.height, greaterThan(tokens.spacing.sp1 + LayrzSliderValueBubble.tailHeight));
    });
  });

  group('LayrzSliderBubblePainter', () {
    const baseShadows = [
      BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
    ];

    LayrzSliderBubblePainter buildPainter({
      Color color = const Color(0xFF3366FF),
      double radius = 6.0,
      double tailWidth = 10.0,
      double tailHeight = 6.0,
      List<BoxShadow> shadows = baseShadows,
    }) {
      return LayrzSliderBubblePainter(
        color: color,
        radius: radius,
        tailWidth: tailWidth,
        tailHeight: tailHeight,
        shadows: shadows,
      );
    }

    test('creates with the given geometry, colour, and shadows', () {
      final painter = buildPainter();
      expect(painter.color, const Color(0xFF3366FF));
      expect(painter.radius, 6.0);
      expect(painter.tailWidth, 10.0);
      expect(painter.tailHeight, 6.0);
      expect(painter.shadows, baseShadows);
    });

    test('buildPath places the tail triangle below the body rect', () {
      final painter = buildPainter(tailWidth: 10, tailHeight: 6);
      const size = Size(80, 24);
      final path = painter.buildPath(size);
      final bounds = path.getBounds();

      // The combined path's bounds must span the full painted size: the body
      // reaches the top, and the tail's tip reaches the very bottom.
      expect(bounds.top, closeTo(0, 0.5));
      expect(bounds.bottom, closeTo(size.height, 0.5));
      expect(bounds.left, closeTo(0, 0.5));
      expect(bounds.right, closeTo(size.width, 0.5));
    });

    test('buildPath centres the tail horizontally under the body', () {
      final painter = buildPainter(tailWidth: 10, tailHeight: 6);
      const size = Size(80, 24);
      final path = painter.buildPath(size);

      // The tail's apex sits at the exact bottom-centre of the painted area:
      // a point there must be inside the unioned path, and points well
      // outside the tail's base width at that same height must not be.
      expect(path.contains(const Offset(40, 23.9)), isTrue);
      expect(path.contains(const Offset(5, 23.9)), isFalse);
      expect(path.contains(const Offset(75, 23.9)), isFalse);
    });

    test('buildPath fills the body region above the tail strip', () {
      final painter = buildPainter(tailWidth: 10, tailHeight: 6);
      const size = Size(80, 24);
      final path = painter.buildPath(size);

      // Well inside the rounded-rect body (away from the corners), the path
      // must be solid.
      expect(path.contains(const Offset(40, 9)), isTrue);
      expect(path.contains(const Offset(5, 9)), isTrue);
      expect(path.contains(const Offset(75, 9)), isTrue);
    });

    test('paint completes without error with shadows present', () {
      final painter = buildPainter();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(80, 24)), returnsNormally);
      recorder.endRecording();
    });

    test('paint completes without error with an empty shadow list', () {
      final painter = buildPainter(shadows: const []);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(80, 24)), returnsNormally);
      recorder.endRecording();
    });

    test('shouldRepaint returns true when color changes', () {
      final a = buildPainter();
      final b = buildPainter(color: const Color(0xFF000000));
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when radius changes', () {
      final a = buildPainter();
      final b = buildPainter(radius: 20.0);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when tailWidth changes', () {
      final a = buildPainter();
      final b = buildPainter(tailWidth: 20.0);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when tailHeight changes', () {
      final a = buildPainter();
      final b = buildPainter(tailHeight: 20.0);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when shadows change', () {
      final a = buildPainter();
      final b = buildPainter(shadows: const []);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final a = buildPainter();
      final b = buildPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}
