import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';

import '../models/time_of_day.dart';
import '../shared/day_grid.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/grid_math.dart';
import '../shared/picker_inline_footer.dart';
import '../shared/time_fields_panel.dart';
import 'datetime_presentation.dart';

/// The surface content for [LayrzDateTimeInput]: composes [LayrzPickersDayGrid]
/// and [LayrzPickersTimeFieldsPanel] stacked in **one** scrollable container
/// (its host is [LayrzEndDrawer] on desktop, [LayrzBottomSheet] below
/// `isCompact`), with a Cancel/Save footer on the mobile path.
///
/// **DESIGN-49 retired the tab/step presentation.** [LayrzDateTimeInput]
/// previously arranged its date and time parts per [presentation]
/// ([LayrzDateTimeInputPresentation.tabbed]/`.stepped`), because the old
/// [LayrzAnchoredPanel] container was too cramped to show both at once. The
/// drawer has the vertical room to show the calendar and the time fields
/// together, so the presentation split has no reason left to exist — this
/// surface always renders both parts stacked, in that fixed order, and
/// [presentation] is accepted but ignored (see that enum's own doc for why
/// it is deprecated rather than removed).
///
/// **DESIGN-98: Cancel/Save move to [LayrzEndDrawer.show]'s `actions` slot on
/// desktop.** See [LayrzDateTimeSurfaceState]'s class doc for why this
/// surface's `State` is now public.
///
/// **Commit model — Cancel/Save, not commit-on-tap.** [LayrzDateTimeInput] is
/// single-valued by *type* (one [DateTime]) but collects two coordinated
/// parts (a date and a time), which is the actual line the implementation
/// plan draws between the three commit-on-tap widgets and the five
/// Save-carrying ones — see "The commit boundary" section there. Neither
/// picking a date nor editing a time field reports or closes anything by
/// itself; only [onSave] does, and only once both parts are set.
///
/// **No midnight default.** [_time] starts as whatever [initialTime] seeds
/// it to — `null` when [LayrzDateTimeInput.value] itself was `null` — and
/// stays `null` until the user has actually touched the time fields. Save
/// is disabled while either part is unset, so there is no way to commit a
/// time the user never chose; see [_canSave].
///
/// **Involuntary close.** [LayrzEndDrawer.show] reconstructs this widget's
/// `State` fresh on every open — a [Navigator.push] always builds a fresh
/// subtree — so seeding in [initState] alone is sufficient;
/// [didUpdateWidget] additionally re-seeds for the rare case a caller
/// changes [initialDate]/[initialTime] while the surface is already open
/// (the mobile bottom-sheet path, or a caller rebuilding this widget in
/// place).
class LayrzDateTimeSurface extends StatefulWidget {
  /// Deprecated and ignored as of DESIGN-49 — see
  /// [LayrzDateTimeInputPresentation]'s own class doc. Retained on the
  /// constructor only so [LayrzDateTimeInput] can keep forwarding its own
  /// (also deprecated) `presentation` parameter without a breaking removal.
  final LayrzDateTimeInputPresentation presentation;

  /// The date part to seed the draft from, or `null` if unset.
  final DateTime? initialDate;

  /// The time part to seed the draft from, or `null` if unset. Never
  /// defaulted to midnight by this widget or its caller — see the class doc.
  final LayrzTimeOfDay? initialTime;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Which [DateTime] weekday constant starts each week in the day grid.
  /// Defaults to [DateTime.monday].
  final int firstDayOfWeek;

  /// Whether the day grid's ISO week-number gutter renders.
  final bool showWeekNumbers;

  /// Whether the seconds field is shown.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form.
  final bool use24HourFormat;

  /// Called with the committed date and time when the user presses Save.
  /// Never called with a `null` part — see [_canSave].
  final void Function(DateTime date, LayrzTimeOfDay time) onSave;

  /// Called when the user cancels — Escape, an involuntary close, or the
  /// explicit Cancel button. The caller closes the hosting surface without
  /// reporting anything; no partial commit is ever made.
  final VoidCallback onCancel;

  /// Called on every draft mutation (a date tap or time field edit), so
  /// [LayrzDateTimeInput] can refresh the `actions` it builds outside this
  /// surface. Ignored when [showInlineFooter] is `true`.
  final VoidCallback? onDraftChanged;

  /// Whether this surface renders its own Cancel/Save footer inline, as the
  /// last child of its scrolling body.
  ///
  /// Defaults to `true`, preserving the mobile [LayrzBottomSheet] path
  /// exactly as it behaved before DESIGN-98. Pass `false` when hosting this
  /// surface in [LayrzEndDrawer] — see [LayrzDateRangeSurface.showInlineFooter]'s
  /// identical doc for the full rationale.
  final bool showInlineFooter;

  /// Creates a new [LayrzDateTimeSurface].
  const LayrzDateTimeSurface({
    super.key,
    required this.presentation,
    required this.initialDate,
    required this.initialTime,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onSave,
    required this.onCancel,
    this.onDraftChanged,
    this.showInlineFooter = true,
  });

