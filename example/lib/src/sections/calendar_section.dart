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
/// - **All three [LayrzCalendarMode] values** — month, week and day — reached
///   through the header's view switcher, which pass 1 had locked with
///   `onTap: null` and this pass unlocked.
/// - **[LayrzCalendar.firstDayOfWeek]** set to `DateTime.monday`, a
///   non-default value, via a toggle button — the default changed from pass
///   1's hardcoded Monday-first grid to `DateTime.sunday`, so this page
///   exercises the case a caller restoring the old behaviour would use.
/// - **[LayrzCalendar.timeFormat]**, switched between [LayrzTimeFormat.h24]
///   (the default) and [LayrzTimeFormat.amPm] via a second toggle. Only the
///   week and day surfaces' hour axis and timed-event blocks change — the
///   month grid renders titles, never times, and is unaffected.
/// - **The space-derived event cap and its tappable "+N" chip**: one sample
///   day carries enough entries to overflow a normal-height month cell, so
///   the chip renders and can be tapped to jump straight to day view for
///   that date.
/// - **Overlapping timed events**, rendered as an even column split with the
///   later-starting entry drawn on top and the covered entry demoted to a
///   lighter fill — visible on the sample day's two overlapping meetings in
///   week and day view.
/// - **A multi-day entry spanning a week boundary**, proving the continuous
///   bar (and its per-month lane assignment) carries across the row break.
/// - Disabled weekends (via `isDateDisabled`), previous/next/Today
///   navigation, driven by a caller-owned [LayrzCalendarController] so its
///   state survives this widget's own rebuilds.
/// - **[LayrzCalendar.onTap]**, fired on empty surface taps (a month cell's
///   body, or an hour slot in week/day view), and **[LayrzCalendarEntry.onTap]**,
///   fired per-entry on every sample event — both wired here to open a
///   [LayrzDialog] showing exactly what the callback received, toggleable via
///   a third option button so the display-only ("no callback wired") case
///   stays demonstrable too.
class CalendarSection extends StatefulWidget {
  /// Creates a new [CalendarSection].
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  /// Controller for the demo calendar, created once so navigation state
  /// (including the active [LayrzCalendarMode]) survives this widget's own
  /// rebuilds.
  late LayrzCalendarController _controller;

  /// Sample events shown across the demo month, mixing single-day,
  /// overlapping-timed, dense and week-boundary-spanning multi-day entries so
  /// every pass-2 capability has something real to render.
  late List<LayrzCalendarEntry> _entries;

  /// The weekday the grid's columns start from.
  ///
  /// Starts at the component's own default ([DateTime.sunday]); the toggle
  /// button below flips it to [DateTime.monday] to demonstrate the
  /// non-default case.
  int _firstDayOfWeek = DateTime.sunday;

  /// The clock convention the week and day surfaces render hour labels and
  /// timed events in.
  ///
  /// Starts at the component's own default ([LayrzTimeFormat.h24]); the
  /// toggle button below switches it to [LayrzTimeFormat.amPm].
  LayrzTimeFormat _timeFormat = LayrzTimeFormat.h24;

