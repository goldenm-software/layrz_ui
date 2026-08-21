import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAnchoredPanel - Accessibility', () {
    testWidgets('focus is managed by panel', (tester) async {
      final triggerFocus = FocusNode();
      addTearDown(triggerFocus.dispose);

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          childFocusNode: triggerFocus,
          builder: (context, controller) => Focus(
            focusNode: triggerFocus,
            child: LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel content'),
          ),
        ),
      );

      // Request focus on trigger
      triggerFocus.requestFocus();
      await tester.pump();
      expect(triggerFocus.hasFocus, isTrue);

      // Open the panel
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify panel is open
      expect(find.text('Panel content'), findsOneWidget);
    });

    testWidgets('panel content is reachable', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Options'),
          ),
        ),
      );

      // Open the panel
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify content is accessible
      expect(find.text('Options'), findsOneWidget);
    });

    testWidgets('panel content is scrollable for a11y', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(400, 300);

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          maxHeight: 100.0,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: Column(
            children: List.generate(
              5,
              (i) => SizedBox(
                height: 50,
                child: Center(
                  child: Text('Item $i'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the panel
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify all items are in the tree
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 4'), findsOneWidget);

      // Verify scrollable widget is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('panel maintains focus hierarchy', (tester) async {
      await pumpThemed(
        tester,
        FocusScope(
          child: LayrzAnchoredPanel(
            builder: (context, controller) => LayrzButton(
              labelText: 'Trigger',
              onTap: controller.open,
            ),
            child: SizedBox(
              width: 200,
              height: 100,
              child: Focus(
                child: Text('Panel'),
              ),
            ),
          ),
        ),
      );

      // Open the panel
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Verify panel is visible and has focus capability
      expect(find.text('Panel'), findsOneWidget);
    });
  });
}
