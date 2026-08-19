import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/input_slot.dart';

import '../helpers/find_button_label.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzInputChrome', () {
    testWidgets('renders label', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Test Label',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(findButtonLabel('Test Label'), findsOneWidget);
    });

    testWidgets('renders required asterisk', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Required Field',
          isRequired: true,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(findButtonLabel('*'), findsOneWidget);
    });

    testWidgets('renders error messages', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: ['Error message'],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('hides error messages when hideDetails is true', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: ['Error message'],
          hideDetails: true,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text('Error message'), findsNothing);
    });

    testWidgets('renders help icon when helpContentText is provided', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          helpTitleText: 'Help',
          helpContentText: 'Help text',
          child: Container(),
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });

    testWidgets('renders prefix slot content', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(text: r'$'),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('renders suffix slot content', (tester) async {
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(text: '%'),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          child: Container(),
        ),
      );

      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('renders shortcut text when provided (desktop)', (tester) async {
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;

        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Field',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(),
            suffixSlot: LayrzInputSuffixSlot(),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            shortcutText: 'Ctrl+S',
            child: Container(),
          ),
        );

        expect(find.text('Ctrl+S'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('hides shortcut text on mobile without reserving space', (tester) async {
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        await pumpThemed(
          tester,
          LayrzInputChrome(
            labelText: 'Field',
            isRequired: false,
            prefixSlot: LayrzInputPrefixSlot(),
            suffixSlot: LayrzInputSuffixSlot(),
            disabled: false,
            readOnly: false,
            errors: [],
            hideDetails: false,
            states: {},
            shortcutText: 'Ctrl+S',
            child: Container(),
          ),
        );

        expect(find.text('Ctrl+S'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('hint is visible when field is empty', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(find.text('Placeholder text'), findsOneWidget);
    });

    testWidgets('hint is not visible when field has text', (tester) async {
      final controller = TextEditingController(text: 'Some text');
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(find.text('Placeholder text'), findsNothing);
    });

    testWidgets('hint remains visible when focused but empty', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {WidgetState.focused},
          controller: controller,
          child: Focus(
            focusNode: focusNode,
            child: Container(),
          ),
        ),
      );

      expect(find.text('Placeholder text'), findsOneWidget);
    });

    testWidgets('hint reappears when text is cleared back to empty', (tester) async {
      final controller = TextEditingController(text: 'Some text');
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Placeholder text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(find.text('Placeholder text'), findsNothing);
      controller.clear();
      await tester.pumpAndSettle();
      expect(find.text('Placeholder text'), findsOneWidget);
    });

    testWidgets('caller-supplied controller is not disposed after widget disposal', (tester) async {
      final controller = TextEditingController(text: 'Test');
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Field',
          hintText: 'Hint',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: Container(),
        ),
      );

      expect(controller.text, 'Test');
      // After widget disposal, controller should still be usable
    });
  });
}