  /// Whether [LayrzCalendar.onTap] and every sample entry's
  /// [LayrzCalendarEntry.onTap] are wired to open a result dialog.
  ///
  /// Starts `true` so both callbacks are demonstrable without an extra step;
  /// the toggle button below flips it to `false`, which passes `onTap: null`
  /// to the calendar and rebuilds the entries with `onTap: null` too --
  /// making the whole surface display-only, with no hover state and no
  /// pointer cursor over either empty space or an entry, per both
  /// callbacks' own docs.
  bool _tapEnabled = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _controller = LayrzCalendarController(initialDate: now);
    _entries = _buildEntries(now);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the sample entries for the month containing [now].
  ///
  /// Day 3 is intentionally overloaded with six entries — enough to overflow
  /// a normal-height month cell and force the "+N" overflow chip — and two of
  /// those six overlap in time, so the even-column-split overlap treatment is
  /// visible on the same day in week and day view. Day 14 anchors a
  /// multi-day entry deliberately chosen to cross a week-row boundary
  /// (spanning from a Friday into the following week) regardless of which
  /// [_firstDayOfWeek] is active, since a week always breaks somewhere inside
  /// a multi-day run of that length.
  ///
  /// Every entry is wired with `onTap: () => _showEntryTapDialog(...)` when
  /// [_tapEnabled] is `true`, and `onTap: null` otherwise -- rebuilt from
  /// scratch each time [_tapEnabled] flips (see the toggle button in
  /// [_buildOptionToggles]) rather than mutated in place, since
  /// [LayrzCalendarEntry] is immutable and has no setter for [onTap].
  List<LayrzCalendarEntry> _buildEntries(DateTime now) {
    final year = now.year;
    final month = now.month;

    /// Wires [onTap] for one sample entry, or leaves it `null` when
    /// [_tapEnabled] is `false`. Declared inline so each closure already has
    /// its own entry's title/start/end in scope, per
    /// [LayrzCalendarEntry.onTap]'s "deliberately parameterless" contract --
    /// there is nothing to hand back that this scope does not already have.
    VoidCallback? tapHandler(String title, DateTime start, DateTime end) {
      if (!_tapEnabled) {
        return null;
      }
      return () => _showEntryTapDialog(title: title, start: start, end: end);
    }

    final teamStandupStart = DateTime(year, month, 3, 9);
    final teamStandupEnd = DateTime(year, month, 3, 9, 15);
    final designReviewStart = DateTime(year, month, 3, 10);
    final designReviewEnd = DateTime(year, month, 3, 11, 30);
    final clientCallStart = DateTime(year, month, 3, 10, 45);
    final clientCallEnd = DateTime(year, month, 3, 11, 45);
    final budgetReviewStart = DateTime(year, month, 3, 13);
    final budgetReviewEnd = DateTime(year, month, 3, 14);
    final oneOnOneStart = DateTime(year, month, 3, 15);
    final oneOnOneEnd = DateTime(year, month, 3, 15, 30);
    final retroStart = DateTime(year, month, 3, 16);
    final retroEnd = DateTime(year, month, 3, 16, 45);
    final conferenceStart = DateTime(year, month, 14);
    final conferenceEnd = DateTime(year, month, 19);

    return [
      LayrzCalendarEntry(
        title: 'Team standup',
        start: teamStandupStart,
        end: teamStandupEnd,
        onTap: tapHandler('Team standup', teamStandupStart, teamStandupEnd),
      ),
      // Two overlapping timed entries on the same busy day, demonstrating the
      // even-column-split treatment: "Design review" starts first and is
      // demoted to a lighter fill once "Client call" (starting later) covers
      // it, per the later-starting-draws-on-top rule.
      LayrzCalendarEntry(
        title: 'Design review',
        start: designReviewStart,
        end: designReviewEnd,
        color: const Color(0xFF9C27B0),
        onTap: tapHandler('Design review', designReviewStart, designReviewEnd),
      ),
      LayrzCalendarEntry(
        title: 'Client call',
        start: clientCallStart,
        end: clientCallEnd,
        color: const Color(0xFF1E88E5),
        onTap: tapHandler('Client call', clientCallStart, clientCallEnd),
      ),
      LayrzCalendarEntry(
        title: 'Budget review',
        start: budgetReviewStart,
        end: budgetReviewEnd,
        color: const Color(0xFF43A047),
        onTap: tapHandler('Budget review', budgetReviewStart, budgetReviewEnd),
      ),
      LayrzCalendarEntry(
        title: 'One-on-one',
        start: oneOnOneStart,
        end: oneOnOneEnd,
        onTap: tapHandler('One-on-one', oneOnOneStart, oneOnOneEnd),
      ),
      LayrzCalendarEntry(
        title: 'Retro',
        start: retroStart,
        end: retroEnd,
        color: const Color(0xFFFF9800),
        onTap: tapHandler('Retro', retroStart, retroEnd),
      ),
      // Spans a week boundary: starts on the 14th and ends on the 19th, so
      // whichever weekday the grid starts from, at least one row break falls
      // inside this run.
      LayrzCalendarEntry(
        title: 'Conference',
        start: conferenceStart,
        end: conferenceEnd,
        color: const Color(0xFFFF9800),
        onTap: tapHandler('Conference', conferenceStart, conferenceEnd),
      ),
    ];
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
            'Month, week and day views with disabled weekends, overlapping timed events, a '
            'multi-day entry crossing a week boundary, and a "+N" overflow chip that jumps to day '
            'view. Tap empty space or an entry to see what each callback receives -- no day is '
            'selectable.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.spacing.sp3),
          _buildOptionToggles(tokens),
          SizedBox(height: tokens.spacing.sp3),
          Expanded(
            child: LayrzCalendar(
              controller: _controller,
              entries: _entries,
              isDateDisabled: _isWeekend,
              firstDayOfWeek: _firstDayOfWeek,
              timeFormat: _timeFormat,
              onTap: _tapEnabled ? _showSurfaceTapDialog : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the row of toggle buttons that flip [_firstDayOfWeek] and
  /// [_timeFormat] between their component-default and non-default values.
  ///
  /// Wrapped in a horizontally scrolling [SingleChildScrollView], mirroring
  /// `StepperSection`'s tab-toggle row: [LayrzButton]'s width is intrinsic,
  /// so a narrow enough window can exceed the row's available space, and this
  /// is a small options row rather than the page-filling component under
  /// demonstration.
  Widget _buildOptionToggles(LayrzTokens tokens) {
    final isMondayFirst = _firstDayOfWeek == DateTime.monday;
    final isAmPm = _timeFormat == LayrzTimeFormat.amPm;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: tokens.spacing.sp2,
        children: [
          LayrzButton(
            labelText: isMondayFirst ? 'Week starts Monday' : 'Week starts Sunday (default)',
            style: isMondayFirst ? LayrzButtonStyle.elevated : LayrzButtonStyle.outlined,
            onTap: () {
              setState(() => _firstDayOfWeek = isMondayFirst ? DateTime.sunday : DateTime.monday);
            },
          ),
          LayrzButton(
            labelText: isAmPm ? 'Time format: AM/PM' : 'Time format: 24h (default)',
            style: isAmPm ? LayrzButtonStyle.elevated : LayrzButtonStyle.outlined,
            onTap: () {
              setState(() => _timeFormat = isAmPm ? LayrzTimeFormat.h24 : LayrzTimeFormat.amPm);
            },
          ),
          LayrzButton(
            labelText: _tapEnabled ? 'Taps: wired' : 'Taps: disabled',
            style: _tapEnabled ? LayrzButtonStyle.elevated : LayrzButtonStyle.outlined,
            onTap: () {
              setState(() {
                _tapEnabled = !_tapEnabled;
                // Entries carry onTap baked in at construction time (see
                // _buildEntries) rather than as a mutable field, so flipping
                // _tapEnabled requires rebuilding the whole list -- there is
                // no copyWith(onTap: null) that would clear it back to null,
                // per LayrzCalendarEntry.copyWith's own doc.
                _entries = _buildEntries(DateTime.now());
              });
            },
          ),
        ],
      ),
    );
  }

  /// Shows the result of a [LayrzCalendar.onTap] callback in a [LayrzDialog].
  ///
  /// [date] is exactly what the calendar handed back: midnight for a month
  /// view tap, or the tapped instant snapped to the nearest 15 minutes for a
  /// week/day view tap. Formatted via [_formatTappedDateTime] so the
  /// distinction between the two is visible rather than hidden by a
  /// date-only or time-only rendering.
  void _showSurfaceTapDialog(DateTime date) {
    final tokens = context.tokens;

    LayrzDialog.show<void>(
      context,
      title: Text('LayrzCalendar.onTap', style: tokens.typography.title),
      content: Text(
        'Empty calendar surface was tapped.\n\n'
        'Received DateTime: ${_formatTappedDateTime(date)}\n\n'
        'Month view always hands back midnight; week and day view hand back the '
        'tapped instant snapped to the nearest 15 minutes.',
        style: tokens.typography.body,
      ),
    );
  }

  /// Shows the result of a [LayrzCalendarEntry.onTap] callback in a
  /// [LayrzDialog].
  ///
  /// [title], [start] and [end] are the tapped entry's own fields, already in
  /// scope where the closure was written (see [_buildEntries]'s `tapHandler`)
  /// -- [LayrzCalendarEntry.onTap] itself takes no parameters, per its own
  /// doc, so there is nothing to receive here beyond what the closure already
  /// captured.
  void _showEntryTapDialog({required String title, required DateTime start, required DateTime end}) {
    final tokens = context.tokens;

    LayrzDialog.show<void>(
      context,
      title: Text('LayrzCalendarEntry.onTap', style: tokens.typography.title),
      content: Text(
        'Entry tapped: "$title"\n\n'
        'Start: ${_formatTappedDateTime(start)}\n'
        'End: ${_formatTappedDateTime(end)}',
        style: tokens.typography.body,
      ),
    );
  }

  /// Formats [dateTime] as `YYYY-MM-DD HH:MM:SS`, zero-padded, so a midnight
  /// value (month view) and a time-of-day value (week/day view) are both
  /// fully visible rather than one of them being collapsed by a date-only or
  /// time-only format. No `intl` dependency is available to this package, so
  /// this pads by hand rather than reaching for `DateFormat`.
  String _formatTappedDateTime(DateTime dateTime) {
    String pad(int value) => value.toString().padLeft(2, '0');

    final year = dateTime.year.toString().padLeft(4, '0');
    final month = pad(dateTime.month);
    final day = pad(dateTime.day);
    final hour = pad(dateTime.hour);
    final minute = pad(dateTime.minute);
    final second = pad(dateTime.second);

    return '$year-$month-$day $hour:$minute:$second';
  }
}
