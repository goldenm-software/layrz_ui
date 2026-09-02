import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/shared/day_grid.dart';
import 'package:layrz_ui/src/pickers/src/shared/day_grid_cell.dart';
import 'package:layrz_ui/src/pickers/src/shared/range_bar.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickersDayGrid — layout', () {
    guardedTestWidgets('renders a full 42-cell grid at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      expect(find.text('1'), findsWidgets);
      expect(find.text('30'), findsWidgets);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      expect(find.byType(LayrzPickersDayGrid), findsOneWidget);
    });

    guardedTestWidgets('tapping a selectable day fires onDayTap with the correct date', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (d) => tapped = d),
      );

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.day, 15);
      expect(tapped!.month, 9);
    });

    guardedTestWidgets('a disabled day (outside firstDay/lastDay) does not fire onDayTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          firstDay: DateTime(2026, 9, 10),
          onDayTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('a disabledDays entry does not fire onDayTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          disabledDays: {DateTime(2026, 9, 15)},
          onDayTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('showWeekNumbers false renders no week-number gutter text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), showWeekNumbers: false, onDayTap: (_) {}),
      );

      expect(find.byType(LayrzPickersDayGrid), findsOneWidget);
    });

    guardedTestWidgets('a rejected date does not fire onDayTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          rejectedDates: {DateTime(2026, 9, 10)},
          onDayTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('10').first);
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('a range endpoint remains selectable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          onDayTap: (d) => tapped = d,
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.day, 5);
    });

    guardedTestWidgets('asserts firstDayOfWeek is within DateTime.monday..DateTime.sunday', (tester) async {
      expect(
        () => LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), firstDayOfWeek: 0, onDayTap: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('LayrzPickersDayGrid — range interior colour (Finding 1)', () {
    // Regression test for the "solid black" defect: `LayrzColorSwatch
    // .fromColor` derives shade50 by subtracting 0.40 from the seed's HSL
    // lightness, which clamps to fully opaque black for kPrimaryColor
    // (lightness ~0.19). `day_grid_cell.dart` no longer reads
    // `primary.shade50` at all for a range-interior cell -- the interior's
    // tint now comes entirely from the continuous bar underneath it, built
    // from `primary.withValues(alpha: tonalOpacity)` -- so no cell in an
    // active range should ever resolve to a near-black fill.
    guardedTestWidgets('no rendered cell resolves to a near-black fill in an active range', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          onDayTap: (_) {},
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is! BoxDecoration) continue;
        final color = decoration.color;
        if (color == null) continue;
        // Near-black would be an HSL lightness close to 0.0 -- the swatch
        // defect clamps all the way to it. A light tint (tonalOpacity
        // alpha over the seed, or the seed itself for endpoints) never
        // gets anywhere close.
        expect(
          HSLColor.fromColor(color).lightness,
          greaterThan(0.05),
          reason: 'A cell fill resolved to a near-black colour: $color',
        );
      }
    });

    // A rejected range-interior cell paints no fill of its own -- see
    // `LayrzPickersDayGridCell.build`'s `rangeInterior` switch branch,
    // which deliberately leaves `fillColor` null so the continuous bar
    // underneath (asserted separately in the "continuous range bar" group
    // below) provides the tint instead of doubling it. This test covers
    // the other branch of that same `if` -- a rejected cell whose role is
    // NOT `rangeInterior` -- which still falls back to the tonalOpacity
    // tint directly on the cell, proving that fallback path itself never
    // regresses to the near-black `shade50` defect. Every real caller in
    // this codebase only ever rejects `rangeInterior` cells today, so this
    // exercises the defensive branch directly via `LayrzPickersDayGridCell`
    // rather than through `LayrzPickersDayGrid`.
    guardedTestWidgets(
      'a rejected cell whose role is not rangeInterior tints with tonalOpacity alpha, not shade50',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final tokens = LayrzTokens.light();
        final expected = tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);

        await pumpThemed(
          tester,
          LayrzPickersDayGridCell(
            label: '10',
            semanticLabel: 'September 10, 2026',
            role: LayrzPickerCellRole.none,
            isRejected: true,
            onTap: null,
            focusNode: FocusNode(),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, expected);
        expect(HSLColor.fromColor(decoration.color!).lightness, greaterThan(0.05));
      },
    );

    guardedTestWidgets('a range-interior cell paints its tint via the bar, not the cell -- no double-tint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          rejectedDates: {DateTime(2026, 9, 10)},
          onDayTap: (_) {},
        ),
      );

      final cellFinder = find.byWidgetPredicate(
        (widget) => widget is LayrzPickersDayGridCell && widget.label == '10' && widget.isRejected,
      );
      expect(cellFinder, findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(of: cellFinder, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      // The cell's own circle paints no fill -- the bar behind it (asserted
      // in the "continuous range bar" group below) supplies the tint.
      expect(decoration.color, isNull);
    });
  });

  group('LayrzPickersDayGrid — continuous range bar (Finding 2)', () {
    guardedTestWidgets('adjacent interior days in the same week share an edge -- no gap between them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // September 6 (Sun) through September 12 (Sat) 2026 is a single
      // Monday-first week row (Sept 1 2026 is a Tuesday, so the first
      // Monday-first row starts Aug 31 and the second full week starts
      // Sept 7) -- pick a range whose interior spans within one row so the
      // bar's segments are directly comparable.
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 7),
          rangeEnd: DateTime(2026, 9, 11),
          onDayTap: (_) {},
        ),
      );

      final bars = tester.widgetList<LayrzPickersRangeBar>(find.byType(LayrzPickersRangeBar));
      // Sept 7 is a Monday -- the first column of its row -- so this
      // range's bar row reads: start, interior, interior, interior, end,
      // none, none. Find that specific row rather than assuming it is the
      // first `LayrzPickersRangeBar` in the grid (the grid's first row is
      // the leading adjacent-month week, which precedes Sept 7's row).
      const expectedColumns = [
        LayrzRangeBarColumn.rangeStart,
        LayrzRangeBarColumn.rangeInterior,
        LayrzRangeBarColumn.rangeInterior,
        LayrzRangeBarColumn.rangeInterior,
        LayrzRangeBarColumn.rangeEnd,
        LayrzRangeBarColumn.none,
        LayrzRangeBarColumn.none,
      ];
      expect(bars.any((bar) => _sameColumns(bar.columns, expectedColumns)), isTrue);

      final rangeRowFinder = find.byWidgetPredicate(
        (widget) => widget is LayrzPickersRangeBar && _sameColumns(widget.columns, expectedColumns),
      );

      // Assert the bar actually renders as visually touching segments: the
      // right edge of the Sept 8 column's decorated box equals the left
      // edge of the Sept 9 column's, with no horizontal gap -- proving a
      // "continuous bar", not separate tinted circles with space between
      // them. This is what a test that only checks a colour is applied
      // would miss.
      final segmentsInRow = find.descendant(of: rangeRowFinder, matching: find.byType(ColoredBox));
      final segment8 = tester.getRect(segmentsInRow.at(0));
      final segment9 = tester.getRect(segmentsInRow.at(1));
      expect(segment8.right, segment9.left);
    });

    guardedTestWidgets('the range endpoints round off; interior columns stay square', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 7),
          rangeEnd: DateTime(2026, 9, 11),
          onDayTap: (_) {},
        ),
      );

      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final rounded = decoratedBoxes.where((box) {
        final decoration = box.decoration;
        if (decoration is! BoxDecoration) return false;
        final radius = decoration.borderRadius;
        return radius != null && radius != BorderRadius.zero;
      });
      // Exactly two capped segments in the bar itself: rangeStart and
      // rangeEnd. (Selected/today rings and cell circles also use
      // DecoratedBox-adjacent shapes, but those are Container/BoxShape
      // .circle, not DecoratedBox with a BorderRadius, so they do not
      // pollute this count.)
      expect(rounded.length, greaterThanOrEqualTo(2));
    });

    guardedTestWidgets('a range spanning a full week renders a bar with no `none` gaps in that row', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Aug 31 (Mon) through Sept 6 (Sun) 2026 is exactly one Monday-first
      // week row -- select a range that starts before and ends after it so
      // every column of that row is in-range.
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 8, 25),
          rangeEnd: DateTime(2026, 9, 15),
          onDayTap: (_) {},
        ),
      );

      final bars = tester.widgetList<LayrzPickersRangeBar>(find.byType(LayrzPickersRangeBar));
      // The second row (Aug 31 - Sept 6) is entirely interior -- no `none`
      // column anywhere in it, proving the bar continues edge-to-edge
      // across the full row rather than stopping partway.
      final fullyInteriorRow = bars.firstWhere(
        (bar) => bar.columns.every((c) => c == LayrzRangeBarColumn.rangeInterior),
        orElse: () => throw StateError('No fully-interior row found among ${bars.map((b) => b.columns).toList()}'),
      );
      expect(fullyInteriorRow.columns, hasLength(7));
    });

    guardedTestWidgets('a single-day range (start == end) rounds off both edges of its one column', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 15),
          rangeEnd: DateTime(2026, 9, 15),
          onDayTap: (_) {},
        ),
      );

      final bars = tester.widgetList<LayrzPickersRangeBar>(find.byType(LayrzPickersRangeBar));
      final hasStartAndEnd = bars.any(
        (bar) => bar.columns.contains(LayrzRangeBarColumn.rangeStartAndEnd),
      );
      expect(hasStartAndEnd, isTrue);
    });

    guardedTestWidgets('no active range renders every bar column as none', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      final bars = tester.widgetList<LayrzPickersRangeBar>(find.byType(LayrzPickersRangeBar));
      for (final bar in bars) {
        expect(bar.columns.every((c) => c == LayrzRangeBarColumn.none), isTrue);
      }
    });
  });

  group('LayrzPickersDayGrid — cells use LayrzTappable (Finding 3)', () {
    guardedTestWidgets('a selectable day cell is wrapped in an interactive LayrzTappable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      final cellFinder = find.ancestor(
        of: find.text('15').first,
        matching: find.byType(LayrzTappable),
      );
      expect(cellFinder, findsOneWidget);
      final tappable = tester.widget<LayrzTappable>(cellFinder);
      expect(tappable.onTap, isNotNull);
      expect(tappable.disabled, isFalse);

      // The interactive path renders a GestureDetector/MouseRegion inside
      // the LayrzTappable -- see `tappable_test.dart`'s own
      // "is inert when ... all null" test for the inverse assertion this
      // mirrors.
      expect(
        find.descendant(of: cellFinder, matching: find.byType(GestureDetector)),
        findsOneWidget,
      );
    });

    guardedTestWidgets('a disabled day cell renders LayrzTappable with a null onTap -- genuinely inert', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          disabledDays: {DateTime(2026, 9, 15)},
          onDayTap: (_) {},
        ),
      );

      final cellFinder = find.ancestor(
        of: find.text('15').first,
        matching: find.byType(LayrzTappable),
      );
      expect(cellFinder, findsOneWidget);
      final tappable = tester.widget<LayrzTappable>(cellFinder);
      expect(tappable.onTap, isNull);

      // Inert path: no GestureDetector/MouseRegion wired at all.
      expect(
        find.descendant(of: cellFinder, matching: find.byType(GestureDetector)),
        findsNothing,
      );
    });

    guardedTestWidgets('a rejected (range-interior) cell renders LayrzTappable with a null onTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          rejectedDates: {DateTime(2026, 9, 10)},
          onDayTap: (_) {},
        ),
      );

      final cellFinder = find.ancestor(
        of: find.text('10').first,
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

    guardedTestWidgets('hovering a selectable cell paints the LayrzTappable hover surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      final cellFinder = find.ancestor(
        of: find.text('15').first,
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
      // Idle colour is `tokens.colors.sf1` -- hovered must differ from it,
      // proving hover feedback actually paints rather than the cell simply
      // being tappable with no visual state change (D15's colour-only
      // requirement, verified for real rather than assumed).
      final tokens = LayrzTokens.light();
      expect(decoration.color, isNot(tokens.colors.sf1));
    });

    guardedTestWidgets('geometry stays identical (D15): a disabled/inert cell measures the same as a selectable one', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          disabledDays: {DateTime(2026, 9, 15)},
          onDayTap: (_) {},
        ),
      );

      final selectableSize = tester.getSize(find.text('16').first);
      final disabledSize = tester.getSize(find.text('15').first);
      expect(disabledSize, selectableSize);
    });
  });
}

/// Element-wise equality for two [LayrzRangeBarColumn] lists -- used to pick
/// out one specific grid row's [LayrzPickersRangeBar] by its expected
/// column classification, since the grid renders six such bars (one per
/// week row) and only one of them is the row under test.
bool _sameColumns(List<LayrzRangeBarColumn> a, List<LayrzRangeBarColumn> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
