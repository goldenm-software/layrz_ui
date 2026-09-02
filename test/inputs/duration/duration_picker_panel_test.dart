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
/// desktop [LayrzEndDrawer] (DESIGN-98), optionally overriding l10n via
/// [delegate] and seeding the fields via [value].
///
/// Deliberately routes through the real [LayrzDurationInput] rather than
/// pumping [LayrzDurationPickerPanel] bare, to reproduce the actual
/// constraint the picker renders under in production. **Unlike the previous
/// `LayrzAnchoredPanel`/`matchAnchor` hosting, the drawer's width is fixed**
/// (`LayrzEndDrawer.width`, 420px) and independent of the anchor field's own
/// width entirely -- there is no `anchorWidth` parameter here any more,
/// because varying the anchor's own width has no effect on the panel's
/// available width post-DESIGN-98. See `duration_input.dart`'s class doc for
/// the worked-out consequence: the drawer's fixed width always yields exactly
/// one field per row, comfortably above `_kNarrowFieldWidth`, so the picker
/// always reads the long-form labels through this real flow now -- the
/// narrow, short-form-selecting width this group used to reach via a narrow
/// `anchorWidth` is reproduced instead by [_pumpNarrowPanel] below, which
/// pumps the bare panel at an explicit width the real drawer no longer
/// produces but the panel's own layout logic must still handle correctly
/// (e.g. a caller embedding it directly, or a future narrower drawer).
Future<void> _pumpDesktopDrawer(
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

/// Pumps the bare [LayrzDurationPickerPanel] constrained to [panelWidth] via
/// a [SizedBox], for the narrow-width capacity cases the real desktop
/// [LayrzEndDrawer] no longer produces (see [_pumpDesktopDrawer]'s own doc for
/// why: the drawer is now a fixed 420px, always well above
/// `_kNarrowFieldWidth`). This proves the panel's own layout logic still
/// behaves correctly at a width the drawer does not currently exercise --
/// the widget's contract does not depend on which host renders it.
Future<void> _pumpNarrowPanel(
  WidgetTester tester, {
  required double panelWidth,
  LocalizationsDelegate<LayrzUiL10n>? delegate,
  Duration? value,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    LayrzApp(
      home: Center(
        child: SizedBox(
          width: panelWidth,
          child: LayrzDurationPickerPanel(
            initialValue: value,
            visibleUnits: _allUnits,
            onChanged: (_) {},
          ),
        ),
      ),
      theme: LayrzThemeData.light(),
      localizationsDelegates: delegate == null ? null : [delegate],
      debugShowCheckedModeBanner: false,
    ),
  );
  await tester.pump();
}

/// Convenience wrapper over [_pumpNarrowPanel] that replaces every duration
/// field's [LayrzNumberInput.suffixText] source key with [suffix].
Future<void> _pumpNarrowPanelWithSuffix(WidgetTester tester, {required String suffix, required double panelWidth}) {
  return _pumpNarrowPanel(tester, panelWidth: panelWidth, delegate: _SyntheticSuffixL10nDelegate(suffix));
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

    group('reset button semantic color', () {
      guardedTestWidgets('the reset button is type warning, not info', (tester) async {
        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

        final button = tester.widget<LayrzButton>(find.byType(LayrzButton));
        expect(
          button.type,
          LayrzButtonType.warning,
          reason:
              'Reset zeroes every field -- a destructive-ish action -- so it must read as warning, not the '
              'neutral/auxiliary info type',
        );
      });

      guardedTestWidgets('the reset button paints tokens.colors.warning as its fill, not tokens.colors.info', (
        tester,
      ) async {
        await _pumpPanel(tester, viewportSize: _wideViewport, visibleUnits: _allUnits);

        final tokens = LayrzTheme.of(tester.element(find.byType(LayrzButton))).tokens;
        final animatedContainer = tester.widget<AnimatedContainer>(
          find.descendant(of: find.byType(LayrzButton), matching: find.byType(AnimatedContainer)).first,
        );
        final fill = (animatedContainer.decoration as BoxDecoration).color;

        expect(fill, tokens.colors.warning);
        expect(fill, isNot(tokens.colors.info));
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
    //
    // DESIGN-98 changed which width the REAL desktop flow actually produces:
    // `LayrzDurationInput`'s desktop branch now opens a fixed 420px
    // `LayrzEndDrawer` rather than a `matchAnchor` panel tracking the anchor
    // field's own width. Per `duration_input.dart`'s class doc, that fixed
    // width always yields exactly one field per row at ~372px per field --
    // comfortably above `_kNarrowFieldWidth` (280.0) -- so the real desktop
    // flow now ALWAYS reads the long-form keys, never the short ones. The
    // short-form selection itself is not dead code (a caller could still
    // embed `LayrzDurationPickerPanel` directly at a narrower width), so the
    // narrow-width cases below move to `_pumpNarrowPanel`, which pumps the
    // bare panel at an explicit width instead of through the drawer.

    /// A panel width narrow enough that `LayrzDurationPickerPanel` renders
    /// one field per row at well under `_kNarrowFieldWidth` (280.0) per field.
    const narrowPanelWidth = 260.0;

    guardedTestWidgets('compact renders the long-form field label as suffixText, through the real sheet flow', (
      tester,
    ) async {
      await _pumpMobileSheet(tester, value: const Duration(days: 2));

      final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
      expect(day.suffixText, 'Days', reason: 'compact has 16 characters of headroom — keeps the long form');
    });

    guardedTestWidgets(
      'the real desktop drawer flow ALWAYS renders the long-form label as suffixText (DESIGN-98: the '
      'fixed 420px drawer never yields a field narrower than _kNarrowFieldWidth)',
      (tester) async {
        await _pumpDesktopDrawer(tester, value: const Duration(days: 2));

        final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
        expect(
          day.suffixText,
          'Days',
          reason: 'the drawer\'s fixed 420px width leaves ~372px per field -- above _kNarrowFieldWidth',
        );
      },
    );

    guardedTestWidgets(
      'a narrow embedded panel (below _kNarrowFieldWidth per field) renders the short-form abbreviated label',
      (tester) async {
        await _pumpNarrowPanel(tester, panelWidth: narrowPanelWidth, value: const Duration(days: 2));

        final day = tester.widget<LayrzNumberInput>(_numberInputUnder(_dayKey));
        expect(day.suffixText, 'd', reason: 'a narrow field has only ~7 characters of headroom — abbreviates');
      },
    );

    guardedTestWidgets(
      'a narrow embedded panel picks the short-form SINGULAR key when the field count is exactly 1',
      (tester) async {
        await _pumpNarrowPanel(
          tester,
          panelWidth: narrowPanelWidth,
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
      },
    );

    guardedTestWidgets(
      'a narrow embedded panel picks the short-form PLURAL key when the field count is 0 or greater than 1',
      (tester) async {
        await _pumpNarrowPanel(
          tester,
          panelWidth: narrowPanelWidth,
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
      },
    );

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
    // a concrete panel width instead: since the panel's width is
    // caller-determined, the "measured safe boundary" is re-expressed as "at
    // this specific, still-realistic width, a 7-char label fits and an
    // 8-char one overflows" -- the same underlying claim (a real capacity
    // ceiling exists, which is why the band-dependent key selection above
    // reads the short keys below `_kNarrowFieldWidth`), reproduced against the
    // new width mechanism.
    //
    // RE-DERIVED A THIRD TIME (DESIGN-98): the real desktop `LayrzDurationInput`
    // flow no longer produces this width at all -- its `LayrzEndDrawer` is a
    // fixed 420px, always well above `_kNarrowFieldWidth` (see
    // `duration_input.dart`'s class doc). The desktop cases below now pump
    // `LayrzDurationPickerPanel` bare via `_pumpNarrowPanel`, at the same
    // measured `narrowAnchorWidth`, to prove the panel's own layout capacity
    // ceiling still holds independent of which host renders it -- the widget's
    // contract does not depend on the drawer being the only caller.
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
    // deleted) against `_pumpNarrowPanelWithSuffix` for a 7-char
    // synthetic suffix and the real 8-char words above, at a spread of
    // `panelWidth` values bracketing the current `narrowAnchorWidth`. If the
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
      'a 7-char synthetic suffix (the measured safe boundary) fits a narrow embedded panel',
      (tester) async {
        // 7 chars, not the English default.
        await _pumpNarrowPanelWithSuffix(tester, suffix: 'Zzzzzzz', panelWidth: narrowAnchorWidth);

        expect(
          tester.takeException(),
          isNull,
          reason: '7-char labels must fit one field per row at the narrow panel\'s real, measured width',
        );
        final dayRect = tester.getRect(find.byKey(_dayKey));
        final hourRect = tester.getRect(find.byKey(_hourKey));
        expect(hourRect.top, greaterThan(dayRect.top), reason: 'one field per row at this width, day above hour');
      },
    );

    guardedTestWidgets(
      'CAPACITY TRIP-WIRE: a narrow embedded panel still cannot take an 8-char suffix — this is WHY the short '
      'keys are used there, not merely a fact about it',
      (tester) async {
        // 8 chars, one over the safe boundary.
        await _pumpNarrowPanelWithSuffix(tester, suffix: 'Zzzzzzzz', panelWidth: narrowAnchorWidth);

        // This assertion is deliberately inverted: it pins the narrow-panel
        // layout's character capacity, which has not changed in kind -- only
        // in which width exhibits it, and (DESIGN-98) in which caller reaches
        // that width -- the real desktop drawer no longer does, see the group
        // doc comment above. What changed is that a field narrower than
        // `_kNarrowFieldWidth` no longer *feeds* this layout an 8-character
        // string — it now reads the short durationUnit*Short{Singular,Plural}
        // keys precisely because this capacity ceiling exists.
        //
        // If this ever starts passing at `narrowAnchorWidth`, see the group
        // doc comment above ("If this trips again") for the re-derivation
        // procedure and what it would mean for the short-key decision.
        expect(
          tester.takeException(),
          isNotNull,
          reason:
              'a $narrowAnchorWidth-wide panel\'s layout capacity currently fits a real 7-char label but not a '
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
