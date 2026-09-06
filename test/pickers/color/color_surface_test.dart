import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/color/color_surface.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzColorSurface — rendering', () {
    guardedTestWidgets('renders both tabs when the palette is non-empty', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: {const Color(0xFFFF0000)},
          onColorSelected: (_) {},
        ),
      );

      expect(find.text('Palette'), findsOneWidget);
      expect(find.text('Wheel'), findsOneWidget);
    });

    guardedTestWidgets('renders no tab switcher and no "Palette" tab when the palette is empty (OQ-2)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      expect(find.text('Palette'), findsNothing);
      expect(find.text('Wheel'), findsNothing);
      // The wheel itself still renders directly, with no switcher framing it.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    guardedTestWidgets('opens on the Palette tab by default when the palette is non-empty', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: {const Color(0xFFFF0000), const Color(0xFF00FF00)},
          onColorSelected: (_) {},
        ),
      );

      // A GridView (the palette grid) renders up-front; the wheel's
      // CustomPaint is not shown until the Wheel tab is selected.
      expect(find.byType(GridView), findsOneWidget);
    });

    guardedTestWidgets('shows the HEX readout for the seeded value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF001E60),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      expect(find.text('#001E60'), findsOneWidget);
    });

    guardedTestWidgets('shows a visible, labeled Paste button beside the HEX readout', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      expect(find.text('Paste'), findsOneWidget);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: {const Color(0xFFFF0000), const Color(0xFF00FF00), const Color(0xFF00FFFF)},
          onColorSelected: (_) {},
        ),
      );

      expect(find.byType(LayrzColorSurface), findsOneWidget);
    });
  });

  group('LayrzColorSurface — tab switching', () {
    guardedTestWidgets('tapping "Wheel" swaps the palette grid for the wheel disc', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: {const Color(0xFFFF0000)},
          onColorSelected: (_) {},
        ),
      );

      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(find.text('Wheel'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
    });

    guardedTestWidgets('tapping "Palette" returns to the swatch grid', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: {const Color(0xFFFF0000)},
          onColorSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Wheel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Palette'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('LayrzColorSurface — draft/Save contract (DESIGN-98-style staging)', () {
    guardedTestWidgets('tapping a palette swatch only drafts it -- onColorSelected does not fire until save()', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      const red = Color(0xFFFF0000);
      final surfaceKey = GlobalKey<LayrzColorSurfaceState>();

      await pumpThemed(
        tester,
        LayrzColorSurface(
          key: surfaceKey,
          value: const Color(0xFF0000FF),
          palette: {red, const Color(0xFF00FF00)},
          onColorSelected: (_) => count++,
        ),
      );

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();

      expect(count, 0);
      expect(surfaceKey.currentState!.canSave, isTrue);

      surfaceKey.currentState!.save();
      expect(count, 1);
    });

    guardedTestWidgets('canSave is false until the draft actually differs from the seeded value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final surfaceKey = GlobalKey<LayrzColorSurfaceState>();

      await pumpThemed(
        tester,
        LayrzColorSurface(
          key: surfaceKey,
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      expect(surfaceKey.currentState!.canSave, isFalse);
    });

    guardedTestWidgets('save() is a no-op while canSave is false', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var count = 0;
      final surfaceKey = GlobalKey<LayrzColorSurfaceState>();

      await pumpThemed(
        tester,
        LayrzColorSurface(
          key: surfaceKey,
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) => count++,
        ),
      );

      surfaceKey.currentState!.save();
      expect(count, 0);
    });

    guardedTestWidgets('onDraftChanged fires once on initial mount and again on every draft mutation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var draftChangedCount = 0;
      const red = Color(0xFFFF0000);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: {red},
          onColorSelected: (_) {},
          onDraftChanged: () => draftChangedCount++,
        ),
      );

      expect(draftChangedCount, 1, reason: 'initial post-frame priming call');

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();

      expect(draftChangedCount, 2);
    });

    guardedTestWidgets('re-seeds the draft when value changes externally (involuntary-close discipline)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final surfaceKey = GlobalKey<LayrzColorSurfaceState>();
      Color current = const Color(0xFF0000FF);

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayrzColorSurface(
                  key: surfaceKey,
                  value: current,
                  palette: const {},
                  onColorSelected: (_) {},
                ),
                GestureDetector(
                  onTap: () => setState(() => current = const Color(0xFFFF0000)),
                  child: const Text('Change value'),
                ),
              ],
            );
          },
        ),
      );

      expect(surfaceKey.currentState!.canSave, isFalse);

      await tester.tap(find.text('Change value'));
      await tester.pump();

      // The draft was re-seeded to the new value, so canSave is false again
      // (draft == value) rather than true (which it would wrongly be if the
      // stale old draft were compared against the new value).
      expect(surfaceKey.currentState!.canSave, isFalse);
    });
  });

  group('LayrzColorSurface — clipboard paste (Decision D-paste)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': '#00FF00'};
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    guardedTestWidgets('pressing Paste with a valid hex clipboard value drafts that color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(find.text('#00FF00'), findsOneWidget);
    });

    guardedTestWidgets('never reads the clipboard before Paste is pressed (no ambient read)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      // No paste happened yet -- the readout still shows the seeded value,
      // not the mocked clipboard content, proving no read occurred on open.
      expect(find.text('#0000FF'), findsOneWidget);
      expect(find.text('#00FF00'), findsNothing);
    });
  });

  group('LayrzColorSurface — clipboard paste, unparseable content (no-op)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': 'not a color'};
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    guardedTestWidgets('pressing Paste with unparseable clipboard content leaves the draft unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final surfaceKey = GlobalKey<LayrzColorSurfaceState>();

      await pumpThemed(
        tester,
        LayrzColorSurface(
          key: surfaceKey,
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(find.text('#0000FF'), findsOneWidget);
      expect(surfaceKey.currentState!.canSave, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzColorSurface — clipboard paste, empty clipboard (no-op)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': ''};
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    guardedTestWidgets('pressing Paste with an empty clipboard leaves the draft unchanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(find.text('#0000FF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzColorSurface — clipboard paste, accepted formats', () {
    guardedTestWidgets('a bare (no #) 6-digit hex string is also accepted', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': 'AABBCC'};
          }
          return null;
        },
      );
      addTearDown(
        () => TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpThemed(
        tester,
        LayrzColorSurface(
          value: const Color(0xFF0000FF),
          palette: const {},
          onColorSelected: (_) {},
        ),
      );

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(find.text('#AABBCC'), findsOneWidget);
    });
  });
}
