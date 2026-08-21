import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTextSelectionControls', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    test('creates with tokens', () {
      final controls = LayrzTextSelectionControls(tokens: tokens);
      expect(controls.tokens, tokens);
    });

    testWidgets('buildHandle returns a GestureDetector with CustomPaint', (WidgetTester tester) async {
      final controls = LayrzTextSelectionControls(tokens: tokens);
      final handle = controls.buildHandle(
        tester.binding.rootElement!,
        TextSelectionHandleType.left,
        16.0,
        () {},
      );

      await pumpThemed(tester, handle);
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    test('getHandleSize returns proportional size based on text line height', () {
      final controls = LayrzTextSelectionControls(tokens: tokens);

      // Test with 16.0 line height
      final size1 = controls.getHandleSize(16.0);
      expect(size1.height, greaterThan(0));
      expect(size1.width, greaterThan(0));
      expect(size1.width, lessThan(size1.height)); // width should be < height

      // Test with larger line height
      final size2 = controls.getHandleSize(32.0);
      expect(size2.height, greaterThanOrEqualTo(size1.height));

      // Test minimum clamping
      final sizeSmall = controls.getHandleSize(1.0);
      expect(sizeSmall.height, greaterThanOrEqualTo(6.0)); // minimum 6px
    });

    test('getHandleAnchor returns offset at handle bottom-center', () {
      final controls = LayrzTextSelectionControls(tokens: tokens);
      final size = controls.getHandleSize(16.0);
      final anchor = controls.getHandleAnchor(TextSelectionHandleType.left, 16.0);

      // Anchor should be at the bottom-center of the handle
      expect(anchor.dx, size.width / 2);
      expect(anchor.dy, size.height);
    });

  });
}
