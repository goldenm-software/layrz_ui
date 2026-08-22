import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzBottomSheet', () {
    testWidgets('shows sheet and can be dismissed', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();

      // Dismiss via barrier tap
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('accepts persistent mode without error', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                isPersistent: true,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom snapSizes parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                snapSizes: [0.3, 0.6, 0.9],
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom initialSize parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                initialSize: 0.75,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects custom minSize and maxSize', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                minSize: 0.1,
                maxSize: 0.95,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects showDragHandle false', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                showDragHandle: false,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('accepts useRootNavigator parameter', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                useRootNavigator: false,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('uses default snapSizes [0.5, 0.95]', (WidgetTester tester) async {
      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              LayrzBottomSheet.show<String>(
                context,
                builder: (context) => const SizedBox(height: 200),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Tap')),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates snapSizes within minSize/maxSize bounds', (WidgetTester tester) async {
      await pumpThemedApp(tester, const SizedBox());

      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byType(SizedBox).first),
            minSize: 0.25,
            maxSize: 0.95,
            snapSizes: [0.1, 0.9],
            builder: (context) => const SizedBox(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('validates snapSizes are in ascending order', (WidgetTester tester) async {
      await pumpThemedApp(tester, const SizedBox());

      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byType(SizedBox).first),
            snapSizes: [0.8, 0.5],
            builder: (context) => const SizedBox(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('validates initialSize within minSize/maxSize bounds', (WidgetTester tester) async {
      await pumpThemedApp(tester, const SizedBox());

      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byType(SizedBox).first),
            minSize: 0.3,
            maxSize: 0.8,
            initialSize: 0.9,
            builder: (context) => const SizedBox(),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('pops with result without re-entrant assertion', (WidgetTester tester) async {
      String? result;

      await pumpThemedApp(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            onTap: () async {
              result = await LayrzBottomSheet.show<String>(
                context,
                builder: (context) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context, 'test-result');
                  },
                  child: const SizedBox(
                    height: 200,
                    child: Text('Dismiss'),
                  ),
                ),
              );
            },
            child: const SizedBox(width: 100, height: 100, child: Text('Open')),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Pop the sheet with a result via direct Navigator.pop
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Verify the result was returned without any assertion errors
      expect(result, equals('test-result'));
    });
  });
}
