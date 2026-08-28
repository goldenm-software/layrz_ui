import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Builds the calendar section for the showroom.
///
/// Demonstrates [LayrzCalendar], another page-filling component in the same
/// sense `LayrzStepper` is: it has no notion of managing its own height, and
/// expects its caller to hand it real, bounded space. Following the stepper
/// precedent, this page does **not** use `ShowroomSection` (which hands its
/// child unbounded height via a `SingleChildScrollView`) — instead it builds
/// its own title band plus a single [Expanded] content area, receiving the
/// page's own real, bounded constraints from `ShowroomLayout`.
///
/// This pass demonstrates:
/// - The month grid with disabled weekends (via `isDateDisabled`).
/// - A mix of single-day and multi-day events.
/// - Previous/next/Today navigation, driven by a caller-owned
///   [LayrzCalendarController] so its state survives this widget's own
///   rebuilds.
/// - The view-mode switcher chrome, with week/day rendered but disabled —
///   this pass renders month only; see `LayrzCalendar`'s class doc.
class CalendarSection extends StatefulWidget {
  /// Creates a new [CalendarSection].
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  /// Controller for the demo calendar, created once so navigation state
  /// survives this widget's own rebuilds.
  late LayrzCalendarController _controller;

  /// Sample events shown across the demo month, mixing single-day and
  /// multi-day entries to prove both render without breaking the grid.
  late List<LayrzCalendarEntry> _entries;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _controller = LayrzCalendarController(initialDate: now);
    _entries = [
      LayrzCalendarEntry(
        title: 'Team standup',
        start: DateTime(now.year, now.month, 3),
        end: DateTime(now.year, now.month, 3),
      ),
      LayrzCalendarEntry(
        title: 'Design review',
        start: DateTime(now.year, now.month, 10),
        end: DateTime(now.year, now.month, 10),
        color: const Color(0xFF9C27B0),
      ),
      LayrzCalendarEntry(
        title: 'Company offsite',
        start: DateTime(now.year, now.month, 14),
        end: DateTime(now.year, now.month, 16),
        color: const Color(0xFFFF9800),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Disables every Saturday and Sunday, demonstrating the predicate-shaped
  /// `isDateDisabled` API against a rule that a bounded set could not express
  /// as naturally.
  bool _isWeekend(DateTime date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendar', style: tokens.typography.headline),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'A month grid with disabled weekends and single/multi-day events. Display-and-navigate '
            'only in this pass -- no day is selectable yet.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Expanded(
            child: LayrzCalendar(
              controller: _controller,
              entries: _entries,
              isDateDisabled: _isWeekend,
            ),
          ),
        ],
      ),
    );
  }
}
