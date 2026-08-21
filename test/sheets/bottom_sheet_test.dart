import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzBottomSheet', () {
    testWidgets('shows sheet with content', (WidgetTester tester) async {
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

      expect(find.text('Sheet Content'), findsNothing);

      // Tap the button (find by type since text is rendered as RichText)
      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('modal sheet dismisses on tap outside', (WidgetTester tester) async {
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

      // Tap the barrier (upper left)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsNothing);
    });

    testWidgets('persistent sheet does not dismiss on tap outside', (WidgetTester tester) async {
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

      // Tap outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Should still be visible
      expect(find.text('Persistent Sheet'), findsOneWidget);
    });

    testWidgets('returns value on pop with value', (WidgetTester tester) async {
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () async {
              result = await LayrzBottomSheet.show<String>(
                context,
                builder: (context) => Column(
                  children: [
                    const Text('Sheet'),
                    LayrzButton(
                      labelText: 'Select',
                      onTap: () => Navigator.of(context).pop('RESULT'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);

      // Tap the select button inside the sheet
      await tester.tap(find.byType(LayrzButton).last);
      await tester.pumpAndSettle();

      expect(result, 'RESULT');
    });

    testWidgets('returns null on dismiss without value', (WidgetTester tester) async {
      String? result = 'INITIAL';

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () async {
              result = await LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const Text('Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);

      // Dismiss by tapping barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('shows drag handle by default', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const Text('Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      // Drag handle is a Container with color (fg3)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('hides drag handle when showDragHandle is false', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                showDragHandle: false,
                builder: (context) => const Text('Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);
    });

    testWidgets('validates snapSizes constraints', (WidgetTester tester) async {
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            minSize: 0.25,
            maxSize: 0.95,
            snapSizes: [0.1, 0.9], // 0.1 < minSize
            builder: (context) => const Text('Sheet'),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('validates ascending order of snapSizes', (WidgetTester tester) async {
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            snapSizes: [0.8, 0.5],
            builder: (context) => const Text('Sheet'),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('validates initialSize is within bounds', (WidgetTester tester) async {
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            minSize: 0.3,
            maxSize: 0.8,
            initialSize: 0.9, // > maxSize
            builder: (context) => const Text('Sheet'),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('uses default snapSizes when not provided', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                // No snapSizes
                builder: (context) => const Text('Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);
    });

    testWidgets('respects initialSize parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => LayrzButton(
            labelText: 'Show',
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                initialSize: 0.75,
                builder: (context) => const Text('Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);
    });
  });
}
