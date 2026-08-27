import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

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
  });
}
