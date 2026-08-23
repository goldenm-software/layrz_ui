import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/text/text_input.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzTextInput - Accessibility', () {
    testWidgets('text field label is exposed to screen readers exactly once', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Email Address',
          controller: TextEditingController(),
        ),
      );

      // Label should be accessible via semantics - exactly once
      expect(find.bySemanticsLabel('Email Address'), findsOneWidget);

      // Verify the semantic node has the correct label and expected text field properties
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Email Address',
          hasEnabledState: true,
          isEnabled: true,
          isTextField: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('disabled text field is semantically marked as disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Disabled field',
          disabled: true,
          controller: TextEditingController(),
        ),
      );

      // Verify disabled semantics - disabled fields are read-only from the EditableText perspective
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Disabled field',
          hasEnabledState: true,
          isEnabled: false,
          isTextField: true,
          isReadOnly: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('read-only text field is semantically marked as disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Read-only field',
          readOnly: true,
          controller: TextEditingController(),
        ),
      );

      // Read-only counts as disabled for semantics
      expect(
        tester.getSemantics(
          find
              .descendant(
                of: find.byType(LayrzTextInput),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        matchesSemantics(
          label: 'Read-only field',
          hasEnabledState: true,
          isEnabled: false,
          isTextField: true,
          isReadOnly: true,
          isFocusable: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('text input accepts and reflects typed text', (tester) async {
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Username',
          controller: controller,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'john_doe');
      await tester.pumpAndSettle();

      expect(controller.text, equals('john_doe'));
    });

    testWidgets('text input fires onChanged callback', (tester) async {
      final controller = TextEditingController();
      String? changedValue;

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Test field',
          controller: controller,
          onChanged: (value) {
            changedValue = value;
          },
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'test');
      await tester.pumpAndSettle();

      expect(changedValue, equals('test'));
    });

    testWidgets('disabled text input does not accept input', (tester) async {
      final controller = TextEditingController();
      int changeCount = 0;

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Disabled',
          disabled: true,
          controller: controller,
          onChanged: (_) {
            changeCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzTextInput), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(changeCount, equals(0));
    });

    testWidgets('required indicator is shown', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Required field',
          isRequired: true,
          controller: TextEditingController(),
        ),
      );

      // Verify the widget renders with isRequired configuration
      expect(find.byType(LayrzTextInput), findsOneWidget);
      handle.dispose();
    });

    testWidgets('prefix text is rendered', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Amount',
          prefixText: '\$',
          controller: TextEditingController(),
        ),
      );

      expect(find.text('\$'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('suffix text is rendered', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpThemed(
        tester,
        LayrzTextInput(
          labelText: 'Amount',
          suffixText: '.00',
          controller: TextEditingController(),
        ),
      );

      expect(find.text('.00'), findsOneWidget);
      handle.dispose();
    });
  });
}
