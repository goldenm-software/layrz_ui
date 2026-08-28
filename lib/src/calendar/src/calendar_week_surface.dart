import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'calendar_all_day_band.dart';
import 'calendar_day_surface.dart';
import 'calendar_entry.dart';
import 'calendar_time_format.dart';
import 'calendar_weekdays.dart';
import 'calendar_zone.dart';

/// The layout surface for [LayrzCalendarMode.week]: seven day columns sharing
/// **one** left-edge hour axis and **one** all-day/multi-day band spanning
/// all seven columns, ordered from [firstDayOfWeek].
///
/// Reuses [LayrzCalendarDaySurface]'s shared timed-grid building blocks
/// ([HourAxis], [HourGridColumn], [AllDayBand]) rather than a second
/// implementation — day view's single column is simply far wider, making the
/// same overlap-column scheme more comfortable there, not a different
/// scheme. See those widgets' docs (in `calendar_day_surface.dart`) for the
/// even-column-split overlap rule, the demoted-when-covered styling, the
/// minimum event-block height, and the DST-safe hour axis.
///
/// **The all-day band renders one continuous bar per multi-day entry**,
/// never one chip per occupied column — matching how
/// [LayrzCalendarMonthSurface] collapses a multi-day event into a single bar
/// per week row. `AllDayBand`'s own height grows with the number of lanes in
/// use for the visible range (never a fixed cap), and lane packing is scoped
/// to this band's own 7-day range rather than the whole month — see
/// `AllDayBand`'s doc in `calendar_all_day_band.dart`.
///
/// **Each column header renders the weekday name above the date number**,
/// the number in `tokens.typography.title` (matching a heading rather than a
/// muted axis tick) and the name in the same muted `label` style the day
/// number previously used alone. The two are stacked in a `Column` rather
/// than composed inline ("Sun 23") because seven columns leaves each header
/// little horizontal room; stacking keeps both lines centered without
/// widening the column. The name is truncated to 3 characters the same way
/// [LayrzCalendarMonthSurface]'s header row truncates
/// [orderedWeekdayLabels] — the l10n weekday namespace only exposes full
/// names, so both surfaces share the one truncation point rather than one
/// hardcoding an abbreviated list. Headers rotate with [firstDayOfWeek] via
/// [orderedWeekdayLabels], the same ordering [_weekDates] uses for the
/// numbers, so the two can never drift apart.
///
/// **Display-only when [onTap] is null, bookable when it is set** — matching
/// [LayrzCalendarDaySurface]'s [HourGridColumn] exactly, since both surfaces
/// share that same widget. No drag-to-create or drag-to-resize regardless of
/// [onTap] — a tap was asked for, not a drag.
class LayrzCalendarWeekSurface extends StatelessWidget {
  /// Creates a [LayrzCalendarWeekSurface].
  const LayrzCalendarWeekSurface({
    required this.focusedDate,
    required this.entries,
    this.isDateDisabled,
    this.firstDayOfWeek = DateTime.sunday,
    this.timeFormat = LayrzTimeFormat.h24,
    this.onTap,
    super.key,
  });

  /// Any date within the week to render.
  final DateTime focusedDate;

  /// The full set of events to place. Filtered per column via
  /// [LayrzCalendarEntry.occupies].
  final List<LayrzCalendarEntry> entries;

  /// Predicate deciding whether a given date is disabled.
  ///
  /// Purely visual, matching every other surface — see `LayrzCalendar`'s
  /// class doc for why this pass has no functional disabling.
  final bool Function(DateTime date)? isDateDisabled;

  /// The weekday the week's columns start from.
  ///
  /// One of `DateTime.monday` (1) through `DateTime.sunday` (7). Defaults to
  /// `DateTime.sunday`, matching [LayrzCalendarMonthSurface]'s default.
  final int firstDayOfWeek;

  /// The clock convention hour-axis labels and timed-event times render in.
  final LayrzTimeFormat timeFormat;

