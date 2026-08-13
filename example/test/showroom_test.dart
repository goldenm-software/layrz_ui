import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:example/src/showroom.dart';

void main() {
  group('Showroom', () {
    testWidgets('builds without exception', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      expect(find.byType(Showroom), findsOneWidget);
    });

    testWidgets('displays all section titles', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      // Verify all section titles are present
      expect(find.text('Typography'), findsOneWidget);
      expect(find.text('Colors'), findsOneWidget);
      expect(find.text('Spacing'), findsOneWidget);
      expect(find.text('Radius'), findsOneWidget);
      expect(find.text('Elevation & Shadow'), findsOneWidget);
      expect(find.text('Borders & Strokes'), findsOneWidget);
      expect(find.text('Motion'), findsOneWidget);
      expect(find.text('Token Access Paths'), findsOneWidget);
    });

    testWidgets('token access paths agree', (WidgetTester tester) async {
      await tester.pumpWidget(LayrzApp(title: kAppTitle, theme: LayrzThemeData.light(), home: const Showroom()));

      // The access-paths section renders match indicators (✓/✗)
      // We expect all to be ✓ (success/green)
      final successIndicators = find.text('✓');
      expect(successIndicators, findsWidgets);

      // No ✗ (mismatch) indicators should be present
      final mismatchIndicators = find.text('✗');
      expect(mismatchIndicators, findsNothing);
    });
  });
}
