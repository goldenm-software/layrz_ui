import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/positioning/positioning.dart';

import 'calendar_mode.dart';

/// The navigation chrome rendered above a [LayrzCalendar]'s active surface:
/// previous/next buttons flanking the focused period's label (`[◀] August
/// 2026 [▶]`), a "Today" shortcut, and a view-mode switcher row.
///
/// The previous/next buttons render as [LayrzButtonStyle.textFab] — no fill
/// or border, so the navigation chrome reads as a cohesive, lower-emphasis
/// unit around the period label. See [focusedDate]'s field doc for how the
/// "Today" button's own style is chosen.
///
/// **The previous/next buttons' label and behaviour are mode-aware.** In
/// month mode they read "Previous/Next month" and call [onPrevious]/[onNext]
/// as wired for month stepping by [LayrzCalendar]; in week mode they read
/// "Previous/Next week"; in day mode, "Previous/Next day". [LayrzCalendar] is
/// responsible for supplying the mode-appropriate callback — this header only
/// selects the mode-appropriate **label**, so a screen reader never announces
/// "Previous month" while the calendar is actually stepping by week or day.
///
/// **The switcher is selectable across all three [LayrzCalendarMode]
/// values** — month, week and day all dispatch through [onModeChanged] when
/// tapped, and the active mode renders as [LayrzButtonStyle.filled] while
/// the other two render [LayrzButtonStyle.outlined].
class LayrzCalendarHeader extends StatelessWidget {
  /// Creates a [LayrzCalendarHeader].
  const LayrzCalendarHeader({
    required this.focusedDate,
    required this.mode,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    this.onModeChanged,
    super.key,
  });

  /// The date currently focused, used to render the period label.
  ///
  /// The label's format depends on [mode]: "August 2026" for
  /// [LayrzCalendarMode.month], a full date such as "Friday, August 28" for
  /// [LayrzCalendarMode.day] (so a caller can orient after jumping here from
  /// a month cell's overflow chip), and a week range for
  /// [LayrzCalendarMode.week].
  ///
  /// Also drives the "Today" button's style: the button reads as
  /// [LayrzButtonStyle.filled] (attention-grabbing) whenever [focusedDate]
  /// is not today's calendar date, and as [LayrzButtonStyle.text]
  /// (de-emphasised) when it is — comparing year/month/day only, the same
  /// granularity `LayrzCalendarController.focusedDate` is normalized to.
  /// This reads "focused on today" as "the period currently in view is the
  /// current period, on the exact day the calendar was last navigated to or
  /// created with" — there is no separate "selected date" concept in this
  /// pass (see `LayrzCalendar`'s class doc), so [focusedDate] is the only
  /// candidate for this comparison.
  final DateTime focusedDate;

  /// The currently selected view mode.
  ///
  /// Selects both the previous/next buttons' label (see the class doc) and
  /// which switcher entry renders as active.
  final LayrzCalendarMode mode;

  /// Called when the "previous period" button is tapped.
  ///
  /// [LayrzCalendar] supplies the mode-appropriate callback
  /// (`previousMonth`/`previousWeek`/`previousDay`) — this header does not
  /// choose which one to call, only which label to show for [mode].
  final VoidCallback onPrevious;

  /// Called when the "next period" button is tapped.
  ///
  /// [LayrzCalendar] supplies the mode-appropriate callback
  /// (`nextMonth`/`nextWeek`/`nextDay`) — this header does not choose which
  /// one to call, only which label to show for [mode].
  final VoidCallback onNext;

  /// Called when the "Today" button is tapped.
  final VoidCallback onToday;

