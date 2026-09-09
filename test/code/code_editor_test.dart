import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_editor.dart';
import 'package:layrz_ui/src/code/src/code_error.dart';
import 'package:layrz_ui/src/code/src/code_gutter.dart';
import 'package:layrz_ui/src/code/src/code_surface.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCodeEditor.applyTabIndent', () {
    test('collapsed caret with useSpaces inserts tabSpaces spaces', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: 'abc', selection: TextSelection.collapsed(offset: 1)),
        tabSpaces: 4,
        useSpaces: true,
        outdent: false,
      );
      expect(result.text, 'a    bc');
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('collapsed caret with useSpaces=false inserts a literal tab', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: 'abc', selection: TextSelection.collapsed(offset: 0)),
        tabSpaces: 4,
        useSpaces: false,
        outdent: false,
      );
      expect(result.text, '\tabc');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('single-line selection is replaced by the indent unit', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: 'abcdef', selection: TextSelection(baseOffset: 1, extentOffset: 4)),
        tabSpaces: 2,
        useSpaces: true,
        outdent: false,
      );
      expect(result.text, 'a  ef');
      expect(result.selection, const TextSelection(baseOffset: 1, extentOffset: 3));
    });

    test('multi-line selection indents every touched line', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(
          text: 'line1\nline2\nline3',
          selection: TextSelection(baseOffset: 2, extentOffset: 8),
        ),
        tabSpaces: 2,
        useSpaces: true,
        outdent: false,
      );
      expect(result.text, '  line1\n  line2\nline3');
    });

    test('multi-line selection ending exactly at a newline does not indent the next line', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(
          text: 'line1\nline2\nline3',
          selection: TextSelection(baseOffset: 0, extentOffset: 6),
        ),
        tabSpaces: 2,
        useSpaces: true,
        outdent: false,
      );
      expect(result.text, '  line1\nline2\nline3');
    });

    test('outdent removes up to tabSpaces leading spaces', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: '    abc', selection: TextSelection.collapsed(offset: 4)),
        tabSpaces: 4,
        useSpaces: true,
        outdent: true,
      );
      expect(result.text, 'abc');
    });

    test('outdent removes fewer spaces when fewer than tabSpaces are present', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: '  abc', selection: TextSelection.collapsed(offset: 2)),
        tabSpaces: 4,
        useSpaces: true,
        outdent: true,
      );
      expect(result.text, 'abc');
    });

    test('outdent removes a single leading tab when no leading spaces exist', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: '\tabc', selection: TextSelection.collapsed(offset: 1)),
        tabSpaces: 4,
        useSpaces: true,
        outdent: true,
      );
      expect(result.text, 'abc');
    });

    test('outdent on a line with no leading whitespace is a no-op for that line', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: 'abc', selection: TextSelection.collapsed(offset: 1)),
        tabSpaces: 4,
        useSpaces: true,
        outdent: true,
      );
      expect(result.text, 'abc');
    });

    test('outdent applies to every selected line', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(
          text: '  line1\n  line2\nline3',
          selection: TextSelection(baseOffset: 2, extentOffset: 15),
        ),
        tabSpaces: 2,
        useSpaces: true,
        outdent: true,
      );
      expect(result.text, 'line1\nline2\nline3');
    });

    test('collapsed-selection outdent still outdents the whole current line', () {
      final result = LayrzCodeEditor.applyTabIndent(
        const TextEditingValue(text: '    abc\ndef', selection: TextSelection.collapsed(offset: 6)),
        tabSpaces: 4,
        useSpaces: true,
        outdent: true,
      );
      expect(result.text, 'abc\ndef');
    });
  });

  group('LayrzCodeGutter.errorsByLine', () {
    test('maps each error to its 1-based line', () {
      final errors = [
        const LayrzCodeError(line: 2, column: 1, message: 'a'),
        const LayrzCodeError(line: 5, column: 3, message: 'b'),
      ];
      final map = LayrzCodeGutter.errorsByLine(errors);
      expect(map[2]?.message, 'a');
      expect(map[5]?.message, 'b');
      expect(map.containsKey(1), isFalse);
    });

    test('first error wins when two errors target the same line', () {
      final errors = [
        const LayrzCodeError(line: 3, column: 1, message: 'first'),
        const LayrzCodeError(line: 3, column: 2, message: 'second'),
      ];
      final map = LayrzCodeGutter.errorsByLine(errors);
      expect(map[3]?.message, 'first');
    });

    test('empty errors produces an empty map', () {
      expect(LayrzCodeGutter.errorsByLine(const []), isEmpty);
    });
  });

  group('LayrzCodeEditor widget', () {
    testWidgets('typing updates the controller and fires onChanged (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          onChanged: (value) => changed = value,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'x = 1');
      await tester.pump();

      expect(changed, 'x = 1');
    });

    testWidgets('typing updates the controller and fires onChanged (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          onChanged: (value) => changed = value,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'x = 1');
      await tester.pump();

      expect(changed, 'x = 1');
    });

    testWidgets('Tab inserts tabSpaces spaces at the caret', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? changed;
      final controller = TextEditingController(text: 'ab');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
          onChanged: (value) => changed = value,
        ),
      );

      final focusNode = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
      focusNode.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(controller.text, 'a    b');
      expect(changed, 'a    b');
    });

    testWidgets('Shift+Tab outdents the current line', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: '    ab');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
        ),
      );

      final focusNode = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
      focusNode.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(controller.text, 'ab');
    });

    testWidgets('shows the correct number of line numbers when showLineNumbers is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc',
        ),
      );

      expect(find.byType(LayrzCodeGutter), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides the gutter when showLineNumbers is false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb',
          showLineNumbers: false,
        ),
      );

      expect(find.byType(LayrzCodeGutter), findsNothing);
    });

    testWidgets('renders a gutter error marker with a reachable message via tooltip', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc',
          errors: [LayrzCodeError(line: 2, column: 3, message: 'Unexpected token')],
        ),
      );

      final gutter = tester.widget<LayrzCodeGutter>(find.byType(LayrzCodeGutter));
      expect(gutter.errors, hasLength(1));
      expect(gutter.errors.single.message, 'Unexpected token');

      // The marked line's number is painted in the error color instead of the
      // default gutter foreground color.
      final lineTwoText = tester.widget<Text>(find.text('2'));
      final regularText = tester.widget<Text>(find.text('1'));
      expect(lineTwoText.style?.color, isNot(equals(regularText.style?.color)));
    });

    testWidgets('current-line highlight moves when the caret moves', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'a\nb\nc');
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
          focusNode: focusNode,
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      expect(tester.widget<LayrzCodeGutter>(find.byType(LayrzCodeGutter)).currentLine, 1);

      controller.selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();
      expect(tester.widget<LayrzCodeGutter>(find.byType(LayrzCodeGutter)).currentLine, 3);
    });

    testWidgets('readOnly renders LayrzCodeSurface and no EditableText (wide)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          readOnly: true,
        ),
      );

      expect(find.byType(LayrzCodeSurface), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('readOnly renders LayrzCodeSurface and no EditableText (compact)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          readOnly: true,
        ),
      );

      expect(find.byType(LayrzCodeSurface), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('disabled renders LayrzCodeSurface and no EditableText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          disabled: true,
        ),
      );

      expect(find.byType(LayrzCodeSurface), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('editable (not readOnly/disabled) renders EditableText, not LayrzCodeSurface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
      expect(find.byType(LayrzCodeSurface), findsNothing);
    });

    testWidgets('copy button shown by default', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );
      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);
    });

    testWidgets('copy button hidden when showCopyButton is false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Two independent pumps, each into its own fresh tree, rather than a
      // single tree re-pumped with a different `showCopyButton` — this
      // helper's `Overlay` only inserts its `initialEntries` once, in
      // `initState`, so re-pumping the *same* tree would keep showing the
      // first pump's overlay entry (and thus its first `LayrzCodeEditor`)
      // no matter what the second pump's widget says.
      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', showCopyButton: false),
      );
      expect(find.byType(LayrzCodeCopyButton), findsNothing);
    });

    testWidgets('copy button shown in the read-only branch too', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', readOnly: true),
      );
      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);
    });

    testWidgets('renders labelText and helperText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          labelText: 'Formula',
          helperText: 'Enter a valid LCL expression',
        ),
      );

      expect(find.text('Formula'), findsOneWidget);
      expect(find.text('Enter a valid LCL expression'), findsOneWidget);
    });

    testWidgets('onFocusChanged fires on focus and blur', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusEvents = <bool>[];
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          focusNode: focusNode,
          onFocusChanged: focusEvents.add,
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      focusNode.unfocus();
      await tester.pump();

      expect(focusEvents, [true, false]);
    });

    testWidgets('maxHeight constrains the editable content in a ConstrainedBox', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc\nd\ne\nf\ng\nh',
          maxHeight: 80,
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(ConstrainedBox)),
      );
      expect(constrainedBox.constraints.maxHeight, 80);

      final renderBox = tester.renderObject<RenderBox>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(ConstrainedBox)),
      );
      expect(renderBox.size.height, lessThanOrEqualTo(80));
    });

    testWidgets('null maxHeight leaves the editable content unconstrained (no ConstrainedBox)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
        ),
      );

      expect(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(ConstrainedBox)),
        findsNothing,
      );
    });

    testWidgets('onTap fires when the editable area is tapped', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapped = false;
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
