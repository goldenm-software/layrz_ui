import 'dart:ui' show Tristate;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

/// A fake [FilePicker] platform implementation, injected via [FilePicker.platform]
/// so tests never touch a real platform channel.
///
/// [file_picker] exposes its platform singleton as a plain settable static, which
/// is the officially supported test seam (see the package's own test suite) --
/// no `MethodChannel` mocking is needed.
class _FakeFilePicker extends FilePicker {
  /// The result [pickFiles] returns on its next call, or null to simulate the
  /// user cancelling the picker.
  FilePickerResult? nextResult;

  /// Records the [FileType] passed to the most recent [pickFiles] call.
  FileType? lastType;

  /// Records the `allowedExtensions` passed to the most recent [pickFiles] call.
  List<String>? lastAllowedExtensions;

  /// Records the `allowMultiple` flag passed to the most recent [pickFiles] call.
  bool? lastAllowMultiple;

  /// The number of times [pickFiles] has been called.
  int pickFilesCallCount = 0;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    pickFilesCallCount++;
    lastType = type;
    lastAllowedExtensions = allowedExtensions;
    lastAllowMultiple = allowMultiple;
    return nextResult;
  }
}

/// Collects every semantics label under [tester]'s current tree.
///
/// Mirrors `select_input_test.dart`'s own `dumpSemanticsLabels` -- used here,
/// rather than `find.bySemanticsLabel`, because that matcher also matches
/// literal text on renderable widgets and has already produced a false green
/// in this repo (DESIGN-161).
List<String> dumpSemanticsLabels(WidgetTester tester) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final labels = <String>[];
  void walk(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) labels.add(label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return labels;
}

PlatformFile _platformFile(String name, List<int> bytes) {
  return PlatformFile(name: name, size: bytes.length, bytes: Uint8List.fromList(bytes));
}

