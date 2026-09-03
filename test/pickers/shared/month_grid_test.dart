import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/month_grid.dart';
import 'package:layrz_ui/src/pickers/src/shared/month_grid_cell.dart';
import 'package:layrz_ui/src/pickers/src/shared/day_grid_cell.dart' show LayrzPickerCellRole;
import 'package:layrz_ui/src/pickers/src/shared/range_bar.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickersMonthGrid — layout', () {
    guardedTestWidgets('renders all 12 full month names at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      expect(find.text('January'), findsOneWidget);
      expect(find.text('September'), findsOneWidget);
      expect(find.text('December'), findsOneWidget);
      // No abbreviation anywhere.
      expect(find.text('Jan'), findsNothing);
      expect(find.text('Sep'), findsNothing);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      expect(find.byType(LayrzPickersMonthGrid), findsOneWidget);
      // All 12 full names -- including the three longest ("September",
      // "November", "December") -- must still be present with no
      // overflow at 400px; `guardedTestWidgets` fails the test if a
      // RenderFlex overflow was reported during the pump above.
      expect(find.text('September'), findsOneWidget);
      expect(find.text('November'), findsOneWidget);
      expect(find.text('December'), findsOneWidget);
    });

    guardedTestWidgets('lays out 3 rows of 4 columns -- January through April on the first row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      double topOf(String label) => tester.getTopLeft(find.text(label)).dy;
      double leftOf(String label) => tester.getTopLeft(find.text(label)).dx;

      // Positive assertion of the new orientation: the first four months
      // share one row (same y, ascending x) -- a 4-rows-by-3-columns grid
      // would instead put January, May and September on that same row.
      final firstRowY = topOf('January');
      expect(topOf('February'), firstRowY);
      expect(topOf('March'), firstRowY);
      expect(topOf('April'), firstRowY);
      expect(leftOf('January') < leftOf('February'), isTrue);
      expect(leftOf('February') < leftOf('March'), isTrue);
      expect(leftOf('March') < leftOf('April'), isTrue);

      // May starts a second, lower row, and September a third -- three
      // rows deep, not four.
      expect(topOf('May'), greaterThan(firstRowY));
      expect(topOf('September'), greaterThan(topOf('May')));
      // December (row 3, col 4) is on the same row as September, not a
      // fourth row.
      expect(topOf('December'), topOf('September'));
    });

    guardedTestWidgets('renders the "Year YYYY" header', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      expect(find.text('Year 2026'), findsOneWidget);
    });

    guardedTestWidgets('tapping a selectable month fires onMonthTap with the correct month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (d) => tapped = d,
        ),
      );

      await tester.tap(find.text('September'));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.month, 9);
      expect(tapped!.year, 2026);
    });

    guardedTestWidgets('a disabled month does not fire onMonthTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          minimum: DateTime(2026, 6),
          onMonthTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('January'));
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('tapping the "next year" chevron advances displayedYear via onYearChanged', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? newYear;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (y) => newYear = y,
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronRight));
      await tester.pump();

      expect(newYear, 2027);
    });

    guardedTestWidgets('tapping the "previous year" chevron decrements displayedYear via onYearChanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? newYear;
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (y) => newYear = y,
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronLeft));
      await tester.pump();

      expect(newYear, 2025);
    });
  });

  group('LayrzPickersMonthGrid — range interior colour (Finding 1)', () {
    // Same defect and same fix as `LayrzPickersDayGridCell` -- see
    // `day_grid_test.dart`'s equivalent group for the full root-cause
    // explanation (`LayrzColorSwatch.fromColor`'s shade50 inversion).
    guardedTestWidgets('no rendered cell resolves to a near-black fill in a consecutive range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          rangeStart: DateTime(2026, 2),
          rangeEnd: DateTime(2026, 5),
          onMonthTap: (_) {},
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is! BoxDecoration) continue;
        final color = decoration.color;
        if (color == null) continue;
        // A fully transparent fill (alpha 0, e.g. LayrzTappable's own idle
        // surface -- Finding 1, see `LayrzPickersMonthGridCell`'s doc) paints
        // nothing at all, so its HSL lightness is meaningless: `Color(
        // 0x00000000)` is literally black at alpha 0, which would otherwise
        // false-positive this near-black check despite being invisible.
        if (color.a == 0.0) continue;
        expect(
          HSLColor.fromColor(color).lightness,
          greaterThan(0.05),
          reason: 'A cell fill resolved to a near-black colour: $color',
        );
      }
    });

    guardedTestWidgets('a rejected cell whose role is not rangeInterior tints with tonalOpacity alpha', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tokens = LayrzTokens.light();
      final expected = tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);

      await pumpThemed(
        tester,
        LayrzPickersMonthGridCell(
          label: 'March',
          semanticLabel: 'March 2026',
          role: LayrzPickerCellRole.none,
          isRejected: true,
          onTap: null,
          focusNode: FocusNode(),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, expected);
    });

    // Finding 2c regression: a consecutive month range's endpoint/interior
    // months previously rendered a bordered card/pill of their own (visible
    // in the maintainer's screenshot), on top of the continuous bar. This
    // asserts neither role paints a fill/border of its own any longer.
    guardedTestWidgets('a consecutive range endpoint/interior month paints no card of its own (Finding 2c)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          rangeStart: DateTime(2026, 2),
          rangeEnd: DateTime(2026, 5),
          onMonthTap: (_) {},
        ),
      );

      final rangeCells = tester.widgetList<LayrzPickersMonthGridCell>(
        find.byWidgetPredicate(
          (widget) =>
              widget is LayrzPickersMonthGridCell &&
              (widget.role == LayrzPickerCellRole.rangeEndpoint || widget.role == LayrzPickerCellRole.rangeInterior),
        ),
      );
      // Feb (start), Mar/Apr (interior), May (end) -- four cells total.
      expect(rangeCells.length, 4);

      for (final label in ['February', 'March', 'April', 'May']) {
        final cellFinder = find.byWidgetPredicate(
          (widget) =>
              widget is LayrzPickersMonthGridCell &&
              widget.label == label &&
              (widget.role == LayrzPickerCellRole.rangeEndpoint || widget.role == LayrzPickerCellRole.rangeInterior),
        );
        expect(cellFinder, findsOneWidget, reason: '$label cell not found');

        // The cell's own rounded-rectangle Container is the innermost one
        // (padded vertically, no fixed size) -- LayrzTappable's own idle
        // surface Container (matching its `tokens.radius.br2` chrome) sits
        // ahead of it in descendant order for a selectable (non-rejected)
        // cell, same trap as the day grid's endpoint test.
        final containers = tester.widgetList<Container>(
          find.descendant(of: cellFinder, matching: find.byType(Container)),
        );
        final innerContainer = containers.last;
        final decoration = innerContainer.decoration as BoxDecoration;
        expect(decoration.color, isNull, reason: '$label must not paint its own card fill');
        expect(decoration.border, isNull, reason: '$label must not paint its own card border');

        // Finding 1 regression (maintainer review): "MonthRange has the same
        // issue as Date" -- a selectable (non-rejected) cell reaches
        // `LayrzTappable` with a non-null `onTap` and renders its own
        // `AnimatedContainer` surface. Before the fix, that surface's idle
        // color defaulted to `tokens.colors.sf1`, which painted a visible
        // card-shaped disc over the range bar underneath, hiding the month
        // label. See `LayrzPickersMonthGridCell`'s own doc for the fix.
        final animatedContainer = tester
            .widgetList<AnimatedContainer>(find.descendant(of: cellFinder, matching: find.byType(AnimatedContainer)))
            .first;
        final surfaceDecoration = animatedContainer.decoration as BoxDecoration;
        expect(
          surfaceDecoration.color?.a ?? 0.0,
          0.0,
          reason:
              '$label must have a fully transparent (alpha 0) idle surface -- any visible alpha here '
              'paints a disc over the range bar, the same "white circles" defect as the day grid',
        );
      }
    });

    // Finding 2b regression, mirrored for the month grid: the bar previously
    // used a tonal tint; the maintainer's ruling is flat primary, "without
    // transparency or filledTonal effect".
    guardedTestWidgets('the month range bar paints flat primary, not a tonal tint (Finding 2b)', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          rangeStart: DateTime(2026, 2),
          rangeEnd: DateTime(2026, 5),
          onMonthTap: (_) {},
        ),
      );

      final tokens = LayrzTokens.light();
      final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      expect(coloredBoxes.any((box) => box.color == tokens.colors.primary), isTrue);
      expect(
        coloredBoxes.any((box) => box.color == tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity)),
        isFalse,
        reason: 'no bar segment may fall back to the retired tonal tint',
      );
    });

    // Numeral-legibility half of Finding 2b: the month name printed on a
    // flat-primary bar must resolve to a contrasting foreground.
    guardedTestWidgets('range endpoint/interior month labels resolve to a legible foreground on the bar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          rangeStart: DateTime(2026, 2),
          rangeEnd: DateTime(2026, 5),
          onMonthTap: (_) {},
        ),
      );

      final tokens = LayrzTokens.light();
      for (final label in ['February', 'March', 'May']) {
        final cellFinder = find.byWidgetPredicate(
          (widget) =>
              widget is LayrzPickersMonthGridCell &&
              widget.label == label &&
              (widget.role == LayrzPickerCellRole.rangeEndpoint || widget.role == LayrzPickerCellRole.rangeInterior),
        );
        final text = tester.widget<Text>(find.descendant(of: cellFinder, matching: find.byType(Text)).first);
        expect(text.style?.color, tokens.colors.sf1, reason: '$label must use the contrasting foreground');
      }
    });
  });

  group('LayrzPickersMonthGrid — continuous range bar (Finding 2)', () {
    guardedTestWidgets('consecutive mode paints a continuous bar across the interior row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // January through April 2026 -- the grid's first row (row 0, cols
      // 0-3) per `LayrzPickersMonthGridState.build`'s `row * 4 + col`
      // layout.
      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          rangeStart: DateTime(2026, 1),
          rangeEnd: DateTime(2026, 4),
          onMonthTap: (_) {},
        ),
      );

      final bar = tester.widget<LayrzPickersRangeBar>(find.byType(LayrzPickersRangeBar).first);
      expect(bar.columns, [
        LayrzRangeBarColumn.rangeStart,
        LayrzRangeBarColumn.rangeInterior,
        LayrzRangeBarColumn.rangeInterior,
        LayrzRangeBarColumn.rangeEnd,
      ]);

      // Touching segments -- no gap between February's and March's columns.
      final segmentsInRow = find.descendant(
        of: find.byType(LayrzPickersRangeBar).first,
        matching: find.byType(ColoredBox),
      );
      final february = tester.getRect(segmentsInRow.at(0));
      final march = tester.getRect(segmentsInRow.at(1));
      expect(february.right, march.left);
    });

    guardedTestWidgets('arbitrary mode never renders an interior bar -- selected months stay individual pills', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          arbitrarySelection: {DateTime(2026, 1), DateTime(2026, 2), DateTime(2026, 3)},
          onMonthTap: (_) {},
        ),
      );

      final bars = tester.widgetList<LayrzPickersRangeBar>(find.byType(LayrzPickersRangeBar));
      for (final bar in bars) {
        expect(bar.columns.every((c) => c == LayrzRangeBarColumn.none), isTrue);
      }
    });
  });

  group('LayrzPickersMonthGrid — cells use LayrzTappable (Finding 3)', () {
    guardedTestWidgets('a selectable month cell is wrapped in an interactive LayrzTappable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      final cellFinder = find.ancestor(
        of: find.text('September'),
        matching: find.byType(LayrzTappable),
      );
      expect(cellFinder, findsOneWidget);
      final tappable = tester.widget<LayrzTappable>(cellFinder);
      expect(tappable.onTap, isNotNull);
      expect(
        find.descendant(of: cellFinder, matching: find.byType(GestureDetector)),
        findsOneWidget,
      );
    });

    guardedTestWidgets('a disabled month cell renders LayrzTappable with a null onTap -- genuinely inert', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          minimum: DateTime(2026, 6),
          onMonthTap: (_) {},
        ),
      );

      final cellFinder = find.ancestor(
        of: find.text('January'),
        matching: find.byType(LayrzTappable),
      );
      expect(cellFinder, findsOneWidget);
      final tappable = tester.widget<LayrzTappable>(cellFinder);
      expect(tappable.onTap, isNull);
      expect(
        find.descendant(of: cellFinder, matching: find.byType(GestureDetector)),
        findsNothing,
      );
    });

    guardedTestWidgets('hovering a selectable month cell paints the LayrzTappable hover surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersMonthGrid(
          displayedYear: 2026,
          onYearChanged: (_) {},
          reference: DateTime(2026),
          onMonthTap: (_) {},
        ),
      );

      final cellFinder = find.ancestor(
        of: find.text('September'),
        matching: find.byType(LayrzTappable),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(cellFinder));
      addTearDown(gesture.removePointer);
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(of: cellFinder, matching: find.byType(AnimatedContainer)),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      final tokens = LayrzTokens.light();
      expect(decoration.color, isNot(tokens.colors.sf1));
    });

    guardedTestWidgets(
      'geometry stays identical (D15): the same cell measures the same box before/after becoming disabled',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? minimum;
        await pumpThemed(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              return LayrzPickersMonthGrid(
                displayedYear: 2026,
                onYearChanged: (_) {},
                reference: DateTime(2026),
                minimum: minimum,
                onMonthTap: (_) {
                  setState(() => minimum = DateTime(2026, 6));
                },
              );
            },
          ),
        );

        // Same cell (January), same label -- only its interactivity is
        // about to change, not its own text content.
        final januaryCellFinder = find.ancestor(
          of: find.text('January'),
          matching: find.byType(LayrzTappable),
        );
        final sizeBefore = tester.getSize(januaryCellFinder);

        // Trip `minimum` to make January disabled, via the surrounding
        // StatefulBuilder rather than a fresh pumpThemed -- a second
        // pumpThemed would rebuild a brand-new Overlay/widget tree instead
        // of exercising this exact cell's own didUpdateWidget path.
        await tester.tap(find.text('September'));
        await tester.pump();

        final sizeAfter = tester.getSize(januaryCellFinder);
        expect(sizeAfter, sizeBefore);
      },
    );
  });
}
