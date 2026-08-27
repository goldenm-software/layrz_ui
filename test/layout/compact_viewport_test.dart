import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('Compact viewport sizing (DESIGN-104)', () {
    /// Helper to set viewport width for testing.
    void setPhysicalSize(WidgetTester tester, double width) {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(width, 800);
    }

    testWidgets('context.isCompact is true at width 400 (xs band)', (tester) async {
      setPhysicalSize(tester, 400);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isTrue);
    });

    testWidgets('context.isCompact is false at width 1200 (md band)', (tester) async {
      setPhysicalSize(tester, 1200);

      final themeData = LayrzThemeData.light();
      late bool resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isFalse);
    });

    testWidgets('Compact boundary: 959 is compact (sm), 960 is not (md)', (tester) async {
      final themeData = LayrzThemeData.light();

      // Test at 959 (should be compact)
      setPhysicalSize(tester, 959);
      late bool resolved959;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved959 = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved959, isTrue);

      // Test at 960 (should be normal)
      setPhysicalSize(tester, 960);
      late bool resolved960;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved960 = context.isCompact;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved960, isFalse);
    });

    testWidgets('kLayrzLayoutCompactIconSize constant exists with value 20', (tester) async {
      // Simple constant verification
      expect(kLayrzLayoutCompactIconSize, equals(20.0));
    });

    testWidgets('kLayrzLayoutIconSize constant is still 18 for normal viewport', (tester) async {
      // Verify we didn't accidentally change the normal size constant
      expect(kLayrzLayoutIconSize, equals(18.0));
    });

    testWidgets('Compact viewport sizing constants cover all required locations', (tester) async {
      // This test documents which components are sized for compact viewports:
      // 1. Top bar height (56 → 64)
      // 2. Top bar icon button (40 → 48)
      // 3. Nav item icon (18 → 20)
      // 4. Nav item font (label 12 → body 14)
      // 5. Nav item padding (sp2 10 → sp3 14)
      // 6. User avatar (30 → 40)
      // 7. Notifications row height (32 → 40)
      // 8. All icons throughout the chrome

      final themeData = LayrzThemeData.light();
      setPhysicalSize(tester, 400);

      late LayrzTokens tokens;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              tokens = context.tokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Verify the token ramps exist and have the expected values
      expect(tokens.typography.label.fontSize, equals(12.0));
      expect(tokens.typography.body.fontSize, equals(14.0));
      expect(tokens.spacing.sp2, equals(10.0));
      expect(tokens.spacing.sp3, equals(14.0));
      expect(tokens.spacing.pd2.top, equals(10.0));
      expect(tokens.spacing.pd3.top, equals(14.0));
    });
  });
}
