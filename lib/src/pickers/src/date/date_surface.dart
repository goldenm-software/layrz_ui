import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';

import '../shared/day_grid.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/grid_math.dart';
import '../shared/picker_inline_footer.dart';

/// The desktop/mobile-shared surface content for [LayrzDateInput]: a month
/// navigation header above a single [LayrzPickersDayGrid] page. Composed by
/// [LayrzDateInput] inside [LayrzEndDrawer] (desktop) or [LayrzBottomSheet]
/// (compact).
///
/// **DESIGN-98: no longer commits on tap.** Before DESIGN-98, tapping a day
/// fired [onDateSelected] immediately and [LayrzDateInput] closed the
/// hosting surface on that same gesture. The maintainer's instruction moved
/// every date-related input onto [LayrzEndDrawer] **with actions**,
/// including this one — a tap now only updates this surface's own in-progress
/// [_draft]; nothing is reported or closed until Save. See
/// [LayrzDateSurfaceState]'s class doc for the full Cancel/Save contract and
/// [LayrzDateInput]'s own doc for why this reverses a previously-settled
/// decision (D75, `engineering/milestone-4.md`).
///
/// **Owns its own month-navigation header.** Unlike
/// [LayrzPickersMonthGrid] — which renders its year-navigation chrome
/// inline because year-stepping is the whole of its own selection state —
/// [LayrzPickersDayGrid] renders only a single page and exposes no
/// navigation of its own; a caller supplies whichever month it wants
/// rendered. This widget is that caller: it owns [_displayedMonth] and
/// steps it with a `‹ "Month YYYY" › ` header built the same way
/// [LayrzPickersMonthGrid]'s year header is, reusing the existing
/// `calendarMonthBack`/`calendarMonthNext` l10n keys (already public,
/// already generic "previous/next month" navigation labels — reusing them
/// here needs no new l10n surface).
class LayrzDateSurface extends StatefulWidget {
  /// The currently selected date, or `null`.
  final DateTime? value;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Which weekday starts each week. Defaults to [DateTime.monday].
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders.
  final bool showWeekNumbers;

  /// Called with the drafted date when the user presses Save. Never called
  /// with a disabled or unselected value.
  final ValueChanged<DateTime> onDateSelected;

  /// Called when the user presses Cancel or otherwise dismisses the surface
  /// involuntarily. The caller is responsible for actually closing the
  /// hosting surface; this widget only reports the intent. `null` on the
  /// mobile [LayrzBottomSheet] path, which has no Cancel action of its own
  /// (tap-outside/Escape/back dismiss it directly).
  final VoidCallback? onCancel;

  /// Called on every draft mutation (a day tap), so [LayrzDateInput] can
  /// refresh the `actions` it builds outside this surface. Ignored when
  /// [showInlineFooter] is `true`.
  final VoidCallback? onDraftChanged;

  /// Whether this surface renders its own Cancel/Save footer inline, as the
  /// last child of its scrolling body.
  ///
  /// Defaults to `false` — unlike the five range-shaped surfaces, this
  /// widget has no pre-DESIGN-98 mobile footer to preserve (it committed on
  /// tap everywhere), so both the desktop [LayrzEndDrawer] and mobile
  /// [LayrzBottomSheet] paths now render Cancel/Save the same way: via
  /// `actions`, built by [LayrzDateInput]. See
  /// [LayrzDateRangeSurface.showInlineFooter]'s doc for the general
  /// mechanism this reuses.
  final bool showInlineFooter;

  /// Creates a new [LayrzDateSurface].
  const LayrzDateSurface({
    super.key,
    required this.value,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    required this.onDateSelected,
    this.onCancel,
    this.onDraftChanged,
    this.showInlineFooter = false,
  });

  @override
  State<LayrzDateSurface> createState() => LayrzDateSurfaceState();
}

/// State for [LayrzDateSurface].
///
/// **Public, not library-private, so [LayrzDateInput] can reach it through a
/// [GlobalKey]** (DESIGN-98) — see [LayrzDateRangeSurfaceState]'s identical
/// class doc for the full rationale. [_draft] holds the tapped-but-unsaved
/// date; [canSave] and [save] are the surface of that draft [LayrzDateInput]
/// reads and drives from its `actions` row.
class LayrzDateSurfaceState extends State<LayrzDateSurface> {
  late DateTime _displayedMonth;

