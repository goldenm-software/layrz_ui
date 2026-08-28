import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'calendar_all_day_band.dart';
import 'calendar_entry.dart';
import 'calendar_time_format.dart';
import 'calendar_zone.dart';

/// The minimum rendered height of a timed event block, in logical pixels.
///
/// **Data-driven, not state-driven — this does not violate decision D15.**
/// D15 governs geometry that varies *across interaction states* for the same
/// event (hover/focus/pressed must never resize); this clamp is a function of
/// the event's own duration and is identical in every interaction state. A
/// short event and a long event render at different heights because they
/// *are* different durations, not because one is hovered. Equally, this is
/// not licence for a hover state to resize anything — hover on a timed block
/// still varies colour/border/shadow/opacity/cursor only.
const double kLayrzCalendarMinEventBlockHeight = 32;

/// The height of one hour row in the timed grid, in logical pixels.
const double kLayrzCalendarHourRowHeight = 48;

/// The width of the shared hour-axis label column, in logical pixels.
///
/// Sized for the wider of the two [LayrzTimeFormat] renderings (`8 AM` vs
/// `08:00`) rather than whichever format happens to be active, so switching
/// [LayrzTimeFormat] never reflows or clips the axis. See
/// [kLayrzCalendarWidestHourLabels].
const double kLayrzCalendarHourAxisWidth = 56;

/// The right-edge inset reserved inside the timed hour grid's scroll view, in
/// logical pixels, so the vertical scrollbar [LayrzScrollBehavior] installs
/// globally on pointer platforms never paints over the rightmost content.
///
/// A [Scrollbar]/[LayrzScrollbar] paints as an overlay on top of the
/// scrollable's own bounds rather than reserving layout space for itself, so
/// without this inset the thumb floats directly over whatever content
/// happens to reach the scroll view's right edge — an event block in the
/// rightmost day column, in this grid's case. Equal to
/// [kLayrzScrollbarThickness] (`constants/src/scrollbar.dart`): the thumb's
/// own cross-axis margin is `0` (see [kLayrzScrollbarCrossAxisMargin]), so
/// the reserved space is exactly the thumb's width, no extra gap needed.
///
/// **Shared by both timed-grid surfaces, [LayrzCalendarDaySurface] and
/// [LayrzCalendarWeekSurface] — not two independent literals.** Both wrap
/// their `Row` of [HourAxis] plus day column(s) in a
/// `Padding(right: kLayrzCalendarHourGridEndPadding)` *inside* the
/// `SingleChildScrollView`, before that `Row`'s [Expanded] day columns
/// resolve their width. This is why the fix does not need to touch
/// [assignOverlapColumns] or [timedEventBlock]: the even column split for
/// overlapping events reads `constraints.maxWidth` from its own column's
/// [LayoutBuilder], which already reflects the narrower width once the
/// inset shrinks the `Row` itself, so no block computes a width that
/// overflows past the reserved track.
const double kLayrzCalendarHourGridEndPadding = kLayrzScrollbarThickness;

