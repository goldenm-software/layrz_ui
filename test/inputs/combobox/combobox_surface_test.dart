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

/// Finds the plain [Text] widget(s) whose [Text.data] equals [text].
///
/// Unlike `find.text`, which also matches an [EditableText] whose current
/// controller value equals [text] (a real risk in this file, since the
/// custom-value row's own text always equals whatever was just typed into
/// the search field), this only ever matches a rendered [Text] widget.
Finder findRowText(String text) {
  return find.byWidgetPredicate((widget) => widget is Text && widget.data == text);
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

    // Restored (bold custom-value row): a non-empty query that matches no
    // option now shows the bold custom-value row instead of the empty-text
    // state -- see BottomSheetContent's own class doc's "The bold
    // custom-value row" section. The empty-text state is reserved for a
    // literally empty query, covered by the group below instead.
    testWidgets('filtering down to no matches shows the bold custom-value row, not the empty text', (tester) async {
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
      expect(find.text('No matches'), findsNothing);
      // find.text('zzz') also matches the search field's own EditableText
      // (whose current value is also "zzz") -- narrow to the plain Text
      // widget the custom-value row renders (see _ComboBoxSheetOptionRow),
      // which is the actual assertion this test is about.
      final customValueRowText = tester.widgetList<Text>(find.byType(Text)).where((t) => t.data == 'zzz');
      expect(customValueRowText, isNotEmpty, reason: 'the custom-value row must render the typed text');
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

    testWidgets('showInlineTitle: false omits the inline heading, but the Semantics name is unaffected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
          labelText: 'Item picker',
          showInlineTitle: false,
        ),
      );

      expect(
        find.text('Item picker'),
        findsNothing,
        reason: 'showInlineTitle: false must suppress the visible inline heading',
      );

      final labels = dumpSemanticsLabels(tester);
      expect(
        labels,
        contains('Item picker'),
        reason: 'labelText must still name the Semantics subtree regardless of showInlineTitle',
      );

      handle.dispose();
    });
  });

  // Restores the bold custom-value row DESIGN-98 initially retired, at the
  // maintainer's own explicit reversal: "now we need it back, not exactly
  // with 'custom ...', well... using bold as indicator". See
  // BottomSheetContent's class doc's "The bold custom-value row" section for
  // the full contract this group pins.
  group('BottomSheetContent custom-value row', () {
    testWidgets('does not render when the search text is empty', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      // Only the two real options render -- two Text widgets in the list,
      // plus the search field's own EditableText, and nothing extra.
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
    });

    testWidgets('does not render when the search text exactly matches an option (case-insensitively)', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      await tester.enterText(find.byType(EditableText), 'alpha');
      await tester.pump();

      // 'alpha' matches 'Alpha' case-insensitively -- no second, duplicate
      // row for the same value. findRowText (not find.text) is used because
      // find.text also matches the search EditableText's own current value,
      // which is 'alpha' here.
      expect(findRowText('Alpha'), findsOneWidget);
      expect(findRowText('alpha'), findsNothing);
    });

    testWidgets('renders bold (w600), while ordinary option rows render at the default weight', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Zzz');
      await tester.pump();

      final customRowText = tester.widget<Text>(findRowText('Zzz'));
      expect(
        customRowText.style?.fontWeight,
        FontWeight.w600,
        reason: 'the custom-value row must render in the design system\'s own semi-bold weight',
      );

      // An ordinary option row (queried with a match instead) must NOT carry
      // that weight -- the emphasis is reserved for the custom-value row only.
      await tester.enterText(find.byType(EditableText), 'Alpha');
      await tester.pump();
      final optionRowText = tester.widget<Text>(findRowText('Alpha'));
      expect(
        optionRowText.style?.fontWeight,
        isNot(FontWeight.w600),
        reason: 'ordinary option rows must not render bold -- only the custom-value row does',
      );
    });

    testWidgets('is tappable and commits the exact typed text, once', (tester) async {
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
                    options: ['Alpha', 'Bravo'],
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

      await tester.enterText(find.byType(EditableText), 'Charlie');
      await tester.pumpAndSettle();

      await tester.tap(findRowText('Charlie'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetContent), findsNothing);
      expect(result, 'Charlie');
    });

    testWidgets('renders no "custom" label, prefix, suffix, or icon -- bold weight is the only indicator', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Charlie');
      await tester.pump();

      // No literal "custom" text anywhere, and no icon beside the row other
      // than the search field's own magnifier/clear icons.
      expect(find.textContaining('custom', findRichText: true), findsNothing);
      expect(find.byIcon(MdiIcons.check), findsNothing);
    });
  });

  // Fixes a device-reported defect: option rows read as centered with no
  // hover feedback. Root cause (centering): LayrzEndDrawer's own outer
  // Column had no explicit crossAxisAlignment (defaulting to center), and
  // BottomSheetContent's own Column and each row's own Container likewise
  // never stretched to fill the available width -- an unconstrained
  // Container shrink-wraps to its Text's own intrinsic width and reads as
  // centered inside whatever wider box its ancestor gives it. Root cause
  // (no hover): a bare GestureDetector, never LayrzTappable, wrapped each
  // row -- the same defect the calendar cells had before adopting
  // LayrzTappable (a raw GestureDetector never paints a hover tint on its
  // own).
  group('BottomSheetContent row alignment and hover (device-reported defect)', () {
    testWidgets('every row (including the custom-value row) stretches to the list\'s full width', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      final listWidth = tester.getSize(find.byType(SingleChildScrollView)).width;

      // The rendered width of each row's own LayrzTappable, not the
      // Container's `constraints` field -- `width: double.infinity` is
      // applied via Container's convenience parameter, which resolves into
      // BoxConstraints during layout rather than populating the
      // `constraints` field itself, so the actually-painted size is the only
      // reliable signal here. Checked with the unfiltered list first (an
      // ordinary option row).
      final optionRowSize = tester.getSize(
        find.ancestor(of: findRowText('Alpha'), matching: find.byType(LayrzTappable)).first,
      );
      expect(optionRowSize.width, closeTo(listWidth, 0.5));

      // Then with a non-matching query, so "Charlie" renders as the
      // custom-value row instead (Alpha/Bravo are filtered out entirely).
      await tester.enterText(find.byType(EditableText), 'Charlie');
      await tester.pump();

      final customRowSize = tester.getSize(
        find.ancestor(of: findRowText('Charlie'), matching: find.byType(LayrzTappable)).first,
      );
      expect(customRowSize.width, closeTo(listWidth, 0.5));
    });

    testWidgets('every row is wrapped in LayrzTappable, for hover feedback', (tester) async {
      await pumpThemed(
        tester,
        const BottomSheetContent(
          options: ['Alpha', 'Bravo'],
          emptyText: 'Nothing here',
        ),
      );

      expect(
        find.ancestor(of: find.text('Alpha'), matching: find.byType(LayrzTappable)),
        findsOneWidget,
        reason: 'option rows must use LayrzTappable, not a bare GestureDetector, for hover feedback',
      );
      expect(
        find.ancestor(of: find.text('Bravo'), matching: find.byType(LayrzTappable)),
        findsOneWidget,
      );
    });
  });
}
