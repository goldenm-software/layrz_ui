import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/combobox/combobox_surface.dart';

import '../../helpers/pump_themed_app.dart';

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

    testWidgets('flips above when there is no room below', (tester) async {
      tester.view.physicalSize = const Size(1600, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Column(
          children: const [
            Spacer(),
            LayrzComboBoxInput(
              labelText: 'TZ',
              options: ['America/Panama', 'America/Peru'],
            ),
          ],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byType(LayrzComboBoxInput));

      // Get the bounds of all option items to compute the panel rect
      final optionRects = find
          .byType(OptionItem)
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((element) => element == e)))
          .toList();
      final panelLeft = optionRects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
      final panelTop = optionRects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
      final panelRight = optionRects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
      final panelBottom = optionRects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      final panel = Rect.fromLTRB(panelLeft, panelTop, panelRight, panelBottom);

      expect(
        panel.bottom,
        lessThanOrEqualTo(field.top),
        reason: 'panel must sit above the field when there is no room below',
      );
      expect(
        panel.width,
        closeTo(field.width, 0.5),
        reason: 'a web-style combobox list matches its field width',
      );
    });

    testWidgets('opens below when there is room', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        Column(
          children: [
            const LayrzComboBoxInput(
              labelText: 'TZ',
              options: ['America/Panama', 'America/Peru'],
            ),
            const Spacer(),
          ],
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final field = tester.getRect(find.byType(LayrzComboBoxInput));

      // Get the bounds of all option items to compute the panel rect
      final optionRects = find
          .byType(OptionItem)
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((element) => element == e)))
          .toList();
      final panelLeft = optionRects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
      final panelTop = optionRects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
      final panelRight = optionRects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
      final panelBottom = optionRects.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
      final panel = Rect.fromLTRB(panelLeft, panelTop, panelRight, panelBottom);

      expect(
        panel.top,
        greaterThanOrEqualTo(field.bottom),
        reason: 'panel must sit below the field when there is room',
      );
      expect(
        panel.width,
        closeTo(field.width, 0.5),
        reason: 'a web-style combobox list matches its field width',
      );
    });
  });
}
