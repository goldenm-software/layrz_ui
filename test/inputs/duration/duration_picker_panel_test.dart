import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_picker_panel.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_unit.dart';
import 'package:layrz_ui/src/inputs/src/number/number_input.dart';

import '../../helpers/pump_themed.dart';

/// The [ValueKey]s assigned to each unit's [LayrzCol] wrapper inside
/// [LayrzDurationPickerPanel], mirroring the keys the panel assigns internally.
const _dayKey = ValueKey('layrz_duration_field_day');
const _hourKey = ValueKey('layrz_duration_field_hour');
const _minuteKey = ValueKey('layrz_duration_field_minute');
const _secondKey = ValueKey('layrz_duration_field_second');

/// The full set of duration units, used by tests that want every field visible.
const _allUnits = {
  LayrzDurationUnit.day,
  LayrzDurationUnit.hour,
  LayrzDurationUnit.minute,
  LayrzDurationUnit.second,
};

/// A compact (`xs` band, < 600px) viewport size used by the layout tests,
/// matching the real mobile viewport this repo's other input suites test at
/// (e.g. `select_input_test.dart`). One field per row at this band (D-f,
/// amended) leaves each field the full 400px width minus panel padding —
/// wide enough for every [LayrzNumberInput.suffixText] unit word, including
/// "Minutes"/"Seconds", to render without the internal overflow a two-column
/// compact layout produced at this width (measured and reported separately).
const _compactViewport = Size(400, 800);

/// A `sm`-band-and-above viewport width, matching the desktop viewport this
/// repo's other input suites use for their "desktop" cases.
const _wideViewport = Size(1600, 1200);