/// The layout surface for [LayrzCalendarMode.day]: a single column with a
/// fixed, always-visible 00:00–23:00 hour axis, plus an all-day band for any
/// multi-day or all-day-length entries occupying [focusedDate].
///
/// **Fixed 24-row axis, never windowed or cropped to "working hours."** The
/// whole column is wrapped in a vertical scroll view so short viewports can
/// still reach every hour — this is not a day-plus-agenda layout, and there
/// is no initial scroll-to-a-particular-hour behaviour (`scrollToHour` is an
/// explicitly out-of-scope additive feature).
///
/// **DST is a second hazard here that the month grid never had.** A
/// transition day has 23 or 25 elapsed hours, but its hour-of-day axis is
/// still the ordinary 24 rows (00:00 through 23:00) — this surface never
/// steps by `Duration(hours: 1)` to build the axis, since that class of bug
/// is exactly what broke pass 1's month grid for calendar-day stepping.
///
/// **Overlapping timed events split their column width evenly** among
/// concurrent events — the deliberately conservative baseline (not Google
/// Calendar's exact two-treatment cascade, which cannot be derived from a
/// single reference screenshot; see `assignOverlapColumns`'s doc). The
/// later-starting event draws on top (tie-broken by title), and a covered
/// event renders demoted to a light-fill/outlined treatment while the
/// covering event keeps the ordinary solid fill — demotion is a function of
/// *being covered*, not of starting first, so an unoverlapped event keeps its
/// ordinary solid chip style.
///
/// **Display-only when [onTap] is null, bookable when it is set.** An
/// earlier ruling forbade per-slot hover highlighting on the grounds that
/// display-only had to be enforced at the interaction layer; that reasoning
/// no longer holds now that a tap has somewhere to go. When [onTap] is
/// non-null, [HourGridColumn] renders a hover affordance and pointer cursor
/// on the grid — a tappable slot with no hover state would be undiscoverable
/// — varying only colour/border/shadow/opacity/cursor per decision D15,
/// never geometry. When [onTap] is null the grid renders exactly as before
/// it existed: no `MouseRegion`, no `GestureDetector`, no interactive
/// semantics node. A timed block's own interactivity is independent of this
/// — it comes from that entry's own [LayrzCalendarEntry.onTap], not from
/// anything on this surface. **Drag-to-create, drag-to-resize, and
/// click-and-drag time-range selection remain non-goals** regardless of
/// [onTap] — a tap was asked for, not a drag.
///
/// Shares its timed-grid rendering ([HourGridColumn], [AllDayBand]) with
/// [LayrzCalendarWeekSurface] — day view's column is simply far wider, making
/// the same overlap-column scheme more comfortable there, not a different
/// implementation.
class LayrzCalendarDaySurface extends StatelessWidget {
  /// Creates a [LayrzCalendarDaySurface].
  const LayrzCalendarDaySurface({
    required this.focusedDate,
    required this.entries,
    this.isDateDisabled,
    this.timeFormat = LayrzTimeFormat.h24,
    this.onTap,
    super.key,
  });

  /// The date to render — only the year/month/day components are used.
  final DateTime focusedDate;

  /// The full set of events to place. Filtered to those occupying
  /// [focusedDate] via [LayrzCalendarEntry.occupies].
  final List<LayrzCalendarEntry> entries;

  /// Predicate deciding whether [focusedDate] is disabled.
  ///
  /// Purely visual, matching every other surface — see `LayrzCalendar`'s
  /// class doc for why this pass has no functional disabling.
  final bool Function(DateTime date)? isDateDisabled;

  /// The clock convention hour-axis labels and timed-event times render in.
  ///
  /// Defaults to [LayrzTimeFormat.h24]. Never affects month view, which has
  /// no timed rendering at all.
  final LayrzTimeFormat timeFormat;

  /// Called when the hour grid is tapped somewhere that is not a timed event
  /// block, with the tapped date and time snapped to the nearest 15-minute
  /// boundary at or before the tapped y-offset — seconds and milliseconds
  /// always zero. Forwarded to [HourGridColumn]; see
  /// [LayrzCalendar.onTap]'s doc for the snapping rule. Null leaves the grid
  /// display-only.
  ///
  /// Tapping a timed event block never calls this — it fires that entry's
  /// own [LayrzCalendarEntry.onTap] instead; there is no entry-tap callback
  /// on this surface.
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDisabled = isDateDisabled?.call(focusedDate) ?? false;

    final allDayEntries = entries.where((e) => e.isMultiDay && e.occupies(focusedDate)).toList(growable: false);
    final timedEntries = entries.where((e) => !e.isMultiDay && e.occupies(focusedDate)).toList(growable: false);

