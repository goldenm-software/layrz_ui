import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the pickers section for the showroom.
///
/// Demonstrates all eight `Layrz*Input` picker widgets. Unlike
/// [CalendarSection], none of these widgets is page-filling — each is a
/// bounded field that opens its own anchored panel (desktop, `>= 960px`) or
/// bottom sheet (`isCompact`, below `960px`), so this section follows
/// [AlertsSection]'s convention: [ShowroomSection] hands its content
/// unbounded height via a [SingleChildScrollView], which is exactly right
/// for a stack of independent field demos rather than a single component
/// that must fill the viewport.
///
/// This pass demonstrates:
/// - **Commit-on-tap** ([LayrzDateInput], [LayrzTimeInput],
///   [LayrzMonthInput]) versus **in-panel Cancel/Save**
///   ([LayrzDateRangeInput], [LayrzTimeRangeInput], [LayrzDateTimeInput],
///   [LayrzDateTimeRangeInput], [LayrzMonthRangeInput]) side by side, so the
///   two commit models are visibly different rather than merely documented.
/// - **`showSeconds` toggled live** on [LayrzTimeInput], proving no layout
///   reflow occurs when the seconds field appears or disappears (D15) —
///   two static instances would not demonstrate this, since nothing would
///   visibly change between them.
/// - **[LayrzMonthRangeInput] in both `consecutive` modes**, next to
///   [LayrzDateRangeInput], making explicit that month range is the *only*
///   range widget that allows a non-contiguous (arbitrary) selection; every
///   other range widget here is contiguous-only.
/// - **Both [LayrzDateTimeInputPresentation] values** on the same
///   [LayrzDateTimeInput], toggled live so the tabbed-vs-stepped difference
///   is observable rather than described.
/// - **The anchored-panel/bottom-sheet breakpoint itself is not fakeable**
///   from within a running app — there is no API to force a viewport size at
///   runtime — so this section documents the `960px` threshold in prose and
///   relies on the user resizing the window to see the panel become a sheet.
/// - **A `strftime` pattern swapped live** on [LayrzDateInput], comparing
///   `%Y-%m-%d` against `%B %d, %Y` on the same value, so the formatter is
///   visibly in effect rather than merely documented. No `intl` dependency
///   is available to this package.
/// - **`showWeekNumbers`** and a non-default `firstDayOfWeek`
///   (`DateTime.sunday`, deliberately differing from every picker's own
///   `DateTime.monday` default and from [LayrzCalendar]'s `DateTime.sunday`
///   default) on [LayrzDateInput].
/// - **An error state**, via a non-empty `errors` list, and a **disabled
///   instance**, both on [LayrzMonthInput] next to a normal instance, so the
///   danger styling and the inert styling are each visible beside the
///   default.
/// - **Contiguity rejection**: [LayrzDateRangeInput] seeded with a
///   pre-existing range, so the interior cells render locked/non-interactive
///   before any tap, demonstrating that only the two endpoints stay
///   tappable once a range exists.
class PickersSection extends StatefulWidget {
  /// Creates a new [PickersSection].
  const PickersSection({super.key});

  @override
  State<PickersSection> createState() => _PickersSectionState();
}

class _PickersSectionState extends State<PickersSection> {
  /// The committed value for the plain [LayrzDateInput] demo.
  DateTime? _date;

  /// Whether the plain date demo formats with `%B %d, %Y` instead of the
  /// widget's own `%Y-%m-%d` default.
  bool _useLongDatePattern = false;

  /// The committed value for the [LayrzTimeInput] demo.
  LayrzTimeOfDay? _time;

  /// Whether the [LayrzTimeInput] demo's seconds field is shown.
  bool _timeShowSeconds = false;

  /// The committed value for the [LayrzMonthInput] demo (normal instance).
  LayrzMonth? _month;