  /// Called when the hour grid is tapped somewhere that is not a timed event
  /// block, with the tapped column's date plus the 15-minute-snapped tapped
  /// time (seconds and milliseconds always zero). Forwarded to every
  /// [_WeekDayColumn]'s [HourGridColumn]; see [LayrzCalendar.onTap]'s doc for
  /// the snapping rule. Null leaves the grid display-only.
  ///
  /// Tapping an event entry — a timed block or an all-day band bar — never
  /// calls this — it fires that entry's own [LayrzCalendarEntry.onTap]
  /// instead; there is no entry-tap callback on this surface.
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);
    final weekdayLabels = orderedWeekdayLabels(l10n, firstDayOfWeek);
    final weekDates = _weekDates(focusedDate, firstDayOfWeek);

    final allDayEntries = entries.where((e) => e.isMultiDay && weekDates.any(e.occupies)).toList(growable: false);
    final hasAllDay = allDayEntries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: kLayrzCalendarHourAxisWidth),
            for (var i = 0; i < weekDates.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // See the class doc for why the name is stacked above
                      // the number (rather than inline) and truncated to 3
                      // characters the same way the month surface's header
                      // row truncates `orderedWeekdayLabels`.
                      Text(
                        weekdayLabels[i].substring(0, weekdayLabels[i].length.clamp(0, 3)),
                        textAlign: TextAlign.center,
                        style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                      ),
                      Text(
                        '${weekDates[i].day}',
                        textAlign: TextAlign.center,
                        style: tokens.typography.title,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (hasAllDay)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp1),
            child: AllDayBand(columnDates: weekDates, entries: allDayEntries),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              // Reserves room for the vertical scrollbar LayrzScrollBehavior
              // installs globally on pointer platforms -- see
              // kLayrzCalendarHourGridEndPadding's doc (calendar_day_surface.dart)
              // for why this must be applied here too, and why the two timed-grid
              // surfaces share one constant rather than each carrying its own.
              padding: const EdgeInsets.only(right: kLayrzCalendarHourGridEndPadding),
              child: SizedBox(
                height: kLayrzCalendarHourRowHeight * 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HourAxis(timeFormat: timeFormat),
                    for (final date in weekDates)
                      Expanded(
                        child: _WeekDayColumn(
                          date: date,
                          entries: entries.where((e) => !e.isMultiDay && e.occupies(date)).toList(growable: false),
                          isDisabled: isDateDisabled?.call(date) ?? false,
                          timeFormat: timeFormat,
                          onTap: onTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the seven dates of the week containing [anchor], starting from
  /// [firstDayOfWeek].
  ///
  /// Steps by [sameZoneDate]'s field-overflow normalization, not
  /// `Duration` — see `LayrzCalendarController.nextWeek` for the same rule.
  /// Every returned date is constructed in [anchor]'s own zone via
  /// [sameZoneDate], so a `TZDateTime` [anchor] produces a week of
  /// `TZDateTime`s in that same `Location` rather than the host's zone.
  static List<DateTime> _weekDates(DateTime anchor, int firstDayOfWeek) {
    final offset = (anchor.weekday - firstDayOfWeek + 7) % 7;
    final weekStart = sameZoneDate(anchor, anchor.year, anchor.month, anchor.day - offset);
    return [for (var i = 0; i < 7; i++) sameZoneDate(weekStart, weekStart.year, weekStart.month, weekStart.day + i)];
  }
}

/// One day column within [LayrzCalendarWeekSurface]'s timed grid — an
/// [HourGridColumn] with a disabled-date visual overlay, matching the same
/// purely-visual disabled treatment every other surface uses.
class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.date,
    required this.entries,
    required this.isDisabled,
    required this.timeFormat,
    this.onTap,
  });

  final DateTime date;
  final List<LayrzCalendarEntry> entries;
  final bool isDisabled;
  final LayrzTimeFormat timeFormat;
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(color: isDisabled ? tokens.colors.sf2 : null),
      child: HourGridColumn(date: date, entries: entries, timeFormat: timeFormat, onTap: onTap),
    );
  }
}
