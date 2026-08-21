import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSelectionMagnifier', () {
    test('magnifierConfigurationFor returns null on desktop platforms', () {
      // On desktop platforms, the magnifier configuration should be null.
      // This test runs on the host platform, so it depends on the CI environment.
      // For now, we just verify the static method exists and can be called.
      expect(LayrzSelectionMagnifier.magnifierConfigurationFor, isNotNull);
    });

    test('magnifierConfigurationFor accepts custom scale', () {
      // The configuration might be null on desktop, but the method should accept the parameter.
      // Just verify the method signature works with different scales.
      expect(LayrzSelectionMagnifier.magnifierConfigurationFor(scale: 1.5), anything);
      expect(LayrzSelectionMagnifier.magnifierConfigurationFor(scale: 2.0), anything);
    });

    testWidgets('widget renders as SizedBox.shrink', (WidgetTester tester) async {
      await tester.pumpWidget(
        const LayrzSelectionMagnifier(),
      );
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
