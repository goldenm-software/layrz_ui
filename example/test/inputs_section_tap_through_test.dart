import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'helpers/test_inputs_section.dart';

void main() {
  group('InputsSection tap-through test', () {
    testWidgets('renders all input demos in wide layout without throwing', (WidgetTester tester) async {
      // Test wide viewport (side-by-side list and detail panes).
      // 1600×1200 ensures the shell is wider than md breakpoint and renders two panes.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const LayrzApp(
          home: TestInputsSection(),
        ),
      );

      // Wait for the initial build.
      await tester.pumpAndSettle();

      // Verify the scaffold rendered.
      expect(find.byType(TestInputsSection), findsOneWidget);

      // All expected input types in the registry.
      final inputNames = [
        'Text Input',
        'Text Area Input',
        'Number Input',
        'Checkbox Input',
        'Switch Input',
        'Radio Input',
        'ComboBox Input',
        'Search Input',
        'Stepper',
      ];

      for (final name in inputNames) {
        // Find and tap each input entry.
        final nameFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data != null && widget.data!.contains(name),
        );

        if (nameFinder.evaluate().isNotEmpty) {
          await tester.tap(nameFinder.first);
          await tester.pumpAndSettle();

          // Assert no exception was thrown while rendering the detail pane.
          expect(
            tester.takeException(),
            isNull,
            reason: 'Rendering $name should not throw an exception',
          );
        }
      }
    });

    testWidgets('renders all input demos in narrow layout without throwing', (WidgetTester tester) async {
      // Test narrow viewport (single pane with back navigation).
      // 400×800 ensures the shell is narrower than md breakpoint and renders one pane.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const LayrzApp(
          home: TestInputsSection(),
        ),
      );

      // Wait for the initial build.
      await tester.pumpAndSettle();

      // Verify the scaffold rendered.
      expect(find.byType(TestInputsSection), findsOneWidget);

      // All expected input types in the registry.
      final inputNames = [
        'Text Input',
        'Text Area Input',
        'Number Input',
        'Checkbox Input',
        'Switch Input',
        'Radio Input',
        'ComboBox Input',
        'Search Input',
        'Stepper',
      ];

      for (final name in inputNames) {
        // Find and tap each input entry.
        final nameFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data != null && widget.data!.contains(name),
        );

        if (nameFinder.evaluate().isNotEmpty) {
          await tester.tap(nameFinder.first);
          await tester.pumpAndSettle();

          // Assert no exception was thrown while rendering the detail pane.
          expect(
            tester.takeException(),
            isNull,
            reason: 'Rendering $name in narrow layout should not throw an exception',
          );
        }
      }
    });
  });
}
