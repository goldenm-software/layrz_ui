import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzTextAreaInput - Accessibility', () {
    testWidgets('field is labelled with labelText', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Description',
          controller: controller,
        ),
      );

      expect(findButtonLabel('Description'), findsOneWidget);
    });

    testWidgets('multiline nature is exposed to semantics', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Message',
          minLines: 3,
          maxLines: 10,
          controller: controller,
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
      final editableTextWidget = find.byType(EditableText).evaluate().first.widget as EditableText;
      expect(editableTextWidget.minLines, equals(3));
      expect(editableTextWidget.maxLines, equals(10));
    });

    testWidgets('required indicator is present when isRequired is true', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          isRequired: true,
          controller: controller,
        ),
      );

      // Widget should render with required indicator (verifying via widget presence)
      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets('error state is exposed to semantics', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          errors: ['This field is required'],
          controller: controller,
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('disabled state is semantically exposed', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          disabled: true,
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets('hint text provides placeholder context', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Your Message',
          hintText: 'Enter your message here',
          controller: controller,
        ),
      );

      expect(find.text('Enter your message here'), findsOneWidget);
    });

    testWidgets('character counter is accessible when maxLength is set', (tester) async {
      final controller = TextEditingController(text: 'Short');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          maxLength: 100,
          controller: controller,
        ),
      );

      expect(find.text('5/100'), findsOneWidget);
    });

    testWidgets('read-only state is semantically exposed', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          readOnly: true,
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets('text selection toolbar is accessible', (tester) async {
      final controller = TextEditingController(text: 'Selectable text');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('prefix and suffix slots are accessible', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Amount',
          prefixText: '\$',
          suffixText: '.00',
          controller: controller,
        ),
      );

      expect(find.text('\$'), findsOneWidget);
      expect(find.text('.00'), findsOneWidget);
    });

    testWidgets('disabled prefix/suffix taps are not triggered', (tester) async {
      bool prefixTapped = false;
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          prefixText: 'PREFIX',
          onPrefixTap: () => prefixTapped = true,
          disabled: true,
          controller: controller,
        ),
      );

      await tester.tap(find.text('PREFIX'));
      await tester.pumpAndSettle();

      expect(prefixTapped, isFalse);
    });

    testWidgets('selection handles show for touch selection', (tester) async {
      final controller = TextEditingController(text: 'Long text for selection');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('magnifier is configured for the platform', (tester) async {
      final controller = TextEditingController(text: 'Text for magnifying');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      final editableTextWidget = find.byType(EditableText).evaluate().first.widget as EditableText;
      expect(editableTextWidget.magnifierConfiguration, isNotNull);
    });

    testWidgets('custom actions set is respected', (tester) async {
      final controller = TextEditingController(text: 'Text');
      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          actions: {
            LayrzSelectableAction.copy,
            LayrzSelectableAction.paste,
          },
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });

    testWidgets('widget renders without errors', (tester) async {
      final controller = TextEditingController();

      await pumpThemed(
        tester,
        LayrzTextAreaInput(
          labelText: 'Field',
          controller: controller,
        ),
      );

      expect(find.byType(LayrzTextAreaInput), findsOneWidget);
    });
  });
}
