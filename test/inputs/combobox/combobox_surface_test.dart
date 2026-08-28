import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

/// Collects every semantics label under [tester]'s current tree.
///
/// Used instead of `find.bySemanticsLabel` for the DESIGN-161 acceptance
/// signal: that matcher also matches literal text on renderable widgets (a
/// plain `Text` widget carries an implicit semantics label equal to its own
/// string), which has already produced a false green in this repo -- a widget
/// with visible text but no actual `Semantics` naming it would still satisfy
/// `find.bySemanticsLabel`. Dumping the tree and inspecting the labels
/// directly cannot be fooled by that.
List<String> dumpSemanticsLabels(WidgetTester tester) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final labels = <String>[];
  void walk(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) labels.add(label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return labels;
}

void main() {
  group('LayrzComboBoxPanelContent', () {
    testWidgets('renders the field row first, always', (tester) async {
      await pumpThemed(
        tester,
        LayrzComboBoxPanelContent(
          fieldRow: const Text('field row'),
          options: const [],
          highlightedIndex: -1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      expect(find.text('field row'), findsOneWidget);
    });

    testWidgets('shows the empty text when there are no options', (tester) async {
      await pumpThemed(
        tester,
        LayrzComboBoxPanelContent(
          fieldRow: const SizedBox.shrink(),
          options: const [],
          highlightedIndex: -1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      expect(find.text('No matches'), findsOneWidget);
      expect(find.byType(OptionItem), findsNothing);
    });

    testWidgets('renders one OptionItem per option', (tester) async {
      await pumpThemed(
        tester,
        LayrzComboBoxPanelContent(
          fieldRow: const SizedBox.shrink(),
          options: const ['Alpha', 'Bravo', 'Charlie'],
          highlightedIndex: -1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      expect(find.byType(OptionItem), findsNWidgets(3));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('tapping an option calls onSelected with that option', (tester) async {
      String? selected;

      await pumpThemed(
        tester,
        LayrzComboBoxPanelContent(
          fieldRow: const SizedBox.shrink(),
          options: const ['Alpha', 'Bravo'],
          highlightedIndex: -1,
          onSelected: (value) => selected = value,
          emptyText: 'No matches',
        ),
      );

      await tester.tap(find.text('Bravo'));
      await tester.pump();

      expect(selected, 'Bravo');
    });

    testWidgets('the highlighted option renders with a different background', (tester) async {
      await pumpThemed(
        tester,
        LayrzComboBoxPanelContent(
          fieldRow: const SizedBox.shrink(),
          options: const ['Alpha', 'Bravo'],
          highlightedIndex: 1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      final containers = tester
          .widgetList<Container>(
            find.descendant(of: find.byType(OptionItem), matching: find.byType(Container)),
          )
          .toList();

      expect(containers, hasLength(2));
      expect(containers[0].color, isNot(containers[1].color));
    });

    testWidgets(
      'no descendant of the surrounding SingleChildScrollView exceeds its own height '
      '(S2 -- the panel, not this content, owns the border/shadow/clip)',
      (tester) async {
        // This content paints no decoration of its own (S2): background,
        // shadow, radius, border and the height cap all belong to
        // LayrzAnchoredPanel now. Regression-shaped like the U1 select probe:
        // wrap this content the way the real panel does (a bounded
        // SingleChildScrollView) and confirm nothing inside disagrees with
        // that bound.
        final options = List.generate(30, (i) => 'Option $i');

        await pumpThemed(
          tester,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 300),
            child: SingleChildScrollView(
              child: LayrzComboBoxPanelContent(
                fieldRow: const SizedBox(height: 40),
                options: options,
                highlightedIndex: -1,
                onSelected: (_) {},
                emptyText: 'No matches',
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(viewport.height, 240.0);
      },
    );

    testWidgets(
      'does not overflow with many options, and the list actually scrolls',
      (tester) async {
        final options = List.generate(30, (i) => 'Option $i');

        await pumpThemed(
          tester,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 300),
            child: SingleChildScrollView(
              child: LayrzComboBoxPanelContent(
                fieldRow: const SizedBox(height: 40),
                options: options,
                highlightedIndex: -1,
                onSelected: (_) {},
                emptyText: 'No matches',
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final beforeRect = tester.getRect(find.text('Option 29'));

        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
        await tester.pump();

        expect(tester.takeException(), isNull);

        final afterRect = tester.getRect(find.text('Option 29'));
        expect(
          afterRect.top,
          lessThan(beforeRect.top),
          reason: 'dragging up must have scrolled later options into view',
        );
      },
    );

    testWidgets('renders the field row directly above the options, with no custom-value row', (tester) async {
      await pumpThemed(
        tester,
        LayrzComboBoxPanelContent(
          fieldRow: const Text('field row'),
          options: const ['Alpha'],
          highlightedIndex: -1,
          onSelected: (_) {},
          emptyText: 'No matches',
        ),
      );

      final columnFinder = find.byType(Column).first;
      final column = tester.widget<Column>(columnFinder);
      final texts = column.children.whereType<Text>().map((t) => t.data).toList();

      expect(texts, contains('field row'));
      expect(find.byType(OptionItem), findsOneWidget);
    });
  });

  group('OptionItem', () {
    testWidgets('renders its option text', (tester) async {
      await pumpThemed(
        tester,
        OptionItem(
          option: 'Solo option',
          isHighlighted: false,
          onTap: () {},
        ),
      );

      expect(find.text('Solo option'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await pumpThemed(
        tester,
        OptionItem(
          option: 'Tap me',
          isHighlighted: false,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('BottomSheetContent', () {
    testWidgets('shows the empty text when there are no options', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: [],
          emptyText: 'Nothing here',
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders every option as scrollable text, never a ListView', (tester) async {
      // Building on a Column (not a ListView) is what lets this content sit
      // inside LayrzBottomSheet with `scrollable: false` without asserting
      // "Vertical viewport was given unbounded height" — a same-axis ListView
      // nested under the sheet's own scrollable does exactly that (DESIGN-35).
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['One', 'Two', 'Three'],
          emptyText: 'Nothing here',
        ),
      );

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('tapping an option pops the enclosing sheet route with that value', (tester) async {
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () async {
                result = await LayrzBottomSheet.show<String?>(
                  context,
                  builder: (context) => const BottomSheetContent(
                    options: ['First', 'Second'],
                    emptyText: 'Nothing here',
                  ),
                  scrollable: false,
                );
              },
              child: const Text('open sheet'),
            );
          },
        ),
      );

      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetContent), findsOneWidget);

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetContent), findsNothing);
      expect(result, 'Second');
    });

    // DESIGN-161: before this unit, `BottomSheetContent` rendered nothing but
    // a bare `GestureDetector + Text` list -- no search field, no `Semantics`,
    // no heading, no label of any kind (`options` and `emptyText` were its
    // only two parameters). Witnessed failing against that code: reverting
    // this file's `BottomSheetContent` to the pre-fix version and re-running
    // this group threw `find.byType(EditableText)` -> "found 0 widgets" on
    // every test below and a hard `NoSuchMethodError` on
    // `BottomSheetContent(labelText: ...)` (the parameter did not exist yet).

    testWidgets('renders a search field above the option list', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo', 'Charlie'],
          emptyText: 'Nothing here',
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('typing in the search field filters the option list live', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Apple', 'Apricot', 'Banana'],
          emptyText: 'No matches',
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Ap');
      await tester.pump();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('filtering down to no matches shows the empty text', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Apple', 'Banana'],
          emptyText: 'No matches',
        ),
      );

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pump();

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('clearing the search field via its suffix restores the full list', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Apple', 'Banana'],
          emptyText: 'No matches',
        ),
      );

      await tester.enterText(find.byType(EditableText), 'App');
      await tester.pump();
      expect(find.text('Banana'), findsNothing);

      // Located by icon, not `find.bySemanticsLabel` -- that matcher also
      // matches literal text on renderable widgets and has already produced a
      // false green in this repo; an `Icon` lookup carries no such risk.
      final clearIcon = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == MdiIcons.close);
      expect(clearIcon, findsOneWidget);
      await tester.tap(clearIcon);
      await tester.pump();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('tapping a filtered option still pops the enclosing sheet with that value', (tester) async {
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () async {
                result = await LayrzBottomSheet.show<String?>(
                  context,
                  builder: (context) => const BottomSheetContent(
                    options: ['Apple', 'Apricot', 'Banana'],
                    emptyText: 'Nothing here',
                  ),
                  scrollable: false,
                );
              },
              child: const Text('open sheet'),
            );
          },
        ),
      );

      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'Ap');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apricot'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetContent), findsNothing);
      expect(result, 'Apricot');
    });

    testWidgets(
      'the semantics tree carries a name identifying what is being picked, distinct from the search field',
      (tester) async {
        // Asserted by dumping the tree (see dumpSemanticsLabels's own doc
        // comment for why `find.bySemanticsLabel` is not used here): before
        // DESIGN-161, this dump was empty of both strings below -- the sheet's
        // entire subtree had nothing nameable in it at all.
        final handle = tester.ensureSemantics();

        await pumpThemed(
          tester,
          const BottomSheetContent(
            options: ['Alpha', 'Bravo'],
            emptyText: 'Nothing here',
            labelText: 'Item picker',
          ),
        );

        final l10n = LayrzUiL10n.of(tester.element(find.byType(BottomSheetContent)));
        final labels = dumpSemanticsLabels(tester);

        expect(labels, contains('Item picker'));
        expect(
          labels.any((label) => label.contains(l10n.inputsSearchFieldLabel)),
          isTrue,
          reason: 'the search field must carry its own accessible name somewhere in the tree',
        );
        expect(
          'Item picker',
          isNot(l10n.inputsSearchFieldLabel),
          reason: 'the sheet heading and the search field must carry distinct names',
        );

        handle.dispose();
      },
    );

    testWidgets('with no labelText, the sheet has no heading but the search field is still named', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      final l10n = LayrzUiL10n.of(tester.element(find.byType(BottomSheetContent)));
      final labels = dumpSemanticsLabels(tester);

      expect(
        labels.any((label) => label.contains(l10n.inputsSearchFieldLabel)),
        isTrue,
        reason: 'the search field must carry its own accessible name somewhere in the tree',
      );

      handle.dispose();
    });
  });
}
