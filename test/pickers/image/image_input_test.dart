import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/image/image_input_preview.dart';

import '../../helpers/pump_themed.dart';

/// A fake [FilePicker] platform implementation, injected via [FilePicker.platform]
/// so tests never touch a real platform channel. Mirrors
/// `test/file_input/file_input_test.dart`'s own `_FakeFilePicker`.
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

/// A minimal, genuinely decodable 1x1 red PNG (verified against a real PNG
/// decoder, not hand-derived) -- used wherever a test needs a *real*,
/// decodable image byte payload rather than an arbitrary byte list (which
/// `LayrzImage`/`Image.memory` would reject, landing on the fallback instead
/// of the happy path).
final Uint8List _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk header
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, // bit depth/color type + CRC
  0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, // IDAT chunk header
  0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00, 0x03, 0x01, 0x01, 0x00, // zlib-compressed pixel data
  0xC9, 0xFE, 0x92, 0xEF, // IDAT CRC
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, // IEND
]);

PlatformFile _platformImageFile(String name, List<int> bytes) {
  return PlatformFile(name: name, size: bytes.length, bytes: Uint8List.fromList(bytes));
}

/// Collects every semantics label under [tester]'s current tree, mirroring
/// `test/file_input/file_input_test.dart`'s own helper -- used rather than
/// `find.bySemanticsLabel`, which has already produced a false green in this
/// repo (DESIGN-161).
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

