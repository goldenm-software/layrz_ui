import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/number/number_field_edge.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';

import '../../helpers/pump_themed.dart';
import '../../helpers/find_button_label.dart';

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

    testWidgets('calls onChanged with null when input is cleared', (tester) async {
      // This test was previously checking that non-numeric input results in onChanged(null).
      // With the new numeric formatter, non-numeric characters are rejected at the keystroke,
      // so the field never accepts them. Instead, test that clearing the field fires onChanged(null).
      num? changedValue = 42;
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), '123');
      expect(changedValue, 123);

      // Now clear the field
      await tester.enterText(find.byType(EditableText), '');
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

      await tester.tap(find.byType(NumberFieldControl).last);
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

      await tester.tap(find.byType(NumberFieldControl).first);
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

      await tester.tap(find.byType(NumberFieldControl).last);
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

      await tester.tap(find.byType(NumberFieldControl).first);
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

      // The increment button should exist (with + glyph icon) and be disabled when at maximum
      expect(find.byType(Icon), findsWidgets);
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

      // The decrement button should exist (with − glyph icon) and be disabled when at minimum
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('hides step buttons when hideStepButtons is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          hideStepButtons: true,
        ),
      );

      // When hideStepButtons is true, there should be no NumberFieldControl icons
      expect(find.byType(NumberFieldControl), findsNothing);
    });

    testWidgets('hides step buttons when disabled is true', (tester) async {
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Number',
          disabled: true,
        ),
      );

      // When disabled is true, there should be no NumberFieldControl icons
      expect(find.byType(NumberFieldControl), findsNothing);
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

      // Buttons should exist (with icons) when readOnly is true
      expect(find.byType(NumberFieldControl), findsWidgets);
    });

    testWidgets('displays formatted value when format is provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          value: 3.14159,
          format: (num n) => n.toStringAsFixed(2),
        ),
      );

      expect(find.text('3.14'), findsOneWidget);
    });

    testWidgets('with inputFormatters null, numeric formatter is applied', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          controller: controller,
          // inputFormatters is null, so numeric formatter applies
        ),
      );

      // Numeric input should work
      await tester.enterText(find.byType(EditableText), '123');
      expect(controller.text, '123');

      // Invalid characters should be filtered out
      await tester.enterText(find.byType(EditableText), '123abc');
      expect(controller.text, '123');
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

      // Baseline: the default (step-buttons visible) configuration already rendered
      // errors correctly before this migration — this must not regress. findsOneWidget
      // also guards against Trap 1 (hideDetails: true on the inner chrome) reappearing
      // as a duplicated error block.
      expect(find.text('Price is required'), findsOneWidget);
    });

    testWidgets('shows error messages when hideStepButtons is true (regression, was dropped)', (tester) async {
      // Failing-first: before the fix, `errors` was never passed on this branch at all,
      // so this assertion found 0 widgets. See dossier §3.3 / plan Trap 2.
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Qty',
          hideStepButtons: true,
          errors: ['Too small'],
        ),
      );

      expect(find.text('Too small'), findsOneWidget);
    });

    testWidgets('shows error messages when disabled is true (regression, was dropped)', (tester) async {
      // Failing-first: `disabled: true` also routes through the no-step-buttons branch
      // (the selector is `!hideStepButtons && !disabled`), so it shared the same bug.
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Qty',
          disabled: true,
          errors: ['Too small'],
        ),
      );

      expect(find.text('Too small'), findsOneWidget);
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

      await tester.tap(find.byType(NumberFieldControl).last);
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

      await tester.tap(find.byType(NumberFieldControl).last);
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

    testWidgets('filters out letters and symbols', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          controller: controller,
        ),
      );

      // Enter text with invalid characters; formatter filters them out
      await tester.enterText(find.byType(EditableText), '123abc!@#');
      // Only numeric characters should remain
      expect(controller.text, '123');
    });

    testWidgets('accepts configured decimal separator (dot)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          decimalSeparator: LayrzDecimalSeparator.dot,
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3.14');
      expect(controller.text, '3.14');
    });

    testWidgets('rejects non-configured separator (comma when dot configured)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          decimalSeparator: LayrzDecimalSeparator.dot,
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3,14');
      // Comma should be rejected, only digits remain
      expect(controller.text, '314');
    });

    testWidgets('accepts configured decimal separator (comma)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          decimalSeparator: LayrzDecimalSeparator.comma,
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3,14');
      expect(controller.text, '3,14');
    });

    testWidgets('accepts leading minus when minimum is negative', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          minimum: -100,
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), '-42');
      expect(controller.text, '-42');
    });

    testWidgets('filters out leading minus when minimum is non-negative', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          minimum: 0,
          controller: controller,
        ),
      );

      // Formatter filters out the minus since negatives are not allowed
      await tester.enterText(find.byType(EditableText), '-42');
      expect(controller.text, '42');
    });

    testWidgets('caps fractional digits at maximumDecimalDigits', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          maximumDecimalDigits: 2,
          controller: controller,
        ),
      );

      // Formatter caps fractional digits at 2, ignoring '159'
      await tester.enterText(find.byType(EditableText), '3.14159');
      expect(controller.text, '3.14');
    });

    testWidgets('rejects separator when maximumDecimalDigits is 0', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          maximumDecimalDigits: 0,
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3.14');
      // Separator should be rejected when no decimals allowed
      expect(controller.text, '314');
    });

    testWidgets('allows intermediate typing states', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          controller: controller,
        ),
      );

      // Empty string should be allowed
      await tester.enterText(find.byType(EditableText), '');
      expect(controller.text, '');

      // Lone minus should be allowed
      await tester.enterText(find.byType(EditableText), '-');
      expect(controller.text, '-');

      // Trailing separator should be allowed
      await tester.enterText(find.byType(EditableText), '12.');
      expect(controller.text, '12.');

      // Complete it
      await tester.enterText(find.byType(EditableText), '12.34');
      expect(controller.text, '12.34');
    });

    testWidgets('caller-supplied inputFormatters replaces numeric formatter completely', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemed(
        tester,
        LayrzNumberInput(
          labelText: 'Number',
          // Custom formatter that allows letters (proving we override the numeric formatter)
          inputFormatters: [_AllowLettersFormatter()],
          controller: controller,
        ),
      );

      // With the custom formatter, letters are now accepted (no numeric-only enforcement)
      await tester.enterText(find.byType(EditableText), 'abc123xyz');
      expect(controller.text, 'abc123xyz');
    });

    testWidgets('inner chrome background is danger.shade50 when errors are non-empty', (tester) async {
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

      final tokens = LayrzTokens.light();
      final expectedBackgroundColor = tokens.colors.danger.shade50;

      // Find the chrome container inside LayrzInputChrome that renders the field background.
      // The chrome is the first Container descendant of LayrzInputChrome with a BoxDecoration.
      final chromeFinder = find.descendant(
        of: find.byType(LayrzInputChrome),
        matching: find.byType(Container),
      );

      // There must be at least one Container inside LayrzInputChrome
      expect(chromeFinder, findsWidgets);

      // Locate the chrome container by examining all Container descendants
      Container? chromeContainer;
      for (final element in chromeFinder.evaluate()) {
        final widget = element.widget as Container;
        if (widget.decoration is BoxDecoration) {
          chromeContainer = widget;
          break;
        }
      }

      // Assert the chrome container is found and its decoration is a BoxDecoration
      expect(chromeContainer, isNotNull, reason: 'Chrome container should be found inside LayrzInputChrome');
      final decoration = chromeContainer!.decoration as BoxDecoration;

      // Assert the chrome's background color is danger.shade50
      expect(
        decoration.color,
        equals(expectedBackgroundColor),
        reason:
            'Inner chrome background should be danger.shade50 (${expectedBackgroundColor.toString()}) '
            'but got ${decoration.color.toString()}',
      );
    });

    testWidgets('error text appears exactly once when errors are non-empty', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      const errorMessage = 'Price is required';
      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          errors: [errorMessage],
        ),
      );

      // Error text should appear exactly once (in the outer footer, not duplicated by the inner chrome)
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('trailing error icon is present when errors are non-empty', (tester) async {
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

      // When errors are present, the trailing error icon should be rendered by the inner chrome
      // The icon is MdiIcons.alertOutline
      expect(find.byIcon(MdiIcons.alertOutline), findsOneWidget);
    });

    testWidgets('trailing error icon is absent when errors are empty', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        const LayrzNumberInput(
          labelText: 'Price',
          errors: [],
        ),
      );

      // When errors are empty, no error icon should be rendered
      expect(find.byIcon(MdiIcons.alertOutline), findsNothing);
    });

    testWidgets('outer container and step buttons are danger-styled when errors are non-empty', (tester) async {
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

      final tokens = LayrzTokens.light();
      final expectedBackgroundColor = tokens.colors.danger.shade50;
      final expectedBorderColor = tokens.colors.danger;

      // Resolve the spec for error state to get the cap's expected background
      final capSpec = LayrzInputStyleSpec.resolve(
        states: <WidgetState>{},
        tokens: tokens,
        hasErrors: true,
        readOnly: false,
      );
      final expectedCapBackgroundColor = capSpec.backgroundColor;

      // Find the outer row Container (the one in _buildNumberInputRow) by looking for a Container
      // that is an ancestor of LayrzInputChrome
      final outerRowFinder = find.ancestor(
        of: find.byType(LayrzInputChrome),
        matching: find.byType(Container),
      );

      // The outermost Container in the hierarchy should be the row's outer container
      expect(outerRowFinder, findsWidgets, reason: 'Outer container should exist');

      final elements = outerRowFinder.evaluate().toList();
      expect(elements, isNotEmpty, reason: 'Outer container must be in the widget tree');

      // Get the outermost container (last in the list of ancestors)
      final outerContainer = elements.last.widget as Container;

      // Assert outer container's decoration is a BoxDecoration
      expect(
        outerContainer.decoration,
        isA<BoxDecoration>(),
        reason: 'Outer container decoration must be a BoxDecoration',
      );
      final decoration = outerContainer.decoration as BoxDecoration;

      // Assert the outer container's background color is danger.shade50
      expect(
        decoration.color,
        equals(expectedBackgroundColor),
        reason:
            'Outer container background should be danger.shade50 (${expectedBackgroundColor.toString()}) '
            'but got ${decoration.color.toString()}',
      );

      // Assert the border exists
      expect(
        decoration.border,
        isNotNull,
        reason: 'Outer container should have a border',
      );

      // Assert the border is a Border type
      expect(
        decoration.border,
        isA<Border>(),
        reason: 'Outer container border must be a Border instance',
      );

      final border = decoration.border as Border;

      // Assert the border color is danger
      expect(
        border.top.color,
        equals(expectedBorderColor),
        reason:
            'Outer container border should be danger color (${expectedBorderColor.toString()}) '
            'but got ${border.top.color.toString()}',
      );

      // Assert exactly two NumberFieldControl widgets exist (left decrement and right increment)
      expect(
        find.byType(NumberFieldControl),
        findsNWidgets(2),
        reason: 'Step buttons: exactly one decrement and one increment control should exist',
      );

      // Verify that the step buttons have danger-styled backgrounds by finding their Container children
      // Each NumberFieldControl renders: AnimatedOpacity → Container (capWithDivider with spec.backgroundColor)
      final capContainerFinder = find.descendant(
        of: find.byType(NumberFieldControl),
        matching: find.byType(Container),
      );

      expect(capContainerFinder, findsWidgets, reason: 'Cap containers should exist inside NumberFieldControl');

      int capContainersWithCorrectColor = 0;
      for (final element in capContainerFinder.evaluate()) {
        final container = element.widget as Container;
        if (container.decoration is BoxDecoration) {
          final capDecoration = container.decoration as BoxDecoration;
          if (capDecoration.color == expectedCapBackgroundColor) {
            capContainersWithCorrectColor++;
          }
        }
      }

      // We expect at least 2 cap containers with the correct danger colour (one for decrement, one for increment)
      expect(
        capContainersWithCorrectColor,
        greaterThanOrEqualTo(2),
        reason:
            'Both step button caps should have danger-styled background color '
            '(${expectedCapBackgroundColor.toString()}), but only found $capContainersWithCorrectColor with correct colour',
      );
    });
  });
}

/// Custom formatter that allows all input (used to test that inputFormatters completely replaces the numeric formatter).
class _AllowLettersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // This formatter allows anything (all input accepted)
    return newValue;
  }
}
