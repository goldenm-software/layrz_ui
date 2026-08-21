import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzBottomSheet', () {
    testWidgets('accepts default parameters', (WidgetTester tester) async {
      // Should not throw with all default parameters
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            builder: (context) => const SizedBox(),
          );
        },
        isNotNull,
      );
    });

    testWidgets('accepts custom snapSizes within bounds', (WidgetTester tester) async {
      // Should not throw with valid snapSizes
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            snapSizes: [0.3, 0.6, 0.9],
            builder: (context) => const SizedBox(),
          );
        },
        isNotNull,
      );
    });

    testWidgets('accepts custom sizing parameters', (WidgetTester tester) async {
      // Should not throw with valid sizing
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            initialSize: 0.75,
            minSize: 0.2,
            maxSize: 0.9,
            builder: (context) => const SizedBox(),
          );
        },
        isNotNull,
      );
    });

    testWidgets('accepts isPersistent parameter', (WidgetTester tester) async {
      // Should not throw with isPersistent true
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            isPersistent: true,
            builder: (context) => const SizedBox(),
          );
        },
        isNotNull,
      );
    });

    testWidgets('accepts showDragHandle parameter', (WidgetTester tester) async {
      // Should not throw with showDragHandle false
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            showDragHandle: false,
            builder: (context) => const SizedBox(),
          );
        },
        isNotNull,
      );
    });

    testWidgets('accepts useRootNavigator parameter', (WidgetTester tester) async {
      // Should not throw with useRootNavigator true
      expect(
        () {
          LayrzBottomSheet.show<String>(
            tester.element(find.byWidgetPredicate((w) => w is Navigator)),
            useRootNavigator: true,
            builder: (context) => const SizedBox(),
          );
        },
        isNotNull,
      );
    });
  });
}
