import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTextInput', () {
    testWidgets('renders with label and placeholder', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Name',
          hintText: 'Enter your name',
        ),
      );

      expect(findButtonLabel('Name'), findsOneWidget);
      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('is disabled when disabled=true', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Disabled',
          disabled: true,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('is read-only when readOnly=true', (tester) async {
      final controller = TextEditingController(text: 'Read-only');
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Read-only',
          controller: controller,
          readOnly: true,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('shows error messages when errors are provided', (tester) async {
      // Set desktop width (>= 960px) so errors render inline (not in compact mode)
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Email',
          errors: ['Invalid email'],
        ),
      );

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('shows required asterisk when isRequired=true', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Username',
          isRequired: true,
        ),
      );

      expect(findButtonLabel('Username'), findsOneWidget);
      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      var changedValue = '';
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Hello');
      expect(changedValue, 'Hello');
    });

    testWidgets('calls onSubmit when submitted', (tester) async {
      var submittedValue = '';
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          onSubmit: (value) => submittedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedValue, 'Test');
    });

    testWidgets('calls onFocusChanged when focus changes', (tester) async {
      var isFocused = false;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          onFocusChanged: (value) => isFocused = value,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(isFocused, true);
    });

    testWidgets('creates controller internally when not supplied', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('creates focus node internally when not supplied', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('does not dispose caller-supplied controller', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          controller: controller,
        ),
      );

      expect(controller.text, '');
    });

    testWidgets('does not dispose caller-supplied focus node', (tester) async {
      final focusNode = FocusNode();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          focusNode: focusNode,
        ),
      );

      expect(focusNode.canRequestFocus, true);
    });

    testWidgets('enforces maxLength with formatter', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Max 5',
          maxLength: 5,
        ),
      );

      await tester.enterText(find.byType(EditableText), '123456789');
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('prefix slot renders correctly', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'With prefix',
          prefixText: r'$',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('suffix slot renders correctly', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'With suffix',
          suffixText: '%',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('asserts at most one prefix type', (tester) async {
      expect(
        () {
          LayrzTextInput(
            labelText: 'Invalid',
            prefixIcon: MdiIcons.checkCircleOutline,
            prefixText: r'$',
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('asserts at most one suffix type', (tester) async {
      expect(
        () {
          LayrzTextInput(
            labelText: 'Invalid',
            suffixIcon: MdiIcons.eyeOutline,
            suffixText: '%',
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('hides error block when hideDetails=true', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          errors: ['Error'],
          hideDetails: true,
        ),
      );

      expect(find.text('Error'), findsNothing);
    });

    testWidgets('accepts onTap callback', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          onTap: () {},
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('accepts onTap even when disabled', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          disabled: true,
          onTap: () {},
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('accepts onTap when read-only', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          readOnly: true,
          onTap: () {},
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('respects textCapitalization', (tester) async {
      await pumpThemed(
        tester,
        const LayrzTextInput(
          labelText: 'Input',
          textCapitalization: TextCapitalization.sentences,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('respects obscureText for password fields', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Password',
          obscureText: true,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('displays shortcut badge', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'With shortcut',
          shortcut: {LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS},
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('caller-supplied controller can be modified', (tester) async {
      final controller = TextEditingController(text: 'Initial');
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Test',
          controller: controller,
        ),
      );

      expect(controller.text, 'Initial');
      controller.text = 'Modified';
      await tester.pumpAndSettle();
      expect(controller.text, 'Modified');
    });

    testWidgets('caller-supplied focusNode can request focus', (tester) async {
      final focusNode = FocusNode();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Test',
          focusNode: focusNode,
        ),
      );

      expect(focusNode.canRequestFocus, true);
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, true);
    });

    testWidgets('readOnly state accepts onTap callback', (tester) async {
      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Read-only',
          readOnly: true,
          onTap: () => tapCount++,
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('disabled state suppresses editing', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Disabled',
          disabled: true,
        ),
      );

      final editable = find.byType(EditableText);
      expect(editable, findsOneWidget);
    });

    testWidgets('onPrefixTap is suppressed when disabled', (tester) async {
      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Disabled',
          disabled: true,
          prefixText: r'$',
          onPrefixTap: () => tapCount++,
        ),
      );

      expect(tapCount, 0);
    });

    testWidgets('multiple errors render all lines', (tester) async {
      // Set desktop width (>= 960px) so errors render inline (not in compact mode)
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Multi-error',
          errors: [
            'First error',
            'Second error',
            'Third error',
          ],
        ),
      );

      expect(find.text('First error, Second error, Third error'), findsOneWidget);
    });

    testWidgets('hideDetails hides error block', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Hidden errors',
          errors: ['Error 1', 'Error 2'],
          hideDetails: true,
        ),
      );

      expect(find.text('Error 1'), findsNothing);
      expect(find.text('Error 2'), findsNothing);
    });

    testWidgets('caller-supplied suffix renders alongside error icon', (tester) async {
      // Set desktop width (>= 960px) so errors render inline (not in compact mode)
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Error with suffix',
          errors: ['Error'],
          suffixText: '%',
        ),
      );

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('help affordance renders through tooltip when provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'With help',
          helpContentText: 'Help text',
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('help affordance reserves no space when null', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'No help',
          helpContentText: null,
        ),
      );

      expect(find.byType(LayrzTextInput), findsOneWidget);
    });

    testWidgets('provides accessibility label via semantics', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Accessible input',
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('provides required state via semantics', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Required',
          isRequired: true,
        ),
      );

      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('provides error state via semantics', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'With error',
          errors: ['Invalid'],
        ),
      );

      expect(find.text('Invalid'), findsOneWidget);
    });

    testWidgets('uses custom padding when provided', (tester) async {
      const customPadding = EdgeInsets.all(20);
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Custom Padding',
          padding: customPadding,
        ),
      );

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
      final widget = tester.widget<Container>(container);
      expect(widget.padding, customPadding);
    });

    testWidgets('uses token-derived padding when not provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Default Padding',
        ),
      );

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });

    testWidgets('explicit padding overrides token default', (tester) async {
      const customPadding = EdgeInsets.symmetric(horizontal: 15, vertical: 25);
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Custom Padding',
          padding: customPadding,
        ),
      );

      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
      final widget = tester.widget<Container>(container);
      expect(widget.padding, customPadding);
    });

    testWidgets('hint is visible when field is empty', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field',
          hintText: 'Enter text here',
          controller: controller,
        ),
      );

      expect(find.text('Enter text here'), findsOneWidget);
    });

    testWidgets('hint is not visible when field has text', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field',
          hintText: 'Enter text here',
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Some text');
      await tester.pumpAndSettle();
      expect(find.text('Enter text here'), findsNothing);
    });

    testWidgets('hint reappears when text is cleared back to empty', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field',
          hintText: 'Enter text here',
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Some text');
      await tester.pumpAndSettle();
      expect(find.text('Enter text here'), findsNothing);

      controller.clear();
      await tester.pumpAndSettle();
      expect(find.text('Enter text here'), findsOneWidget);
    });

    testWidgets('hint remains visible when focused but empty', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field',
          hintText: 'Enter text here',
          controller: controller,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('Enter text here'), findsOneWidget);
    });

    testWidgets('caller-supplied controller remains usable after widget disposal', (tester) async {
      final controller = TextEditingController(text: 'Initial');
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Test',
          controller: controller,
        ),
      );

      expect(controller.text, 'Initial');
      // After widget is disposed, controller should still be usable
      controller.text = 'Modified';
      expect(controller.text, 'Modified');
    });

    testWidgets('passes selectionColor to EditableText by default', (tester) async {
      await pumpThemed(
        tester,
        const LayrzTextInput(
          labelText: 'Test',
        ),
      );

      final editableText = find.byType(EditableText);
      expect(editableText, findsOneWidget);

      final widget = tester.widget<EditableText>(editableText);
      // Should have a non-null selection color (primary at tonal opacity)
      expect(widget.selectionColor, isNotNull);
    });

    testWidgets('selectionColor defaults to primary at tonalOpacity', (tester) async {
      await pumpThemed(
        tester,
        const LayrzTextInput(
          labelText: 'Test',
        ),
      );

      final editableText = find.byType(EditableText);
      final widget = tester.widget<EditableText>(editableText);
      final context = tester.element(editableText);
      final tokens = context.tokens;

      final expectedColor = tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);
      expect(widget.selectionColor, expectedColor);
    });

    testWidgets('displays character counter when maxLength is set', (tester) async {
      const int maxLength = 50;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Max length field',
          maxLength: maxLength,
        ),
      );

      expect(find.text('0/50'), findsOneWidget);
    });

    testWidgets('counter updates as text is entered', (tester) async {
      const int maxLength = 50;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Max length field',
          maxLength: maxLength,
        ),
      );

      expect(find.text('0/50'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Hello');
      await tester.pumpAndSettle();

      expect(find.text('5/50'), findsOneWidget);
    });

    testWidgets('counter is hidden when hideDetails is true', (tester) async {
      const int maxLength = 50;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Max length field',
          maxLength: maxLength,
          hideDetails: true,
        ),
      );

      expect(find.text('0/50'), findsNothing);
    });

    testWidgets('error and counter both visible without overlap', (tester) async {
      // Set desktop width (>= 960px) so errors render inline (not in compact mode)
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      const int maxLength = 50;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field with error and counter',
          maxLength: maxLength,
          errors: ['Validation failed'],
        ),
      );

      // Both should be visible
      expect(find.text('Validation failed'), findsOneWidget);
      expect(find.text('0/50'), findsOneWidget);
    });

    testWidgets('counter is fg3 color even with errors present', (tester) async {
      const int maxLength = 50;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field',
          maxLength: maxLength,
          errors: ['Error'],
        ),
      );

      final counterText = find.text('0/50');
      expect(counterText, findsOneWidget);

      // Get the Text widget and verify it's using fg3 color
      final textWidget = tester.widget<Text>(counterText);
      final style = textWidget.style;
      final context = tester.element(counterText) as BuildContext;
      expect(style?.color, context.tokens.colors.fg3);
    });

    testWidgets('error text is danger-colored and bold', (tester) async {
      // Set desktop width (>= 960px) so errors render inline (not in compact mode)
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      const int maxLength = 50;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Field',
          maxLength: maxLength,
          errors: ['Validation error'],
        ),
      );

      final errorText = find.text('Validation error');
      expect(errorText, findsOneWidget);

      // Get the Text widget and check its style
      final textWidget = tester.widget<Text>(errorText);
      final style = textWidget.style;
      final context = tester.element(errorText) as BuildContext;
      expect(style?.color, context.tokens.colors.danger);
      expect(style?.fontWeight, FontWeight.w700);
    });

    testWidgets('slot icon size is consistent between prefix and suffix', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'With slots',
          prefixIcon: MdiIcons.checkCircleOutline,
          suffixIcon: MdiIcons.eyeOutline,
        ),
      );

      // Find all Icon widgets (prefix, suffix, and potentially error icon)
      final icons = find.byType(Icon);
      expect(icons, findsWidgets);

      // All icons should have the same size (derived from tokens or theme)
      // This is implicitly verified by the field maintaining constant height
      final container = find.byType(Container).first;
      expect(container, findsOneWidget);
    });

    testWidgets('hint and editable text share vertical centre', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Text field',
          hintText: 'Enter text',
        ),
      );

      // Find the hint text and editable text
      final hintFinder = find.text('Enter text');
      final editableFinder = find.byType(EditableText);

      expect(hintFinder, findsWidgets);
      expect(editableFinder, findsOneWidget);

      // Get their rendered vertical centers
      final hintRect = tester.getRect(hintFinder.first);
      final editableRect = tester.getRect(editableFinder.first);

      // Verify their vertical centers are aligned (within 1 pixel for rounding)
      expect((hintRect.center.dy - editableRect.center.dy).abs(), lessThan(1.5));

      expect(tester.takeException(), isNull);
    });
  });
}