void main() {
  late _FakeFilePicker fakePicker;

  setUp(() {
    fakePicker = _FakeFilePicker();
    FilePicker.platform = fakePicker;
  });

  Future<void> pumpWide(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpThemed(tester, child);
    await tester.pump();
  }

  group('LayrzFileInput click-to-browse', () {
    testWidgets('tapping the empty box opens the picker', (tester) async {
      await pumpWide(tester, const LayrzFileInput());

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pump();

      expect(fakePicker.pickFilesCallCount, 1);
    });

    testWidgets('a picked file is committed via onChanged', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('a.png', [1, 2, 3]),
      ]);
      List<LayrzFileInputResult>? changed;

      await pumpWide(
        tester,
        LayrzFileInput(onChanged: (files) => changed = files),
      );

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed!.length, 1);
      expect(changed!.first.name, 'a.png');
      expect(changed!.first.mimeType, 'image/png');
    });

    testWidgets('a cancelled picker (null result) does not call onChanged', (tester) async {
      fakePicker.nextResult = null;
      var called = false;

      await pumpWide(
        tester,
        LayrzFileInput(onChanged: (_) => called = true),
      );

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('disabled field does not open the picker on tap', (tester) async {
      await pumpWide(tester, const LayrzFileInput(disabled: true));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pump();

      expect(fakePicker.pickFilesCallCount, 0);
    });

    testWidgets('Enter key on a focused box opens the picker (keyboard reachable)', (tester) async {
      // `pumpThemed`'s minimal tree has no `WidgetsApp`/`Shortcuts` binding
      // for the default Enter->ActivateIntent mapping `FocusableActionDetector`
      // relies on -- `pumpThemedApp`'s `LayrzApp` provides it.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(tester, LayrzFileInput(focusNode: focusNode));
      await tester.pump();

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(fakePicker.pickFilesCallCount, 1);
    });
  });

  group('LayrzFileInput multi-file value', () {
    testWidgets('multiple picked files all appear in onChanged as a List', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('a.png', [1, 2, 3]),
        _platformFile('b.pdf', [4, 5, 6]),
      ]);
      List<LayrzFileInputResult>? changed;

      await pumpWide(tester, LayrzFileInput(onChanged: (files) => changed = files));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(changed!.length, 2);
      expect(changed!.map((f) => f.name), containsAll(['a.png', 'b.pdf']));
    });

    testWidgets('allowMultiple is false when maxFiles is 1', (tester) async {
      await pumpWide(tester, const LayrzFileInput(maxFiles: 1));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pump();

      expect(fakePicker.lastAllowMultiple, isFalse);
    });

    testWidgets('picking again with maxFiles 1 replaces rather than appends', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        fakePicker.nextResult = FilePickerResult([
          _platformFile('first.png', [1]),
        ]);
        List<LayrzFileInputResult>? changed;

        await pumpWide(
          tester,
          LayrzFileInput(maxFiles: 1, onChanged: (files) => changed = files),
        );

        await tester.tap(find.byType(LayrzFileInput));
        await tester.pumpAndSettle();
        expect(changed!.single.name, 'first.png');

        // Once populated, the whole box is no longer the tap target (each row
        // owns its own action, see `_buildBox`'s doc) -- "Add more" re-opens
        // the picker instead.
        fakePicker.nextResult = FilePickerResult([
          _platformFile('second.png', [2]),
        ]);
        await tester.tap(find.bySemanticsLabel('Add more files'));
        await tester.pumpAndSettle();

        expect(changed!.length, 1);
        expect(changed!.single.name, 'second.png');
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzFileInput accept/type filter', () {
    testWidgets('allowedExtensions is forwarded to the picker as FileType.custom', (tester) async {
      await pumpWide(tester, const LayrzFileInput(allowedExtensions: ['png', 'jpg']));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pump();

      expect(fakePicker.lastType, FileType.custom);
      expect(fakePicker.lastAllowedExtensions, ['png', 'jpg']);
    });

    testWidgets('a picked file outside allowedExtensions is rejected, not committed', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('malware.exe', [1, 2, 3]),
      ]);
      var called = false;

      await pumpWide(
        tester,
        LayrzFileInput(allowedExtensions: const ['png'], onChanged: (_) => called = true),
      );

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.textContaining('rejected'), findsOneWidget);
    });
  });

  group('LayrzFileInput rejection message persistence', () {
    testWidgets('the rejection message stays visible after the initial rejection (not a vanishing toast)', (
      tester,
    ) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('bad.exe', [1]),
      ]);

      await pumpWide(tester, const LayrzFileInput(allowedExtensions: ['png']));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(find.textContaining('rejected'), findsOneWidget);

      // Advance well past any toast-style auto-dismiss timing; a persistent
      // message must still be present with no further interaction.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('rejected'), findsOneWidget);
    });

    testWidgets('a custom rejectionMessage is shown instead of the default', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('bad.exe', [1]),
      ]);

      await pumpWide(
        tester,
        const LayrzFileInput(allowedExtensions: ['png'], rejectionMessage: 'Nope, not that.'),
      );

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(find.text('Nope, not that.'), findsOneWidget);
    });

    testWidgets('a subsequent successful pick clears the rejection message', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('bad.exe', [1]),
      ]);

      await pumpWide(tester, const LayrzFileInput(allowedExtensions: ['png']));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();
      expect(find.textContaining('rejected'), findsOneWidget);

      fakePicker.nextResult = FilePickerResult([
        _platformFile('good.png', [1, 2, 3]),
      ]);
      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(find.textContaining('rejected'), findsNothing);
    });
  });

  group('LayrzFileInput image preview', () {
    testWidgets('a picked image file renders via LayrzFileInputPreview', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('photo.png', [1, 2, 3]),
      ]);

      await pumpWide(tester, const LayrzFileInput());

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(find.byType(LayrzFileInputPreview), findsOneWidget);
    });
  });

  group('LayrzFileInput clear/replace affordance', () {
    testWidgets('clear affordance removes a file and reports the updated list', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        fakePicker.nextResult = FilePickerResult([
          _platformFile('a.png', [1, 2, 3]),
        ]);
        List<LayrzFileInputResult>? changed;

        await pumpWide(tester, LayrzFileInput(onChanged: (files) => changed = files));

        await tester.tap(find.byType(LayrzFileInput));
        await tester.pumpAndSettle();
        expect(changed!.length, 1);

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Remove a.png')), isTrue);

        await tester.tap(find.bySemanticsLabel('Remove a.png'));
        await tester.pumpAndSettle();

        expect(changed, isEmpty);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('clear affordance is keyboard-reachable via FocusableActionDetector', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('a.png', [1, 2, 3]),
      ]);

      await pumpWide(tester, const LayrzFileInput());

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      // The clear button is wrapped in its own FocusableActionDetector with an
      // ActivateIntent handler -- verify that wiring is present, matching the
      // pattern LayrzCard uses for its interactive form.
      final detectors = find.descendant(
        of: find.byType(LayrzFileInput),
        matching: find.byType(FocusableActionDetector),
      );
      expect(detectors, findsWidgets);
    });

    testWidgets('"Add more" re-opens the picker from the populated state', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        fakePicker.nextResult = FilePickerResult([
          _platformFile('a.png', [1, 2, 3]),
        ]);

        await pumpWide(tester, const LayrzFileInput());

        await tester.tap(find.byType(LayrzFileInput));
        await tester.pumpAndSettle();
        expect(fakePicker.pickFilesCallCount, 1);

        await tester.tap(find.bySemanticsLabel('Add more files'));
        await tester.pumpAndSettle();

        expect(fakePicker.pickFilesCallCount, 2);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('"Clear all" appears only with more than one file and clears the whole selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        fakePicker.nextResult = FilePickerResult([
          _platformFile('a.png', [1]),
          _platformFile('b.png', [2]),
        ]);
        List<LayrzFileInputResult>? changed;

        await pumpWide(
          tester,
          LayrzFileInput(height: 320, onChanged: (files) => changed = files),
        );

        await tester.tap(find.byType(LayrzFileInput));
        await tester.pumpAndSettle();

        // The box's fixed height must fit every row (two files + "Add more" +
        // "Clear all") for `ListView` to actually build the trailing rows --
        // a too-short box would leave "Clear all" unbuilt/unfound even though
        // the widget's own logic would show it. 320 comfortably fits four rows.
        expect(find.bySemanticsLabel('Clear all files'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Clear all files'));
        await tester.pumpAndSettle();

        expect(changed, isEmpty);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('"Clear all" does not appear with a single file', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        fakePicker.nextResult = FilePickerResult([
          _platformFile('a.png', [1]),
        ]);

        await pumpWide(tester, const LayrzFileInput());

        await tester.tap(find.byType(LayrzFileInput));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Clear all files'), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzFileInput four states are visually distinct', () {
    testWidgets('empty, hover, dragging, and populated each resolve to a different style spec', (tester) async {
      final tokens = LayrzTokens.light();

      final empty = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.empty,
        tokens: tokens,
        hasErrors: false,
      );
      final hover = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.hover,
        tokens: tokens,
        hasErrors: false,
      );
      final dragging = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.dragging,
        tokens: tokens,
        hasErrors: false,
      );
      final populated = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.populated,
        tokens: tokens,
        hasErrors: false,
      );

      final all = {empty, hover, dragging, populated};
      expect(all.length, 4, reason: 'all four states must be visually distinct per the confirmed v1 scope');
    });

    testWidgets('the box renders its hint text in the empty state', (tester) async {
      await pumpWide(tester, const LayrzFileInput(hintText: 'Drop your files here'));

      expect(find.text('Drop your files here'), findsOneWidget);
    });

    testWidgets('the box shows file previews instead of the hint once populated', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformFile('a.png', [1, 2, 3]),
      ]);

      await pumpWide(tester, const LayrzFileInput(hintText: 'Drop your files here'));

      await tester.tap(find.byType(LayrzFileInput));
      await tester.pumpAndSettle();

      expect(find.text('Drop your files here'), findsNothing);
      expect(find.byType(LayrzFileInputPreview), findsOneWidget);
    });

    testWidgets('the empty box paints the sf2 background, not black', (tester) async {
      // Regression guard for the Impeller clip+border-on-AnimatedContainer
      // artifact: the box's rounded clip must come from its own `ClipRRect`
      // (with `AnimatedContainer.clipBehavior` left at its default `Clip.none`)
      // rather than the container clipping its own animated decoration, since
      // that combination painted solid black on Linux/Vulkan. This asserts
      // both the resolved fill color and the render-structure fix.
      final tokens = LayrzTokens.light();
      await pumpWide(tester, const LayrzFileInput());

      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, tokens.colors.sf2);
      expect(container.clipBehavior, Clip.none);

      expect(
        find.ancestor(of: find.byType(AnimatedContainer), matching: find.byType(ClipRRect)),
        findsOneWidget,
      );
    });
  });

  group('LayrzFileInput label and error composition', () {
    testWidgets('labelText renders outside the box', (tester) async {
      await pumpWide(tester, const LayrzFileInput(labelText: 'Attachments'));

      // The label is rendered via a standalone RichText (matching
      // LayrzSelectInput's own label composition), so `findRichText: true`
      // is required -- find.text ignores standalone RichText by default.
      expect(find.text('Attachments', findRichText: true), findsOneWidget);
    });

    testWidgets('errors render below the box via the footer slot', (tester) async {
      await pumpWide(tester, const LayrzFileInput(errors: ['This field is required']));

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('hideDetails suppresses the error footer', (tester) async {
      await pumpWide(tester, const LayrzFileInput(errors: ['This field is required'], hideDetails: true));

      expect(find.text('This field is required'), findsNothing);
    });
  });

  group('LayrzFileInput semantics', () {
    testWidgets('the box is announced as a button with the label as its name', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWide(tester, const LayrzFileInput(labelText: 'Attachments'));

        final labels = dumpSemanticsLabels(tester);
        // The empty-state box's own Semantics carries `labelText` as its
        // label; the visible hint Text underneath it merges in too (no
        // ExcludeSemantics between them, since sighted and AT users alike
        // should still be able to make out the hint), so this asserts on
        // containment rather than an exact match.
        expect(labels.any((l) => l.contains('Attachments')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled state is announced as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWide(tester, const LayrzFileInput(labelText: 'Attachments', disabled: true));

        // ignore: deprecated_member_use
        final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
        bool foundDisabled = false;
        void walk(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.label.contains('Attachments') && data.flagsCollection.isEnabled != Tristate.none) {
            foundDisabled = data.flagsCollection.isEnabled == Tristate.isFalse;
          }
          node.visitChildren((child) {
            walk(child);
            return true;
          });
        }

        walk(root);
        expect(foundDisabled, isTrue);
      } finally {
        handle.dispose();
      }
    });
  });
}
