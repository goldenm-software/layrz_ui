import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';

import '../models/time_of_day.dart';
import '../shared/day_grid.dart';
import '../shared/time_fields_panel.dart';
import 'datetime_presentation.dart';

/// The surface content for [LayrzDateTimeInput]: composes [LayrzPickersDayGrid]
/// and [LayrzPickersTimeFieldsPanel] inside **one** anchored panel, arranged
/// per [presentation], with an in-panel Cancel/Save footer.
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
/// **Involuntary close.** [LayrzAnchoredPanel] reconstructs this widget's
/// `State` fresh on every open (verified: `child` is consumed only inside
/// the overlay builder, which is torn down and rebuilt on close/reopen —
/// see [LayrzDateTimeInput] for the citation), so seeding in [initState]
/// alone is sufficient; [didUpdateWidget] additionally re-seeds for the
/// mobile bottom-sheet branch and for the rare case a caller changes
/// [initialDate]/[initialTime] while the panel is already open. Either path
/// also resets [_selectedTab]/[_step] back to their initial values, so a
/// dismissed draft never reopens mid-tab or mid-step.
class LayrzDateTimeSurface extends StatefulWidget {
  /// Which arrangement this surface uses.
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
  });

  @override
  State<LayrzDateTimeSurface> createState() => _LayrzDateTimeSurfaceState();
}

/// Which half of the panel [LayrzDateTimeInputPresentation.tabbed] currently
/// shows.
enum _DateTimeTab {
  /// The date grid is visible.
  date,

  /// The time fields panel is visible.
  time,
}

class _LayrzDateTimeSurfaceState extends State<LayrzDateTimeSurface> {
  DateTime? _date;
  LayrzTimeOfDay? _time;
  late DateTime _displayedMonth;

  /// Which tab is selected in [LayrzDateTimeInputPresentation.tabbed].
  /// Reset to [_DateTimeTab.date] on every seed — see [_seed].
  _DateTimeTab _selectedTab = _DateTimeTab.date;

  /// Whether [LayrzDateTimeInputPresentation.stepped] is on its time step
  /// (`true`) or its date step (`false`). Reset to `false` on every seed.
  bool _onTimeStep = false;

  @override
  void initState() {
    super.initState();
    _seed();
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
    _selectedTab = _DateTimeTab.date;
    _onTimeStep = false;
  }

  /// Whether both parts are set, so Save is enabled. Never `true` from a
  /// silently-substituted default — see the class doc's "No midnight
  /// default" note.
  bool get _canSave => _date != null && _time != null;

  void _handleSave() {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return;
    widget.onSave(date, time);
  }

  void _handleDateTap(DateTime date) {
    setState(() {
      _date = date;
      if (widget.presentation == LayrzDateTimeInputPresentation.stepped) {
        _onTimeStep = true;
      }
    });
  }

  void _handleTimeChanged(LayrzTimeOfDay time) {
    setState(() => _time = time);
  }

  void _stepMonth(int months) {
    setState(() {
      _displayedMonth = sameZoneDate(_displayedMonth, _displayedMonth.year, _displayedMonth.month + months);
    });
  }

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

  Widget _buildSteppedBody(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    if (!_onTimeStep) return _buildDatePart(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: l10n.actionCancel,
          onTap: () => setState(() => _onTimeStep = false),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => setState(() => _onTimeStep = false),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MdiIcons.chevronLeft, color: tokens.colors.fg2, size: tokens.typography.body.fontSize),
                  Text(l10n.dateTimePickerDate, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sp2),
        _buildTimePart(context),
      ],
    );
  }

  Widget _buildTabbedBody(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LayrzDateTimeTabStrip(
          selected: _selectedTab,
          onSelected: (tab) => setState(() => _selectedTab = tab),
        ),
        SizedBox(height: tokens.spacing.sp2),
        switch (_selectedTab) {
          _DateTimeTab.date => _buildDatePart(context),
          _DateTimeTab.time => _buildTimePart(context),
        },
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: LayrzButton.cancel(labelText: l10n.actionCancel, onTap: widget.onCancel),
        ),
        SizedBox(width: tokens.spacing.sp2),
        Expanded(
          child: LayrzButton.save(
            labelText: l10n.actionSave,
            onTap: _canSave ? _handleSave : () {},
            isDisabled: !_canSave,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final body = widget.presentation == LayrzDateTimeInputPresentation.stepped
        ? _buildSteppedBody(context)
        : _buildTabbedBody(context);

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          SizedBox(height: tokens.spacing.sp3),
          _buildFooter(context),
        ],
      ),
    );
  }
}

