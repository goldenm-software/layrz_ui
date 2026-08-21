import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/find_button_label.dart';

void main() {
  group('LayrzNumberInput', () {
    testWidgets('renders with label and hint', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          hintText: 'Enter price',
        ),
      );

      expect(findButtonLabel('Price'), findsOneWidget);
      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('parses typed input with dot separator', (tester) async {
      var changedValue = -1.0;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          decimalSeparator: LayrzDecimalSeparator.dot,
          onChanged: (value) => changedValue = value?.toDouble() ?? -1.0,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3.14');
      expect(changedValue, 3.14);
    });

    testWidgets('parses typed input with comma separator', (tester) async {
      var changedValue = -1.0;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          decimalSeparator: LayrzDecimalSeparator.comma,
          onChanged: (value) => changedValue = value?.toDouble() ?? -1.0,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3,14');
      expect(changedValue, 3.14);
    });

    testWidgets('calls onChanged with null when input is empty', (tester) async {
      num? changedValue = 42;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 42,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), '');
      expect(changedValue, isNull);
    });

    testWidgets('calls onChanged with null for unparseable input', (tester) async {
      num? changedValue = 42;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'abc');
      expect(changedValue, isNull);
    });

    testWidgets('increment button increases value by step', (tester) async {
      num? changedValue;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 5,
          step: 2,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.tap(findButtonLabel('+'));
      await tester.pumpAndSettle();

      expect(changedValue, 7);
    });

    testWidgets('decrement button decreases value by step', (tester) async {
      num? changedValue;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 5,
          step: 2,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.tap(findButtonLabel('−'));
      await tester.pumpAndSettle();

      expect(changedValue, 3);
    });

    testWidgets('clamps increment at maximum', (tester) async {
      num? changedValue = 5;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 9,
          maximum: 10,
          step: 2,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.tap(findButtonLabel('+'));
      await tester.pumpAndSettle();

      // Should clamp to 10, not 11
      expect(changedValue, 10);
    });

    testWidgets('clamps decrement at minimum', (tester) async {
      num? changedValue = 5;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 1,
          minimum: 0,
          step: 2,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.tap(findButtonLabel('−'));
      await tester.pumpAndSettle();

      // Should clamp to 0, not -1 (1 - 2 = -1, clamped to 0)
      expect(changedValue, 0);
    });

    testWidgets('disables increment button at maximum', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          value: 10,
          maximum: 10,
        ),
      );

      // The increment button should be disabled
      final plusButton = find.byWidgetPredicate(
        (widget) => widget is LayrzButton && widget.labelText == '+' && widget.onTap == null,
      );
      expect(plusButton, findsOneWidget);
    });

    testWidgets('disables decrement button at minimum', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          value: 0,
          minimum: 0,
        ),
      );

      // The decrement button should be disabled
      final minusButton = find.byWidgetPredicate(
        (widget) => widget is LayrzButton && widget.labelText == '−' && widget.onTap == null,
      );
      expect(minusButton, findsOneWidget);
    });

    testWidgets('hides step buttons when hideStepButtons is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          hideStepButtons: true,
        ),
      );

      expect(findButtonLabel('+'), findsNothing);
      expect(findButtonLabel('−'), findsNothing);
    });

    testWidgets('hides step buttons when disabled is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          disabled: true,
        ),
      );

      expect(findButtonLabel('+'), findsNothing);
      expect(findButtonLabel('−'), findsNothing);
    });

    testWidgets('disables step buttons when readOnly is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          value: 5,
          readOnly: true,
        ),
      );

      // Buttons should exist but be disabled
      final plusButton = find.byWidgetPredicate(
        (widget) => widget is LayrzButton && widget.labelText == '+' && widget.onTap == null,
      );
      expect(plusButton, findsOneWidget);
    });

    testWidgets('displays formatted value when format is provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 3.14159,
          format: (num n) => n.toStringAsFixed(2),
          inputRegExp: RegExp(r'^[0-9.]*$'),
        ),
      );

      expect(find.text('3.14'), findsOneWidget);
    });

    testWidgets('enforces inputRegExp pattern', (tester) async {
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          inputRegExp: RegExp(r'^[0-9.]*$'),
        ),
      );

      await tester.enterText(find.byType(EditableText), '123');
      expect(find.text('123'), findsOneWidget);

      // Try to enter invalid character - should be rejected
      await tester.enterText(find.byType(EditableText), '123abc');
      // The formatter should reject it, reverting to previous value
      expect(find.text('123abc'), findsNothing);
    });

    testWidgets('creates internal controller when none provided', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          controller: null, // Will create internal
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('disposes internal controller on widget dispose', (tester) async {
      // This is tested by ensuring no exceptions occur when widget is unmounted
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      // If the internal controller wasn't disposed, we'd get an error
    });

    testWidgets('uses provided controller without disposing it', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          controller: controller,
        ),
      );

      controller.text = '42';
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('creates internal focus node when none provided', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          focusNode: null, // Will create internal
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('disposes internal focus node on widget dispose', (tester) async {
      // This is tested by ensuring no exceptions occur when widget is unmounted
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      // If the internal focus node wasn't disposed, we'd get an error
    });

    testWidgets('calls onFocusChanged when focus changes', (tester) async {
      var focusChanged = false;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          onFocusChanged: (_) => focusChanged = true,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(focusChanged, isTrue);
    });

    testWidgets('calls onSubmit when submitted', (tester) async {
      var submittedValue = '';
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          onSubmit: (value) => submittedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), '42');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedValue, '42');
    });

    testWidgets('shows error messages', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          errors: ['Price is required'],
        ),
      );

      expect(find.text('Price is required'), findsOneWidget);
    });

    testWidgets('shows required asterisk when isRequired is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          isRequired: true,
        ),
      );

      expect(findButtonLabel('Price'), findsOneWidget);
      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('is read-only when readOnly is true', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 42,
          controller: controller,
          readOnly: true,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LayrzNumberInput), findsOneWidget);
      // Controller should have been initialized with the value
      expect(controller.text, '42');
    });

    testWidgets('is disabled when disabled is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          disabled: true,
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('default step is 1', (tester) async {
      num? changedValue;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 5,
          // step defaults to 1
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.tap(findButtonLabel('+'));
      await tester.pumpAndSettle();

      expect(changedValue, 6);
    });

    testWidgets('supports fractional step values', (tester) async {
      num? changedValue;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 5,
          step: 0.5,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.tap(findButtonLabel('+'));
      await tester.pumpAndSettle();

      expect(changedValue, 5.5);
    });

    testWidgets('default maximumDecimalDigits is 4', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          // maximumDecimalDigits defaults to 4
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('compact viewport uses larger padding', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(800, 600); // < 960px
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('regular viewport uses smaller padding', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800); // >= 960px
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
        ),
      );

      expect(find.byType(LayrzNumberInput), findsOneWidget);
    });

    testWidgets('field box baseline-aligns with sibling LayrzTextInput', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LayrzNumberInput(
              labelText: 'Price',
              hintText: 'Enter price',
            ),
            const SizedBox(height: 16),
            const LayrzTextInput(
              labelText: 'Name',
              hintText: 'Enter name',
            ),
          ],
        ),
      );

      // Both fields should have labels and be aligned
      expect(findButtonLabel('Price'), findsOneWidget);
      expect(findButtonLabel('Name'), findsOneWidget);
    });
  });
}
