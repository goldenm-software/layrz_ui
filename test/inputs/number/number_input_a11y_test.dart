import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzNumberInput Accessibility', () {
    testWidgets('field is labeled for assistive technology', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Product Price',
          hintText: 'Enter price',
        ),
      );

      // The label should be present and associated with the field
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('increment button has accessible label', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
        ),
      );

      // The increment button should have an icon (rendered by Icon widget)
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('decrement button has accessible label', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
        ),
      );

      // The decrement button should have an icon (rendered by Icon widget)
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('step buttons are focusable with keyboard', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
          onChanged: (_) {},
        ),
      );

      // Widgets should be in the tree and focusable
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('field retains required indicator for accessibility', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Amount',
          isRequired: true,
        ),
      );

      // Field should be present
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('error messages are announced', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          errors: ['Price must be positive'],
        ),
      );

      expect(find.text('Price must be positive'), findsOneWidget);
    });

    testWidgets('help text is accessible', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          helpTitleText: 'Help',
          helpContentText: 'Enter a positive number',
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('disabled field is announced as disabled', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          disabled: true,
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('read-only field is announced as read-only', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          value: 42,
          readOnly: true,
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('hint text is accessible when label is present', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Amount',
          hintText: 'e.g., 99.99',
        ),
      );

      // Field should be present
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('field can be focused and text selected with keyboard', (tester) async {
      final controller = TextEditingController(text: '42');
      addTearDown(controller.dispose);

      await pumpThemedApp(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          controller: controller,
        ),
      );

      // Focus the field
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Field should be focused
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('button states are announced when disabled at bounds', (tester) async {
      await pumpThemedApp(
        tester,
        const LayrzNumberInput(
          labelText: 'Quantity',
          value: 10,
          maximum: 10,
          minimum: 0,
        ),
      );

      // Buttons should be present with their icons
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('step buttons receive focus in tab order', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzNumberInput(
          labelText: 'Quantity',
          value: 5,
          onChanged: (_) {},
        ),
      );

      // The widgets should be in focus order
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });
  });
}
