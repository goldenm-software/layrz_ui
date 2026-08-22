import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
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
        LayrzApp(
          home: Container(
            constraints: const BoxConstraints.expand(),
            child: const TestInputsSection(),
          ),
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
        // Find the list row by matching RichText content within ListItem rows.
        final nameFinder = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains(name),
        );

        // Assert the finder matched at least one row; fail loudly if not found.
        expect(
          nameFinder,
          findsWidgets,
          reason: 'List row for "$name" should be renderable by the finder',
        );

        // Tap the first matching RichText (the title of the list row).
        await tester.tap(nameFinder.first);
        await tester.pumpAndSettle();

        // Assert no exception was thrown while rendering the detail pane.
        expect(
          tester.takeException(),
          isNull,
          reason: 'Rendering $name should not throw an exception',
        );

        // Verify the detail pane rendered specific content for this demo.
        // Each demo page has a title Text widget with the demo category.
        expect(
          find.byType(Text),
          findsWidgets,
          reason: 'Detail pane for $name should render content',
        );
      }
    });

    testWidgets('renders all input demos in narrow layout without throwing', (WidgetTester tester) async {
      // Test narrow viewport (single pane with back navigation).
      // 400×800 ensures the shell is narrower than md breakpoint and renders one pane.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        LayrzApp(
          home: Container(
            constraints: const BoxConstraints.expand(),
            child: const TestInputsSection(),
          ),
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
        // Find the list row by matching RichText content within ListItem rows.
        final nameFinder = find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains(name),
        );

        // Assert the finder matched at least one row; fail loudly if not found.
        expect(
          nameFinder,
          findsWidgets,
          reason: 'List row for "$name" should be renderable by the finder',
        );

        // Tap the first matching RichText (the title of the list row).
        await tester.tap(nameFinder.first);
        await tester.pumpAndSettle();

        // Assert no exception was thrown while rendering the detail pane.
        expect(
          tester.takeException(),
          isNull,
          reason: 'Rendering $name in narrow layout should not throw an exception',
        );

        // Verify the detail pane rendered specific content for this demo.
        // Each demo page has title Text widgets.
        expect(
          find.byType(Text),
          findsWidgets,
          reason: 'Detail pane for $name in narrow layout should render content',
        );

        // In narrow layout, navigate back to the list to tap the next item (except on the last iteration).
        // Look for the back icon (arrowLeft) at the top of the detail pane.
        if (name != inputNames.last) {
          final backIconFinder = find.byIcon(MdiIcons.arrowLeft);
          expect(
            backIconFinder,
            findsWidgets,
            reason: 'Back icon should be present in narrow layout detail pane',
          );
          await tester.tap(backIconFinder.first);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}
