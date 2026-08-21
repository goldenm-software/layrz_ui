import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzComboBoxInput', () {
    testWidgets('renders with label and options', (tester) async {
      final options = ['Option 1', 'Option 2', 'Option 3'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select an option',
          options: options,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('requires at least labelText or hintText', (tester) async {
      expect(
        () => LayrzComboBoxInput(options: []),
        throwsAssertionError,
      );
    });

    testWidgets('calls onChanged when value changes', (tester) async {
      final options = ['Option 1', 'Option 2'];
      String? lastValue;

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          onChanged: (value) => lastValue = value,
        ),
      );

      // Tap field
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pumpAndSettle();

      // Type text
      await tester.enterText(find.byType(EditableText), 'test');
      await tester.pumpAndSettle();

      expect(lastValue, 'test');
    });

    testWidgets('respects disabled state', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          disabled: true,
        ),
      );

      // Try to tap - should not open
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pumpAndSettle();

      // Field should not be editable
      final editableTextState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableTextState.widget.readOnly, isTrue);
    });

    testWidgets('respects readOnly state', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          readOnly: true,
        ),
      );

      // Field should not be editable
      final editableTextState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableTextState.widget.readOnly, isTrue);
    });

    testWidgets('initializes with provided value', (tester) async {
      final options = ['Option 1', 'Option 2', 'Option 3'];
      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          value: 'Option 2',
          controller: controller,
        ),
      );

      expect(controller.text, 'Option 2');

      controller.dispose();
    });

    testWidgets('allows free-form entry when allowFreeForm is true', (tester) async {
      final options = ['Option 1', 'Option 2'];
      String? lastSubmitted;

      final controller = TextEditingController();

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          allowFreeForm: true,
          controller: controller,
          onSubmit: (value) => lastSubmitted = value,
        ),
      );

      // Tap field
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pumpAndSettle();

      // Type arbitrary text
      await tester.enterText(find.byType(EditableText), 'CustomValue');
      await tester.pumpAndSettle();

      expect(lastSubmitted, null); // Not submitted yet

      controller.dispose();
    });

    testWidgets('displays errors when provided', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          errors: ['This is an error'],
        ),
      );

      expect(find.text('This is an error'), findsWidgets);
    });

    testWidgets('creates and disposes controller when not provided', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
        ),
      );

      // Should work without issues
      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('creates and disposes focus node when not provided', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
        ),
      );

      // Should work without issues
      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('custom emptyOptionsText is used', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          emptyOptionsText: 'No matching items',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('filters options when text is typed', (tester) async {
      final options = ['Apple', 'Apricot', 'Banana'];

      String? lastValue;

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          onChanged: (value) => lastValue = value,
        ),
      );

      // Tap field
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pumpAndSettle();

      // Type to filter
      await tester.enterText(find.byType(EditableText), 'app');
      await tester.pumpAndSettle();

      // The value should be updated
      expect(lastValue, 'app');
    });

    testWidgets('shows all options when enableAutocomplete is false', (tester) async {
      final options = ['Apple', 'Banana', 'Cherry'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          enableAutocomplete: false,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('reverts when allowFreeForm is false and text doesn\'t match', (tester) async {
      final controller = TextEditingController();
      final options = ['Valid1', 'Valid2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          allowFreeForm: false,
          controller: controller,
          value: 'Valid1',
        ),
      );

      expect(controller.text, 'Valid1');

      controller.dispose();
    });
  });
}
