import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzChip Accessibility', () {
    testWidgets('chip body has label and is not a button', (tester) async {
      await pumpThemed(
        tester,
        const LayrzChip(labelText: 'alpha'),
      );

      // The chip body is not a button — verify that the text has the label and is not marked as button
      final textSemantics = tester.getSemantics(find.text('alpha'));
      expect(textSemantics.label, contains('alpha'));
      // Ensure no button flag on the chip body itself
      expect(
        tester.getSemantics(find.byType(LayrzChip)),
        isSemantics(isButton: false),
      );
    });

    testWidgets('delete affordance is a button with correct label', (tester) async {
      await pumpThemed(
        tester,
        LayrzChip(
          labelText: 'alpha',
          onDelete: () {},
        ),
      );

      final deleteFinder = find.bySemanticsLabel('Delete alpha');
      expect(deleteFinder, findsWidgets);

      expect(
        tester.getSemantics(deleteFinder.first),
        isSemantics(label: 'Delete alpha', isButton: true),
      );
    });

    testWidgets('delete affordance is tappable', (tester) async {
      bool deleted = false;
      await pumpThemed(
        tester,
        LayrzChip(
          labelText: 'Delete Me',
          onDelete: () {
            deleted = true;
          },
        ),
      );

      await tester.tap(find.byIcon(LayrzIcons.solarBoldCloseCircle));
      expect(deleted, isTrue);
    });

    testWidgets('chip with leading icon is accessible', (tester) async {
      await pumpThemed(
        tester,
        LayrzChip(
          labelText: 'With Icon',
          leadingIcon: LayrzIcons.solarOutlineCheckCircle,
        ),
      );

      // Verify the chip, label text, and icon are rendered
      expect(find.byType(LayrzChip), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
      expect(find.byIcon(LayrzIcons.solarOutlineCheckCircle), findsOneWidget);
    });

    testWidgets('chip group items are all accessible', (tester) async {
      await pumpThemed(
        tester,
        LayrzChipGroup(
          chips: const [
            LayrzChip(labelText: 'Chip A'),
            LayrzChip(labelText: 'Chip B'),
            LayrzChip(labelText: 'Chip C'),
          ],
          behavior: LayrzChipGroupBehavior.none,
        ),
      );

      // Verify all chip labels are rendered
      expect(find.text('Chip A'), findsOneWidget);
      expect(find.text('Chip B'), findsOneWidget);
      expect(find.text('Chip C'), findsOneWidget);
      expect(find.byType(LayrzChip), findsNWidgets(3));
    });

    testWidgets('delete buttons in chip group are tappable', (tester) async {
      bool deletedA = false;
      bool deletedB = false;

      await pumpThemed(
        tester,
        LayrzChipGroup(
          chips: [
            LayrzChip(
              labelText: 'Deletable A',
              onDelete: () {
                deletedA = true;
              },
            ),
            LayrzChip(
              labelText: 'Deletable B',
              onDelete: () {
                deletedB = true;
              },
            ),
          ],
          behavior: LayrzChipGroupBehavior.none,
        ),
      );

      // Find all close icons and tap them
      final closeIcons = find.byIcon(LayrzIcons.solarBoldCloseCircle);
      expect(closeIcons, findsWidgets);

      // Tap first delete icon
      await tester.tap(closeIcons.first);
      expect(deletedA, isTrue);
      expect(deletedB, isFalse);

      // Tap second delete icon
      await tester.tap(closeIcons.last);
      expect(deletedB, isTrue);
    });
  });
}