  @override
  State<LayrzDateTimeSurface> createState() => LayrzDateTimeSurfaceState();
}

/// State for [LayrzDateTimeSurface].
///
/// **Public, not library-private, so [LayrzDateTimeInput] can reach it
/// through a [GlobalKey]** (DESIGN-98) — see
/// [LayrzDateRangeSurfaceState]'s identical class doc for the full rationale.
class LayrzDateTimeSurfaceState extends State<LayrzDateTimeSurface> {
  DateTime? _date;
  LayrzTimeOfDay? _time;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _seed();
    // Syncs the caller's external draft-state mirror immediately -- see
    // LayrzDateRangeSurfaceState's identical initState comment for why.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
  }

  @override
  void didUpdateWidget(LayrzDateTimeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate != widget.initialDate || oldWidget.initialTime != widget.initialTime) {
      _seed();
    }
  }

  void _seed() {
    _date = widget.initialDate;
    _time = widget.initialTime;
    _displayedMonth = widget.initialDate ?? DateTime.now();
  }

  /// Whether both parts are set, so Save is enabled. Never `true` from a
  /// silently-substituted default — see the class doc's "No midnight
  /// default" note. Read by [LayrzDateTimeInput] through a [GlobalKey].
  bool get canSave => _date != null && _time != null;

  /// Commits the draft via [LayrzDateTimeSurface.onSave]. Invoked by
  /// [LayrzDateTimeInput] through a [GlobalKey] when the Save action it
  /// builds is pressed.
  void save() {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return;
    widget.onSave(date, time);
  }

  void _handleDateTap(DateTime date) {
    setState(() => _date = date);
    widget.onDraftChanged?.call();
  }

  void _handleTimeChanged(LayrzTimeOfDay time) {
    setState(() => _time = time);
    widget.onDraftChanged?.call();
  }

  void _stepMonth(int months) {
    setState(() {
      _displayedMonth = sameZoneDate(_displayedMonth, _displayedMonth.year, _displayedMonth.month + months);
    });
  }

  /// Whether [date] is unselectable — mirrors [LayrzPickersDayGrid]'s own
  /// internal `_isDisabled || isAdjacent` combination exactly, so
  /// `buildDayGridKeyboardHandler`'s skip-disabled-cells and
  /// Enter/Space-never-selects-a-disabled-cell behavior agrees with what
  /// the grid itself would actually let a tap select. See
  /// `LayrzDateSurface._isDisabled`'s identical doc for why this is
  /// duplicated rather than read back from the grid.
  bool _isDisabled(DateTime date) {
    if (!isInGridMonth(date, year: _displayedMonth.year, month: _displayedMonth.month)) return true;
    if (widget.firstDay != null && date.isBefore(_dayOnly(widget.firstDay!))) return true;
    if (widget.lastDay != null && date.isAfter(_dayOnly(widget.lastDay!))) return true;
    return widget.disabledDays.any((d) => isSameDay(d, date));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Widget _buildMonthHeader(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final label = formatStrftime(_displayedMonth, '%B %Y', l10n);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: l10n.calendarMonthBack,
          onTap: () => _stepMonth(-1),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => _stepMonth(-1),
              child: Icon(MdiIcons.chevronLeft, color: tokens.colors.fg2),
            ),
          ),
        ),
        Text(label, style: tokens.typography.title),
        Semantics(
          button: true,
          label: l10n.calendarMonthNext,
          onTap: () => _stepMonth(1),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => _stepMonth(1),
              child: Icon(MdiIcons.chevronRight, color: tokens.colors.fg2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePart(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildMonthHeader(context),
      SizedBox(height: context.tokens.spacing.sp2),
      LayrzPickersDayGrid(
        displayedMonth: _displayedMonth,
        selectedDate: _date,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onDayTap: _handleDateTap,
        keyboardHandler: buildDayGridKeyboardHandler(
          isDisabled: _isDisabled,
          onSelect: _handleDateTap,
          firstDayOfWeek: widget.firstDayOfWeek,
        ),
        onDisplayedMonthChanged: _stepMonth,
      ),
    ],
  );

  Widget _buildTimePart(BuildContext context) => LayrzPickersTimeFieldsPanel(
    // Genuinely unset until the user edits a field -- never defaulted to
    // midnight (see the class doc). The panel itself requires a non-null
    // `value` to render, so an unset draft is shown as 00:00 without ever
    // being *reported* as 00:00: `_handleTimeChanged` is the only path that
    // sets `_time`, and it only runs when the user actually edits a field.
    value: _time ?? const LayrzTimeOfDay(hour: 0, minute: 0),
    showSeconds: widget.showSeconds,
    use24HourFormat: widget.use24HourFormat,
    onChanged: _handleTimeChanged,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDatePart(context),
          SizedBox(height: tokens.spacing.sp3),
          _buildTimePart(context),
          if (widget.showInlineFooter) ...[
            SizedBox(height: tokens.spacing.sp3),
            LayrzPickerInlineFooter(
              onCancel: widget.onCancel,
              onSave: canSave ? save : null,
            ),
          ],
        ],
      ),
    );
  }
}
