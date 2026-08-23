import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzTextAreaInput', () {
    testWidgets('renders with default configuration', (tester) async {
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Description',
          hintText: 'Enter your description here',
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
      expect(findButtonLabel('Description'), findsOneWidget);
    });

    testWidgets('grows from minLines to maxLines', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Message',
          minLines: 2,
          maxLines: 5,
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets('minLines and maxLines assertions', (tester) async {
      expect(
        () {
          LayrzTextAreaInput(
            labelText: 'Invalid',
            minLines: 0,
          );
        },
        throwsAssertionError,
      );

      expect(
        () {
          LayrzTextAreaInput(
            labelText: 'Invalid',
            minLines: 5,
            maxLines: 3,
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('maxLength with character counter', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Limited text',
          maxLength: 100,
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Hello');
      await tester.pumpAndSettle();

      expect(find.text('5/100'), findsOneWidget);
    });

    testWidgets('disabled state prevents editing', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Disabled field',
          disabled: true,
          controller: controller,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'Should not appear');
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    testWidgets('readOnly state allows tapping but not editing', (tester) async {
      final controller = TextEditingController(text: 'Read-only text');
      bool tapped = false;

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Read-only',
          readOnly: true,
          controller: controller,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);

      await tester.enterText(find.byType(EditableText), 'New text');
      await tester.pumpAndSettle();

      expect(controller.text, equals('Read-only text'));
    });

    testWidgets('error state displays errors', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          errors: ['Error message 1', 'Error message 2'],
          controller: controller,
        ),
      );

      expect(findButtonLabel('Error message 1'), findsOneWidget);
      expect(findButtonLabel('Error message 2'), findsOneWidget);
    });

    testWidgets('hideDetails hides error messages', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          errors: ['Error message'],
          hideDetails: true,
          controller: controller,
        ),
      );

      expect(find.text('Error message'), findsNothing);
    });

    testWidgets('suffix and prefix slots', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          prefixText: 'PREFIX:',
          suffixText: 'SUFFIX',
          controller: controller,
        ),
      );

      expect(find.text('PREFIX:'), findsOneWidget);
      expect(find.text('SUFFIX'), findsOneWidget);
    });

    testWidgets('onChanged callback fires on text change', (tester) async {
      final controller = TextEditingController();
      String? changedValue;

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
          onChanged: (value) => changedValue = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'Hello world');
      await tester.pumpAndSettle();

      expect(changedValue, equals('Hello world'));
    });

    testWidgets('onFocusChanged callback', (tester) async {
      final controller = TextEditingController();
      bool? focusState;

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
          onFocusChanged: (isFocused) => focusState = isFocused,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(focusState, isTrue);
    });

    testWidgets('caller-supplied controller remains usable after disposal', (tester) async {
      final controller = TextEditingController(text: 'Initial');

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      controller.text = 'Changed';
      expect(controller.text, equals('Changed'));

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets('multi-line selection across lines', (tester) async {
      final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final state = tester.state<EditableTextState>(find.byType(EditableText));
      state.selectAll(SelectionChangedCause.toolbar);
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, equals(0));
      expect(controller.selection.extentOffset, equals(controller.text.length));
    });

    testWidgets('trailing elements align to top on tall box', (tester) async {
      final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          suffixText: '%',
          controller: controller,
        ),
      );

      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('input formatters apply', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z]')),
          ],
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'ABC');
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
    });

    testWidgets('disposes created controller and focusNode', (tester) async {
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });
  });
}