    return DecoratedBox(
      // Purely visual, matching every other surface's disabled treatment --
      // see `LayrzCalendar`'s class doc for why this pass has no functional
      // disabling.
      decoration: BoxDecoration(color: isDisabled ? tokens.colors.sf2 : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allDayEntries.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.sp1),
              child: AllDayBand(columnDates: [focusedDate], entries: allDayEntries),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                // Reserves room for the vertical scrollbar LayrzApp installs
                // globally (LayrzScrollBehavior) on pointer platforms -- a
                // Scrollbar paints as an overlay on top of the scrollable's
                // own bounds rather than adding layout space, so without this
                // inset the thumb floats directly over the rightmost content
                // instead of ending before it. See kLayrzCalendarHourGridEndPadding's
                // doc for why both timed-grid surfaces share one constant.
                padding: const EdgeInsets.only(right: kLayrzCalendarHourGridEndPadding),
                child: SizedBox(
                  height: kLayrzCalendarHourRowHeight * 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HourAxis(timeFormat: timeFormat),
                      Expanded(
                        child: HourGridColumn(
                          date: focusedDate,
                          entries: timedEntries,
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
      ),
    );
  }
}

/// The shared left-edge hour axis rendered once by [LayrzCalendarDaySurface]
/// and once (shared across all seven columns) by [LayrzCalendarWeekSurface].
///
/// Fixed [kLayrzCalendarHourAxisWidth] wide regardless of [timeFormat], so
/// switching format never reflows the grid next to it.
///
/// **Each label sits at its own row's vertical midpoint, not its top edge.**
/// The maintainer looked at the top-aligned rendering next to the grid's
/// fill and judged it as reading like the label belongs to the gridline
/// rather than to the hour block beneath it -- centring is a deliberate
/// deviation from the convention most calendar UIs use (label pinned to the
/// line marking where the hour starts). This is a vertical-only change: row
/// height ([kLayrzCalendarHourRowHeight]) and the row boundaries themselves
/// are untouched, so the axis stays in lockstep with the timed grid, whose
/// event blocks still position from `startMinutes / 60 * rowHeight` measured
/// from the top of each row.
class HourAxis extends StatelessWidget {
  /// Creates an [HourAxis].
  const HourAxis({required this.timeFormat, super.key});

  /// The clock convention hour labels render in.
  final LayrzTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);

