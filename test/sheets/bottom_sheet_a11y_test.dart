import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzBottomSheet - Accessibility', () {
    testWidgets('Escape dismisses modal sheet', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const Text('Sheet Content'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);

      // Press Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsNothing);
    });

    testWidgets('Escape does not dismiss persistent sheet', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                isPersistent: true,
                builder: (context) => const Text('Persistent Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Persistent Sheet'), findsOneWidget);

      // Press Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Persistent sheet should still be visible
      expect(find.text('Persistent Sheet'), findsOneWidget);
    });

    testWidgets('barrier is tappable in modal mode', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const Text('Sheet Content'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);

      // GestureDetector for barrier should be present
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('content is scrollable without dragging', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => Column(
                  children: List.generate(
                    20,
                    (index) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Item $index'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 5'), findsNothing); // Off-screen

      // Scroll within the sheet
      await tester.drag(find.text('Item 0'), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(find.text('Item 5'), findsWidgets);
    });

    testWidgets('initial content is visible without drag', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                initialSize: 0.5,
                builder: (context) => Column(
                  children: [
                    const Text('Primary Content'),
                    const Text('Secondary Content'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Both should be visible at initial size
      expect(find.text('Primary Content'), findsOneWidget);
      expect(find.text('Secondary Content'), findsOneWidget);
    });

    testWidgets('back button dismisses modal sheet', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const Text('Sheet Content'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);

      // Simulate back button press
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsNothing);
    });
  });
}
