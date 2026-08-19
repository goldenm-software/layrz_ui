import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/input_error_block.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzInputErrorBlock', () {
    testWidgets('renders error messages when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['Error 1', 'Error 2'],
          hideDetails: false,
        ),
      );

      expect(find.text('Error 1, Error 2'), findsOneWidget);
    });

    testWidgets('renders nothing when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['Error 1'],
          hideDetails: true,
        ),
      );

      expect(find.text('Error 1'), findsNothing);
    });

    testWidgets('renders nothing when errors list is empty', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: [],
          hideDetails: false,
        ),
      );

      expect(find.byType(LayrzInputErrorBlock), findsOneWidget);
    });

    testWidgets('renders multiple errors joined with comma separator', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['First', 'Second', 'Third'],
          hideDetails: false,
        ),
      );

      expect(find.text('First, Second, Third'), findsOneWidget);
    });

    testWidgets('renders character counter when maxLength is provided', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: [],
          hideDetails: false,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      expect(find.text('0/50'), findsOneWidget);

      controller.text = 'Hello';
      await tester.pumpAndSettle();

      expect(find.text('5/50'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('renders counter as "0/maxLength" on empty field', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: [],
          hideDetails: false,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      expect(find.text('0/50'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('hides counter when hideDetails is true', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController(text: 'Hello');

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: [],
          hideDetails: true,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      expect(find.text('5/50'), findsNothing);

      controller.dispose();
    });

    testWidgets('renders both errors and counter on same row without overlap', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController(text: 'Hello');

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['This is a validation error'],
          hideDetails: false,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      // Both error and counter should be visible
      expect(find.text('This is a validation error'), findsOneWidget);
      expect(find.text('5/50'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('error text is danger-colored and bold', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['Error message'],
          hideDetails: false,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      final errorText = find.text('Error message');
      expect(errorText, findsOneWidget);

      // Get the Text widget and check its style
      final textWidget = tester.widget<Text>(errorText);
      final style = textWidget.style;
      final context = tester.element(errorText) as BuildContext;
      expect(style?.color, context.tokens.colors.danger);
      expect(style?.fontWeight, FontWeight.w700);

      controller.dispose();
    });

    testWidgets('counter is always fg3 color even with errors present', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController(text: 'Test');

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: ['Error'],
          hideDetails: false,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      final counterText = find.text('4/50');
      expect(counterText, findsOneWidget);

      // Check that counter text is fg3 color
      final textWidget = tester.widget<Text>(counterText);
      final style = textWidget.style;
      final context = tester.element(counterText) as BuildContext;
      expect(style?.color, context.tokens.colors.fg3);

      controller.dispose();
    });

    testWidgets('counter updates in real-time as text is entered', (tester) async {
      const int maxLength = 50;
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzInputErrorBlock(
          errors: [],
          hideDetails: false,
          maxLength: maxLength,
          controller: controller,
        ),
      );

      expect(find.text('0/50'), findsOneWidget);

      controller.text = 'A';
      await tester.pumpAndSettle();
      expect(find.text('1/50'), findsOneWidget);

      controller.text = 'AB';
      await tester.pumpAndSettle();
      expect(find.text('2/50'), findsOneWidget);

      controller.text = 'ABC';
      await tester.pumpAndSettle();
      expect(find.text('3/50'), findsOneWidget);

      controller.dispose();
    });
  });
}