    return SizedBox(
      width: kLayrzCalendarHourAxisWidth,
      child: Column(
        children: [
          for (var hour = 0; hour < 24; hour++)
            SizedBox(
              height: kLayrzCalendarHourRowHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: tokens.spacing.sp1),
                  child: Text(
                    formatHourLabel(hour, timeFormat, l10n),
                    style: tokens.typography.label.copyWith(color: tokens.colors.fg3, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One day's worth of the timed hour grid: 24 fixed-height hour rows with
/// horizontal divider lines, overlaid with [timedEventBlock]s for [entries].
///
/// **Display-only when [onTap] is null**: no `MouseRegion`, no
/// `GestureDetector`, on the grid rows themselves — enforced structurally,
/// not merely by omitting a callback on some other widget. **Bookable when
/// [onTap] is non-null**: each hour row renders a hover affordance and
/// pointer cursor (see the class doc on [LayrzCalendarDaySurface] for why
/// this reverses an earlier display-only ruling), and tapping a row calls
/// [onTap] with [date] plus the tapped time, snapped to the nearest
/// 15-minute boundary at or before the tapped y-offset within that row.
///
/// **The whole hour row is one hit target; only the returned value is
/// quantised.** A 15-minute slice of a 48px row is a 12px band — far under
/// any reasonable touch target — so the row stays one
/// [HitTestBehavior.opaque] region, and [_snappedTimeForOffset] computes
/// which 15-minute slot the tap's y-offset falls into after the fact.
class HourGridColumn extends StatefulWidget {
  /// Creates an [HourGridColumn].
  const HourGridColumn({
    required this.date,
    required this.entries,
    required this.timeFormat,
    this.onTap,
    super.key,
  });

  /// The calendar date this column renders timed events for.
  final DateTime date;

  /// The non-multi-day events occupying [date]. Each block's own
  /// [LayrzCalendarEntry.onTap] drives that block's interactivity — there is
  /// no separate entry-tap callback on this widget.
  final List<LayrzCalendarEntry> entries;

  /// The clock convention used to format event start/end times, when shown.
  final LayrzTimeFormat timeFormat;

  /// Called when an hour row is tapped somewhere that is not a timed event
  /// block, with [date] plus the 15-minute-snapped tapped time (seconds and
  /// milliseconds always zero). Null renders every hour row inert: no hover,
  /// no cursor, no interactive semantics node.
  ///
  /// A block's own tap target sits above the row's, so tapping a block fires
  /// only that entry's own [LayrzCalendarEntry.onTap], never also this.
  final void Function(DateTime date)? onTap;

  @override
  State<HourGridColumn> createState() => _HourGridColumnState();
}

class _HourGridColumnState extends State<HourGridColumn> {
  int? _hoveredHour;

  void _setHoveredHour(int? hour) {
    if (_hoveredHour == hour) return;
    setState(() => _hoveredHour = hour);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final layout = assignOverlapColumns(widget.entries);
    final isInteractive = widget.onTap != null;

    return Stack(
      children: [
        Column(
          children: [
            for (var hour = 0; hour < 24; hour++)
              _hourRow(context, tokens: tokens, hour: hour, isInteractive: isInteractive),
          ],
        ),
        for (final placement in layout) timedEventBlock(context, date: widget.date, placement: placement),
      ],
    );
  }

  Widget _hourRow(BuildContext context, {required LayrzTokens tokens, required int hour, required bool isInteractive}) {
    final decoration = BoxDecoration(
      // Colour-only hover feedback per D15 -- the row's height, border width
      // and every other geometric property stay fixed regardless of hover.
      color: isInteractive && _hoveredHour == hour ? tokens.colors.primary.shade500.withValues(alpha: 0.05) : null,
      border: Border(
        top: BorderSide(color: tokens.colors.divider, width: tokens.border.stroke1),
      ),
    );

    if (!isInteractive) {
      return Container(height: kLayrzCalendarHourRowHeight, decoration: decoration);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHoveredHour(hour),
      onExit: (_) => _setHoveredHour(null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final snapped = _snappedTimeForOffset(
            date: widget.date,
            hour: hour,
            localDy: details.localPosition.dy,
          );
          widget.onTap!(snapped);
        },
        child: Container(height: kLayrzCalendarHourRowHeight, decoration: decoration),
      ),
    );
  }

  /// Returns [date] at [hour], with minutes snapped to the nearest
  /// 15-minute boundary at or before [localDy] within the row — see
  /// [LayrzCalendar.onTap]'s doc for the snapping rule.
  ///
  /// Constructed via [sameZoneDateTime] in [date]'s own zone, so a
  /// `TZDateTime` [date] produces a tap result in that same zone rather than
  /// the host's.
  static DateTime _snappedTimeForOffset({required DateTime date, required int hour, required double localDy}) {
    final clampedDy = localDy.clamp(0.0, kLayrzCalendarHourRowHeight);
    final minuteWithinHour = (clampedDy / kLayrzCalendarHourRowHeight) * 60;
    final snappedMinute = (minuteWithinHour ~/ 15) * 15;
    return sameZoneDateTime(date, date.year, date.month, date.day, hour, snappedMinute.clamp(0, 45));
  }
}

/// One [LayrzCalendarEntry] positioned within its overlap column by
/// [assignOverlapColumns].
@immutable
class TimedEventPlacement {
  /// Creates a [TimedEventPlacement].
  const TimedEventPlacement({
    required this.entry,
    required this.column,
    required this.columnCount,
    required this.isCovered,
  });

  /// The timed event this placement positions.
  final LayrzCalendarEntry entry;

  /// The zero-based column index this entry occupies among concurrent
  /// overlapping entries, out of [columnCount] total.
  final int column;

  /// The number of columns the concurrent overlap group this entry belongs to
  /// is split into. `1` when [entry] does not overlap any other entry.
  final int columnCount;

  /// Whether another concurrent entry starting later fully or partially draws
  /// over this one.
  ///
  /// Demotion is a function of *being covered*, not of starting first — an
  /// entry with [columnCount] of `1` is never covered.
  final bool isCovered;
}

/// Packs [entries] into evenly split overlap columns for one day's timed
/// hour grid.
///
/// **Ships the even column split, the deliberately conservative baseline —
/// not Google Calendar's exact two-treatment cascade.** A single reference
/// screenshot measured for this pass showed two genuinely different
/// geometries (a small fixed inset in one overlap pair, a ~50%-offset
/// side-by-side split in another) and could not reveal which selector chooses
/// between them, so reproducing it would mean guessing a rule with no
/// evidence for it. Even splitting among all concurrent events in a group is
/// simple, consistent, and additive — the precise cascade can be layered on
/// later without breaking this baseline.
///
/// **Z-order: the later-starting event draws on top**, tie-broken by title —
/// the same ordering convention `LayrzCalendarMonthSurface` and
/// `calendar_event_lane.dart` already use, so there is one sort convention in
/// this codebase, not two. **A covered event is demoted** (see
/// [TimedEventPlacement.isCovered]) — this is a styling rule, not just paint
/// order, so a naive implementation that clips two identically-styled blocks
/// produces something visibly different from the intended result.
///
/// [entries] need not be sorted or pre-filtered; must not contain a multi-day
/// entry (the caller filters those into the all-day band instead).
List<TimedEventPlacement> assignOverlapColumns(List<LayrzCalendarEntry> entries) {
  if (entries.isEmpty) return const [];

  final sorted = [...entries]
    ..sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.title.compareTo(b.title);
    });

  // Group entries into maximal clusters of mutual/transitive time overlap --
  // two entries in the same cluster share their column split even if they
  // do not themselves directly overlap (A overlaps B, B overlaps C -> A, B
  // and C all split the same group).
  final clusters = <List<LayrzCalendarEntry>>[];
  for (final entry in sorted) {
    final overlappingCluster = clusters.where(
      (cluster) => cluster.any((e) => e.start.isBefore(entry.end) && entry.start.isBefore(e.end)),
    );
    if (overlappingCluster.isEmpty) {
      clusters.add([entry]);
    } else {
      overlappingCluster.first.add(entry);
      // Merge any other clusters this entry also bridges, keeping clusters
      // maximal (transitive overlap).
      final toMerge = overlappingCluster.skip(1).toList();
      for (final other in toMerge) {
        overlappingCluster.first.addAll(other);
        clusters.remove(other);
      }
    }
  }

  final placements = <TimedEventPlacement>[];
  for (final cluster in clusters) {
    final columnCount = cluster.length;
    // Later start draws on top -- assign column indices in start order (so
    // column 0 is visually leftmost/earliest), but z-order at paint time is
    // controlled by list order in the returned placements, later entries
    // painting on top of earlier ones in a Stack.
    final ordered = [...cluster]
      ..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        return byStart != 0 ? byStart : a.title.compareTo(b.title);
      });
    for (var i = 0; i < ordered.length; i++) {
      final entry = ordered[i];
      final isCovered =
          columnCount > 1 &&
          ordered.any((other) {
            if (identical(other, entry)) return false;
            final otherIsLater =
                other.start.isAfter(entry.start) ||
                (other.start == entry.start && other.title.compareTo(entry.title) > 0);
            return otherIsLater && other.start.isBefore(entry.end) && entry.start.isBefore(other.end);
          });
      placements.add(
        TimedEventPlacement(entry: entry, column: i, columnCount: columnCount, isCovered: isCovered),
      );
    }
  }

  // Later-starting events must draw on top: sort final output so later
  // placements in the list (painted last in the Stack) start later.
  placements.sort((a, b) {
    final byStart = a.entry.start.compareTo(b.entry.start);
    return byStart != 0 ? byStart : a.entry.title.compareTo(b.entry.title);
  });

  return placements;
}

/// Renders one timed event block positioned by [placement] within [date]'s
/// 24-row hour grid.
///
/// Vertical position and height come from [placement.entry]'s start/end time
/// of day; height is clamped to [kLayrzCalendarMinEventBlockHeight] so a very
/// short event is never rendered as an illegible hairline (see that
/// constant's doc for why this is data-driven, not a D15 violation).
/// Horizontal position and width come from [placement.column] /
/// [placement.columnCount], split evenly among concurrent events.
///
/// Thin factory over [_TimedEventBlock] so call sites keep this function
/// signature; the widget itself owns hover state, and its interactivity
/// comes from [TimedEventPlacement.entry]'s own [LayrzCalendarEntry.onTap].
Widget timedEventBlock(BuildContext context, {required DateTime date, required TimedEventPlacement placement}) {
  return _TimedEventBlock(date: date, placement: placement);
}

/// The stateful implementation behind [timedEventBlock].
///
/// **[TimedEventPlacement.entry]'s [LayrzCalendarEntry.isPreview] composes
/// with [TimedEventPlacement.isCovered] rather than replacing it** — a
/// preview that is covered gets both the ghosted preview treatment and the
/// covered-event demotion, since the two answer different questions (is this
/// committed yet vs. is something else drawn on top of it).
///
/// **Interactive when [TimedEventPlacement.entry]'s
/// [LayrzCalendarEntry.onTap] is non-null**: hover and pointer cursor,
/// varying only colour/border per D15 — no change to [top]/[height]/column
/// geometry on hover, which would desynchronize this block from its
/// [TimedEventPlacement].
class _TimedEventBlock extends StatefulWidget {
  const _TimedEventBlock({required this.date, required this.placement});

