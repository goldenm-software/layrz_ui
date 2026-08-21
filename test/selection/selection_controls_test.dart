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
  });
}
