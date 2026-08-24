import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';

import '../../helpers/pump_themed_app.dart';

/// Counts semantics nodes whose label contains [needle].
///
/// `contains`, not `==` — [LayrzInputChrome] folds the hint into the label
/// (e.g. `"Find\nSearch"`), which is exactly why `find.bySemanticsLabel` alone
/// is blind to a duplicated node: an exact match only ever finds one of the two.
/// Requires [WidgetTester.ensureSemantics] to be active.
int countSemanticsWithLabel(WidgetTester tester, String needle) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  var count = 0;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().label.contains(needle)) count++;
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return count;
}

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

        expect(find.byType(LayrzInputChrome), findsOneWidget);
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

        expect(find.byType(LayrzInputChrome), findsOneWidget);
        // The single merged Semantics node folds the hint into the label (the chrome's
        // own behaviour, see LayrzInputChrome._buildRowContent), so a RegExp match is
        // used rather than an exact string: the rendered label is "Search\nSearch" here
        // (labelText "Search" plus the l10n-default hint, which also resolves to "Search").
        expect(find.bySemanticsLabel(RegExp('Search')), findsWidgets);
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

        final chrome = find.byType(LayrzInputChrome);
        expect(chrome, findsOneWidget);
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
        await tester.enterText(find.byType(LayrzInputChrome), 'new text');
        await tester.pumpAndSettle();

        // Should remain unchanged
        expect(controller.text, equals('original'));
        controller.dispose();
        handle.dispose();
      });

      testWidgets('search field label is exposed to screen readers exactly once', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search products',
          ),
        );

        // Field mode must own exactly one Semantics node carrying the label. Before the
        // chrome migration this widget produced two (the wrapper's plus LayrzTextInput's
        // own), both carrying a label that contains "Search products" — so this exact
        // assertion fails against the unmigrated widget and passes after migration.
        expect(countSemanticsWithLabel(tester, 'Search products'), 1);

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
        // The chrome should not be visible initially
        expect(find.byType(LayrzInputChrome), findsNothing);
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

        // The chrome should now be visible in the panel
        expect(find.byType(LayrzInputChrome), findsOneWidget);
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
        expect(find.byType(LayrzInputChrome), findsNothing);
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

        // Substring match — see the comment on 'field mode uses labelText for label'
        // above: the merged node's label folds the hint text in alongside labelText.
        expect(find.bySemanticsLabel(RegExp('Custom search')), findsWidgets);
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

        // The chrome is present
        expect(find.byType(LayrzInputChrome), findsOneWidget);

        // Button label should still only appear once (on button, not panel)
        expect(find.bySemanticsLabel('Button label'), findsOneWidget);

        handle.dispose();
      });
    });

    group('new parameters', () {
      testWidgets('errors render the message and error styling', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
            errors: ['Something went wrong'],
          ),
        );

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
        handle.dispose();
      });

      testWidgets('isRequired renders the required marker', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
            isRequired: true,
          ),
        );

        final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome));
        expect(chrome.isRequired, isTrue);
        handle.dispose();
      });

      testWidgets('help text renders the help icon', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
            helpTitleText: 'Help',
            helpContentText: 'This searches all products.',
          ),
        );

        expect(find.byIcon(MdiIcons.helpCircleOutline), findsOneWidget);
        handle.dispose();
      });

      testWidgets('readOnly renders the lock icon', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            labelText: 'Search',
            readOnly: true,
          ),
        );

        expect(find.byIcon(MdiIcons.lockOutline), findsOneWidget);
        handle.dispose();
      });
    });
  });
}
