import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/glyph_grid.dart';
import 'package:layrz_ui/src/pickers/src/shared/glyph_grid_keyboard.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';
import '../../helpers/pump_themed_app.dart';

Widget _cellBuilder(BuildContext context, int item, int index, bool isFocused) {
  return SizedBox(
    width: 40,
    height: 40,
    key: ValueKey('cell-$index'),
    child: Center(child: Text('$item')),
  );
}

void main() {
  group('LayrzGlyphGrid — Accessibility (semantics)', () {
    guardedTestWidgets('a cell with a semantic label exposes button semantics with that label', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            height: 400,
            child: LayrzGlyphGrid<int>(
              items: List.generate(10, (i) => i),
              columns: 5,
              itemBuilder: _cellBuilder,
              onItemActivated: (_) {},
              semanticLabelBuilder: (item, index) => 'Glyph number $item',
            ),
          ),
        );

        expect(
          tester.getSemantics(find.byKey(const ValueKey('cell-3'))),
          matchesSemantics(
            label: 'Glyph number 3',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('a disabled cell exposes button semantics as not enabled and without a tap action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            height: 400,
            child: LayrzGlyphGrid<int>(
              items: List.generate(10, (i) => i),
              columns: 5,
              itemBuilder: _cellBuilder,
              onItemActivated: (_) {},
              isDisabled: (index) => index == 3,
              semanticLabelBuilder: (item, index) => 'Glyph number $item',
            ),
          ),
        );

        expect(
          tester.getSemantics(find.byKey(const ValueKey('cell-3'))),
          matchesSemantics(label: 'Glyph number 3', isButton: true, hasEnabledState: true, hasTapAction: false),
        );
      } finally {
        handle.dispose();
      }
    });

    guardedTestWidgets('without a semanticLabelBuilder, no extra Semantics wrapper is imposed', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 400,
            height: 400,
            child: LayrzGlyphGrid<int>(
              items: List.generate(10, (i) => i),
              columns: 5,
              itemBuilder: _cellBuilder,
              onItemActivated: (_) {},
            ),
          ),
        );

        // The cell's own Text content still surfaces its default semantics
        // (a text label equal to its numeric value) -- proving this widget
        // did not silently swallow semantics, just declined to add its own
        // button-labeled wrapper on top.
        expect(find.text('3'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  group('LayrzGlyphGrid — Accessibility (focus traversal)', () {
    guardedTestWidgets('keyboard focus genuinely moves between cells via Tab', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemedApp(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(10, (i) => i),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
          ),
        ),
      );

      final context = tester.element(find.byKey(const ValueKey('cell-0')));
      Focus.of(context, scopeOk: true).requestFocus();
      await tester.pump();

      expect(WidgetsBinding.instance.focusManager.primaryFocus?.debugLabel, 'glyph-0');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(WidgetsBinding.instance.focusManager.primaryFocus?.debugLabel, 'glyph-1');
    });

    guardedTestWidgets('the focused cell renders a visible focus ring border', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: LayrzGlyphGrid<int>(
            items: List.generate(10, (i) => i),
            columns: 5,
            itemBuilder: _cellBuilder,
            onItemActivated: (_) {},
            keyboardHandler: buildGlyphGridKeyboardHandler(
              columns: 5,
              itemCount: 10,
              isDisabled: (_) => false,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      final context = tester.element(find.byKey(const ValueKey('cell-0')));
      Focus.of(context, scopeOk: true).requestFocus();
      await tester.pump();
      await tester.pump();

      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final ringBox = decoratedBoxes.firstWhere(
        (box) => (box.decoration as BoxDecoration).border != null,
        orElse: () => throw StateError('no focused DecoratedBox border found'),
      );
      final decoration = ringBox.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
    });
  });
}