/// A two-header selectable tab strip switching between
/// [LayrzDateTimeSurface]'s date and time halves — the primitive built for
/// [LayrzDateTimeInputPresentation.tabbed] since this Material-free library
/// has no `TabBar`/`TabController`.
///
/// **Library-private to this module** — not a new shared `LayrzTabs`
/// component; see the implementation plan for why building one here would
/// be out of scope for this unit.
///
/// **D15 compliance**: selection is communicated by colour and a bottom
/// indicator bar of *fixed* height/width per slot — never by resizing,
/// repadding, or rescaling a header. The indicator bar occupies the same
/// [sp1]-tall slot under every header at all times, painted transparent
/// when that header is not selected, so switching tabs never reflows the
/// strip.
///
/// **Keyboard reachable and screen-reader correct**: each header is a
/// [FocusableActionDetector] wired to [ActivateIntent] (Enter/Space
/// activates, mirroring `LayrzCard`'s identical pattern) and wrapped in
/// [Semantics] reporting `button: true` and `selected`. Switching tabs
/// never commits or closes the panel — see [LayrzDateTimeSurface]'s own
/// `onSelected` handler, which only calls `setState`.
class _LayrzDateTimeTabStrip extends StatelessWidget {
  /// The currently selected tab.
  final _DateTimeTab selected;

  /// Called with the tapped or activated tab.
  final ValueChanged<_DateTimeTab> onSelected;

  /// Creates a new [_LayrzDateTimeTabStrip].
  const _LayrzDateTimeTabStrip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _LayrzDateTimeTabHeader(
            label: l10n.dateTimePickerDate,
            isSelected: selected == _DateTimeTab.date,
            onTap: () => onSelected(_DateTimeTab.date),
          ),
        ),
        Expanded(
          child: _LayrzDateTimeTabHeader(
            label: l10n.dateTimePickerTime,
            isSelected: selected == _DateTimeTab.time,
            onTap: () => onSelected(_DateTimeTab.time),
          ),
        ),
      ],
    );
  }
}

/// A single header inside [_LayrzDateTimeTabStrip].
class _LayrzDateTimeTabHeader extends StatefulWidget {
  /// The header's label text.
  final String label;

  /// Whether this header is the currently selected tab.
  final bool isSelected;

  /// Called when this header is tapped or activated via keyboard.
  final VoidCallback onTap;

  /// Creates a new [_LayrzDateTimeTabHeader].
  const _LayrzDateTimeTabHeader({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_LayrzDateTimeTabHeader> createState() => _LayrzDateTimeTabHeaderState();
}

class _LayrzDateTimeTabHeaderState extends State<_LayrzDateTimeTabHeader> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Colour-only state resolution (D15): selection takes precedence over
    // hover/focus, matching this batch's usual precedence style
    // (disabled > readOnly > error > pressed > hover/focused > default).
    // Nothing here ever changes size, padding, or the indicator bar's
    // fixed-height slot -- only these two colours and the bar's opacity do.
    final labelColor = widget.isSelected
        ? tokens.colors.primary.shade500
        : (_isHovered || _isFocused)
        ? tokens.colors.fg1
        : tokens.colors.fg2;
    final indicatorColor = widget.isSelected ? tokens.colors.primary.shade500 : const Color(0x00000000);

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          onShowHoverHighlight: (show) => setState(() => _isHovered = show),
          onShowFocusHighlight: (show) => setState(() => _isFocused = show),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          mouseCursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp2),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: tokens.typography.label.copyWith(color: labelColor),
                  ),
                ),
                Container(height: tokens.spacing.sp1 / 2, color: indicatorColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