  /// The committed value for the [LayrzDateRangeInput] demo, pre-seeded so
  /// the contiguity-rejection behaviour (locked interior cells) is visible
  /// from the first frame rather than only after a first selection.
  LayrzDateRange? _dateRange = LayrzDateRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 10),
    end: DateTime(DateTime.now().year, DateTime.now().month, 15),
  );

  /// The committed start of the [LayrzTimeRangeInput] demo.
  LayrzTimeOfDay? _timeRangeStart;

  /// The committed end of the [LayrzTimeRangeInput] demo.
  LayrzTimeOfDay? _timeRangeEnd;

  /// The committed value for the [LayrzDateTimeInput] demo.
  DateTime? _dateTime;

  /// Which [LayrzDateTimeInputPresentation] the [LayrzDateTimeInput] demo
  /// currently uses.
  LayrzDateTimeInputPresentation _dateTimePresentation = LayrzDateTimeInputPresentation.tabbed;

  /// The committed start of the [LayrzDateTimeRangeInput] demo.
  DateTime? _dateTimeRangeStart;

  /// The committed end of the [LayrzDateTimeRangeInput] demo.
  DateTime? _dateTimeRangeEnd;

  /// The committed arbitrary (non-contiguous) selection for the first
  /// [LayrzMonthRangeInput] demo.
  List<LayrzMonth> _monthRangeArbitrary = const [];

  /// The committed contiguous range for the second [LayrzMonthRangeInput]
  /// demo.
  LayrzMonthRange? _monthRangeConsecutive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Pickers',
      description:
          'Eight Material-free date/time/month picker fields. Each opens an anchored panel on wide '
          'viewports (>= 960px) and a bottom sheet below that -- resize the window to see the switch.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spacing.sp5,
        children: [
          _buildBreakpointNote(tokens),
          _buildDateDemo(tokens),
          _buildTimeDemo(tokens),
          _buildMonthDemo(tokens),
          _buildDateRangeDemo(tokens),
          _buildTimeRangeDemo(tokens),
          _buildDateTimeDemo(tokens),
          _buildDateTimeRangeDemo(tokens),
          _buildMonthRangeDemo(tokens),
        ],
      ),
    );
  }

  /// Documents the `960px` anchored-panel/bottom-sheet breakpoint in prose,
  /// since no API exists to force a viewport size from within a running app
  /// — the only way to actually see both surfaces is to resize the window.
  Widget _buildBreakpointNote(LayrzTokens tokens) {
    return Container(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      decoration: BoxDecoration(color: tokens.colors.sf2, borderRadius: tokens.radius.br3),
      child: Text(
        'Every field below opens a LayrzAnchoredPanel anchored to the field on viewports >= 960px, and '
        'a LayrzBottomSheet on narrower ones (context.isCompact). Resize this window across 960px to '
        'see a field switch from one to the other.',
        style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
      ),
    );
  }

  /// Demonstrates [LayrzDateInput]: commit-on-tap, a live `strftime` pattern
  /// swap, `showWeekNumbers`, and a non-default `firstDayOfWeek`.
  Widget _buildDateDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzDateInput -- commit on tap', style: tokens.typography.title),
        Text(
          'Selecting a day commits immediately; there is no Save button. Toggle the pattern to see the '
          'strftime formatter change the display text for the same value. firstDayOfWeek is set to '
          'DateTime.sunday here, differing from the widget\'s own DateTime.monday default.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzButton(
          labelText: _useLongDatePattern ? 'Pattern: %B %d, %Y' : 'Pattern: %Y-%m-%d (default)',
          style: _useLongDatePattern ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
          onTap: () => setState(() => _useLongDatePattern = !_useLongDatePattern),
        ),
        LayrzDateInput(
          value: _date,
          onChanged: (value) => setState(() => _date = value),
          labelText: 'Date',
          hintText: 'Pick a date',
          pattern: _useLongDatePattern ? '%B %d, %Y' : '%Y-%m-%d',
          firstDayOfWeek: DateTime.sunday,
          showWeekNumbers: true,
        ),
      ],
    );
  }

  /// Demonstrates [LayrzTimeInput], including a live `showSeconds` toggle
  /// proving no layout reflow occurs when the seconds field appears (D15).
  Widget _buildTimeDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzTimeInput -- commit on tap', style: tokens.typography.title),
        Text(
          'Every field edit is itself a commit -- there is no separate save gesture. Toggle showSeconds '
          'below; the panel/sheet does not reflow when the seconds field appears or disappears.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzButton(
          labelText: _timeShowSeconds ? 'showSeconds: true' : 'showSeconds: false (default)',
          style: _timeShowSeconds ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
          onTap: () => setState(() => _timeShowSeconds = !_timeShowSeconds),
        ),
        LayrzTimeInput(
          value: _time,
          onChanged: (value) => setState(() => _time = value),
          labelText: 'Time',
          hintText: 'Pick a time',
          showSeconds: _timeShowSeconds,
        ),
      ],
    );
  }

  /// Demonstrates [LayrzMonthInput] three ways side by side: a normal
  /// instance, an instance with a non-empty `errors` list, and a `disabled`
  /// instance.
  Widget _buildMonthDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzMonthInput -- commit on tap', style: tokens.typography.title),
        Text(
          'Left: a normal instance. Middle: a non-empty errors list, showing the danger border. Right: '
          'disabled.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 4,
              child: LayrzMonthInput(
                value: _month,
                onChanged: (value) => setState(() => _month = value),
                labelText: 'Month',
                hintText: 'Pick a month',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 4,
              child: LayrzMonthInput(
                value: null,
                onChanged: (_) {},
                labelText: 'Month (error)',
                errors: const ['This field is required.'],
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 4,
              child: LayrzMonthInput(
                value: LayrzMonth.fromDateTime(DateTime.now()),
                onChanged: (_) {},
                labelText: 'Month (disabled)',
                disabled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Demonstrates [LayrzDateRangeInput] with in-panel Cancel/Save, seeded
  /// with a pre-existing range so the interior cells render locked and
  /// non-interactive before any tap -- only the two endpoints stay tappable
  /// once a range exists.
  Widget _buildDateRangeDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzDateRangeInput -- in-panel Cancel/Save', style: tokens.typography.title),
        Text(
          'Contiguous only. Seeded with a range below, so the days between the two endpoints render '
          'tinted and genuinely inert (no hover, no pointer cursor) before you tap anything -- only the '
          'two endpoints stay tappable once a range exists.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzDateRangeInput(
          value: _dateRange,
          onChanged: (value) => setState(() => _dateRange = value),
          labelText: 'Date range',
          hintText: 'Pick a date range',
        ),
      ],
    );
  }

  /// Demonstrates [LayrzTimeRangeInput], which follows the range rule (Save
  /// button inside the panel) despite pairing two single-time clusters
  /// rather than a grid.
  Widget _buildTimeRangeDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzTimeRangeInput -- in-panel Cancel/Save', style: tokens.typography.title),
        Text(
          'Built from two single-time clusters, but still gets a Save button -- every range widget in '
          'this batch shares the same commit model for uniformity.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzTimeRangeInput(
          startValue: _timeRangeStart,
          endValue: _timeRangeEnd,
          onChanged: (start, end) => setState(() {
            _timeRangeStart = start;
            _timeRangeEnd = end;
          }),
          labelText: 'Time range',
          hintText: 'Pick a time range',
        ),
      ],
    );
  }

  /// Demonstrates [LayrzDateTimeInput] with both [LayrzDateTimeInputPresentation]
  /// values toggled live, so the tabbed-vs-stepped arrangement is observable
  /// rather than only documented.
  Widget _buildDateTimeDemo(LayrzTokens tokens) {
    final isStepped = _dateTimePresentation == LayrzDateTimeInputPresentation.stepped;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzDateTimeInput -- in-panel Cancel/Save', style: tokens.typography.title),
        Text(
          'Single DateTime value, but collects two coordinated parts (date and time), so it gets a Save '
          'button like the range widgets. Toggle the presentation below: tabbed shows two selectable tab '
          'headers; stepped shows the calendar first, then advances to the time step with a back '
          'affordance.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzButton(
          labelText: isStepped ? 'Presentation: stepped' : 'Presentation: tabbed (default)',
          style: isStepped ? LayrzButtonStyle.filled : LayrzButtonStyle.outlined,
          onTap: () => setState(() {
            _dateTimePresentation = isStepped
                ? LayrzDateTimeInputPresentation.tabbed
                : LayrzDateTimeInputPresentation.stepped;
          }),
        ),
        LayrzDateTimeInput(
          value: _dateTime,
          onChanged: (value) => setState(() => _dateTime = value),
          presentation: _dateTimePresentation,
          labelText: 'Date & time',
          hintText: 'Pick a date and time',
        ),
      ],
    );
  }

  /// Demonstrates [LayrzDateTimeRangeInput], the widest of the range
  /// widgets, coordinating start/end dates each paired with their own time.
  Widget _buildDateTimeRangeDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzDateTimeRangeInput -- in-panel Cancel/Save', style: tokens.typography.title),
        Text(
          'Start and end datetimes, each with its own date and time part, committed together on Save.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzDateTimeRangeInput(
          startValue: _dateTimeRangeStart,
          endValue: _dateTimeRangeEnd,
          onChanged: (start, end) => setState(() {
            _dateTimeRangeStart = start;
            _dateTimeRangeEnd = end;
          }),
          labelText: 'Date & time range',
          hintText: 'Pick a date and time range',
        ),
      ],
    );
  }

  /// Demonstrates [LayrzMonthRangeInput] in both `consecutive` modes side by
  /// side, making explicit that month range is the only range widget in the
  /// whole batch that allows a non-contiguous (arbitrary) selection.
  Widget _buildMonthRangeDemo(LayrzTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sp3,
      children: [
        Text('LayrzMonthRangeInput -- in-panel Cancel/Save', style: tokens.typography.title),
        Text(
          'The only picker in this batch where a non-contiguous selection is reachable. Left: the '
          'default arbitrary mode (consecutive: false) -- pick any set of months, not necessarily '
          'adjacent. Right: consecutive mode (consecutive: true), which behaves like '
          'LayrzDateRangeInput\'s endpoint-adjust state machine.',
          style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
        ),
        LayrzRow(
          spacing: tokens.spacing.sp3,
          children: [
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzMonthRangeInput(
                arbitraryValue: _monthRangeArbitrary,
                onArbitraryChanged: (value) => setState(() => _monthRangeArbitrary = value),
                labelText: 'Months (arbitrary)',
                hintText: 'Pick any months',
              ),
            ),
            LayrzCol(
              xs: 12,
              md: 6,
              child: LayrzMonthRangeInput(
                consecutive: true,
                rangeValue: _monthRangeConsecutive,
                onRangeChanged: (value) => setState(() => _monthRangeConsecutive = value),
                labelText: 'Months (consecutive)',
                hintText: 'Pick a range of months',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
