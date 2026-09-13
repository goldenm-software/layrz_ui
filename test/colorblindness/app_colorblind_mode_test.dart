import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzApp colorblindMode (BETA colorblindness simulation)', () {
    testWidgets('colorblindMode: deuteranopia wraps the app content in a ColorFiltered', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          colorblindMode: ColorblindMode.deuteranopia,
          home: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(find.byType(ColorFiltered), findsWidgets);

      final colorFiltered = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered)).first;
      expect(colorFiltered.colorFilter, equals(ColorblindMode.deuteranopia.filter(1.0)));
    });

    testWidgets('colorblindMode: normal still builds without error', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == 100 && widget.height == 100),
        findsOneWidget,
      );

      final colorFiltered = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered)).first;
      expect(colorFiltered.colorFilter, equals(ColorblindMode.normal.filter(1.0)));
    });

    testWidgets('colorblindStrength interpolates the applied filter', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          colorblindMode: ColorblindMode.protanopia,
          colorblindStrength: 0.5,
          home: const SizedBox(width: 100, height: 100),
        ),
      );

      final colorFiltered = tester.widgetList<ColorFiltered>(find.byType(ColorFiltered)).first;
      expect(colorFiltered.colorFilter, equals(ColorblindMode.protanopia.filter(0.5)));
    });
  });
}
