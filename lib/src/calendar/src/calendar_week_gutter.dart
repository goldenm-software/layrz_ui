import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'calendar_week_number.dart';

/// The fixed width of a [LayrzCalendarWeekGutter] column, in logical pixels.
///
/// Named rather than inlined so the gutter's width is a single point of
/// change — `LayrzCalendarMonthSurface` reads this same constant to size the
/// gutter's sibling reservation and to size its own header spacer to match.
const double kLayrzCalendarWeekGutterWidth = 32;

/// A column of tappable ISO 8601 week numbers rendered beside a
/// [LayrzCalendarMonthSurface]'s month grid, one number per week row.
///
/// **Must be composed as a sibling to the LEFT of the grid's own [Stack],
/// never inside it.** `_MultiDayBar` (`calendar_month_surface.dart`) computes
/// `columnWidth = constraints.maxWidth / 7` against that `Stack`'s own
/// constraints; the bars are `Positioned` siblings of the day-cell [Row]
/// inside the exact same `Stack`. A gutter placed inside would silently
/// narrow `maxWidth` for both, so every multi-day bar would shift and
/// mis-size while the [Expanded] day cells kept looking correct — a
/// hard-to-diagnose failure with no visual signal at the cell level. Composing
/// this widget as an outer `Row` sibling (grid gutter + grid `Expanded`)
/// keeps the grid's own `Stack` measuring the exact same width whether or not
/// [LayrzCalendar.showWeekNumbers] is on.
///
/// **Renders one equal-[Expanded] row per entry in [weekStarts]**, mirroring
/// `LayrzCalendarMonthSurface`'s own week rows exactly — every grid week row
/// is an `Expanded` child with the default flex of `1`, so a [Column] of
/// equal-flex cells here stays pixel-for-pixel aligned with the grid's rows
/// under any container height, with no row-height measurement needed. This
/// widget renders the week-number column ONLY — the leading blank space
/// needed to align it under the grid's weekday-header row (rather than under
/// the grid body) is `LayrzCalendarMonthSurface`'s own responsibility, sized
/// from [kLayrzCalendarWeekGutterWidth] and the same header-row metrics the
/// grid itself uses.
///
/// **Numbering rule — read `calendar_week_number.dart`'s class doc for the
/// full ISO-vs-`firstDayOfWeek` conflict.** In short: each row is labeled with
/// the ISO 8601 week number of that row's own first date
/// ([isoWeekNumberOf]). Under a non-Monday [LayrzCalendar.firstDayOfWeek]
/// (the default is `DateTime.sunday`), a row's last day or two may
/// technically fall in the following ISO week — that overlap is expected and
/// does not produce a duplicate or reversed number in the gutter itself.
///
/// **Month view only.** In week view, a single row has nothing to compare its
/// number against — it stops being a row *label* and becomes a redundant
/// constant, so this widget is not composed there.
class LayrzCalendarWeekGutter extends StatelessWidget {
  /// Creates a [LayrzCalendarWeekGutter].
  const LayrzCalendarWeekGutter({required this.weekStarts, this.onWeekTap, super.key});

  /// The first date of each grid week row, top to bottom — one entry per row,
  /// in the same order [LayrzCalendarMonthSurface] renders its rows.
  ///
  /// Each date's own ISO 8601 week number (via [isoWeekNumberOf]) is the
  /// label painted for that row.
  final List<DateTime> weekStarts;

  /// Called with a row's first date when its week number is tapped.
  ///
  /// `LayrzCalendar` wires this to jump the controller to that date and
  /// switch to [LayrzCalendarMode.week], the same navigation shape
  /// `LayrzCalendarDayCell.onOverflowTap` uses for day view. Null renders
  /// every number inert — no hover state, no pointer cursor, no interactive
  /// semantics node.
  final void Function(DateTime weekStart)? onWeekTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kLayrzCalendarWeekGutterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final weekStart in weekStarts)
            Expanded(
              child: _WeekNumberCell(weekStart: weekStart, onTap: onWeekTap),
            ),
        ],
      ),
    );
  }
}

/// One tappable week-number cell within a [LayrzCalendarWeekGutter].
///
/// Mirrors `LayrzCalendarDayCell`'s `_DateNumber`/`_OverflowChip` interaction
/// shape: a hover state and pointer cursor when interactive, varying only
/// text color per decision D15 (colour/border/shadow/opacity/cursor only —
/// never geometry), and a live semantics node carrying a concrete action
/// label rather than the bare number.
class _WeekNumberCell extends StatefulWidget {
  const _WeekNumberCell({required this.weekStart, this.onTap});

  /// The first date of the grid week row this cell labels.
  final DateTime weekStart;

  /// Called with [weekStart] when this cell is tapped. Null renders it inert.
  final void Function(DateTime weekStart)? onTap;

  @override
  State<_WeekNumberCell> createState() => _WeekNumberCellState();
}

class _WeekNumberCellState extends State<_WeekNumberCell> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isInteractive = widget.onTap != null;
    final weekNumber = isoWeekNumberOf(widget.weekStart);

    final Color textColor;
    if (!isInteractive) {
      textColor = tokens.colors.fg3;
    } else if (_isHovered) {
      textColor = tokens.colors.primary.shade500;
    } else {
      textColor = tokens.colors.fg3;
    }

    final text = AnimatedDefaultTextStyle(
      duration: tokens.motion.dHover,
      curve: tokens.motion.easing,
      style: tokens.typography.label.copyWith(color: textColor, fontSize: 11),
      child: Center(child: Text('$weekNumber')),
    );

    if (!isInteractive) return ExcludeSemantics(child: text);

    final content = Semantics(
      button: true,
      enabled: true,
      label: 'Week $weekNumber, opens week view',
      onTap: () => widget.onTap!(widget.weekStart),
      child: ExcludeSemantics(child: text),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: () => widget.onTap!(widget.weekStart),
        child: content,
      ),
    );
  }
}