  /// The calendar date this block's hour grid belongs to.
  final DateTime date;

  /// This block's position, sizing, covered/preview state, and the entry
  /// whose own [LayrzCalendarEntry.onTap] drives this block's
  /// interactivity — there is no separate callback parameter here.
  final TimedEventPlacement placement;

  @override
  State<_TimedEventBlock> createState() => _TimedEventBlockState();
}

class _TimedEventBlockState extends State<_TimedEventBlock> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final date = widget.date;
    final placement = widget.placement;
    final entry = placement.entry;
    final isInteractive = entry.onTap != null;
    final color = entry.color ?? tokens.colors.info.shade500;

    final startMinutes = _minutesIntoDay(entry.start, date);
    final endMinutes = _minutesIntoDay(entry.end, date, isEnd: true);
    final top = startMinutes / 60 * kLayrzCalendarHourRowHeight;
    final rawHeight = (endMinutes - startMinutes) / 60 * kLayrzCalendarHourRowHeight;
    final height = rawHeight < kLayrzCalendarMinEventBlockHeight ? kLayrzCalendarMinEventBlockHeight : rawHeight;

    // Covered and preview are independent axes that compose: a preview that
    // is also covered gets the ghost fill AND the covered outline/demoted
    // text colour, never one replacing the other.
    final Color fillColor;
    final Border? border;
    final Color textColor;
    if (entry.isPreview) {
      final baseAlpha = placement.isCovered ? 0.08 : 0.12;
      fillColor = color.withValues(alpha: baseAlpha);
      border = Border.all(color: color.withValues(alpha: isInteractive && _isHovered ? 0.9 : 0.6));
      textColor = color;
    } else if (placement.isCovered) {
      fillColor = color.withValues(alpha: 0.16);
      border = Border.all(color: color);
      textColor = tokens.colors.fg1;
    } else {
      fillColor = color;
      border = null;
      textColor = color.contrastColor;
    }

