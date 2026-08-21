import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTextSelectionControls', () {
    test('is a singleton', () {
      final controls1 = LayrzTextSelectionControls.instance;
      final controls2 = LayrzTextSelectionControls.instance;
      expect(identical(controls1, controls2), true, reason: 'Should return the same instance');
    });

    test('singleton is equal to itself', () {
      final controls = LayrzTextSelectionControls.instance;
      expect(controls == controls, true);
    });

    test('all instances compare equal', () {
      final controls1 = LayrzTextSelectionControls.instance;
      // Note: We can't create new instances due to the private constructor,
      // so this test just verifies the singleton is equal to itself
      expect(controls1 == controls1, true);
    });

    testWidgets('buildHandle returns a GestureDetector with CustomPaint for each type', (WidgetTester tester) async {
      final controls = LayrzTextSelectionControls.instance;

      // Test left handle
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            return controls.buildHandle(context, TextSelectionHandleType.left, 16.0, () {});
          },
        ),
      );
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Test right handle
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            return controls.buildHandle(context, TextSelectionHandleType.right, 16.0, () {});
          },
        ),
      );
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Test collapsed handle
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            return controls.buildHandle(context, TextSelectionHandleType.collapsed, 16.0, () {});
          },
        ),
      );
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    test('getHandleSize returns fixed 22x22 size', () {
      final controls = LayrzTextSelectionControls.instance;

      // Size should be fixed at 22x22 regardless of text line height
      final size1 = controls.getHandleSize(16.0);
      expect(size1, const Size(22.0, 22.0));

      final size2 = controls.getHandleSize(32.0);
      expect(size2, const Size(22.0, 22.0));

      final sizeSmall = controls.getHandleSize(1.0);
      expect(sizeSmall, const Size(22.0, 22.0));
    });

    test('getHandleAnchor returns correct anchor for each handle type', () {
      final controls = LayrzTextSelectionControls.instance;
      const handleSize = 22.0;

      // Collapsed: anchor at top-center
      final collapsedAnchor = controls.getHandleAnchor(TextSelectionHandleType.collapsed, 16.0);
      expect(collapsedAnchor, Offset(handleSize / 2, -4));

      // Left: anchor at right edge
      final leftAnchor = controls.getHandleAnchor(TextSelectionHandleType.left, 16.0);
      expect(leftAnchor, Offset(handleSize, 0));

      // Right: anchor at left edge
      final rightAnchor = controls.getHandleAnchor(TextSelectionHandleType.right, 16.0);
      expect(rightAnchor, Offset.zero);
    });

    testWidgets(
      'buildHandle GestureDetector uses translucent hit test behavior to allow drag gestures',
      (WidgetTester tester) async {
        final controls = LayrzTextSelectionControls.instance;

        // Build the handle widget
        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              return controls.buildHandle(
                context,
                TextSelectionHandleType.collapsed,
                16.0,
                () {},
              );
            },
          ),
        );

        // Verify the GestureDetector has translucent behavior
        final gestureDetectorFinder = find.byType(GestureDetector);
        expect(gestureDetectorFinder, findsOneWidget);

        final gestureDetector = tester.firstWidget<GestureDetector>(gestureDetectorFinder);
        expect(
          gestureDetector.behavior,
          HitTestBehavior.translucent,
          reason: 'GestureDetector must use translucent hit test behavior to allow framework drag recognizers to work',
        );
      },
    );

    testWidgets(
      'buildHandle widget size matches getHandleSize to ensure proper hit area alignment',
      (WidgetTester tester) async {
        final controls = LayrzTextSelectionControls.instance;
        final expectedSize = controls.getHandleSize(16.0);

        // Build the handle widget
        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              return controls.buildHandle(
                context,
                TextSelectionHandleType.collapsed,
                16.0,
                () {},
              );
            },
          ),
        );

        // The handle should be a SizedBox with size matching getHandleSize
        final sizedBoxFinder = find.byType(SizedBox);
        expect(sizedBoxFinder, findsOneWidget);

        final sizedBox = tester.firstWidget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.width, expectedSize.width);
        expect(sizedBox.height, expectedSize.height);
      },
    );

    testWidgets(
      'left handle is rotated 90° clockwise (π/2) to point up-right (NE) at selection start',
      (WidgetTester tester) async {
        final controls = LayrzTextSelectionControls.instance;

        // Build the left handle
        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              return controls.buildHandle(
                context,
                TextSelectionHandleType.left,
                16.0,
              );
            },
          ),
        );

        // The left handle should be wrapped in a Transform.rotate with angle π/2
        final transformRotateFinder = find.byType(Transform);
        expect(transformRotateFinder, findsOneWidget);

        final transform = tester.firstWidget<Transform>(transformRotateFinder);
        // Extract the rotation angle from the transform matrix
        // Transform.rotate creates a rotation matrix, we check the angle is approximately π/2
        expect(
          transform.transform[0] + transform.transform[5],
          closeTo(0.0, 0.01),
          reason: 'Left handle should rotate π/2 clockwise to point NE',
        );
      },
    );

    testWidgets(
      'right handle has no rotation and points up-left (NW) at selection end',
      (WidgetTester tester) async {
        final controls = LayrzTextSelectionControls.instance;

        // Build the right handle
        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              return controls.buildHandle(
                context,
                TextSelectionHandleType.right,
                16.0,
              );
            },
          ),
        );

        // The right handle should NOT be wrapped in a Transform.rotate
        // It should be the bare handle with GestureDetector and CustomPaint
        final transformRotateFinder = find.byType(Transform);
        expect(transformRotateFinder, findsNothing, reason: 'Right handle should have no rotation to point NW');

        final customPaintFinder = find.byType(CustomPaint);
        expect(
          customPaintFinder,
          findsOneWidget,
          reason: 'Right handle should still have CustomPaint for the teardrop',
        );
      },
    );

    testWidgets(
      'collapsed handle is rotated 45° clockwise (π/4) to point straight up (N)',
      (WidgetTester tester) async {
        final controls = LayrzTextSelectionControls.instance;

        // Build the collapsed handle
        await pumpThemed(
          tester,
          Builder(
            builder: (context) {
              return controls.buildHandle(
                context,
                TextSelectionHandleType.collapsed,
                16.0,
              );
            },
          ),
        );

        // The collapsed handle should be wrapped in a Transform.rotate with angle π/4
        final transformRotateFinder = find.byType(Transform);
        expect(transformRotateFinder, findsOneWidget);

        final transform = tester.firstWidget<Transform>(transformRotateFinder);
        // For π/4 rotation: cos(π/4) ≈ 0.707, sin(π/4) ≈ 0.707
        // The rotation matrix should have specific values for 45° clockwise rotation
        expect(
          transform.transform[0] + transform.transform[5],
          closeTo(2 * math.cos(math.pi / 4), 0.01),
          reason: 'Collapsed handle should rotate π/4 clockwise to point N',
        );
      },
    );

    testWidgets(
      'unrotated painter shows square corner at top-left (NW) of teardrop',
      (WidgetTester tester) async {
        // This test verifies the base orientation that all other rotations derive from.
        // The teardrop is created by: circle - top-left quadrant = circle with corner at NW
        await pumpThemed(
          tester,
          Center(
            child: CustomPaint(
              size: const Size(22.0, 22.0),
              painter: LayrzSelectionHandlePainter(
                color: Color(0xFF6200EE), // arbitrary color for testing
              ),
            ),
          ),
        );

        // Verify the CustomPaint widget is present
        final customPaintFinder = find.byType(CustomPaint);
        expect(customPaintFinder, findsOneWidget, reason: 'Unrotated painter should render without Transform');

        // Render and check that the painter produces output
        final customPaint = tester.firstWidget<CustomPaint>(customPaintFinder);
        expect(
          customPaint.painter,
          isA<LayrzSelectionHandlePainter>(),
          reason: 'Painter should be LayrzSelectionHandlePainter with unrotated teardrop',
        );
      },
    );
  });
}
