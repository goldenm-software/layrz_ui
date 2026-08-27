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

import '../../helpers/no_overflow.dart';
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
/// desktop anchored panel, optionally overriding l10n via [delegate],
/// seeding the fields via [value], and constraining the anchor field's own
/// width via [anchorWidth].
///
/// Deliberately routes through the real [LayrzDurationInput] rather than
/// pumping [LayrzDurationPickerPanel] bare at the full viewport width, to
/// reproduce the actual constraint the picker renders under in production.
/// `LayrzDurationInput`'s anchored panel is `matchAnchor`
/// (`duration_input.dart`), so the panel's real available width tracks
/// whatever width the anchor field itself renders at -- there is no longer a
/// fixed cap the picker can be tested against independent of the caller's
/// own layout. [anchorWidth], when supplied, constrains the anchor (and so
/// the panel) to that width via a [SizedBox]; when null, the anchor is left
/// to size to the full 1200px viewport under [Center]. A pin test that skips
/// this indirection risks proving a width, or a key selection, the picker
/// never actually renders at.
Future<void> _pumpDesktopAnchored(
  WidgetTester tester, {
  LocalizationsDelegate<LayrzUiL10n>? delegate,
  Duration? value,
  double? anchorWidth,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final anchor = LayrzDurationInput(labelText: 'Duration', value: value);

  await tester.pumpWidget(
    LayrzApp(
      home: Center(
        child: anchorWidth == null ? anchor : SizedBox(width: anchorWidth, child: anchor),
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
/// duration field's [LayrzNumberInput.suffixText] source key with [suffix],
/// optionally constraining the anchor field's own width via [anchorWidth].
Future<void> _pumpDesktopAnchoredWithSuffix(WidgetTester tester, {required String suffix, double? anchorWidth}) {
  return _pumpDesktopAnchored(tester, delegate: _SyntheticSuffixL10nDelegate(suffix), anchorWidth: anchorWidth);
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
      guardedTestWidgets('stacks all four fields one per row, in day/hour/minute/second order, with no overflow', (
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

      guardedTestWidgets('fields are not squeezed into a forced square cell', (tester) async {
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
      // Replaces the old fixed two-column assertion: the panel no longer picks its
      // column count from a viewport breakpoint (see the class doc on
      // `LayrzDurationPickerPanel` for why -- `matchAnchor` removed the fixed
      // 280.0-480.0 width cap this depended on). At `_wideViewport`'s 1600px, all
      // four ~390px-wide fields comfortably clear `_kFieldMinWidth` (200.0) on one
      // row, so "fill the available width" now means all four sit side by side
      // instead of wrapping into two rows of two.
      guardedTestWidgets('lays out all four fields on one row when the panel is wide enough, in day/hour/minute/second '
          'order, evenly filling the width', (
        tester,
      ) async {
        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        final minuteRect = tester.getRect(find.byKey(_minuteKey));
        final secondRect = tester.getRect(find.byKey(_secondKey));

        // All four fields share the same visual row ...
        expect(hourRect.top, closeTo(dayRect.top, 0.5), reason: 'day and hour should share the same row');
        expect(minuteRect.top, closeTo(dayRect.top, 0.5), reason: 'minute should share the same row as day');
        expect(secondRect.top, closeTo(dayRect.top, 0.5), reason: 'second should share the same row as day');

        // ... in day/hour/minute/second order, left to right ...
        expect(dayRect.left, lessThan(hourRect.left));
        expect(hourRect.left, lessThan(minuteRect.left));
        expect(minuteRect.left, lessThan(secondRect.left));

        // ... each clearing the minimum usable width ...
        expect(dayRect.width, greaterThanOrEqualTo(200.0));

        // ... and, since all four are on one row, each is given an equal share of
        // the available width -- "fill the available width", not merely "stay
        // above the minimum and leave the rest empty".
        expect(dayRect.width, closeTo(hourRect.width, 0.5));
        expect(minuteRect.width, closeTo(secondRect.width, 0.5));
        expect(dayRect.width, closeTo(minuteRect.width, 0.5));
      });

      guardedTestWidgets('wraps to two rows of two fields when the panel is too narrow for all four at the minimum '
          'width, still evenly filling each row', (
        tester,
      ) async {
        // 460px: two 200px-minimum fields plus the 6px inter-field gap fit
        // (2*200 + 6 = 406 <= availableWidth after the panel's own sp2 padding),
        // but a third does not (3*200 + 2*6 = 612 > availableWidth). This is the
        // exact "never shrink a field below its minimum, wrap instead" scenario
        // the maintainer asked for, reproduced at a width the four-field row
        // above does not exercise.
        await _pumpPanel(tester, viewportSize: const Size(460, 800), visibleUnits: _allUnits);
        expect(tester.takeException(), isNull, reason: 'no field should overflow when wrapping to two rows');

        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        final minuteRect = tester.getRect(find.byKey(_minuteKey));
        final secondRect = tester.getRect(find.byKey(_secondKey));

        // Row 1: day and hour.
        expect(hourRect.top, closeTo(dayRect.top, 0.5), reason: 'day and hour should share visual row 1');
        expect(dayRect.left, lessThan(hourRect.left));

        // Row 2: minute and second, below row 1.
        expect(secondRect.top, closeTo(minuteRect.top, 0.5), reason: 'minute and second should share visual row 2');
        expect(minuteRect.top, greaterThan(dayRect.top), reason: 'row 2 must be below row 1');
        expect(minuteRect.left, lessThan(secondRect.left));

        // Neither field drops below the usable minimum ...
        expect(dayRect.width, greaterThanOrEqualTo(200.0));
        expect(minuteRect.width, greaterThanOrEqualTo(200.0));

        // ... and each row's two fields still evenly fill that row's width, rather
        // than sitting at the bare minimum with empty trailing space.
        expect(dayRect.width, closeTo(hourRect.width, 0.5));
        expect(minuteRect.width, closeTo(secondRect.width, 0.5));
      });

      guardedTestWidgets('field height does not scale proportionally with column width (no forced square)', (
        tester,
      ) async {
        // Compact stays a genuine single-field-per-row case (400px, well under two
        // fields' combined minimum). The "wide" case now needs an explicit narrow
        // viewport (460px) rather than `_wideViewport` -- at `_wideViewport`'s
        // 1600px, all four fields fit one row and each is given nearly the same
        // generous per-field width as the compact single-column case, which would
        // no longer exercise "column widths should genuinely differ". 460px instead
        // forces two fields per row (see the wrap test above), giving a narrower,
        // genuinely different per-field width to compare against.
        await _pumpPanel(tester, viewportSize: _compactViewport, visibleUnits: _allUnits);
        final compactRect = tester.getRect(find.byKey(_dayKey));

        await _pumpPanel(tester, viewportSize: const Size(460, 800), visibleUnits: _allUnits);
        final wideRect = tester.getRect(find.byKey(_dayKey));

        // Width changes substantially with the column count (one-per-row on compact vs.
        // two-per-row when wrapped), so a forced-square layout would make height track it.
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
      guardedTestWidgets('only the requested units render as fields', (tester) async {
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

      guardedTestWidgets('two visible units still lay out side by side', (tester) async {
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

      guardedTestWidgets('a single visible unit renders exactly one field', (tester) async {
        await _pumpPanel(
          tester,
          viewportSize: _wideViewport,
          visibleUnits: const {LayrzDurationUnit.second},
        );

        expect(find.byType(LayrzNumberInput), findsOneWidget);
        expect(find.byKey(_secondKey), findsOneWidget);
      });

      guardedTestWidgets('an empty visibleUnits set renders no fields but keeps the reset button', (tester) async {
        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: const {});

        expect(find.byType(LayrzNumberInput), findsNothing);
        expect(find.byType(LayrzButton), findsOneWidget, reason: 'the reset button renders regardless of field count');
      });
    });
  });

  group('LayrzDurationPickerPanel value binding', () {
    guardedTestWidgets('initializes each field from initialValue', (tester) async {
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

    // Regression for a device-reported bug: every unit field rendered its
    // value with a trailing ".0" ("0.0" Days, "2.0" Hours, "30.0" Minutes,
    // "0.0" Seconds) even though duration components are always whole
    // numbers -- there is no fractional hour once minutes are their own
    // field. Root cause was `LayrzNumberInput.value` being fed a `double`
    // (`_hour.toDouble()`) with no `format` override, so
    // `LayrzNumberInput._formatNumber` fell through to `num.toString()`,
    // which always renders a decimal point for a `double`. Asserts the
    // actual rendered `EditableText` content, not `LayrzNumberInput.value`
    // (a `num?`, where `2 == 2.0`  and so cannot tell int and double display
    // apart -- see the numeric `.value` assertions above, which pass either
    // way and would not have caught this).
    guardedTestWidgets('renders unit field values as integers, not decimals', (tester) async {
      await _pumpPanel(
        tester,
        viewportSize: _wideViewport,
        visibleUnits: _allUnits,
        initialValue: const Duration(hours: 2, minutes: 30),
      );

      String textUnder(Key fieldKey) {
        final editable = tester.widget<EditableText>(
          find.descendant(of: find.byKey(fieldKey), matching: find.byType(EditableText)),
        );
        return editable.controller.text;
      }

      expect(textUnder(_dayKey), '0');
      expect(textUnder(_hourKey), '2');
      expect(textUnder(_minuteKey), '30');
      expect(textUnder(_secondKey), '0');
    });

    guardedTestWidgets('defaults every field to zero when initialValue is null', (tester) async {
      await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.value, 0.0);
    });

    guardedTestWidgets(
      'carries the unit label as suffixText, not as a separate sibling widget (compact, long form)',
      (tester) async {
        await _pumpPanel(tester, viewportSize: _compactViewport, visibleUnits: _allUnits);

        final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
        expect(day.suffixText, 'Days');
        expect(day.suffix, isNull);
        expect(day.suffixIcon, isNull);
      },
    );

    guardedTestWidgets('carries the abbreviated unit label as suffixText when the field is narrow (short form)', (
      tester,
    ) async {
      // The narrow/wide label split is now driven by the panel's own measured
      // per-field width (see `_kNarrowFieldWidth` on `duration_picker_panel.dart`),
      // not by a viewport breakpoint -- `_wideViewport` no longer produces a
      // narrow field once the panel spans its full available width (matchAnchor
      // removed the old 480.0 cap that used to force two cramped columns there).
      // A narrow *viewport* (260px) is used here purely as a vehicle to force a
      // narrow *field*, exactly as `_pumpPanel`'s own bare-panel flow requires.
      await _pumpPanel(tester, viewportSize: const Size(260, 800), visibleUnits: _allUnits);

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'd');
      expect(day.suffix, isNull);
      expect(day.suffixIcon, isNull);
    });

    guardedTestWidgets('changing the hour field recomputes and reports the full duration', (tester) async {
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

    guardedTestWidgets('reset zeroes every field and reports Duration.zero', (tester) async {
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

    guardedTestWidgets('minute field clamps changes to 0-59', (tester) async {
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

    guardedTestWidgets('second field clamps changes to 0-59', (tester) async {
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

    guardedTestWidgets('hour field clamps changes to 0-23', (tester) async {
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

    guardedTestWidgets('day field has no upper clamp', (tester) async {
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

    guardedTestWidgets('a null onChanged callback value falls back to zero for that field', (tester) async {
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
    // The resolution of the locale-length findings below: a field with at least
    // 16 characters of headroom keeps the long-form durationField* keys
    // unabridged; a field with only ~7 characters of headroom -- narrower than
    // `_kNarrowFieldWidth` -- reads the short, count-aware
    // durationUnit*Short{Singular,Plural} keys instead, since real translations
    // of "seconds" are 8 characters in at least four major European languages.
    // This split is now driven by the panel's own measured per-field width
    // (see `duration_picker_panel.dart`'s class doc), not by a viewport
    // breakpoint, so the "desktop" cases below constrain the anchor field's own
    // width (`anchorWidth`) to force a narrow field through the real anchored
    // flow -- `_pumpDesktopAnchored`'s default (a field spanning the full
    // viewport) no longer reproduces a narrow field on its own now that
    // `matchAnchor` removed the old fixed 480.0 cap. Asserted through the real
    // end-to-end flow (tap -> sheet / anchored panel), with the actual default
    // English keys — no l10n override — since this is about which *keys* each
    // width reads, not about a synthetic width stress case.

    /// An anchor width narrow enough that `LayrzDurationPickerPanel` renders
    /// one field per row at well under `_kNarrowFieldWidth` (280.0) per field
    /// -- see the "narrow anchor field" width tests in
    /// `duration_input_test.dart` for the same 320.0/240.0 style measurement
    /// this is based on.
    const narrowAnchorWidth = 260.0;

    guardedTestWidgets('compact renders the long-form field label as suffixText, through the real sheet flow', (
      tester,
    ) async {
      await _pumpMobileSheet(tester, value: const Duration(days: 2));

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'Days', reason: 'compact has 16 characters of headroom — keeps the long form');
    });

    guardedTestWidgets(
      'a narrow desktop anchor renders the short-form abbreviated label as suffixText, through the real '
      'anchored flow',
      (tester) async {
        await _pumpDesktopAnchored(tester, value: const Duration(days: 2), anchorWidth: narrowAnchorWidth);

        final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
        expect(day.suffixText, 'd', reason: 'a narrow field has only ~7 characters of headroom — abbreviates');
      },
    );

    guardedTestWidgets('a narrow desktop anchor picks the short-form SINGULAR key when the field count is exactly 1', (
      tester,
    ) async {
      await _pumpDesktopAnchored(
        tester,
        delegate: const _DistinctShortPluralL10nDelegate(),
        value: const Duration(days: 1, hours: 1, minutes: 1, seconds: 1),
        anchorWidth: narrowAnchorWidth,
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

    guardedTestWidgets('a narrow desktop anchor picks the short-form PLURAL key when the field count is 0 or greater '
        'than 1', (tester) async {
      await _pumpDesktopAnchored(
        tester,
        delegate: const _DistinctShortPluralL10nDelegate(),
        value: const Duration(days: 2, hours: 0, minutes: 5, seconds: 0),
        anchorWidth: narrowAnchorWidth,
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

    guardedTestWidgets('compact fits an 8+ character REAL locale word — the premise the decision rests on', (
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
    // repo. At the real compact width (380px, one column), 16 characters fit
    // and 18 do not — comfortably roomy for any real locale.
    //
    // RE-DERIVED for `matchAnchor` (previously pinned to a fixed 227px desktop
    // panel width -- see `duration_picker_panel.dart`'s class doc for why that
    // width no longer exists as a constant). The desktop case below now fixes
    // a concrete `anchorWidth` instead: since the panel's width is
    // caller-determined, the "measured safe boundary" is re-expressed as "at
    // this specific, still-realistic anchor width, a 7-char label fits and an
    // 8-char one overflows" -- the same underlying claim (a real capacity
    // ceiling exists, which is why the band-dependent key selection above
    // reads the short keys below `_kNarrowFieldWidth`), reproduced against the
    // new width mechanism.
    //
    // RE-DERIVED A SECOND TIME (2026-08-26) after `LayrzTextTheme.body.fontSize`
    // dropped 16 -> 14 and `_InputComfortableSpec` lost its `isCompact` branch
    // (both `53b8cf4`): both changes make text fit in less horizontal space,
    // so this group's previous anchor width of 250.0 stopped being narrow
    // enough to overflow an 8-char label at all -- capacity there grew from 7
    // characters to 8. Measured directly (temporary probes, deleted): the
    // 7-char/8-char boundary itself did not disappear, it moved narrower. A
    // synthetic 7-char suffix ('Zzzzzzz') fits from 224px up; a real 8-char
    // translation overflows through 236px and starts fitting at 238px. Note
    // English itself was never the constraint here -- the longest English
    // `durationField*` value is 7 characters ("Minutes"/"Seconds"), so it
    // always fit and fitting was never in question for it. What the 8-char
    // case protects is non-English translations: "Segundos" (Spanish),
    // "Secondes" (French) and "Sekunden" (German) are all 8 characters and
    // all still overflow in the [224px, 236px] window, confirmed individually.
    // `narrowAnchorWidth` below is re-derived to 230.0, centered in that
    // window (~6px of margin on each side against the two measured
    // boundaries, rather than sitting on either one) so the trip-wire keeps
    // pinning a real, reachable overflow rather than a boundary that no
    // longer exists at the old value. `layrz_ui_i18n` (the actual translation
    // package) is not checked out in this repo, so "Segundos"/"Secondes"/
    // "Sekunden" are the best available real-word evidence, not the full
    // locale set -- an untested translation could plausibly run a character
    // or two longer, which is itself part of why the short-form abbreviation
    // stays rather than being dropped now that English clears easily.
    //
    // If this trips again: re-run the same bisection (temporary probes,
    // deleted) against `_pumpDesktopAnchoredWithSuffix` for a 7-char
    // synthetic suffix and the real 8-char words above, at a spread of
    // `anchorWidth` values bracketing the current `narrowAnchorWidth`. If the
    // 7-char boundary and the 8-char boundary have drifted apart (capacity
    // widened), re-center `narrowAnchorWidth` in the new window the same way.
    // If capacity ever grows enough that even the real 8-char translations
    // stop overflowing at a realistic anchor width, that is the point flagged
    // by the trip-wire below: revisit whether the short-form abbreviation
    // (`durationUnit*Short{Singular,Plural}`) is still earning its place, per
    // the class doc comment on `_kNarrowFieldWidth` in
    // `duration_picker_panel.dart`.

    /// The concrete anchor width this group's desktop cases pin, chosen
    /// (temporary probes, deleted) as a width centered inside the window
    /// where a 7-char suffix fits and an 8-char one still overflows -- see
    /// the group doc comment above for the measured boundaries and the
    /// 2026-08-26 re-derivation.
    const narrowAnchorWidth = 230.0;

    guardedTestWidgets(
      'a 7-char synthetic suffix (the measured safe boundary) fits the real compact bottom-sheet flow',
      (tester) async {
        await _pumpMobileSheetWithSuffix(tester, suffix: 'Zzzzzzz'); // 7 chars, not the English default

        expect(tester.takeException(), isNull, reason: '7-char labels must fit the compact (xs: 12) column');
        final dayRect = tester.getRect(find.byKey(_dayKey));
        final secondRect = tester.getRect(find.byKey(_secondKey));
        expect(dayRect.width, closeTo(secondRect.width, 0.5));
      },
    );

    guardedTestWidgets(
      'a 7-char synthetic suffix (the measured safe boundary) fits the real desktop anchored-panel flow at a '
      'narrow anchor width',
      (tester) async {
        // 7 chars, not the English default.
        await _pumpDesktopAnchoredWithSuffix(tester, suffix: 'Zzzzzzz', anchorWidth: narrowAnchorWidth);

        expect(
          tester.takeException(),
          isNull,
          reason: '7-char labels must fit one field per row at the narrow anchor\'s real, measured width',
        );
        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        expect(hourRect.top, greaterThan(dayRect.top), reason: 'one field per row at this width, day above hour');
      },
    );

    guardedTestWidgets(
      'CAPACITY TRIP-WIRE: a narrow desktop anchor still cannot take an 8-char suffix — this is WHY the short '
      'keys are used there, not merely a fact about it',
      (tester) async {
        // 8 chars, one over the safe boundary.
        await _pumpDesktopAnchoredWithSuffix(tester, suffix: 'Zzzzzzzz', anchorWidth: narrowAnchorWidth);

        // This assertion is deliberately inverted: it pins the narrow-anchor
        // layout's character capacity, which has not changed in kind -- only
        // in which width exhibits it, now that the panel's width is
        // caller-determined instead of built-in. What changed is that a
        // desktop field narrower than `_kNarrowFieldWidth` no longer *feeds*
        // this layout an 8-character string — it now reads the short
        // durationUnit*Short{Singular,Plural} keys precisely because this
        // capacity ceiling exists.
        //
        // If this ever starts passing at `narrowAnchorWidth`, see the group
        // doc comment above ("If this trips again") for the re-derivation
        // procedure and what it would mean for the short-key decision.
        expect(
          tester.takeException(),
          isNotNull,
          reason:
              'a $narrowAnchorWidth-wide anchor\'s layout capacity currently fits a real 7-char label but not a '
              'real 8-char one (e.g. "Segundos"); if this starts passing, the capacity grew and the short-key '
              'decision above should be revisited',
        );
      },
      // This test deliberately drives content past the layout's capacity and
      // asserts on the resulting overflow above via tester.takeException() --
      // it opts out of guardedTestWidgets' own overflow check rather than
      // being silently caught by it.
      expectOverflow: true,
    );
  });
}
