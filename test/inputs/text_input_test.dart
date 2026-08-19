import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzTextInput', () {
    testWidgets('renders with label and placeholder', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Name',
          placeholder: 'Enter your name',
        ),
      );

      expect(find.text('Name'), findsOneWidget);
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

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
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
            prefixIcon: material.Icons.search,
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
            suffixIcon: material.Icons.clear,
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
      var tapped = false;
      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Input',
          onTap: () => tapped = true,
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
  });
}

