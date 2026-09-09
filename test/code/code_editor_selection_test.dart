import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_editor.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/selection/selection.dart';

import '../helpers/pump_themed.dart';

/// Finds the [RenderEditable] beneath the pumped [EditableText], mirroring the
/// tree-walk `test/inputs/text/text_input_selection_test.dart` uses to locate
/// a caret-accurate tap/selection position (the [EditableText] render object
/// itself is not a [RenderEditable] — it wraps one further down).
RenderEditable _findRenderEditable(WidgetTester tester) {
  late RenderEditable renderEditable;
  var found = false;

  void visit(RenderObject? render) {
    if (found || render == null) return;
    if (render is RenderEditable) {
      renderEditable = render;
      found = true;
      return;
    }
    if (render is RenderObjectWithChildMixin<RenderObject>) {
      visit(render.child);
      if (found) return;
    }
    try {
      render.visitChildren((child) {
        if (!found) visit(child);
      });
    } catch (_) {
      // Some render objects don't support visitChildren; ignore.
    }
  }

  visit(tester.renderObject(find.byType(EditableText)));
  return renderEditable;
}

/// Double-taps the middle of `word` (assumed to start at [wordOffset] within
/// [renderEditable]'s text) to select it and raise the selection toolbar,
/// then settles the resulting animations.
Future<void> _doubleTapToSelect(WidgetTester tester, RenderEditable renderEditable, int wordOffset) async {
  final rect = renderEditable.getLocalRectForCaret(TextPosition(offset: wordOffset));
  final point = renderEditable.localToGlobal(rect.center);

  await tester.tapAt(point);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tapAt(point);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // The toolbar's copy/cut/paste actions round-trip through the platform
    // clipboard channel; mock it so pressing those buttons doesn't hang the
    // test waiting on a real platform response (same setup as
    // text_input_selection_test.dart).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': ''};
        }
        if (call.method == 'Clipboard.hasStrings') {
          return <String, dynamic>{'value': false};
        }
        return null;
      },
    );
  });

  group('buildCodeEditorContextMenu via LayrzCodeEditor', () {
    testWidgets('selecting text in an editable editor shows copy, cut, paste and select all', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'hello world');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
        ),
      );

      final renderEditable = _findRenderEditable(tester);
      await _doubleTapToSelect(tester, renderEditable, 2);

      expect(controller.selection.isCollapsed, isFalse, reason: 'double-tap should select the word under it');
      expect(find.byType(LayrzSelectionToolbar), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('readOnly LayrzCodeEditor never reaches EditableText, so no toolbar exists', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // `buildCodeEditorContextMenu`'s readOnly-filtering branch is a
      // defensive no-op: `LayrzCodeEditor` never builds an `EditableText` at
      // all when `readOnly` is true (see the class-level "Read-only
      // rendering" note in code_editor.dart) — it renders `LayrzCodeSurface`
      // instead, which has no selection toolbar of its own. This test pins
      // that contract down so a future change that started wiring an
      // EditableText into the read-only branch would be caught here.
      await pumpThemed(
        tester,
        const LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          value: 'hello world',
          readOnly: true,
        ),
      );

      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(LayrzSelectionToolbar), findsNothing);
    });

    testWidgets('tapping Select All in the toolbar selects the whole text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'hello world');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
        ),
      );

      final renderEditable = _findRenderEditable(tester);
      await _doubleTapToSelect(tester, renderEditable, 2);

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset, controller.text.length);
    });

    testWidgets('tapping Copy in the toolbar keeps the text unchanged and dismisses the toolbar', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'hello world');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
        ),
      );

      final renderEditable = _findRenderEditable(tester);
      await _doubleTapToSelect(tester, renderEditable, 2);
      expect(find.byType(LayrzSelectionToolbar), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(controller.text, 'hello world');
      expect(find.byType(LayrzSelectionToolbar), findsNothing);
    });

    testWidgets('tapping Cut in the toolbar removes the selected text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController(text: 'hello world');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
        ),
      );

      final renderEditable = _findRenderEditable(tester);
      await _doubleTapToSelect(tester, renderEditable, 2);

      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();

      expect(controller.text, ' world');
    });

    testWidgets('tapping Paste in the toolbar replaces the selected text with clipboard contents', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': 'X'};
          }
          if (call.method == 'Clipboard.hasStrings') {
            return <String, dynamic>{'value': true};
          }
          return null;
        },
      );

      final controller = TextEditingController(text: 'hello world');
      await pumpThemed(
        tester,
        LayrzCodeEditor(
          language: LayrzCodeLanguage.python,
          controller: controller,
        ),
      );

      final renderEditable = _findRenderEditable(tester);
      await _doubleTapToSelect(tester, renderEditable, 2);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(controller.text, 'X world');
    });
  });
}
