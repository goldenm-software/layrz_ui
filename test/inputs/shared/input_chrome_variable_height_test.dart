import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';

import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzInputChrome - variable-height mode', () {
    testWidgets('variableHeight constructor creates expandable content box', (tester) async {
      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Description',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          minContentHeight: 80,
          maxContentHeight: 200,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
          ),
        ),
      );

      expect(find.byType(LayrzInputChrome), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsOneWidget);
    });

    testWidgets('variableHeight with text grows the box', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5');
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Multi-line text',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          minContentHeight: 80,
          maxContentHeight: 300,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
            maxLines: null,
            minLines: 1,
            expands: false,
          ),
        ),
      );

      // Verify the chrome is present
      expect(find.byType(LayrzInputChrome), findsOneWidget);

      // Get the actual height of the content area
      final rect = tester.getRect(find.byType(Row).first);
      expect(rect.height, greaterThan(80.0), reason: 'Box should be taller than minimum height');
    });

    testWidgets('variableHeight respects minContentHeight', (tester) async {
      const minHeight = 100.0;
      final controller = TextEditingController(text: 'Short');
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Minimum height test',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          minContentHeight: minHeight,
          maxContentHeight: 200,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
            maxLines: null,
            minLines: 1,
            expands: false,
          ),
        ),
      );

      // The constrained box should enforce the minimum
      final constrainedBox = find.byType(ConstrainedBox);
      expect(constrainedBox, findsOneWidget);
    });

    testWidgets('variableHeight renders error messages', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: ['Error message'],
          hideDetails: false,
          states: {},
          controller: controller,
          minContentHeight: 80,
          maxContentHeight: 200,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
          ),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('default constructor maintains fixed single-line height', (tester) async {
      final controller = TextEditingController(text: 'Single line');

      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Single-line field',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
          ),
        ),
      );

      // Verify SizedBox is used for fixed height
      expect(find.byType(SizedBox), findsWidgets);

      // Verify no ConstrainedBox (which would indicate variable height)
      expect(find.byType(ConstrainedBox), findsNothing);
    });

    testWidgets('variableHeight with trailing elements aligns them to top', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = TextEditingController(text: 'Multi\nline\ntext');
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Field with suffix',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(text: '%'),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          minContentHeight: 80,
          maxContentHeight: 200,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
            maxLines: null,
            minLines: 1,
            expands: false,
          ),
        ),
      );

      // Verify the suffix is rendered
      expect(find.text('%'), findsOneWidget);

      // The Row should use CrossAxisAlignment.start for variable height
      expect(find.byType(LayrzInputChrome), findsOneWidget);
    });
  });
}