    return Positioned(
      top: top,
      height: height,
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth / placement.columnCount;

          final block = Container(
            margin: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 / 4, vertical: 1),
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1, vertical: tokens.spacing.sp1 / 2),
            decoration: BoxDecoration(
              color: fillColor,
              border: border,
              borderRadius: BorderRadius.circular(tokens.radius.r1),
            ),
            alignment: Alignment.topLeft,
            child: Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tokens.typography.label.copyWith(color: textColor, fontSize: 10),
            ),
          );

          // Unlike a month cell (which merges its events into one cell-level
          // label), nothing else announces a timed block, so this carries
          // its own Semantics node rather than an ExcludeSemantics-only
          // wrapper, whether or not it is interactive.
          final content = Semantics(
            label: entry.title,
            container: true,
            button: isInteractive,
            enabled: isInteractive ? true : null,
            onTap: entry.onTap,
            child: ExcludeSemantics(child: block),
          );

          final tappableBlock = !isInteractive
              ? content
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => _setHovered(true),
                  onExit: (_) => _setHovered(false),
                  child: GestureDetector(onTap: entry.onTap, child: content),
                );

          return Padding(
            padding: EdgeInsets.only(
              left: placement.column * columnWidth,
              right: (placement.columnCount - 1 - placement.column) * columnWidth,
            ),
            child: tappableBlock,
          );
        },
      ),
    );
  }
}

double _minutesIntoDay(DateTime dateTime, DateTime date, {bool isEnd = false}) {
  final sameDay = dateTime.year == date.year && dateTime.month == date.month && dateTime.day == date.day;
  if (!sameDay) {
    // An entry that starts before this date or ends after it is clamped to
    // the visible day's bounds -- start of day (0 minutes) or end of day
    // (1440 minutes) respectively.
    return isEnd ? 1440 : 0;
  }
  return (dateTime.hour * 60 + dateTime.minute).toDouble();
}

// [AllDayBand] and [kLayrzCalendarAllDayRowHeight] live in
// `calendar_all_day_band.dart` -- extracted from this file (which was already
// large) since collapsing a multi-day entry into one continuous bar is its
// own concern, distinct from this file's per-column timed-grid rendering.
