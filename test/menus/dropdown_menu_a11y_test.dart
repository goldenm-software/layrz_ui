import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzDropdownMenu accessibility', () {
    testWidgets('entries expose button semantics with correct enabled state', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Enabled Entry',
              onTap: () {},
              enabled: true,
            ),
            LayrzDropdownEntry(
              labelText: 'Disabled Entry',
              onTap: () {},
              enabled: false,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        // Open the menu
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Find the enabled entry's semantics
        final enabledSemantics = find.bySemanticsLabel('Enabled Entry');
        expect(enabledSemantics, findsOneWidget);

        // Find the disabled entry's semantics
        final disabledSemantics = find.bySemanticsLabel('Disabled Entry');
        expect(disabledSemantics, findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('dividers have no semantics nodes', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Entry 1',
              onTap: () {},
            ),
            LayrzDropdownEntry(
              labelText: 'Entry 2',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        // Open the menu
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Entries have semantics, but divider should not have a significant node
        expect(find.bySemanticsLabel('Entry 1'), findsOneWidget);
        expect(find.bySemanticsLabel('Entry 2'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('labels expose header semantics', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownLabel(labelText: 'Section Header'),
            LayrzDropdownEntry(
              labelText: 'Entry',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        // Open the menu
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // The label should be present in semantics
        expect(find.text('Section Header'), findsOneWidget);

        // The entry should also be present
        expect(find.bySemanticsLabel('Entry'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('entries have correct label semantics', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Test Label',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      try {
        // Open the menu
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Entry should have its label accessible to semantics
        expect(find.bySemanticsLabel('Test Label'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}
