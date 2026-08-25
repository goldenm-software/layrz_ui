import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/app/app.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_input.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_picker_panel.dart';
import 'package:layrz_ui/src/inputs/src/duration/duration_unit.dart';
import 'package:layrz_ui/src/inputs/src/number/number_input.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/theme/theme.dart';

import '../../helpers/pump_themed.dart';

/// An [LayrzUiL10n] override that replaces every duration unit field label —
/// long-form (compact) and short-form (desktop), singular and plural alike —
/// with [suffix], a deliberately non-English synthetic string.
///
/// Used to prove the picker's layout survives realistic (or worse) locale
/// lengths, instead of only ever exercising the English default — the
/// English "Days"/"Hours"/"Minutes"/"Seconds" (compact) and "d"/"h"/"m"/"s"
/// (desktop) are not what a Spanish or Portuguese device renders
/// (`layrz_ui_i18n` supplies those), and a test that only passes the English
/// case proves the least interesting thing available. Overriding every key
/// this widget reads, not just the long-form ones, means the same override
/// pins both bands regardless of which key set a given band happens to use.
class _SyntheticSuffixL10n extends LayrzUiL10n {
  /// Creates an override that reports [suffix] for every duration field key,
  /// long-form or short-form, singular or plural.
  const _SyntheticSuffixL10n(this.suffix);

  /// The synthetic suffix returned for every duration unit field getter.
  final String suffix;

  @override
  String get durationFieldDay => suffix;

  @override
  String get durationFieldHour => suffix;

  @override
  String get durationFieldMinute => suffix;

  @override
  String get durationFieldSecond => suffix;

  @override
  String get durationUnitDayShortSingular => suffix;

  @override
  String get durationUnitDayShortPlural => suffix;

  @override
  String get durationUnitHourShortSingular => suffix;

  @override
  String get durationUnitHourShortPlural => suffix;

  @override
  String get durationUnitMinuteShortSingular => suffix;

  @override
  String get durationUnitMinuteShortPlural => suffix;

  @override
  String get durationUnitSecondShortSingular => suffix;

  @override
  String get durationUnitSecondShortPlural => suffix;
}

/// A [LocalizationsDelegate] that always resolves to a [_SyntheticSuffixL10n]
/// carrying [suffix], regardless of locale.
class _SyntheticSuffixL10nDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  /// Creates a delegate that always resolves to [_SyntheticSuffixL10n]([suffix]).
  const _SyntheticSuffixL10nDelegate(this.suffix);

  /// The synthetic suffix the resolved [LayrzUiL10n] reports for every field.
  final String suffix;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LayrzUiL10n> load(Locale locale) => SynchronousFuture<LayrzUiL10n>(_SyntheticSuffixL10n(suffix));

  @override
  bool shouldReload(_SyntheticSuffixL10nDelegate old) => old.suffix != suffix;
}

/// An [LayrzUiL10n] override whose short-form singular and plural duration
/// keys are deliberately distinct strings, so a test can tell which one a
/// build actually selected — English's real short forms ('d'/'h'/'m'/'s')
/// are identical for singular and plural, so they cannot prove the selector
/// logic runs at all, only that some string rendered.
class _DistinctShortPluralL10n extends LayrzUiL10n {
  /// Creates the singular/plural-distinguishing override.
  const _DistinctShortPluralL10n();

  /// The string every short-form *singular* getter reports.
  static const singular = '1u';

  /// The string every short-form *plural* getter reports.
  static const plural = 'Nu';

  @override
  String get durationUnitDayShortSingular => singular;

  @override
  String get durationUnitDayShortPlural => plural;

  @override
  String get durationUnitHourShortSingular => singular;

  @override
  String get durationUnitHourShortPlural => plural;

  @override
  String get durationUnitMinuteShortSingular => singular;

  @override
  String get durationUnitMinuteShortPlural => plural;

