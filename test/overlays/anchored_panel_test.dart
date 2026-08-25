import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAnchoredPanel', () {
    testWidgets('tapping trigger opens the panel', (tester) async {
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
            child: Text('Panel content'),
          ),
        ),
      );

      expect(find.text('Panel content'), findsNothing);
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);
    });

    testWidgets('tapping trigger again closes the panel', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel content'),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsNothing);
    });

    testWidgets('matchAnchor width policy makes panel width equal to anchor', (tester) async {
      await pumpThemed(
        tester,
        SizedBox(
          width: 300,
          child: LayrzAnchoredPanel(
            widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
            builder: (context, controller) => LayrzButton(
              labelText: 'Open',
              onTap: controller.open,
            ),
            child: SizedBox(
              height: 100,
              child: Text('Panel'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      final buttonRect = tester.getRect(find.byType(LayrzButton));
      final textRect = tester.getRect(find.text('Panel'));

      expect(textRect.width, closeTo(buttonRect.width, 1.0));
    });

    testWidgets('contentSized width policy respects min/max bounds', (tester) async {
      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          widthPolicy: LayrzAnchoredPanelWidthPolicy.contentSized,
          widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 100.0, maxWidth: 200.0),
          builder: (context, controller) => SizedBox(
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: controller.isOpen ? controller.close : controller.open,
              child: Text('Open'),
            ),
          ),
          child: SizedBox(
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textRect = tester.getRect(find.text('Panel'));
      expect(textRect.width, greaterThanOrEqualTo(100.0));
      expect(textRect.width, lessThanOrEqualTo(200.0));
    });

    testWidgets('panel with custom maxHeight scrolls content', (tester) async {
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
              10,
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

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 9'), findsOneWidget);

      final scrollViewRect = tester.getRect(find.byType(SingleChildScrollView));
      expect(scrollViewRect.height, lessThanOrEqualTo(120.0));
    });

    testWidgets('different alignment options position panel on a vertical side', (tester) async {
      for (final alignment in LayrzAnchoredPanelAlignment.values) {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 400);

        await pumpThemed(
          tester,
          Align(
            alignment: Alignment.center,
            child: LayrzAnchoredPanel(
              alignment: alignment,
              builder: (context, controller) => LayrzButton(
                labelText: 'Open',
                onTap: controller.open,
              ),
              child: SizedBox(
                width: 150,
                height: 100,
                child: Text('Panel'),
              ),
            ),
          ),
        );

        // Tap the button at its center.
        final buttonCenter = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenter);
        await tester.pumpAndSettle();

        expect(find.text('Panel'), findsOneWidget);

        // Tap the button again to close the panel.
        final buttonCenterAgain = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenterAgain);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('different alignment options position panel on a horizontal side', (tester) async {
      for (final alignment in LayrzAnchoredPanelAlignment.values) {
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(400, 400);

        await pumpThemed(
          tester,
          Align(
            alignment: Alignment.center,
            child: LayrzAnchoredPanel(
              preferredSide: LayrzPreferredSide.right,
              alignment: alignment,
              builder: (context, controller) => LayrzButton(
                labelText: 'Open',
                onTap: controller.open,
              ),
              child: SizedBox(
                width: 100,
                height: 60,
                child: Text('Panel'),
              ),
            ),
          ),
        );

        // Tap the button at its center.
        final buttonCenter = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenter);
        await tester.pumpAndSettle();

        expect(find.text('Panel'), findsOneWidget);

        // Tap the button again to close the panel.
        final buttonCenterAgain = tester.getCenter(find.byType(LayrzButton));
        await tester.tapAt(buttonCenterAgain);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('onOpen callback is called when panel opens', (tester) async {
      int openCount = 0;

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          onOpen: () => openCount++,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      expect(openCount, 0);
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(openCount, 1);
    });

    testWidgets('onClose callback is called when panel closes', (tester) async {
      int closeCount = 0;

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          onClose: () => closeCount++,
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.isOpen ? controller.close : controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      expect(closeCount, 0);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(closeCount, 0);

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();
      expect(closeCount, 1);
    });

    testWidgets('onFlipped callback is invoked', (tester) async {
      int callCount = 0;

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          onFlipped: (up) {
            callCount++;
          },
          builder: (context, controller) => LayrzButton(
            labelText: 'Open',
            onTap: controller.open,
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel'),
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(callCount, greaterThan(0));
    });

    testWidgets('controller parameter allows external control', (tester) async {
      final controller = MenuController();

      await pumpThemed(
        tester,
        LayrzAnchoredPanel(
          controller: controller,
          builder: (context, menuController) => LayrzButton(
            labelText: 'Trigger',
            onTap: () {},
          ),
          child: SizedBox(
            width: 200,
            height: 100,
            child: Text('Panel content'),
          ),
        ),
      );

      expect(find.text('Panel content'), findsNothing);

      controller.open();
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
      expect(find.text('Panel content'), findsNothing);
    });
  });
}
