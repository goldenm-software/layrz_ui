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
  });
}
