import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/glyph_grid.dart';
import 'package:layrz_ui/src/pickers/src/shared/glyph_grid_keyboard.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

/// A minimal, deterministic cell builder used across this file's tests:
/// renders [item]'s string form as [Text], keyed by index so individual
/// cells are addressable via [find.byKey].
Widget _cellBuilder(BuildContext context, int item, int index, bool isFocused) {
  return SizedBox(
    width: 40,
    height: 40,
    key: ValueKey('cell-$index'),
    child: Center(child: Text('$item')),
  );
}

void main() {
  group('LayrzGlyphGrid — rendering', () {
    guardedTestWidgets('renders a cell for every item within the viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(20, (i) => i),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
          ),
        ),
      );

      for (var i = 0; i < 20; i++) {
        expect(find.byKey(ValueKey('cell-$i')), findsOneWidget);
      }
    });

    guardedTestWidgets('an empty item list renders no cells and does not throw', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: const [],
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byKey(const ValueKey('cell-0')), findsNothing);
    });

    guardedTestWidgets(
      'a very large item count does not build every cell eagerly (lazy/viewport-based)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            height: 400,
            child: LayrzGlyphGrid<int>(
              items: List.generate(7000, (i) => i),
              columns: 5,
              itemBuilder: _cellBuilder,
              onItemActivated: (_) {},
            ),
          ),
        );

        // The last item is nowhere near the small viewport -- if the grid
        // built every cell eagerly this would still find it (and the test
        // would likely also be far slower / risk an OOM on a real 7000-cell
        // eager build). Finding it absent, with the widget tree still built
        // successfully and no overflow/exception, is the proxy for laziness
        // this test asserts.
        expect(find.byKey(const ValueKey('cell-6999')), findsNothing);
        expect(find.byKey(const ValueKey('cell-0')), findsOneWidget);
      },
    );
  });

  group('LayrzGlyphGrid — activation', () {
    guardedTestWidgets('tapping a cell invokes onItemActivated with that item', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? activated;
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(20, (i) => i * 10),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (item) => activated = item,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('cell-3')));
      await tester.pump();

      expect(activated, 30);
    });

    guardedTestWidgets('tapping a disabled cell does not invoke onItemActivated', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var activatedCount = 0;
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(20, (i) => i),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) => activatedCount++,
            isDisabled: (index) => index == 3,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('cell-3')));
      await tester.pump();

      expect(activatedCount, 0);
    });
  });

  group('LayrzGlyphGrid — keyboard integration', () {
    /// Requests focus on the cell rendering [index] via [Focus.of],
    /// resolving to that cell's own attached [FocusNode] -- mirrors
    /// `grid_keyboard_test.dart`'s identical `_focusDay` helper.
    void focusCell(WidgetTester tester, int index) {
      final context = tester.element(find.byKey(ValueKey('cell-$index')));
      Focus.of(context, scopeOk: true).requestFocus();
    }

    guardedTestWidgets('an injected keyboard handler moves focus on ArrowRight', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(20, (i) => i),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
            keyboardHandler: buildGlyphGridKeyboardHandler(
              columns: 5,
              itemCount: 20,
              isDisabled: (_) => false,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      focusCell(tester, 6);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      final node = WidgetsBinding.instance.focusManager.primaryFocus;
      expect(node?.debugLabel, 'glyph-7');
    });

    guardedTestWidgets('Enter via the injected handler invokes onSelect for the focused cell', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? selected;
      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(20, (i) => i * 100),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
            keyboardHandler: buildGlyphGridKeyboardHandler(
              columns: 5,
              itemCount: 20,
              isDisabled: (_) => false,
              onSelect: (index) => selected = index,
            ),
          ),
        ),
      );

      focusCell(tester, 4);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, 4);
    });

    guardedTestWidgets('with no keyboardHandler supplied, arrow keys are ignored (no crash)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(20, (i) => i),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
          ),
        ),
      );

      focusCell(tester, 6);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      final node = WidgetsBinding.instance.focusManager.primaryFocus;
      expect(node?.debugLabel, 'glyph-6');
    });
  });

  group('LayrzGlyphGrid — assertions', () {
    test('columns must be at least 1', () {
      expect(
        () => LayrzGlyphGrid<int>(
          items: const [1, 2, 3],
          columns: 0,
          itemBuilder: _cellBuilder,
          onItemActivated: (_) {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
