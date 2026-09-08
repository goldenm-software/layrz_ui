import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/skeleton/src/skeleton_fill.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzSkeletonFill', () {
    guardedTestWidgets('the default constructor stores the given borderRadius and is not a circle', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const SizedBox(width: 50, height: 30, child: LayrzSkeletonFill(borderRadius: 8)));

      final fill = tester.widget<LayrzSkeletonFill>(find.byType(LayrzSkeletonFill));
      expect(fill.borderRadius, 8);
      expect(fill.isCircle, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('LayrzSkeletonFill.circle sets isCircle and leaves borderRadius null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const SizedBox(width: 40, height: 40, child: LayrzSkeletonFill.circle()));

      final fill = tester.widget<LayrzSkeletonFill>(find.byType(LayrzSkeletonFill));
      expect(fill.isCircle, isTrue);
      expect(fill.borderRadius, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('fills exactly the size given by its parent (no-reflow)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const SizedBox(width: 120, height: 45, child: LayrzSkeletonFill(borderRadius: 4)));

      final box = tester.renderObject<RenderBox>(find.byType(LayrzSkeletonFill));
      expect(box.size, const Size(120, 45));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('paints a rounded rect with antialiasing disabled, matching the ShaderMask hard edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const SizedBox(width: 60, height: 60, child: LayrzSkeletonFill(borderRadius: 12)));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(LayrzSkeletonFill), matching: find.byType(CustomPaint)),
      );

      // The seam this widget exists to fix comes from an antialiasing
      // mismatch between the shape's own fill edge and the engine's
      // ShaderMask mask edge (a hard, non-antialiased rect -- see
      // shader_mask_layer.cc). Record the actual paint call this painter
      // issues and assert its Paint really does disable antialiasing --
      // not merely that painting completes without throwing.
      final recordingCanvas = TestRecordingCanvas();
      customPaint.painter!.paint(recordingCanvas, const Size(60, 60));

      final drawRRectCall = recordingCanvas.invocations.single;
      expect(drawRRectCall.invocation.memberName, #drawRRect);
      final paint = drawRRectCall.invocation.positionalArguments[1] as Paint;
      expect(paint.isAntiAlias, isFalse);
      expect(paint.color, const Color(0xFF000000));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('LayrzSkeletonFill.circle paints via drawOval with antialiasing disabled', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const SizedBox(width: 40, height: 40, child: LayrzSkeletonFill.circle()));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(LayrzSkeletonFill), matching: find.byType(CustomPaint)),
      );

      final recordingCanvas = TestRecordingCanvas();
      customPaint.painter!.paint(recordingCanvas, const Size(40, 40));

      final drawOvalCall = recordingCanvas.invocations.single;
      expect(drawOvalCall.invocation.memberName, #drawOval);
      final paint = drawOvalCall.invocation.positionalArguments[1] as Paint;
      expect(paint.isAntiAlias, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('a zero borderRadius paints via drawRect (sharp corners) rather than drawRRect', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const SizedBox(width: 30, height: 30, child: LayrzSkeletonFill(borderRadius: 0)));

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(LayrzSkeletonFill), matching: find.byType(CustomPaint)),
      );

      final recordingCanvas = TestRecordingCanvas();
      customPaint.painter!.paint(recordingCanvas, const Size(30, 30));

      final drawCall = recordingCanvas.invocations.single;
      expect(drawCall.invocation.memberName, #drawRect);
      final paint = drawCall.invocation.positionalArguments[1] as Paint;
      expect(paint.isAntiAlias, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('a zero-size box does not throw when painted', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const SizedBox(width: 0, height: 0, child: LayrzSkeletonFill.circle()),
      );

      expect(find.byType(LayrzSkeletonFill), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    guardedTestWidgets('shouldRepaint compares borderRadius and isCircle by value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final painter8 = await _painterOf(tester, const LayrzSkeletonFill(borderRadius: 8));
      final painter8Again = await _painterOf(tester, const LayrzSkeletonFill(borderRadius: 8));
      final painter12 = await _painterOf(tester, const LayrzSkeletonFill(borderRadius: 12));
      final painterCircle = await _painterOf(tester, const LayrzSkeletonFill.circle());

      expect(painter8.shouldRepaint(painter8Again), isFalse);
      expect(painter8.shouldRepaint(painter12), isTrue);
      expect(painter8.shouldRepaint(painterCircle), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// Pumps [fill] standalone and reads back the [CustomPainter] its build
/// produced, so [CustomPainter.shouldRepaint] can be exercised directly
/// against a real widget tree rather than a hand-built [BuildContext].
///
/// Fully tears down the tree first with [SizedBox.shrink] -- [pumpThemed]'s
/// [Overlay] treats `initialEntries` as a one-time seed, not something it
/// re-reads on every rebuild, so calling this back-to-back without a reset
/// between calls would silently keep the first pump's [OverlayEntry] (and
/// therefore its already-built [CustomPaint]) instead of building a new one
/// for the new [fill].
Future<CustomPainter> _painterOf(WidgetTester tester, LayrzSkeletonFill fill) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpThemed(tester, SizedBox(width: 40, height: 40, child: fill));
  final customPaint = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(LayrzSkeletonFill), matching: find.byType(CustomPaint)),
  );
  return customPaint.painter!;
}
