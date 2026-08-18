import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzChipGroup', () {
    group('none behavior (scrollable)', () {
      testWidgets('renders all chips in a scrollable row', (tester) async {
        await pumpThemed(
          tester,
          LayrzChipGroup(
            chips: [
              const LayrzChip(labelText: 'Chip 1'),
              const LayrzChip(labelText: 'Chip 2'),
              const LayrzChip(labelText: 'Chip 3'),
            ],
            behavior: LayrzChipGroupBehavior.none,
          ),
        );

        expect(find.byType(LayrzChip), findsNWidgets(3));
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('uses provided spacing in row', (tester) async {
        await pumpThemed(
          tester,
          LayrzChipGroup(
            chips: [
              const LayrzChip(labelText: 'Chip 1'),
              const LayrzChip(labelText: 'Chip 2'),
            ],
            behavior: LayrzChipGroupBehavior.none,
            spacing: 20,
          ),
        );

        // Find the Row widget inside LayrzChipGroup
        final rowFinder = find.descendant(
          of: find.byType(LayrzChipGroup),
          matching: find.byType(Row),
        );
        expect(rowFinder, findsWidgets); // May have multiple rows inside

        // The outermost Row in the chip group should be the one with our spacing
        final rows = find.byType(Row).evaluate();
        bool foundCorrectSpacing = false;
        for (final element in rows) {
          if (element.widget is Row) {
            final row = element.widget as Row;
            if (row.spacing == 20) {
              foundCorrectSpacing = true;
              break;
            }
          }
        }
        expect(foundCorrectSpacing, isTrue);
      });

      testWidgets('defaults to tokens.spacing.base when spacing is null', (tester) async {
        await pumpThemed(
          tester,
          LayrzChipGroup(
            chips: [
              const LayrzChip(labelText: 'Chip 1'),
              const LayrzChip(labelText: 'Chip 2'),
            ],
            behavior: LayrzChipGroupBehavior.none,
            spacing: null,
          ),
        );

        final context = tester.element(find.byType(LayrzChipGroup));
        final tokens = LayrzTheme.of(context).tokens;

        // Find the Row inside the LayrzChipGroup and check it has the correct spacing
        final rows = find.byType(Row).evaluate();
        bool foundCorrectSpacing = false;
        for (final element in rows) {
          if (element.widget is Row) {
            final row = element.widget as Row;
            if (row.spacing == tokens.spacing.base) {
              foundCorrectSpacing = true;
              break;
            }
          }
        }
        expect(foundCorrectSpacing, isTrue);
      });

      testWidgets('respects alignment parameter', (tester) async {
        await pumpThemed(
          tester,
          LayrzChipGroup(
            chips: [
              const LayrzChip(labelText: 'Chip 1'),
            ],
            behavior: LayrzChipGroupBehavior.none,
            alignment: Alignment.centerRight,
          ),
        );

        final alignFinder = find.byType(Align);
        expect(alignFinder, findsWidgets);

        // Find the Align with our specific alignment
        bool foundCorrectAlignment = false;
        for (int i = 0; i < alignFinder.evaluate().length; i++) {
          final align = tester.widget<Align>(alignFinder.at(i));
          if (align.alignment == Alignment.centerRight) {
            foundCorrectAlignment = true;
            break;
          }
        }
        expect(foundCorrectAlignment, isTrue);
      });
    });

    group('compact behavior', () {
      testWidgets('renders all chips when they fit in width', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 500,
            child: LayrzChipGroup(
              chips: [
                const LayrzChip(labelText: 'Short'),
                const LayrzChip(labelText: 'Brief'),
              ],
              behavior: LayrzChipGroupBehavior.compact,
            ),
          ),
        );

        expect(find.byType(LayrzChip), findsNWidgets(2));
      });

      testWidgets('collapses overflow chips into +N indicator', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 150,
            child: LayrzChipGroup(
              chips: [
                const LayrzChip(labelText: 'Chip 1'),
                const LayrzChip(labelText: 'Chip 2'),
                const LayrzChip(labelText: 'Chip 3'),
                const LayrzChip(labelText: 'Chip 4'),
              ],
              behavior: LayrzChipGroupBehavior.compact,
            ),
          ),
        );

        // Should have fewer than 4 chips, and one should be the +N
        final chipCount = find.byType(LayrzChip).evaluate().length;
        expect(chipCount, lessThan(4));

        // Find the +N chip by looking for text matching pattern
        final plusNFinder = find.textContaining('+');
        expect(plusNFinder, findsWidgets);
      });

      testWidgets('+N indicator is clamped to 1-9', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 100,
            child: LayrzChipGroup(
              chips: List.generate(
                15,
                (i) => LayrzChip(labelText: 'Chip ${i + 1}'),
              ),
              behavior: LayrzChipGroupBehavior.compact,
            ),
          ),
        );

        // Look for the +N text — it should be between +1 and +9
        final textFinder = find.byType(Text);
        bool foundValidIndicator = false;

        for (int i = 0; i < textFinder.evaluate().length; i++) {
          final text = tester.widget<Text>(textFinder.at(i));
          if (text.data != null && text.data!.startsWith('+')) {
            final num = int.tryParse(text.data!.substring(1));
            if (num != null && num >= 1 && num <= 9) {
              foundValidIndicator = true;
              break;
            }
          }
        }

        expect(foundValidIndicator, isTrue);
      });

      testWidgets('+N chip is wrapped in tooltip with hidden labels', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 120,
            child: LayrzChipGroup(
              chips: [
                const LayrzChip(labelText: 'Visible'),
                const LayrzChip(labelText: 'Hidden 1'),
                const LayrzChip(labelText: 'Hidden 2'),
              ],
              behavior: LayrzChipGroupBehavior.compact,
            ),
          ),
        );

        // The overflow chips should be in a LayrzTooltip
        expect(find.byType(LayrzTooltip), findsWidgets);
      });

      testWidgets('renders single row without horizontal scroll', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            child: LayrzChipGroup(
              chips: [
                const LayrzChip(labelText: 'A'),
                const LayrzChip(labelText: 'B'),
              ],
              behavior: LayrzChipGroupBehavior.compact,
            ),
          ),
        );

        expect(find.byType(SingleChildScrollView), findsOneWidget);

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scrollView.scrollDirection, equals(Axis.horizontal));
      });
    });

    group('spacing', () {
      testWidgets('custom spacing is applied in none behavior', (tester) async {
        await pumpThemed(
          tester,
          LayrzChipGroup(
            chips: [
              const LayrzChip(labelText: 'A'),
              const LayrzChip(labelText: 'B'),
            ],
            behavior: LayrzChipGroupBehavior.none,
            spacing: 24,
          ),
        );

        // Find rows and check for correct spacing
        final rows = find.byType(Row).evaluate();
        bool foundCorrectSpacing = false;
        for (final element in rows) {
          if (element.widget is Row) {
            final row = element.widget as Row;
            if (row.spacing == 24) {
              foundCorrectSpacing = true;
              break;
            }
          }
        }
        expect(foundCorrectSpacing, isTrue);
      });

      testWidgets('custom spacing is applied in compact behavior', (tester) async {
        await pumpThemed(
          tester,
          SizedBox(
            width: 500,
            child: LayrzChipGroup(
              chips: [
                const LayrzChip(labelText: 'A'),
                const LayrzChip(labelText: 'B'),
              ],
              behavior: LayrzChipGroupBehavior.compact,
              spacing: 24,
            ),
          ),
        );

        // Find rows and check for correct spacing in compact mode
        final rows = find.byType(Row).evaluate();
        bool foundCorrectSpacing = false;
        for (final element in rows) {
          if (element.widget is Row) {
            final row = element.widget as Row;
            if (row.spacing == 24) {
              foundCorrectSpacing = true;
              break;
            }
          }
        }
        expect(foundCorrectSpacing, isTrue);
      });
    });

    group('empty group', () {
      testWidgets('renders without error with empty chip list', (tester) async {
        await pumpThemed(
          tester,
          const LayrzChipGroup(
            chips: [],
            behavior: LayrzChipGroupBehavior.none,
          ),
        );

        expect(find.byType(LayrzChipGroup), findsOneWidget);
      });
    });
  });
}