  /// Called with the newly selected mode when a switcher entry is tapped.
  ///
  /// Null disables the switcher entirely (all three buttons render but are
  /// non-interactive). `LayrzCalendar` always supplies this, so in practice
  /// the switcher is always interactive when reached through that widget.
  final void Function(LayrzCalendarMode mode)? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);
    final today = DateTime.now();
    final isFocusedOnToday =
        focusedDate.year == today.year && focusedDate.month == today.month && focusedDate.day == today.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Tight-fit `Expanded`, not `Flexible`, and it is the row's
            // ONLY flex participant — `Today` below is a plain trailing
            // child with no `Spacer()`. `Expanded` forces this group to
            // consume every pixel the row has left after `Today`'s
            // intrinsic width, which is exactly what pushes `Today` flush
            // to the trailing edge; the label's own `Flexible` inside then
            // ellipsizes within whatever width that forced allocation
            // leaves it. A `Flexible`/`Spacer()` pairing here does NOT
            // work: `RenderFlex` splits its free space evenly across every
            // flex child regardless of how much a loose-fit child actually
            // uses, so a second `flex: 1` participant (the label, or a
            // group wrapping it) silently strands half the row's free
            // space in its own allocation whenever the ellipsized text
            // doesn't need all of it, leaving `Today` short of the
            // trailing edge. That is precisely the regression this
            // structure fixes — see `calendar_header_test.dart` for the
            // geometry assertion.
            Expanded(
              child: Row(
                children: [
                  LayrzButton(
                    labelText: _previousLabel(l10n),
                    icon: MdiIcons.chevronLeft,
                    style: LayrzButtonStyle.textFab,
                    onTap: onPrevious,
                    // The nav row sits directly above the mode switcher, so
                    // a bottom-anchored tooltip (the button's own default)
                    // would render on top of the switcher's buttons and
                    // obscure them.
                    tooltipPosition: LayrzPreferredSide.top,
                  ),
                  SizedBox(width: tokens.spacing.sp1),
                  Flexible(
                    child: Text(
                      _periodLabel(l10n),
                      style: tokens.typography.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sp1),
                  LayrzButton(
                    labelText: _nextLabel(l10n),
                    icon: MdiIcons.chevronRight,
                    style: LayrzButtonStyle.textFab,
                    onTap: onNext,
                    // See the previous button's tooltipPosition comment above.
                    tooltipPosition: LayrzPreferredSide.top,
                  ),
                ],
              ),
            ),
            LayrzButton(
              labelText: l10n.calendarToday,
              // Filled draws attention back to today when the calendar is
              // focused elsewhere; text de-emphasises the button once the
              // caller is already looking at today, since tapping it again
              // would be a no-op. See `focusedDate`'s field doc for what
              // "focused on today" means here.
              style: isFocusedOnToday ? LayrzButtonStyle.text : LayrzButtonStyle.filled,
              onTap: onToday,
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp2),
        _ModeSwitcher(mode: mode, onModeChanged: onModeChanged),
      ],
    );
  }

  String _previousLabel(LayrzUiL10n l10n) {
    switch (mode) {
      case LayrzCalendarMode.month:
        return l10n.calendarMonthBack;
      case LayrzCalendarMode.week:
        return l10n.calendarWeekBack;
      case LayrzCalendarMode.day:
        return l10n.calendarDayBack;
    }
  }

  String _nextLabel(LayrzUiL10n l10n) {
    switch (mode) {
      case LayrzCalendarMode.month:
        return l10n.calendarMonthNext;
      case LayrzCalendarMode.week:
        return l10n.calendarWeekNext;
      case LayrzCalendarMode.day:
        return l10n.calendarDayNext;
    }
  }

  String _periodLabel(LayrzUiL10n l10n) {
    switch (mode) {
      case LayrzCalendarMode.month:
        return '${_monthName(l10n, focusedDate.month)} ${focusedDate.year}';
      case LayrzCalendarMode.week:
        return '${_monthName(l10n, focusedDate.month)} ${focusedDate.year}';
      case LayrzCalendarMode.day:
        return '${_weekdayName(l10n, focusedDate.weekday)}, ${_monthName(l10n, focusedDate.month)} '
            '${focusedDate.day}';
    }
  }

  static String _monthName(LayrzUiL10n l10n, int month) {
    return switch (month) {
      1 => l10n.monthJanuary,
      2 => l10n.monthFebruary,
      3 => l10n.monthMarch,
      4 => l10n.monthApril,
      5 => l10n.monthMay,
      6 => l10n.monthJune,
      7 => l10n.monthJuly,
      8 => l10n.monthAugust,
      9 => l10n.monthSeptember,
      10 => l10n.monthOctober,
      11 => l10n.monthNovember,
      12 => l10n.monthDecember,
      _ => throw ArgumentError.value(month, 'month', 'Must be between 1 and 12.'),
    };
  }

  static String _weekdayName(LayrzUiL10n l10n, int weekday) {
    return switch (weekday) {
      DateTime.monday => l10n.dateTimeMonday,
      DateTime.tuesday => l10n.dateTuesday,
      DateTime.wednesday => l10n.dateWednesday,
      DateTime.thursday => l10n.dateThursday,
      DateTime.friday => l10n.dateFriday,
      DateTime.saturday => l10n.dateSaturday,
      DateTime.sunday => l10n.dateSunday,
      _ => throw ArgumentError.value(weekday, 'weekday', 'Must be between 1 and 7.'),
    };
  }
}

/// The row of view-mode buttons under [LayrzCalendarHeader]'s navigation row.
class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onModeChanged});

  final LayrzCalendarMode mode;
  final void Function(LayrzCalendarMode mode)? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: tokens.spacing.sp1,
        children: [
          _buildButton(context, LayrzCalendarMode.month, l10n.calendarViewMonth),
          _buildButton(context, LayrzCalendarMode.week, l10n.calendarViewWeek),
          _buildButton(context, LayrzCalendarMode.day, l10n.calendarViewDay),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, LayrzCalendarMode buttonMode, String label) {
    final isSelected = buttonMode == mode;

    return LayrzButton(
      labelText: label,
      style: isSelected ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
      onTap: onModeChanged != null ? () => onModeChanged!(buttonMode) : null,
    );
  }
}