  /// The tapped-but-unsaved date. `null` until the user taps a day, mirroring
  /// every other picker surface's "never silently default" discipline —
  /// [LayrzDateInput] renders Save disabled until this is set.
  DateTime? _draft;

  @override
  void initState() {
    super.initState();
    _seed();
    // Syncs the caller's external draft-state mirror immediately -- see
    // LayrzDateRangeSurfaceState's identical initState comment for why.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
  }

  @override
  void didUpdateWidget(LayrzDateSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Involuntary-close discipline: re-seed from `widget.value` on every
    // incoming update, not only in `initState` -- see the implementation
    // plan's "Involuntary close" section for why this is load-bearing.
    if (oldWidget.value != widget.value) {
      _seed();
    }
  }

  void _seed() {
    _displayedMonth = widget.value ?? DateTime.now();
    _draft = widget.value;
  }

  /// Whether a draft date has been tapped and Save is reachable. Read by
  /// [LayrzDateInput] through a [GlobalKey].
  bool get canSave => _draft != null;

  /// Commits the draft via [LayrzDateSurface.onDateSelected]. Invoked by
  /// [LayrzDateInput] through a [GlobalKey] when the Save action it builds
  /// is pressed.
  void save() {
    final draft = _draft;
    if (draft == null) return;
    widget.onDateSelected(draft);
  }

  /// Steps [_displayedMonth] by [months], through [sameZoneDate] rather
  /// than [Duration] arithmetic so a `TZDateTime` value steps according to
  /// its own zone's calendar-field rules rather than absolute elapsed time
  /// — see `sameZoneDate`'s own doc for why `Duration` is unsafe here.
  void _stepMonth(int months) {
    setState(() {
      _displayedMonth = sameZoneDate(_displayedMonth, _displayedMonth.year, _displayedMonth.month + months);
    });
  }

  /// Whether [date] is unselectable — mirrors [LayrzPickersDayGrid]'s own
  /// internal `_isDisabled || isAdjacent` combination exactly (bounds,
  /// [disabledDays], and outside-the-displayed-month), so
  /// `buildDayGridKeyboardHandler`'s skip-disabled-cells and
  /// Enter/Space-never-selects-a-disabled-cell behavior agrees with what
  /// the grid itself would actually let a tap select. Duplicated rather
  /// than read back from the grid because [LayrzPickersDayGrid] does not
  /// expose its resolved disabled set — see `grid_keyboard_handler.dart`'s
  /// `isDisabled` parameter doc.
  bool _isDisabled(DateTime date) {
    if (!isInGridMonth(date, year: _displayedMonth.year, month: _displayedMonth.month)) return true;
    if (widget.firstDay != null && date.isBefore(_dayOnly(widget.firstDay!))) return true;
    if (widget.lastDay != null && date.isAfter(_dayOnly(widget.lastDay!))) return true;
    return widget.disabledDays.any((d) => isSameDay(d, date));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _handleTap(DateTime date) {
    setState(() => _draft = date);
    widget.onDraftChanged?.call();
  }

  Widget _buildHeader(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: tokens.spacing.sp2),
          LayrzPickersDayGrid(
            displayedMonth: _displayedMonth,
            selectedDate: _draft,
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            disabledDays: widget.disabledDays,
            firstDayOfWeek: widget.firstDayOfWeek,
            showWeekNumbers: widget.showWeekNumbers,
            onDayTap: _handleTap,
            keyboardHandler: buildDayGridKeyboardHandler(
              isDisabled: _isDisabled,
              onSelect: _handleTap,
              firstDayOfWeek: widget.firstDayOfWeek,
            ),
            onDisplayedMonthChanged: _stepMonth,
          ),
          if (widget.showInlineFooter && widget.onCancel != null) ...[
            SizedBox(height: tokens.spacing.sp3),
            LayrzPickerInlineFooter(
              onCancel: widget.onCancel!,
              onSave: canSave ? save : null,
            ),
          ],
        ],
      ),
    );
  }
}
