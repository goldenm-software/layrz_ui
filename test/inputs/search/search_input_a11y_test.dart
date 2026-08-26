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
            hintText: 'Search',
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
            hintText: 'Search products',
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

      testWidgets('clear icon appears while typing, without seeding an initial value', (tester) async {
        final handle = tester.ensureSemantics();
        final controller = TextEditingController();

        await pumpThemedApp(
          tester,
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            controller: controller,
            debounce: Duration.zero,
          ),
        );

        // No initial value seeded: the clear icon must be absent until the user types.
        expect(find.byIcon(MdiIcons.close), findsNothing);

        await tester.enterText(find.byType(LayrzInputChrome), 'flutter');
        await tester.pump();

        // D-I: this is the deliberate behavioural fix — the icon now appears while
        // typing, where it previously only appeared after an unrelated rebuild.
        expect(find.byIcon(MdiIcons.close), findsOneWidget);

        // Clearing hides it again.
        await tester.enterText(find.byType(LayrzInputChrome), '');
        await tester.pump();
        expect(find.byIcon(MdiIcons.close), findsNothing);

        controller.dispose();
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
            hintText: 'Custom search',
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
            hintText: 'Custom button',
          ),
        );

        // Button should have the custom label
        expect(find.bySemanticsLabel('Custom button'), findsOneWidget);
        handle.dispose();
      });

      // Regression test for a real accessibility defect: the panel field used
      // to genuinely re-announce the trigger button's label. Root cause: the
      // chrome's hint Text (painting [hintText] as a placeholder) is a
      // SIBLING of the field content in a Stack, not a descendant of it --
      // so no Semantics wrapper placed around the field content could reach
      // or suppress it (verified empirically: neither an ancestor `label`
      // nor `container: true` stops a sibling Text's own semantics
      // contribution, and `excludeSemantics: true` does stop it but also
      // deletes EditableText's own dynamic value/focus semantics, which is
      // worse than the duplicate -- a screen reader would then never hear
      // what is typed or that the field gained focus).
      //
      // Fixed by not asking the chrome to render a hint at all in icon mode
      // (`hintText: null` there skips both of input_chrome.dart's hint
      // branches) and instead painting an equivalent hint inside the field's
      // own subtree, wrapped in `ExcludeSemantics` -- safe here specifically
      // because this hint is not a sibling of EditableText's semantics, it
      // is independent and scoped to itself. Same visual result (verified
      // below), only its semantics changed. The field itself is wrapped in
      // an explicit `Semantics(textField: true, label:
      // l10n.inputsSearchFieldLabel, ...)`, giving it a real, distinct,
      // localized name instead of an inferred or empty one.
      testWidgets(
        'icon mode panel field does not inherit button label',
        (tester) async {
          final handle = tester.ensureSemantics();

          await pumpThemedApp(
            tester,
            const LayrzSearchInput(
              mode: LayrzSearchInputMode.icon,
              hintText: 'Button label',
            ),
          );

          // Button has the label
          expect(find.bySemanticsLabel('Button label'), findsOneWidget);

          // Open panel
          await tester.tap(find.byType(LayrzButton));
          await tester.pumpAndSettle();

          // The chrome is present
          expect(find.byType(LayrzInputChrome), findsOneWidget);

          // The visible hint is unchanged: still shown, inside the chrome, while
          // the field is empty. Scoped to the chrome specifically -- checking a
          // bare `find.text('Button label')` count here would also depend on how
          // LayrzButton happens to render its own label, which is unrelated to
          // this hint and not what this assertion means to cover.
          expect(
            find.descendant(of: find.byType(LayrzInputChrome), matching: find.text('Button label')),
            findsOneWidget,
          );

          // The button's label must not be duplicated onto the panel field.
          expect(countSemanticsWithLabel(tester, 'Button label'), 1);

          // The field must not have been silenced in the process of fixing the
          // duplication above -- it must still be identifiable as exactly one
          // accessible text field, carrying its own distinct, non-empty label.
          expect(countSemanticsWithLabel(tester, 'Search field'), 1);
          final fieldSemantics = tester.getSemantics(find.byType(LayrzInputChrome));
          expect(fieldSemantics.getSemanticsData().flagsCollection.isTextField, isTrue);

          // The field is still genuinely usable: it accepts focus and typed input,
          // and the hint disappears once there is a value, same as before.
          await tester.enterText(find.byType(LayrzInputChrome), 'query');
          await tester.pump();
          expect(find.text('query'), findsOneWidget);
          expect(
            find.descendant(of: find.byType(LayrzInputChrome), matching: find.text('Button label')),
            findsNothing,
          );

          handle.dispose();
        },
      );
    });

    group('new parameters', () {
      testWidgets('errors render the message and error styling', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            hintText: 'Search',
            errors: ['Something went wrong'],
          ),
        );

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
        handle.dispose();
      });

      testWidgets('help text renders the help icon', (tester) async {
        final handle = tester.ensureSemantics();

        await pumpThemedApp(
          tester,
          const LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            hintText: 'Search',
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
            hintText: 'Search',
            readOnly: true,
          ),
        );

        expect(find.byIcon(MdiIcons.lockOutline), findsOneWidget);
        handle.dispose();
      });
    });
  });
}
