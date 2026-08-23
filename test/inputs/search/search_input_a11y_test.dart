import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzSearchInput A11y', () {
    group('field mode accessibility', () {
      testWidgets('field mode has text input with label', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            hintText: 'Enter search term',
          ),
        );

        expect(find.byType(LayrzTextInput), findsOneWidget);
        expect(find.bySemanticsLabel('Enter search term'), findsWidgets);
        handle.dispose();
      });

      testWidgets('field mode uses labelText for label', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
          ),
        );

        expect(find.byType(LayrzTextInput), findsOneWidget);
        expect(find.bySemanticsLabel('Search'), findsWidgets);
        handle.dispose();
      });

      testWidgets('field mode has l10n default label', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        final textInput = find.byType(LayrzTextInput);
        expect(textInput, findsOneWidget);
        handle.dispose();
      });

      testWidgets('disabled field does not accept input', (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController(text: 'original');

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            disabled: true,
            controller: controller,
          ),
        );

        // Try to enter text
        await tester.enterText(find.byType(LayrzTextInput), 'new text');
        await tester.pumpAndSettle();

        // Should remain unchanged
        expect(controller.text, equals('original'));
        controller.dispose();
        handle.dispose();
      });
    });

    group('icon mode accessibility', () {
      testWidgets('icon mode has button trigger', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        expect(find.byType(LayrzButton), findsOneWidget);
        // Text input should not be visible initially
        expect(find.byType(LayrzTextInput), findsNothing);
        handle.dispose();
      });

      testWidgets('icon mode panel opens on tap', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
          ),
        );

        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Text input should now be visible in the panel
        expect(find.byType(LayrzTextInput), findsOneWidget);
        handle.dispose();
      });

      testWidgets('disabled button does not open panel', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            disabled: true,
          ),
        );

        // Try to tap the button
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Panel should not open
        expect(find.byType(LayrzTextInput), findsNothing);
        handle.dispose();
      });
    });

    group('clear button accessibility', () {
      testWidgets('clear icon is present when field has value', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            value: 'search',
          ),
        );

        expect(find.byIcon(MdiIcons.close), findsOneWidget);
        handle.dispose();
      });

      testWidgets('clear icon is absent when field is empty', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
          ),
        );

        expect(find.byIcon(MdiIcons.close), findsNothing);
        handle.dispose();
      });

      testWidgets('clear button clears field', (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController(text: 'test');
        String? lastSearch;

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
            value: 'test',
            onSearch: (value) => lastSearch = value,
            debounce: Duration.zero,
          ),
        );

        expect(find.byIcon(MdiIcons.close), findsOneWidget);

        await tester.tap(find.byIcon(MdiIcons.close));
        await tester.pumpAndSettle();

        expect(controller.text, isEmpty);
        expect(lastSearch, equals(''));
        controller.dispose();
        handle.dispose();
      });
    });

    group('label text behavior', () {
      testWidgets('labelText overrides default in field mode', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Custom search',
          ),
        );

        expect(find.bySemanticsLabel('Custom search'), findsWidgets);
        handle.dispose();
      });

      testWidgets('labelText overrides default in icon mode', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            labelText: 'Custom button',
          ),
        );

        // Button should have the custom label
        expect(find.bySemanticsLabel('Custom button'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('icon mode panel field does not inherit button label', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.icon,
            labelText: 'Button label',
          ),
        );

        // Button has the label
        expect(find.bySemanticsLabel('Button label'), findsOneWidget);

        // Open panel
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Text input is present
        expect(find.byType(LayrzTextInput), findsOneWidget);

        // Button label should still only appear once (on button, not panel)
        expect(find.bySemanticsLabel('Button label'), findsOneWidget);

        handle.dispose();
      });
    });
  });
}
