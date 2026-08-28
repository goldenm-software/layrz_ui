import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'calendar_mode.dart';

/// The navigation chrome rendered above a [LayrzCalendar]'s active surface:
/// previous/next buttons flanking the focused period's label (`[◀] August
/// 2026 [▶]`), a "Today" shortcut, and a view-mode switcher row.
///
/// The previous/next buttons render as [LayrzButtonStyle.outlinedTonalFab] —
/// tonal rather than plain outlined, so the navigation chrome reads as a
/// cohesive, lower-emphasis unit around the period label. See [focusedDate]'s
/// field doc for how the "Today" button's own style is chosen.
///
/// **The switcher renders all three [LayrzCalendarMode] affordances even
/// though only [LayrzCalendarMode.month] is selectable in this pass** — week
/// and day are rendered disabled rather than omitted, so the chrome's shape
/// does not change once pass 2 makes them selectable. This follows directly
/// from the l10n strings already written for all three
/// (`calendarViewMonth`/`Week`/`Day`) and from the plan's requirement that
/// the enum ship with all three values now.
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

  /// The date currently focused, used to render the period label (e.g.
  /// "August 2026" for the month view).
  ///
  /// Also drives the "Today" button's style: the button reads as
  /// [LayrzButtonStyle.elevated] (attention-grabbing) whenever [focusedDate]
  /// is not today's calendar date, and as [LayrzButtonStyle.outlinedTonal]
  /// (de-emphasised) when it is — comparing year/month/day only, the same
  /// granularity `LayrzCalendarController.focusedDate` is normalized to.
  /// This reads "focused on today" as "the month currently in view is the
  /// current month, on the exact day the calendar was last navigated to or
  /// created with" — there is no separate "selected date" concept in this
  /// pass (see `LayrzCalendar`'s class doc), so [focusedDate] is the only
  /// candidate for this comparison.
  final DateTime focusedDate;

  /// The currently selected view mode.
  final LayrzCalendarMode mode;

  /// Called when the "previous period" button is tapped.
  final VoidCallback onPrevious;

  /// Called when the "next period" button is tapped.
  final VoidCallback onNext;

  /// Called when the "Today" button is tapped.
  final VoidCallback onToday;

  /// Called with the newly selected mode when a switcher entry is tapped.
  ///
  /// Null disables the switcher entirely (all three buttons render but are
  /// non-interactive). `LayrzCalendar` always supplies this in pass 1, since
  /// the plan requires the switcher to render even though only
  /// [LayrzCalendarMode.month] is implemented.
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
            LayrzButton(
              labelText: l10n.calendarMonthBack,
              icon: MdiIcons.chevronLeft,
              style: LayrzButtonStyle.outlinedTonalFab,
              onTap: onPrevious,
            ),
            SizedBox(width: tokens.spacing.sp1),
            Expanded(
              child: Text(
                _periodLabel(),
                style: tokens.typography.title,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: tokens.spacing.sp1),
            LayrzButton(
              labelText: l10n.calendarMonthNext,
              icon: MdiIcons.chevronRight,
              style: LayrzButtonStyle.outlinedTonalFab,
              onTap: onNext,
            ),
            SizedBox(width: tokens.spacing.sp2),
            LayrzButton(
              labelText: l10n.calendarToday,
              // Elevated draws attention back to today when the calendar is
              // focused elsewhere; outlinedTonal de-emphasises the button
              // once the caller is already looking at today, since tapping
              // it again would be a no-op. See `focusedDate`'s field doc for
              // what "focused on today" means here.
              style: isFocusedOnToday ? LayrzButtonStyle.outlinedTonal : LayrzButtonStyle.elevated,
              onTap: onToday,
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp2),
        _ModeSwitcher(mode: mode, onModeChanged: onModeChanged),
      ],
    );
  }

  String _periodLabel() {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[focusedDate.month - 1]} ${focusedDate.year}';
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
    // Week and day are not yet implemented (see LayrzCalendarMode's doc), so
    // their buttons render disabled regardless of onModeChanged, rather than
    // letting the caller select a mode LayrzCalendar would throw on.
    final isImplemented = buttonMode == LayrzCalendarMode.month;

    return LayrzButton(
      labelText: label,
      style: isSelected ? LayrzButtonStyle.elevated : LayrzButtonStyle.outlined,
      onTap: (isImplemented && onModeChanged != null) ? () => onModeChanged!(buttonMode) : null,
    );
  }
}
