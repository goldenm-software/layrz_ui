import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzDropdownMenu', () {
    testWidgets('tapping trigger opens the menu', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Option 1',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      // Menu is initially closed
      expect(find.text('Option 1'), findsNothing);

      // Tap the trigger
      await tester.tap(find.byType(LayrzButton));
      // Wait for overlay to be built and animation to start
      await tester.pump();
      // Wait for animation to complete (dHover is typically 200ms)
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // Check for swallowed exceptions
      final exception = tester.takeException();
      if (exception != null) {
        throw exception;
      }

      // Menu is now open; the entry is visible
      expect(find.text('Option 1'), findsOneWidget);
    });

    testWidgets('tapping trigger again closes the menu', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Option 1',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Option 1'), findsOneWidget);

      // Close the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('tapping entry calls onTap and closes menu', (tester) async {
      int tapCount = 0;
      int menuCloseCount = 0;

      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          onClose: () => menuCloseCount++,
          items: [
            LayrzDropdownEntry(
              labelText: 'Option 1',
              onTap: () => tapCount++,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Tap the entry
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      // Verify entry's onTap fired
      expect(tapCount, 1);

      // Verify menu closed (entry is gone)
      expect(find.text('Option 1'), findsNothing);

      // Verify onClose callback was invoked
      expect(menuCloseCount, 1);
    });

    testWidgets('escape key closes the menu', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Option 1',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Option 1'), findsOneWidget);

      // Press Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Menu is closed
      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('tap outside menu closes it', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Option 1',
              onTap: () {},
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      // Menu is initially closed
      expect(find.text('Option 1'), findsNothing);

      // Open the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify menu is open
      expect(find.text('Option 1'), findsOneWidget);

      // Tap outside the menu near the top-left corner to trigger outside-tap dismissal
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Menu is closed
      expect(find.text('Option 1'), findsNothing);
    });

    testWidgets('disabled entry does not respond to taps', (tester) async {
      int tapCount = 0;

      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownEntry(
              labelText: 'Disabled',
              onTap: () => tapCount++,
              enabled: false,
            ),
          ],
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Tap the disabled entry
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();

      // onTap was not called
      expect(tapCount, 0);

      // Menu is still open (not closed by tap)
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('panel flips above when trigger is near bottom', (tester) async {
      final key = GlobalKey();

      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(400, 300);

      await pumpThemed(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LayrzDropdownMenu(
            key: key,
            items: List.generate(
              3,
              (i) => LayrzDropdownEntry(
                labelText: 'Option $i',
                onTap: () {},
              ),
            ),
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Get the button and menu positions
      final buttonRect = tester.getRect(find.byType(LayrzButton));
      final optionRect = tester.getRect(find.text('Option 0'));

      // Menu should be above the button
      expect(optionRect.bottom, lessThanOrEqualTo(buttonRect.top));
    });

    testWidgets('different alignments render correctly', (tester) async {
      for (final alignment in LayrzDropdownMenuAlignment.values) {
        await pumpThemed(
          tester,
          LayrzDropdownMenu(
            alignment: alignment,
            items: [
              LayrzDropdownEntry(
                labelText: 'Option',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
        );

        // Open the menu
        await tester.tap(find.byType(LayrzButton));
        await tester.pumpAndSettle();

        // Verify the entry is visible
        expect(find.text('Option'), findsOneWidget);

        // Close for next iteration
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('all item types render correctly', (tester) async {
      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          items: [
            LayrzDropdownLabel(labelText: 'Header'),
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

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify all items are present
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Entry 1'), findsOneWidget);
      expect(find.text('Entry 2'), findsOneWidget);
    });

    testWidgets('controller.open() opens the menu programmatically', (tester) async {
      final controller = MenuController();

      await pumpThemed(
        tester,
        LayrzDropdownMenu(
          controller: controller,
          items: [
            LayrzDropdownEntry(
              labelText: 'Option',
              onTap: () {},
            ),
          ],
          builder: (context, ctrl) => LayrzButton(
            labelText: 'Open',
            onTap: ctrl.open,
          ),
        ),
      );

      // Menu is initially closed
      expect(find.text('Option'), findsNothing);

      // Open via controller
      controller.open();
      await tester.pumpAndSettle();

      // Menu is open
      expect(find.text('Option'), findsOneWidget);
    });
  });
}
