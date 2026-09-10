import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_editor.dart';
import 'package:layrz_ui/src/code/src/code_error.dart';
import 'package:layrz_ui/src/code/src/code_gutter.dart';
import 'package:layrz_ui/src/code/src/code_surface.dart';
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/theme/theme.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import '../helpers/pump_themed.dart';

/// Finds the [LayrzButton] whose [LayrzButton.labelText] equals [label].
///
/// The editor's run/lint/copy actions render as Fab-styled [LayrzButton]s,
/// which show no visible text (the label is Fab-only tooltip/semantics
/// content) — so `findButtonLabel`/`find.text` cannot locate them. Matching
/// on the widget's own `labelText` field is the reliable way to find a
/// specific action button and drive a tap on it.
Finder _findActionButton(String label) =>
    find.byWidgetPredicate((widget) => widget is LayrzButton && widget.labelText == label);

/// Concatenates the plain text of every leaf [TextSpan] under [span], in
/// visiting order, so a gutter's single [RichText] can be compared against
/// the expected `"1\n2\n3"`-style line-number text.
String _plainTextOf(InlineSpan span) {
  final buffer = StringBuffer();
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null) {
      buffer.write(child.text);
    }
    return true;
  });
  return buffer.toString();
}

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
      final gutter = tester.widget<LayrzCodeGutter>(find.byType(LayrzCodeGutter));
      expect(gutter.lineCount, 3);

      final gutterRichText = tester.widget<RichText>(
        find.descendant(of: find.byType(LayrzCodeGutter), matching: find.byType(RichText)).first,
      );
      expect(_plainTextOf(gutterRichText.text), '1\n2\n3');
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
      // default gutter foreground color — both numbers live as leaf TextSpans
      // inside the gutter's single RichText.
      final gutterRichText = tester.widget<RichText>(
        find.descendant(of: find.byType(LayrzCodeGutter), matching: find.byType(RichText)).first,
      );
      final leaves = <TextSpan>[];
      gutterRichText.text.visitChildren((child) {
        if (child is TextSpan && child.text != null) {
          leaves.add(child);
        }
        return true;
      });
      final lineTwoSpan = leaves.firstWhere((span) => span.text == '2\n');
      final lineOneSpan = leaves.firstWhere((span) => span.text == '1\n');
      expect(lineTwoSpan.style?.color, isNot(equals(lineOneSpan.style?.color)));

      // A tooltip region within the gutter exposes the error message over the
      // marked line (the copy button also renders its own `LayrzTooltip`
      // elsewhere in the tree, so this is scoped to the gutter specifically).
      final tooltip = tester.widget<LayrzTooltip>(
        find.descendant(of: find.byType(LayrzCodeGutter), matching: find.byType(LayrzTooltip)),
      );
      expect(tooltip.contentText, contains('Unexpected token'));
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

    testWidgets('height fixes the editable content to a SizedBox of that height', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc\nd\ne\nf\ng\nh',
          height: 80,
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(SizedBox)),
      );
      final heightBox = sizedBoxes.firstWhere((box) => box.height != null);
      expect(heightBox.height, 80);

      final heightBoxElement = find
          .ancestor(of: find.byType(EditableText), matching: find.byType(SizedBox))
          .evaluate()
          .firstWhere((element) => (element.widget as SizedBox).height != null);
      final renderBox = heightBoxElement.renderObject! as RenderBox;
      expect(renderBox.size.height, 80);
    });

    testWidgets('height defaults to 220 when not supplied', (tester) async {
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

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(SizedBox)),
      );
      final heightBox = sizedBoxes.firstWhere((box) => box.height != null);
      expect(heightBox.height, 220);
    });

    testWidgets('editable branch wraps its content in the same rounded chrome as LayrzCodeSurface', (tester) async {
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

      // Editable branch: EditableText must sit inside a `ClipRRect` whose
      // radius matches `LayrzCodeSurface`'s `tokens.radius.br2`, and that
      // `ClipRRect` must in turn be preceded by a `DecoratedBox` carrying
      // the same radius — the same outer chrome `LayrzCodeSurface` builds.
      final editableClip = tester.widget<ClipRRect>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(ClipRRect)).first,
      );
      final editableDecoration = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(ClipRRect), matching: find.byType(DecoratedBox)).first,
      );
      final tokens = LayrzThemeData.light().tokens;
      expect(editableClip.borderRadius, tokens.radius.br2);
      expect((editableDecoration.decoration as BoxDecoration).borderRadius, tokens.radius.br2);
    });

    testWidgets('editable branch pins the EditableText line height so gutter numbers stay aligned', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const fontSize = 14.0;
      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc\nd\ne',
          fontSize: fontSize,
        ),
      );

      // The EditableText must carry a StrutStyle that forces every line box to
      // exactly `kCodeLineHeightFactor * fontSize`. Without this the text lays
      // out on the font's intrinsic metrics while the gutter is positioned on
      // the fixed factor, and the line numbers drift progressively down the
      // file. `forceStrutHeight` guarantees the box height regardless of glyphs.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.height, kCodeLineHeightFactor);
      expect(editable.strutStyle.height, kCodeLineHeightFactor);
      expect(editable.strutStyle.fontSize, fontSize);
      expect(editable.strutStyle.forceStrutHeight, isTrue);

      // The gutter's per-row height is the *measured* line box the strut
      // produces (via a TextPainter), not the naive `factor * fontSize` — the
      // editor measures rather than computes so it matches EditableText's
      // real layout regardless of font metric rounding. It must still be
      // strictly positive and, at this fontSize/factor, comes out to 20.0
      // rather than the naive 19.6.
      final gutter = tester.widget<LayrzCodeGutter>(find.byType(LayrzCodeGutter));
      expect(gutter.lineHeight, greaterThan(0));
      expect(gutter.lineHeight, 20.0);
    });

    testWidgets('readOnly branch (LayrzCodeSurface) uses the same border radius as the editable branch', (
      tester,
    ) async {
      // Two independent pumps, each into its own fresh tree, rather than a
      // single tree re-pumped with a different `readOnly` — this helper's
      // `Overlay` only inserts its `initialEntries` once, in `initState`, so
      // re-pumping the *same* tree would keep showing the first pump's
      // overlay entry (and thus its first `LayrzCodeEditor`) no matter what
      // the second pump's widget says (see the `showCopyButton` test above
      // for the same caveat).
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

      final surfaceClip = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(LayrzCodeSurface), matching: find.byType(ClipRRect)).first,
      );
      final tokens = LayrzThemeData.light().tokens;
      expect(surfaceClip.borderRadius, tokens.radius.br2);
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

    testWidgets('reserves right-side space for the copy button in the editable branch', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', showCopyButton: true),
      );

      final tokens = LayrzThemeData.light().tokens;
      final defaultRight = tokens.spacing.pd3.right;

      final contentPadding = tester.widget<Padding>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(Padding)).first,
      );
      final resolvedRight = contentPadding.padding.resolve(TextDirection.ltr).right;
      expect(resolvedRight, defaultRight + kLayrzButtonCompactHeight + tokens.spacing.sp1);
      expect(resolvedRight, greaterThan(defaultRight));
    });

    testWidgets('does not reserve right-side space in the editable branch when the copy button is hidden', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', showCopyButton: false),
      );

      final tokens = LayrzThemeData.light().tokens;
      final defaultRight = tokens.spacing.pd3.right;

      final contentPadding = tester.widget<Padding>(
        find.ancestor(of: find.byType(EditableText), matching: find.byType(Padding)).first,
      );
      expect(contentPadding.padding.resolve(TextDirection.ltr).right, defaultRight);
    });

    testWidgets('onRun/onLint are absent by default (no run or lint button rendered)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1'),
      );

      expect(_findActionButton('Run'), findsNothing);
      expect(_findActionButton('Lint'), findsNothing);
    });

    testWidgets('onRun renders a Run button that fires the callback on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var ran = false;
      await pumpThemed(
        tester,
        LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', onRun: () => ran = true),
      );

      expect(_findActionButton('Run'), findsOneWidget);
      expect(_findActionButton('Lint'), findsNothing);

      await tester.tap(_findActionButton('Run'));
      await tester.pump();
      expect(ran, isTrue);
    });

    testWidgets('onLint renders a Lint button that fires the callback on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var linted = false;
      await pumpThemed(
        tester,
        LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', onLint: () => linted = true),
      );

      expect(_findActionButton('Lint'), findsOneWidget);
      expect(_findActionButton('Run'), findsNothing);

      await tester.tap(_findActionButton('Lint'));
      await tester.pump();
      expect(linted, isTrue);
    });

    testWidgets('onRun and onLint render together alongside the copy button, both tappable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var ran = false;
      var linted = false;
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          onRun: () => ran = true,
          onLint: () => linted = true,
        ),
      );

      expect(_findActionButton('Run'), findsOneWidget);
      expect(_findActionButton('Lint'), findsOneWidget);
      expect(find.byType(LayrzCodeCopyButton), findsOneWidget);

      await tester.tap(_findActionButton('Lint'));
      await tester.pump();
      await tester.tap(_findActionButton('Run'));
      await tester.pump();
      expect(ran, isTrue);
      expect(linted, isTrue);
    });

    testWidgets('the action-row reserve with copy button only matches a single button width', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(language: LayrzCodeLanguage.python, value: 'x = 1', showCopyButton: true),
      );
      final tokens = LayrzThemeData.light().tokens;
      final defaultRight = tokens.spacing.pd3.right;
      final copyOnlyPadding = tester
          .widget<Padding>(find.ancestor(of: find.byType(EditableText), matching: find.byType(Padding)).first)
          .padding
          .resolve(TextDirection.ltr)
          .right;
      expect(copyOnlyPadding, defaultRight + kLayrzButtonCompactHeight + tokens.spacing.sp1);
    });

    testWidgets('the action-row reserve with lint+run+copy scales to three button widths', (tester) async {
      // A fresh pump into its own tree (see the `showCopyButton` test above
      // for why this helper's Overlay requires a fresh tree per widget
      // configuration rather than re-pumping the same tree).
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'x = 1',
          onRun: () {},
          onLint: () {},
        ),
      );
      final tokens = LayrzThemeData.light().tokens;
      final defaultRight = tokens.spacing.pd3.right;
      final threeButtonsPadding = tester
          .widget<Padding>(find.ancestor(of: find.byType(EditableText), matching: find.byType(Padding)).first)
          .padding
          .resolve(TextDirection.ltr)
          .right;
      expect(threeButtonsPadding, defaultRight + 3 * kLayrzButtonCompactHeight + tokens.spacing.sp1);
    });

    testWidgets('error line gets a full-row tonal red background (gutter + code area)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const codeTheme = LayrzCodeThemeExtension.dark();
      final expectedBackground = codeTheme.errorColor.withValues(alpha: 0.12);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc',
          errors: [LayrzCodeError(line: 2, column: 1, message: 'boom')],
        ),
      );

      // Both the gutter half and the code-area half of the error band are
      // painted as `Positioned ColoredBox` widgets in this rewrite — the
      // gutter no longer wraps each row number in its own `Container`, so
      // this asserts on the count/color of `ColoredBox`es directly instead.
      final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      final errorBands = coloredBoxes.where((box) => box.color == expectedBackground);
      // One band in the gutter (left half) + one in the code area (right
      // half) for the single error line.
      expect(
        errorBands.length,
        2,
        reason: 'expected exactly one error-tinted ColoredBox in the gutter and one in the code area',
      );
    });

    testWidgets('non-error line has no tonal red background in the code area', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const codeTheme = LayrzCodeThemeExtension.dark();
      final errorBackground = codeTheme.errorColor.withValues(alpha: 0.12);

      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'a\nb\nc',
        ),
      );

      final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      expect(coloredBoxes.any((box) => box.color == errorBackground), isFalse);
    });

    testWidgets('error red wins over the current-line highlight when the caret sits on an error line', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const codeTheme = LayrzCodeThemeExtension.dark();
      final errorBackground = codeTheme.errorColor.withValues(alpha: 0.12);

      final controller = TextEditingController(text: 'a\nb\nc');
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
          focusNode: focusNode,
          errors: const [LayrzCodeError(line: 2, column: 1, message: 'boom')],
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      // Offset 2 sits on line 2 ("b"), which is also the error line.
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      expect(tester.widget<LayrzCodeGutter>(find.byType(LayrzCodeGutter)).currentLine, 2);

      // Precedence: an error-marked line paints the tonal-red error band, not
      // the current-line highlight, even though the caret sits on it — so no
      // `ColoredBox` at `currentLineBackground` exists at all, only the error
      // color (gutter half + code-area half).
      final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      final errorBands = coloredBoxes.where((box) => box.color == errorBackground);
      expect(errorBands.length, 2);
      expect(
        coloredBoxes.any((box) => box.color == codeTheme.currentLineBackground),
        isFalse,
        reason: 'the current-line highlight must not paint when the same line is an error line',
      );
    });
  });
}
