import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/pickers/src/color/color_input.dart';

import '../../helpers/find_button_label.dart';
import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed_app.dart';

void main() {
  group('LayrzColorInput — construction', () {
    guardedTestWidgets('asserts at least one of labelText/hintText is provided', (tester) async {
      expect(
        () => LayrzColorInput(value: const Color(0xFF0000FF)),
        throwsAssertionError,
      );
    });

    guardedTestWidgets('can be created with only hintText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), hintText: 'Pick a color'));

      expect(find.byType(LayrzColorInput), findsOneWidget);
    });

    guardedTestWidgets('defaults palette to an empty set', (tester) async {
      const widget = LayrzColorInput(value: Color(0xFF0000FF), labelText: 'Color');
      expect(widget.palette, isEmpty);
    });
  });

  group('LayrzColorInput — rendering', () {
    guardedTestWidgets('renders the label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      expect(findButtonLabel('Color'), findsOneWidget);
    });

    guardedTestWidgets('shows the current value as hex text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF001E60), labelText: 'Color'));

      expect(find.text('#001E60'), findsOneWidget);
    });

    guardedTestWidgets('renders the palette affordance icon', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      expect(find.byIcon(MdiIcons.paletteOutline), findsOneWidget);
    });

    guardedTestWidgets('renders a Cancel/Save footer inside the drawer', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
      expect(findButtonLabel('Cancel'), findsOneWidget);
    });

    guardedTestWidgets('the drawer shows labelText as a visible title', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Brand color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('Brand color'), findsOneWidget);
    });
  });

  group('LayrzColorInput — errors', () {
    guardedTestWidgets('displays error text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', errors: const ['Required']),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    guardedTestWidgets('hides error text when hideDetails is true', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          errors: const ['Required'],
          hideDetails: true,
        ),
      );

      expect(find.text('Required'), findsNothing);
    });

    // The readOnly trap: LayrzInputStyleSpec.resolve ranks `readOnly` above
    // `error`, so hardcoding `readOnly: true` on the anchor would silently
    // suppress the danger border even with `errors` non-empty.
    guardedTestWidgets('error styling actually paints -- the affordance icon resolves to the danger color', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', errors: const ['Required']),
      );

      final icon = tester.widget<Icon>(find.byIcon(MdiIcons.paletteOutline));
      expect(icon.color, tokens.colors.danger);
      expect(icon.color, isNot(tokens.colors.fg1));
    });

    guardedTestWidgets('LayrzInputChrome.readOnly stays false even with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', errors: const ['Required']),
      );

      final chrome = tester.widget<LayrzInputChrome>(find.byType(LayrzInputChrome).first);
      expect(chrome.readOnly, isFalse);
    });
  });

  group('LayrzColorInput — disabled vs enabled tap behavior', () {
    guardedTestWidgets('disabled blocks the tap from opening the surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', disabled: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsNothing);
    });

    guardedTestWidgets('a non-disabled field opens the surface on tap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
    });
  });

  group('LayrzColorInput — Save commits, Cancel reverts, both close (desktop)', () {
    guardedTestWidgets('picking a palette swatch alone does not fire onChanged -- only Save does', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      final palette = {Color(0xFFFF0000), Color(0xFF00FF00), Color(0xFF0000FF)};

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          palette: palette,
          onChanged: (_) => changeCount++,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GridView));
      await tester.pumpAndSettle();

      expect(changeCount, 0, reason: 'a tap alone must not commit');
    });

    guardedTestWidgets('selecting a swatch and pressing Save fires onChanged once and closes the drawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? changed;
      var changeCount = 0;
      const red = Color(0xFFFF0000);
      final palette = {red, const Color(0xFF00FF00), const Color(0xFF0000FF)};

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          palette: palette,
          onChanged: (c) {
            changed = c;
            changeCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      // The first palette swatch cell is the Container painted with `red`
      // (insertion order of a Dart Set literal is deterministic).
      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(changed, red);
      expect(findButtonLabel('Save'), findsNothing);
    });

    guardedTestWidgets('pressing Cancel after a swatch pick does not fire onChanged and closes the drawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var changeCount = 0;
      const red = Color(0xFFFF0000);
      final palette = {red, const Color(0xFF00FF00), const Color(0xFF0000FF)};

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          palette: palette,
          onChanged: (_) => changeCount++,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(changeCount, 0);
      expect(findButtonLabel('Save'), findsNothing);
    });

    guardedTestWidgets('the closed field reflects the newly saved color', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color current = const Color(0xFF0000FF);
      const red = Color(0xFFFF0000);
      final palette = {red, const Color(0xFF00FF00), const Color(0xFF0000FF)};

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return LayrzColorInput(
              value: current,
              labelText: 'Color',
              palette: palette,
              onChanged: (c) => setState(() => current = c),
            );
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(find.text('#FF0000'), findsOneWidget);
    });

    // Regression guard: Save must be disabled at open time when nothing has
    // been changed yet -- the draft is seeded from `value`, so `canSave`
    // (draft != value) starts false, unlike LayrzDateInput where any
    // pre-existing value already enables Save immediately.
    guardedTestWidgets('Save starts disabled on open with zero interaction', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final saveButton = findButtonLabel('Save');
      expect(saveButton, findsOneWidget);
      final saveWidget = tester.widget<LayrzButton>(
        find.ancestor(of: saveButton, matching: find.byType(LayrzButton)).first,
      );
      expect(saveWidget.onTap, isNull, reason: 'Save must start disabled -- the draft has not changed yet.');
    });
  });

  group('LayrzColorInput — commit on tap (mobile, compact viewport)', () {
    guardedTestWidgets('opens the bottom sheet on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('does NOT open the surface before the tap on a compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      expect(findButtonLabel('Save'), findsNothing);
    });

    guardedTestWidgets('picking a swatch in the bottom sheet only drafts it -- Save commits and dismisses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? changed;
      var changeCount = 0;
      const red = Color(0xFFFF0000);
      final palette = {red, const Color(0xFF00FF00), const Color(0xFF0000FF)};

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          palette: palette,
          onChanged: (c) {
            changed = c;
            changeCount++;
          },
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();
      expect(changeCount, 0, reason: 'a tap alone must not commit, even on mobile');

      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(changed, red);
    });

    guardedTestWidgets('disabled does not open the bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', disabled: true),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsNothing);
    });
  });

  group('LayrzColorInput — involuntary close discards draft state (desktop)', () {
    guardedTestWidgets('Cancel closes the drawer without changing value', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? changed;
      const red = Color(0xFFFF0000);
      final palette = {red, const Color(0xFF00FF00), const Color(0xFF0000FF)};

      await pumpThemedApp(
        tester,
        Center(
          child: LayrzColorInput(
            value: const Color(0xFF0000FF),
            labelText: 'Color',
            palette: palette,
            onChanged: (c) => changed = c,
          ),
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();
      expect(findButtonLabel('Save'), findsOneWidget);

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(findButtonLabel('Cancel'));
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsNothing);
      expect(changed, isNull);
      expect(find.text('#0000FF'), findsOneWidget);
    });
  });

  group('LayrzColorInput — controller and focus node lifecycle', () {
    guardedTestWidgets('disposes a self-created controller on widget dispose', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });

    guardedTestWidgets('does not dispose a caller-provided controller', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', controller: controller),
      );
      await tester.pumpWidget(const SizedBox());

      expect(() => controller.text, returnsNormally);
    });

    guardedTestWidgets('does not dispose a caller-provided focus node', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', focusNode: focusNode),
      );
      await tester.pumpWidget(const SizedBox());

      expect(() => focusNode.hasFocus, returnsNormally);
    });
  });

  group('LayrzColorInput — empty palette opens on Wheel (OQ-2)', () {
    guardedTestWidgets('with an empty palette, the drawer opens directly on the wheel, with no tab switcher', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('Palette'), findsNothing);
      expect(find.text('Wheel'), findsNothing, reason: 'a single-tab surface renders no switcher at all');
      expect(find.byType(CustomPaint), findsWidgets);
    });

    guardedTestWidgets('with a non-empty palette, the drawer opens on Palette, with both tabs visible', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          palette: {const Color(0xFFFF0000), const Color(0xFF00FF00)},
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(find.text('Palette'), findsOneWidget);
      expect(find.text('Wheel'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('LayrzColorInput — help affordance', () {
    guardedTestWidgets('provides help affordance when helpContentText is non-null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          helpTitleText: 'About colors',
          helpContentText: 'Pick a brand color.',
        ),
      );

      expect(find.byType(LayrzColorInput), findsOneWidget);
    });
  });

  group('LayrzColorInput — viewport branch selection', () {
    guardedTestWidgets('opens the drawer (fixed-width, not a bottom sheet) at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('opens a bottom sheet route (not the drawer) below isCompact', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(tester, LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color'));

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
    });
  });

  group('LayrzColorInput — error state stays fully interactive', () {
    guardedTestWidgets('tapping the anchor opens the surface even with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        LayrzColorInput(value: const Color(0xFF0000FF), labelText: 'Color', errors: const ['Required']),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      expect(findButtonLabel('Save'), findsOneWidget);
    });

    guardedTestWidgets('a selection still commits onChanged with errors present', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Color? changed;
      const red = Color(0xFFFF0000);
      final palette = {red, const Color(0xFF00FF00)};

      await pumpThemedApp(
        tester,
        LayrzColorInput(
          value: const Color(0xFF0000FF),
          labelText: 'Color',
          palette: palette,
          errors: const ['Required'],
          onChanged: (c) => changed = c,
        ),
      );

      await tester.tap(find.byType(LayrzInputChrome).first);
      await tester.pumpAndSettle();

      final swatchFinder = find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).color == red,
      );
      await tester.tap(swatchFinder.first);
      await tester.pumpAndSettle();
      await tester.tap(findButtonLabel('Save'));
      await tester.pumpAndSettle();

      expect(changed, red);
    });
  });
}