/// Pumps [LayrzDurationPickerPanel] at the given viewport, letting its own
/// [Center] ancestor (from [pumpThemed]) bound its width to the real,
/// physical test viewport — no artificial [SizedBox] or [MediaQuery]
/// override, both of which can desynchronize the row's breakpoint-band
/// selection from the width it is actually laid out with.
Future<void> _pumpPanel(
  WidgetTester tester, {
  required Size viewportSize,
  required Set<LayrzDurationUnit> visibleUnits,
  Duration? initialValue,
  ValueChanged<Duration?>? onChanged,
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await pumpThemed(
    tester,
    LayrzDurationPickerPanel(
      initialValue: initialValue,
      visibleUnits: visibleUnits,
      onChanged: onChanged ?? (_) {},
    ),
  );
}

/// Finds the [LayrzNumberInput] nested inside the field wrapper carrying [fieldKey].
Finder _numberInputUnder(Key fieldKey) {
  return find.descendant(of: find.byKey(fieldKey), matching: find.byType(LayrzNumberInput));
}

void main() {
  group('LayrzDurationPickerPanel layout', () {
    group('compact viewport (xs band, < 600px)', () {
      testWidgets('stacks all four fields one per row, in day/hour/minute/second order, with no overflow', (
        tester,
      ) async {
        // This is the exact scenario a 2-column compact layout could not render: all
        // four units, including "Minutes"/"Seconds", at a real 400px phone width. If
        // any field overflows, `tester.takeException()` below fails the test.
        await _pumpPanel(tester, viewportSize: _compactViewport, visibleUnits: _allUnits);
        expect(tester.takeException(), isNull, reason: 'no field should overflow at a real 400px phone width');

        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        final minuteRect = tester.getRect(find.byKey(_minuteKey));
        final secondRect = tester.getRect(find.byKey(_secondKey));

        // Every field shares the same left edge (one column) ...
        expect(hourRect.left, closeTo(dayRect.left, 0.5));
        expect(minuteRect.left, closeTo(dayRect.left, 0.5));
        expect(secondRect.left, closeTo(dayRect.left, 0.5));

        // ... and each is strictly below the previous one, in enum order.
        expect(hourRect.top, greaterThan(dayRect.top));
        expect(minuteRect.top, greaterThan(hourRect.top));
        expect(secondRect.top, greaterThan(minuteRect.top));

        // A full-width (xs: 12) column spans (nearly) the whole panel width.
        expect(dayRect.width, closeTo(hourRect.width, 0.5));
        expect(dayRect.width, greaterThan(300.0), reason: 'a full-width compact column should be close to 400px');
      });

      testWidgets('fields are not squeezed into a forced square cell', (tester) async {
        await _pumpPanel(tester, viewportSize: _compactViewport, visibleUnits: _allUnits);

        final dayRect = tester.getRect(find.byKey(_dayKey));

        // The old childAspectRatio: 1.0 forced a square (measured 90x90 on compact).
        // A number input row is short and wide; its width must dwarf its height.
        expect(
          dayRect.width,
          greaterThan(dayRect.height * 2),
          reason: 'field width should be much larger than height, unlike a forced-square cell',
        );
      });
    });

    group('wide viewport (sm band and above, >= 600px)', () {
      testWidgets('lays out fields two per row, in day/hour/minute/second order (span change applies)', (
        tester,
      ) async {
        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        final minuteRect = tester.getRect(find.byKey(_minuteKey));
        final secondRect = tester.getRect(find.byKey(_secondKey));

        // Row 1: day and hour share the same top edge, day to the left of hour.
        expect(dayRect.top, closeTo(hourRect.top, 0.5), reason: 'day and hour should share visual row 1');
        expect(dayRect.left, lessThan(hourRect.left));

        // Row 2: minute and second share the same top edge, below row 1, minute left of second.
        expect(minuteRect.top, closeTo(secondRect.top, 0.5), reason: 'minute and second should share visual row 2');
        expect(minuteRect.top, greaterThan(dayRect.top), reason: 'row 2 must be below row 1');
        expect(minuteRect.left, lessThan(secondRect.left));

        // The two-column grid lines up vertically: day/minute share the left column,
        // hour/second share the right column. This is the span change (xs: 12 -> sm: 6)
        // actually taking effect, not merely a breakpoint value nobody exercised.
        expect(dayRect.left, closeTo(minuteRect.left, 0.5), reason: 'day and minute share the left column');
        expect(hourRect.left, closeTo(secondRect.left, 0.5), reason: 'hour and second share the right column');

        // Two equal-span (sm: 6) columns in the same row must be equal width.
        expect(dayRect.width, closeTo(hourRect.width, 0.5));
        expect(minuteRect.width, closeTo(secondRect.width, 0.5));
      });

      testWidgets('field height does not scale proportionally with column width (no forced square)', (
        tester,
      ) async {
        await _pumpPanel(tester, viewportSize: _compactViewport, visibleUnits: _allUnits);
        final compactRect = tester.getRect(find.byKey(_dayKey));

        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);
        final wideRect = tester.getRect(find.byKey(_dayKey));

        // Width changes substantially with the column count (one-per-row on compact vs.
        // two-per-row on wide), so a forced-square layout would make height track it.
        // Height instead only shifts by the compact-vs-regular comfortable-density
        // padding delta (pd3 10px -> pd2 14px per side, ~8px total) — not by anything
        // resembling the width's change — confirming height is intrinsic to content
        // and density, never to the column's width.
        expect(
          wideRect.width,
          isNot(closeTo(compactRect.width, 50.0)),
          reason: 'column widths should genuinely differ',
        );
        expect(wideRect.height, closeTo(compactRect.height, 10.0), reason: 'height should track density, not width');
      });
    });

    group('visibleUnits subset', () {
      testWidgets('only the requested units render as fields', (tester) async {
        await _pumpPanel(
          tester,
          viewportSize: _wideViewport,
          visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
        );

        expect(find.byKey(_dayKey), findsNothing);
        expect(find.byKey(_hourKey), findsOneWidget);
        expect(find.byKey(_minuteKey), findsOneWidget);
        expect(find.byKey(_secondKey), findsNothing);
      });

      testWidgets('two visible units still lay out side by side', (tester) async {
        await _pumpPanel(
          tester,
          viewportSize: _wideViewport,
          visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
        );

        final hourRect = tester.getRect(find.byKey(_hourKey));
        final minuteRect = tester.getRect(find.byKey(_minuteKey));

        expect(hourRect.top, closeTo(minuteRect.top, 0.5));
        expect(hourRect.left, lessThan(minuteRect.left));
      });

      testWidgets('a single visible unit renders exactly one field', (tester) async {
        await _pumpPanel(
          tester,
          viewportSize: _wideViewport,
          visibleUnits: const {LayrzDurationUnit.second},
        );

        expect(find.byType(LayrzNumberInput), findsOneWidget);
        expect(find.byKey(_secondKey), findsOneWidget);
      });

      testWidgets('an empty visibleUnits set renders no fields but keeps the reset button', (tester) async {
        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: const {});

        expect(find.byType(LayrzNumberInput), findsNothing);
        expect(find.byType(LayrzButton), findsOneWidget, reason: 'the reset button renders regardless of field count');
      });
    });
  });

  group('LayrzDurationPickerPanel value binding', () {
    testWidgets('initializes each field from initialValue', (tester) async {
      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        initialValue: const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
      );

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      final hour = tester.widget<LayrzNumberInput>(_numberInputUnder(_hourKey));
      final minute = tester.widget<LayrzNumberInput>(_numberInputUnder(_minuteKey));
      final second = tester.widget<LayrzNumberInput>(_numberInputUnder(_secondKey));

      expect(day.value, 1.0);
      expect(hour.value, 2.0);
      expect(minute.value, 3.0);
      expect(second.value, 4.0);
    });

    testWidgets('defaults every field to zero when initialValue is null', (tester) async {
      await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.value, 0.0);
    });

    testWidgets('carries the unit label as suffixText, not as a separate sibling widget', (tester) async {
      await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'Days');
      expect(day.suffix, isNull);
      expect(day.suffixIcon, isNull);
    });

    testWidgets('changing the hour field recomputes and reports the full duration', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        initialValue: const Duration(hours: 2, minutes: 30),
        onChanged: (value) => reported = value,
      );

      final hourInput = tester.widget<LayrzNumberInput>(_numberInputUnder(_hourKey));
      hourInput.onChanged?.call(5);
      await tester.pump();

      expect(reported, const Duration(hours: 5, minutes: 30));
    });

    testWidgets('reset zeroes every field and reports Duration.zero', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        initialValue: const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
        onChanged: (value) => reported = value,
      );

      await tester.tap(find.byType(LayrzButton));
      await tester.pump();

      expect(reported, Duration.zero);

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      final hour = tester.widget<LayrzNumberInput>(_numberInputUnder(_hourKey));
      final minute = tester.widget<LayrzNumberInput>(_numberInputUnder(_minuteKey));
      final second = tester.widget<LayrzNumberInput>(_numberInputUnder(_secondKey));
      expect(day.value, 0.0);
      expect(hour.value, 0.0);
      expect(minute.value, 0.0);
      expect(second.value, 0.0);
    });

    testWidgets('minute field clamps changes to 0-59', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        onChanged: (value) => reported = value,
      );

      final minuteInput = tester.widget<LayrzNumberInput>(_numberInputUnder(_minuteKey));
      minuteInput.onChanged?.call(120);
      await tester.pump();

      expect(reported, const Duration(minutes: 59));
    });

    testWidgets('second field clamps changes to 0-59', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        onChanged: (value) => reported = value,
      );

      final secondInput = tester.widget<LayrzNumberInput>(_numberInputUnder(_secondKey));
      secondInput.onChanged?.call(90);
      await tester.pump();

      expect(reported, const Duration(seconds: 59));
    });

    testWidgets('hour field clamps changes to 0-23', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        onChanged: (value) => reported = value,
      );

      final hourInput = tester.widget<LayrzNumberInput>(_numberInputUnder(_hourKey));
      hourInput.onChanged?.call(30);
      await tester.pump();

      expect(reported, const Duration(hours: 23));
    });

    testWidgets('day field has no upper clamp', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        onChanged: (value) => reported = value,
      );

      final dayInput = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      dayInput.onChanged?.call(400);
      await tester.pump();

      expect(reported, const Duration(days: 400));
    });

    testWidgets('a null onChanged callback value falls back to zero for that field', (tester) async {
      Duration? reported;

      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        initialValue: const Duration(days: 3),
        onChanged: (value) => reported = value,
      );

      final dayInput = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      dayInput.onChanged?.call(null);
      await tester.pump();

      expect(reported, Duration.zero);
    });
  });
}