  @override
  String get durationUnitSecondShortSingular => singular;

  @override
  String get durationUnitSecondShortPlural => plural;
}

/// A [LocalizationsDelegate] that always resolves to a
/// [_DistinctShortPluralL10n], regardless of locale.
class _DistinctShortPluralL10nDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  /// Creates a delegate that always resolves to [_DistinctShortPluralL10n].
  const _DistinctShortPluralL10nDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LayrzUiL10n> load(Locale locale) => SynchronousFuture<LayrzUiL10n>(const _DistinctShortPluralL10n());

  @override
  bool shouldReload(_DistinctShortPluralL10nDelegate old) => false;
}

/// Pumps the real [LayrzDurationInput] at a desktop viewport and opens its
/// desktop anchored panel, optionally overriding l10n via [delegate] and
/// seeding the fields via [value].
///
/// Deliberately routes through the real [LayrzDurationInput] rather than
/// pumping [LayrzDurationPickerPanel] bare at the full viewport width, to
/// reproduce the actual constraint the picker renders under in production:
/// `LayrzDurationInput`'s anchored panel is `contentSized` with
/// `maxWidth: 480` (`duration_input.dart`), so the panel's real available
/// width is capped well below the bare viewport — 227px per field at the
/// time of writing, not whatever the 1600px test viewport alone would give.
/// A pin test that skips this indirection risks proving a width, or a key
/// selection, the picker never actually renders at.
Future<void> _pumpDesktopAnchored(
  WidgetTester tester, {
  LocalizationsDelegate<LayrzUiL10n>? delegate,
  Duration? value,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    LayrzApp(
      home: Center(
        child: LayrzDurationInput(labelText: 'Duration', value: value),
      ),
      theme: LayrzThemeData.light(),
      localizationsDelegates: delegate == null ? null : [delegate],
      debugShowCheckedModeBanner: false,
    ),
  );
  await tester.pump();

  await tester.tap(find.byType(LayrzInputChrome));
  await tester.pumpAndSettle();
}

/// Convenience wrapper over [_pumpDesktopAnchored] that replaces every
/// duration field's [LayrzNumberInput.suffixText] source key with [suffix].
Future<void> _pumpDesktopAnchoredWithSuffix(WidgetTester tester, {required String suffix}) {
  return _pumpDesktopAnchored(tester, delegate: _SyntheticSuffixL10nDelegate(suffix));
}

/// Pumps the real [LayrzDurationInput] at a compact (mobile) viewport and
/// opens its compact bottom-sheet picker, optionally overriding l10n via
/// [delegate] and seeding the fields via [value].
///
/// The compact path routes through `LayrzBottomSheet` rather than the
/// desktop anchored panel's `maxWidth: 480` cap, so — unlike the desktop
/// case — this is not expected to be as tight. It still goes through the
/// real end-to-end flow rather than the bare panel, so that claim rests on
/// a measurement, not an inference from the desktop finding.
Future<void> _pumpMobileSheet(
  WidgetTester tester, {
  LocalizationsDelegate<LayrzUiL10n>? delegate,
  Duration? value,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    LayrzApp(
      home: Center(
        child: LayrzDurationInput(labelText: 'Duration', value: value),
      ),
      theme: LayrzThemeData.light(),
      localizationsDelegates: delegate == null ? null : [delegate],
      debugShowCheckedModeBanner: false,
    ),
  );
  await tester.pump();

  await tester.tap(find.byType(LayrzInputChrome));
  await tester.pumpAndSettle();
}

