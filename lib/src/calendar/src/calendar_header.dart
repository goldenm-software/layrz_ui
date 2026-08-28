import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'calendar_mode.dart';

/// The navigation chrome rendered above a [LayrzCalendar]'s active surface:
/// previous/next buttons, a "Today" shortcut, the focused period's label,
/// and a view-mode switcher row.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LayrzButton(
              labelText: l10n.calendarMonthBack,
              icon: MdiIcons.chevronLeft,
              style: LayrzButtonStyle.outlinedFab,
              onTap: onPrevious,
            ),
            SizedBox(width: tokens.spacing.sp1),
            LayrzButton(
              labelText: l10n.calendarMonthNext,
              icon: MdiIcons.chevronRight,
              style: LayrzButtonStyle.outlinedFab,
              onTap: onNext,
            ),
            SizedBox(width: tokens.spacing.sp2),
            Expanded(
              child: Text(
                _periodLabel(),
                style: tokens.typography.title,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: tokens.spacing.sp2),
            LayrzButton(
              labelText: l10n.calendarToday,
              style: LayrzButtonStyle.outlined,
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
