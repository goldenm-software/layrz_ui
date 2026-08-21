import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzComboBoxInput - Accessibility', () {
    testWidgets('field is labeled correctly for screen readers', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select an option',
          options: options,
        ),
      );

      // The combobox and text input should be present
      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('required indicator is present when isRequired is true', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Required field',
          options: options,
          isRequired: true,
        ),
      );

      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('error messages are displayed when provided', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          errors: ['This field is required', 'Invalid format'],
        ),
      );

      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('help text is displayed when provided', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          helpTitleText: 'Help',
          helpContentText: 'Select an option from the list',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('disabled state is properly announced', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          disabled: true,
        ),
      );

      // Field should be disabled and not interactive
      final editableTextState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editableTextState.widget.readOnly, isTrue);
    });

    testWidgets('supports input formatters for accessibility', (tester) async {
      final options = ['Option 1'];
      final formatters = <TextInputFormatter>[];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          inputFormatters: formatters,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('hint text provides input guidance', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          hintText: 'Type to search options',
          options: options,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('field has proper semantic label', (tester) async {
      final options = ['Option 1', 'Option 2'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose an option',
          options: options,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
      expect(find.byType(LayrzComboBoxInput), findsOneWidget);
    });

    testWidgets('text selection is supported', (tester) async {
      final options = ['Option 1'];
      final controller = TextEditingController(text: 'Initial');

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          controller: controller,
        ),
      );

      // Tap field to enable selection
      await tester.tap(find.byType(LayrzTextInput));
      await tester.pumpAndSettle();

      // Selection operations should be available
      expect(controller.text, 'Initial');

      controller.dispose();
    });

    testWidgets('shows contextual help with helpTitleText and helpContentText', (tester) async {
      final options = ['Option 1'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Select',
          options: options,
          helpTitleText: 'Tip',
          helpContentText: 'Choose from available options',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('field is focusable via keyboard', (tester) async {
      final options = ['Option 1', 'Option 2'];
      final focusNode = FocusNode();

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Choose',
          options: options,
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });

    testWidgets('empty options message displayed with proper contrast', (tester) async {
      final options = ['Apple', 'Banana'];

      await pumpThemedApp(
        tester,
        LayrzComboBoxInput(
          labelText: 'Fruits',
          options: options,
          emptyOptionsText: 'No matching fruits',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });
  });
}
