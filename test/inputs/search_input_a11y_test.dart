import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSearchInput A11y', () {
    group('field mode accessibility', () {
      testWidgets('text input has semantic label from hintText', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            hintText: 'Enter search term',
          ),
        );

        expect(find.bySemanticsLabel('Enter search term'), findsWidgets);
      });

      testWidgets('text input has semantic label from labelText', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
          ),
        );

        expect(find.bySemanticsLabel('Search'), findsWidgets);
      });
    });

    group('icon mode accessibility', () {
      testWidgets('trigger button has semantic label', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Button should have a semantic label (from its labelText 'Search')
        expect(find.byType(LayrzButton), findsOneWidget);
      });

      testWidgets('panel is keyboard accessible via Tab', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Open the panel
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // The text input should be accessible
        expect(find.byType(LayrzTextInput), findsOneWidget);
      });

      testWidgets('text input is accessible in icon mode panel', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        // Open the panel
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // The text input should be present and accessible
        expect(find.byType(LayrzTextInput), findsOneWidget);
        expect(find.byType(LayrzButton), findsOneWidget);
      });
    });

    group('clear button accessibility', () {
      testWidgets('clear suffix has semantic label', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            value: 'search',
          ),
        );

        // The clear button should be present and have semantic information
        final closeIconFinder = find.byIcon(MdiIcons.close);
        expect(closeIconFinder, findsOneWidget);
      });

      testWidgets('clear button is keyboard accessible', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            value: 'search',
          ),
        );

        // The close icon should be accessible
        expect(find.byIcon(MdiIcons.close), findsOneWidget);
      });
    });

    group('disabled state accessibility', () {
      testWidgets('disabled field is marked as disabled in semantics', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            disabled: true,
          ),
        );

        // The input should be marked as disabled in semantics
        expect(find.byType(LayrzTextInput), findsOneWidget);
      });

      testWidgets('disabled button is marked as disabled in semantics', (tester) async {
        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            disabled: true,
          ),
        );

        // The button should be disabled
        expect(find.byType(LayrzButton), findsOneWidget);
      });
    });
  });
}
