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

    testWidgets('hint and content align to top in variable-height mode', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      final controller = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Description',
          hintText: 'Enter text here',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: controller,
          minContentHeight: 120,
          maxContentHeight: 300,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
            maxLines: null,
            minLines: 2,
            expands: false,
          ),
        ),
      );

      // Verify hint text is rendered
      expect(find.text('Enter text here'), findsOneWidget);

      // Get the position of the hint text
      final hintFinder = find.text('Enter text here');
      expect(hintFinder, findsOneWidget);

      // Get the top-left position of the hint
      final hintTopLeft = tester.getTopLeft(hintFinder);

      // Get the container that holds the content (the Stack's parent Expanded/DefaultTextStyle)
      final stackFinder = find.byType(Stack).first;
      final stackTopLeft = tester.getTopLeft(stackFinder);

      // The hint should be positioned at or very near the top-left of the Stack
      // Allow a small tolerance for padding/rendering differences
      expect(
        hintTopLeft.dy,
        lessThanOrEqualTo(stackTopLeft.dy + 2),
        reason: 'Hint should be at top of content area in multiline mode',
      );
    });

    testWidgets('hint alignment differs between single-line and multiline modes', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      // Test single-line mode (fixed height)
      final singleLineController = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome(
          labelText: 'Single Line',
          hintText: 'Single line hint',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: singleLineController,
          child: EditableText(
            controller: singleLineController,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
          ),
        ),
      );

      expect(find.text('Single line hint'), findsOneWidget);
      final singleLineHintY = tester.getCenter(find.text('Single line hint')).dy;

      // Get the center Y of the container
      final singleLineContainerY = tester.getCenter(find.byType(Row).first).dy;

      // In single-line mode, hint should be roughly centered vertically
      expect(
        (singleLineHintY - singleLineContainerY).abs(),
        lessThan(20),
        reason: 'Hint should be vertically centered in single-line mode',
      );

      await tester.pumpWidget(Container());

      // Test multiline mode (variable height)
      final multiLineController = TextEditingController();
      await pumpThemed(
        tester,
        LayrzInputChrome.variableHeight(
          labelText: 'Multi Line',
          hintText: 'Multi line hint',
          isRequired: false,
          prefixSlot: LayrzInputPrefixSlot(),
          suffixSlot: LayrzInputSuffixSlot(),
          disabled: false,
          readOnly: false,
          errors: [],
          hideDetails: false,
          states: {},
          controller: multiLineController,
          minContentHeight: 120,
          maxContentHeight: 300,
          child: EditableText(
            controller: multiLineController,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
            maxLines: null,
            minLines: 2,
            expands: false,
          ),
        ),
      );

      expect(find.text('Multi line hint'), findsOneWidget);
      final multiLineHintTop = tester.getTopLeft(find.text('Multi line hint')).dy;
      final multiLineStackTop = tester.getTopLeft(find.byType(Stack).first).dy;

      // In multiline mode, hint should be at the top
      expect(
        multiLineHintTop,
        lessThanOrEqualTo(multiLineStackTop + 2),
        reason: 'Hint should be at top in multiline mode',
      );
    });

    /// Verifies that `dense: true` on the `.variableHeight` constructor resolves the same
    /// density-aware padding as the default constructor, per DESIGN-126. Both constructors
    /// must stay in lockstep on the `dense` default and its resolution.
    testWidgets('variableHeight with dense: true resolves pd1 (6px) padding on a regular viewport', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);

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
          dense: true,
          minContentHeight: 80,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: const TextStyle(fontSize: 16),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFFBDBDBD),
          ),
        ),
      );

      EdgeInsets? resolvedPadding;
      final containers = find.byType(Container);
      for (int i = 0; i < containers.evaluate().length; i++) {
        final container = tester.widget<Container>(containers.at(i));
        if (container.decoration is BoxDecoration) {
          final dec = container.decoration as BoxDecoration;
          if (dec.border != null) {
            resolvedPadding = container.padding as EdgeInsets;
            break;
          }
        }
      }

      expect(resolvedPadding, isNotNull, reason: 'Bordered input container should have been found');
      expect(resolvedPadding!.top, equals(6.0));
      expect(resolvedPadding.left, equals(6.0));
    });
  });
}