/// Convenience wrapper over [_pumpMobileSheet] that replaces every duration
/// field's [LayrzNumberInput.suffixText] source key with [suffix].
Future<void> _pumpMobileSheetWithSuffix(WidgetTester tester, {required String suffix}) {
  return _pumpMobileSheet(tester, delegate: _SyntheticSuffixL10nDelegate(suffix));
}

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

    testWidgets(
      'carries the unit label as suffixText, not as a separate sibling widget (compact, long form)',
      (tester) async {
        await _pumpPanel(tester, viewportSize: _compactViewport, visibleUnits: _allUnits);

        final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
        expect(day.suffixText, 'Days');
        expect(day.suffix, isNull);
        expect(day.suffixIcon, isNull);
      },
    );

    testWidgets('carries the abbreviated unit label as suffixText on desktop (short form)', (tester) async {
      await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'd');
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

  group('LayrzDurationPickerPanel band-dependent key selection', () {
    // The resolution of the locale-length findings below: compact has 16
    // characters of headroom (no realistic word gets close), so it keeps
    // the long-form durationField* keys unabridged. Desktop has only 7, and
    // real translations of "seconds" are 8 characters in at least four major
    // European languages, so desktop reads the short, count-aware
    // durationUnit*Short{Singular,Plural} keys instead. Asserted through the
    // real end-to-end flow (tap -> sheet / anchored panel), with the actual
    // default English keys — no l10n override — since this is about which
    // *keys* each band reads, not about a synthetic width stress case.

    testWidgets('compact renders the long-form field label as suffixText, through the real sheet flow', (
      tester,
    ) async {
      await _pumpMobileSheet(tester, value: const Duration(days: 2));

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'Days', reason: 'compact has 16 characters of headroom — keeps the long form');
    });

    testWidgets('desktop renders the short-form abbreviated label as suffixText, through the real anchored flow', (
      tester,
    ) async {
      await _pumpDesktopAnchored(tester, value: const Duration(days: 2));

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'd', reason: 'desktop has only 7 characters of headroom — abbreviates');
    });

    testWidgets('desktop picks the short-form SINGULAR key when the field count is exactly 1', (tester) async {
      await _pumpDesktopAnchored(
        tester,
        delegate: const _DistinctShortPluralL10nDelegate(),
        value: const Duration(days: 1, hours: 1, minutes: 1, seconds: 1),
      );

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      final hour = tester.widget<LayrzNumberInput>(_numberInputUnder(_hourKey));
      final minute = tester.widget<LayrzNumberInput>(_numberInputUnder(_minuteKey));
      final second = tester.widget<LayrzNumberInput>(_numberInputUnder(_secondKey));
      expect(day.suffixText, _DistinctShortPluralL10n.singular);
      expect(hour.suffixText, _DistinctShortPluralL10n.singular);
      expect(minute.suffixText, _DistinctShortPluralL10n.singular);
      expect(second.suffixText, _DistinctShortPluralL10n.singular);
    });

    testWidgets('desktop picks the short-form PLURAL key when the field count is 0 or greater than 1', (
      tester,
    ) async {
      await _pumpDesktopAnchored(
        tester,
        delegate: const _DistinctShortPluralL10nDelegate(),
        value: const Duration(days: 2, hours: 0, minutes: 5, seconds: 0),
      );

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      final hour = tester.widget<LayrzNumberInput>(_numberInputUnder(_hourKey));
      final minute = tester.widget<LayrzNumberInput>(_numberInputUnder(_minuteKey));
      final second = tester.widget<LayrzNumberInput>(_numberInputUnder(_secondKey));
      expect(day.suffixText, _DistinctShortPluralL10n.plural, reason: '2 days is plural');
      expect(hour.suffixText, _DistinctShortPluralL10n.plural, reason: '0 hours is plural');
      expect(minute.suffixText, _DistinctShortPluralL10n.plural, reason: '5 minutes is plural');
      expect(second.suffixText, _DistinctShortPluralL10n.plural, reason: '0 seconds is plural');
    });

    testWidgets('compact fits an 8+ character REAL locale word — the premise the decision rests on', (
      tester,
    ) async {
      // Spanish "Segundos" — the exact real word that overflows desktop.
      // Compact having room for it, not merely a same-length synthetic
      // filler, is why compact keeps the long form at all.
      await _pumpMobileSheetWithSuffix(tester, suffix: 'Segundos');

      expect(tester.takeException(), isNull, reason: '"Segundos" (8 chars) must fit the compact column');
      final secondRect = tester.getRect(find.byKey(_secondKey));
      final dayRect = tester.getRect(find.byKey(_dayKey));
      expect(secondRect.width, closeTo(dayRect.width, 0.5));
    });
  });

  group('LayrzDurationPickerPanel locale-length safety', () {
    // These pin measured character-length thresholds rather than the English
    // default, per the false-green lesson elsewhere in this run: a test that
    // only exercises "Days"/"Hours"/"Minutes"/"Seconds" proves nothing about
    // what a Spanish or Portuguese build actually renders through
    // `layrz_ui_i18n`, since those keys are translated, not literal in this
    // repo. Measured directly (temporary probes, deleted): at the real
    // desktop anchored-panel width (227px, sm: 6, two columns), a 7-char
    // synthetic suffix fits and an 8-char one ("Segundos", "Secondes",
    // "Sekunden" among them) overflows. At the real compact width (380px,
    // xs: 12, one column), 16 characters fit and 18 do not — comfortably
    // roomy for any real locale. This is precisely why the band-dependent
    // key selection above exists: desktop's 7-character capacity is what
    // makes the short keys necessary there, not a style preference.

    testWidgets(
      'a 7-char synthetic suffix (the measured safe boundary) fits the real compact bottom-sheet flow',
      (tester) async {
        await _pumpMobileSheetWithSuffix(tester, suffix: 'Zzzzzzz'); // 7 chars, not the English default

        expect(tester.takeException(), isNull, reason: '7-char labels must fit the compact (xs: 12) column');
        final dayRect = tester.getRect(find.byKey(_dayKey));
        final secondRect = tester.getRect(find.byKey(_secondKey));
        expect(dayRect.width, closeTo(secondRect.width, 0.5));
      },
    );

    testWidgets(
      'a 7-char synthetic suffix (the measured safe boundary) fits the real desktop anchored-panel flow',
      (tester) async {
        await _pumpDesktopAnchoredWithSuffix(tester, suffix: 'Zzzzzzz'); // 7 chars, not the English default

        expect(
          tester.takeException(),
          isNull,
          reason: '7-char labels must fit the wide (sm: 6) two-column row at the anchor\'s real, capped width',
        );
        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        expect(dayRect.top, closeTo(hourRect.top, 0.5), reason: 'still two per row, not forced to wrap');
      },
    );

    testWidgets(
      'CAPACITY TRIP-WIRE: desktop layout still cannot take an 8-char suffix — this is WHY the short '
      'keys are used there, not merely a fact about it',
      (tester) async {
        await _pumpDesktopAnchoredWithSuffix(tester, suffix: 'Zzzzzzzz'); // 8 chars, one over the safe boundary

        // This assertion is deliberately inverted: it pins the desktop
        // *layout's* character capacity, which has not changed and is not
        // what the band-dependent key selection above touched. What changed
        // is that desktop no longer *feeds* this layout an 8-character
        // string — it now reads the short durationUnit*Short{Singular,
        // Plural} keys precisely because this capacity ceiling exists.
        //
        // If this ever starts passing (the anchor's width cap grows, this
        // row's padding/spacing gets more room, or the fields' internal
        // chrome changes), desktop's capacity would clear 8 characters and
        // the long-form keys become viable there again — at which point
        // this test should be inverted back to isNull, and the
        // band-dependent key selection above should be reconsidered rather
        // than left as a now-unnecessary abbreviation.
        expect(
          tester.takeException(),
          isNotNull,
          reason:
              'desktop layout capacity is currently 7 characters, not 8+; if this starts passing, the '
              'capacity grew and the short-key decision above should be revisited',
        );
      },
    );
  });
}