void main() {
  late _FakeFilePicker fakePicker;

  setUp(() {
    fakePicker = _FakeFilePicker();
    FilePicker.platform = fakePicker;
  });

  /// Pumps [child] at a wide (desktop, non-compact) viewport -- trap 1 (project
  /// CLAUDE.md rule #2): the default 800x600 test surface silently exercises
  /// only the compact branch, so every test that cares about the widget's
  /// normal desktop rendering sets an explicit size and resets it afterward.
  Future<void> pumpWide(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpThemed(tester, child);
    await tester.pump();
  }

  /// Pumps [child] at a narrow (compact, mobile-shaped) viewport, for tests
  /// asserting the widget still renders correctly below the 960px
  /// `isCompact` threshold.
  Future<void> pumpCompact(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpThemed(tester, child);
    await tester.pump();
  }

  group('LayrzImageInput value in — URL pass-through is never re-encoded (Decision, dossier §8b OQ-9)', () {
    testWidgets('a URL passed as value is NOT re-encoded or emitted on mount', (tester) async {
      var callCount = 0;

      await pumpWide(
        tester,
        LayrzImageInput(
          value: 'https://example.com/photo.png',
          onChanged: (_) => callCount++,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(callCount, 0, reason: 'onChanged must never fire on mount for an untouched incoming value');
    });

    testWidgets('a URL passed as value renders via LayrzImageInputPreview unmodified', (tester) async {
      await pumpWide(tester, const LayrzImageInput(value: 'https://example.com/photo.png'));

      final preview = tester.widget<LayrzImageInputPreview>(find.byType(LayrzImageInputPreview));
      expect(preview.source, 'https://example.com/photo.png');
    });

    testWidgets('updating value externally (still untouched by the user) still does not call onChanged', (
      tester,
    ) async {
      var callCount = 0;

      await tester.pumpWidget(
        _HostWithUpdatableValue(onChanged: () => callCount++, initialValue: 'https://example.com/a.png'),
      );
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pump();

      final state = tester.state<_HostWithUpdatableValueState>(find.byType(_HostWithUpdatableValue));
      state.setValue('https://example.com/b.png');
      await tester.pump();

      expect(callCount, 0);
    });
  });

  group('LayrzImageInput picking a file emits base64 via onChanged (user action only)', () {
    testWidgets('picking a file DOES emit base64 through onChanged', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('photo.png', _validPngBytes),
      ]);
      String? emitted;

      await pumpWide(tester, LayrzImageInput(onChanged: (value) => emitted = value));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      expect(emitted, startsWith('data:image/png;base64,'));
    });

    testWidgets('a cancelled picker (null result) does not call onChanged', (tester) async {
      fakePicker.nextResult = null;
      var called = false;

      await pumpWide(tester, LayrzImageInput(onChanged: (_) => called = true));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('picking again replaces rather than appends (single-image, maxFiles:1 semantics)', (
      tester,
    ) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('first.png', _validPngBytes),
      ]);
      final emitted = <String?>[];

      await pumpWide(tester, LayrzImageInput(onChanged: (value) => emitted.add(value)));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();
      expect(emitted.length, 1);

      // A distinct byte payload (need not be a decodable image -- this test
      // exercises the onChanged plumbing, not the preview) so the two emitted
      // `dataUri`s are provably different rather than accidentally identical.
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('second.png', [9, 9, 9, 9]),
      ]);
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(emitted.length, 2);
      expect(emitted.last, isNot(equals(emitted.first)));
    });

    testWidgets('allowMultiple is always false (single image field)', (tester) async {
      await pumpWide(tester, const LayrzImageInput());

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pump();

      expect(fakePicker.lastAllowMultiple, isFalse);
    });

    testWidgets('the default allowed extensions restrict the system picker to image types', (tester) async {
      await pumpWide(tester, const LayrzImageInput());

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pump();

      expect(fakePicker.lastType, FileType.custom);
      expect(fakePicker.lastAllowedExtensions, kDefaultImageInputExtensions);
    });

    testWidgets('a caller-supplied allowedExtensions overrides the default', (tester) async {
      await pumpWide(tester, const LayrzImageInput(allowedExtensions: ['png']));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pump();

      expect(fakePicker.lastAllowedExtensions, ['png']);
    });
  });

  group('LayrzImageInput oversized rejection fires before encode', () {
    testWidgets('an oversized file is rejected with a plain-language message and never reaches onChanged', (
      tester,
    ) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('huge.png', List.filled(20, 1)),
      ]);
      var called = false;

      await pumpWide(
        tester,
        LayrzImageInput(
          maxFileSizeBytes: 10,
          maxFileSizeLabel: '10 bytes',
          onChanged: (_) => called = true,
        ),
      );

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();

      expect(called, isFalse, reason: 'oversized rejection must fire before any base64 encode/emit');
      expect(find.textContaining('too large'), findsOneWidget);
      expect(find.textContaining('10 bytes'), findsOneWidget);
    });

    testWidgets('the oversized rejection message persists (not a vanishing toast)', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('huge.png', List.filled(20, 1)),
      ]);

      await pumpWide(tester, const LayrzImageInput(maxFileSizeBytes: 10, maxFileSizeLabel: '10 bytes'));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();
      expect(find.textContaining('too large'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('too large'), findsOneWidget);
    });

    testWidgets('a subsequent successfully-sized pick clears the oversized rejection', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('huge.png', List.filled(20, 1)),
      ]);

      await pumpWide(tester, const LayrzImageInput(maxFileSizeBytes: 10, maxFileSizeLabel: '10 bytes'));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();
      expect(find.textContaining('too large'), findsOneWidget);

      // Genuinely within the 10-byte limit -- need not be a decodable image,
      // since this test only exercises the rejection-message lifecycle, not
      // the preview.
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('small.png', [1, 2, 3]),
      ]);
      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();

      expect(find.textContaining('too large'), findsNothing);
    });

    testWidgets('a custom rejectionMessage is shown instead of the default oversized text', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('huge.png', List.filled(20, 1)),
      ]);

      await pumpWide(
        tester,
        const LayrzImageInput(maxFileSizeBytes: 10, rejectionMessage: 'Nope, too big.'),
      );

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();

      expect(find.text('Nope, too big.'), findsOneWidget);
    });

    testWidgets('a disallowed extension is rejected with an extension message', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('doc.pdf', _validPngBytes),
      ]);
      var called = false;

      await pumpWide(
        tester,
        LayrzImageInput(allowedExtensions: const ['png'], onChanged: (_) => called = true),
      );

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.textContaining('allowed types'), findsOneWidget);
    });
  });

  group('LayrzImageInput clear affordance', () {
    testWidgets('clear emits null via onChanged', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('a.png', _validPngBytes),
      ]);
      final emitted = <String?>[];

      await pumpWide(tester, LayrzImageInput(onChanged: (value) => emitted.add(value)));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();
      expect(emitted.length, 1);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(emitted.last, isNull);
    });

    testWidgets('after clear, the box returns to its empty-state hint', (tester) async {
      fakePicker.nextResult = FilePickerResult([
        _platformImageFile('a.png', _validPngBytes),
      ]);

      await pumpWide(tester, const LayrzImageInput(hintText: 'Drop your image here'));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pumpAndSettle();
      expect(find.text('Drop your image here'), findsNothing);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Drop your image here'), findsOneWidget);
    });
  });

  group('LayrzImageInput label and error composition', () {
    testWidgets('labelText renders outside the box', (tester) async {
      await pumpWide(tester, const LayrzImageInput(labelText: 'Avatar'));

      expect(find.text('Avatar', findRichText: true), findsOneWidget);
    });

    testWidgets('errors render below the box via the footer slot', (tester) async {
      await pumpWide(tester, const LayrzImageInput(errors: ['This field is required']));

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('hideDetails suppresses the error footer', (tester) async {
      await pumpWide(tester, const LayrzImageInput(errors: ['This field is required'], hideDetails: true));

      expect(find.text('This field is required'), findsNothing);
    });
  });

  group('LayrzImageInput disabled state', () {
    testWidgets('disabled field does not open the picker on tap', (tester) async {
      await pumpWide(tester, const LayrzImageInput(disabled: true));

      await tester.tap(find.byType(LayrzImageInput));
      await tester.pump();

      expect(fakePicker.pickFilesCallCount, 0);
    });
  });

  group('LayrzImageInput renders correctly at both compact and wide viewports', () {
    testWidgets('wide viewport: the empty hint renders', (tester) async {
      await pumpWide(tester, const LayrzImageInput(hintText: 'Click or drop an image here'));

      expect(find.text('Click or drop an image here'), findsOneWidget);
    });

    testWidgets('compact viewport: the empty hint still renders (box is not width-adaptive)', (tester) async {
      await pumpCompact(tester, const LayrzImageInput(hintText: 'Click or drop an image here'));

      expect(find.text('Click or drop an image here'), findsOneWidget);
    });
  });

  group('LayrzImageInput semantics', () {
    testWidgets('the empty box is announced as a button with the label as its name', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWide(tester, const LayrzImageInput(labelText: 'Avatar'));

        final labels = dumpSemanticsLabels(tester);
        expect(labels.any((l) => l.contains('Avatar')), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('disabled state is announced with isEnabled false', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWide(tester, const LayrzImageInput(labelText: 'Avatar', disabled: true));

        // The announced label merges the visible hint text underneath
        // (`"Avatar\n<hint>"`, matching `LayrzFileInput`'s identical,
        // documented behavior), so this matches by prefix rather than an
        // exact label.
        expect(
          tester.getSemantics(find.bySemanticsLabel(RegExp('^Avatar'))),
          matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a populated box exposes independent Replace and Clear semantics nodes', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        fakePicker.nextResult = FilePickerResult([
          _platformImageFile('a.png', _validPngBytes),
        ]);

        await pumpWide(tester, const LayrzImageInput());

        await tester.tap(find.byType(LayrzImageInput));
        await tester.pumpAndSettle();

        final labels = dumpSemanticsLabels(tester);
        expect(labels, contains('Replace'));
        expect(labels, contains('Clear'));
      } finally {
        handle.dispose();
      }
    });
  });
}

/// A tiny stateful host used to prove that an externally-driven change to
/// [LayrzImageInput.value] (still untouched by the user) never triggers
/// [onChanged] -- distinct from the widget's own internal state changes.
class _HostWithUpdatableValue extends StatefulWidget {
  /// Called whenever the wrapped [LayrzImageInput] reports a change.
  final VoidCallback onChanged;

  /// The initial value passed to the wrapped [LayrzImageInput].
  final String initialValue;

  /// Creates a new [_HostWithUpdatableValue].
  const _HostWithUpdatableValue({required this.onChanged, required this.initialValue});

  @override
  State<_HostWithUpdatableValue> createState() => _HostWithUpdatableValueState();
}

class _HostWithUpdatableValueState extends State<_HostWithUpdatableValue> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  /// Updates the value fed to the wrapped [LayrzImageInput], simulating a
  /// caller-driven rebuild with a new externally-supplied value.
  void setValue(String value) => setState(() => _value = value);

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Center(
                child: LayrzImageInput(value: _value, onChanged: (_) => widget.onChanged()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
