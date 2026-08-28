import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'calendar_entry.dart';
import 'calendar_style_spec.dart';

/// The fixed height of the day-of-month number row at the top of a
/// [LayrzCalendarDayCell], not including the cell's own outer padding.
///
/// Fixed (rather than left to the date [Text]'s natural intrinsic height) so
/// `LayrzCalendarMonthSurface` can compute exactly where the first event
/// slot begins for its multi-day bar overlay, without measuring rendered
/// text metrics. See [kLayrzCalendarEventSlotHeight]'s doc for the sibling
/// constant this pairs with.
///
/// Sized with comfortable margin above [titleWeightedBodyStyle]'s rendered
/// height (`calendar_style_spec.dart`, 14px — `body`'s size, `title`'s
/// weight/family), which the date number now renders in — 16 was sized for
/// the previous plain `label` (12px) style and would clip a taller style.
/// See `_DateNumber`'s "no clipping" regression test, which compares
/// [RenderParagraph.textSize] (the paragraph's real intrinsic content size)
/// against this row's constrained box height directly, rather than trusting
/// a hardcoded margin to stay correct forever.
const double kLayrzCalendarDateRowHeight = 22;

/// The fixed height of one event slot (a chip, a reserved multi-day
/// placeholder, or a bar segment painted by `LayrzCalendarMonthSurface`),
/// including its bottom margin.
///
/// `LayrzCalendarMonthSurface` reads this constant, together with
/// [kLayrzCalendarDateRowHeight], to compute the exact vertical offset of
/// each event slot for its continuous multi-day bar overlay, so a bar lands
/// on top of the blank [_ReservedEventSlot] a day cell reserves for it
/// rather than overlapping a single-day chip. The two widgets must agree on
/// slot height pixel-for-pixel, or a bar would drift from the reserved gap
/// it is meant to cover.
///
/// It is also the unit `LayrzCalendarMonthSurface`'s per-week-row
/// `LayoutBuilder` divides available height by to compute the measured
/// `maxSlots` a [LayrzCalendarDayCell] is given — see [maxVisibleSlots]'s
/// field doc.
const double kLayrzCalendarEventSlotHeight = 20;

/// A single day cell in a [LayrzCalendar] month grid.
///
/// Renders the day-of-month number and up to [maxVisibleSlots] total event
/// slots — [entries] as ordinary title chips, plus [reservedLaneIndices]
/// blank placeholder slots of identical height — with any remainder
/// collapsed into a tappable "+N" chip.
///
/// **Four distinct tap regions, each with its own callback and its own
/// gating — never collapse two of them into one handler:**
///
/// 1. The **date number** → [onDateNumberTap], gated by
///    [dayNumberOpensDayView]. Navigates to day view.
/// 2. The **"+N" overflow chip** → [onOverflowTap], gated **only** by its
///    own nullability — [dayNumberOpensDayView] never governs it. Navigates
///    to day view.
/// 3. An **event chip** → that chip's own [LayrzCalendarEntry.onTap]. Its
///    own detector sits above the cell body's, so tapping a chip fires only
///    the entry's callback, never also [onTap]. There is no callback on
///    this cell (or on `LayrzCalendar`) for this region — it is wired
///    entirely from the entry the caller constructed.
/// 4. **Anywhere else in the cell body** → [onTap], with [date].
///
/// Regions 1 and 2 reach the same destination (day view) but are reached
/// through separate callbacks with separate gating — a caller collapsing
/// them into one handler would silently make the "+N" chip obey the date
/// number's flag, which is not the contract. Regions 3 and 4 are new
/// alongside 1 and 2, which are unaffected by their addition.
///
/// **[maxVisibleSlots] is measured, not a fixed constant.** It is computed
/// once per week row by `LayrzCalendarMonthSurface`'s `LayoutBuilder` (not
/// per cell — see that class's doc for why a cell-level measurement would
/// arrive too late to also bound the surface's multi-day bars) from the
/// row's actual available height, then passed down unchanged to every cell in
/// the row. All seven cells in a row share the same height, so one
/// measurement is correct for all of them.
///
/// **Multi-day events are not drawn by this cell.** A multi-day entry is
/// rendered as a single continuous bar spanning the week row, painted by
/// `LayrzCalendarMonthSurface` in a `Stack` layer above the grid of day
/// cells — see that class's doc. This cell only reserves the vertical space
/// a bar needs via [reservedLaneIndices], so the surface's bar lands
/// exactly on top of a blank slot rather than overlapping a single-day chip.
/// [entries] therefore never includes a multi-day [LayrzCalendarEntry] — the
/// surface filters those out before constructing this cell.
///
/// **Disabled dates and "no events" are rendered by distinct code paths.**
/// [isDisabled] alone controls the disabled visual treatment (dimmed date
/// number, muted background) via [LayrzCalendarDayCellStyleSpec]; whether
/// [entries] is empty never influences that treatment. A disabled day with
/// events still renders those events at their ordinary event colors — this
/// pass does not dim event chips to match the disabled date number — and a
/// day with no events that is not disabled renders as a perfectly ordinary
/// empty cell; there is no shared "nothing to show" branch between the two
/// states.
class LayrzCalendarDayCell extends StatelessWidget {
  /// Creates a [LayrzCalendarDayCell].
  const LayrzCalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isOutsideMonth,
    required this.isDisabled,
    required this.entries,
    this.reservedLaneIndices = const {},
    this.totalEventCount,
    this.maxVisibleSlots = 3,
    this.onOverflowTap,
    this.dayNumberOpensDayView = true,
    this.onDateNumberTap,
    this.onTap,
    super.key,
  });

  /// The calendar date this cell represents.
  final DateTime date;

  /// Whether [date] is today's date.
  final bool isToday;

  /// Whether [date] falls outside the month currently in view (a leading or
  /// trailing day used to fill out the grid).
  final bool isOutsideMonth;

  /// Whether [date] is disabled per the calendar's `isDateDisabled`
  /// predicate.
  ///
  /// Purely a visual flag — a disabled date does not prevent anything
  /// itself; the date number (see [onDateNumberTap]) and the "+N" chip (see
  /// [onOverflowTap]) are the only interactive elements in this cell, and
  /// disabled state does not affect either of them.
  final bool isDisabled;

  /// The single-day events that occupy [date], already filtered and ordered
  /// by the caller (`LayrzCalendarMonthSurface`).
  ///
  /// Must not contain a multi-day [LayrzCalendarEntry] (one whose
  /// [LayrzCalendarEntry.isMultiDay] is `true`) — those are rendered as
  /// continuous bars by the surface instead. See the class doc.
  final List<LayrzCalendarEntry> entries;

  /// The lane indices reserved by multi-day bars the surface will paint over
  /// this cell.
  ///
  /// Produced by `assignLanes` (`calendar_event_lane.dart`) under
  /// per-month lane stability: an entry keeps the same lane index across
  /// every week row it spans, so on any given day the occupied lanes can be
  /// sparse — e.g. `{2}` while lanes 0 and 1 are free that day, because those
  /// lanes belong to entries that occupy this date only in a different week
  /// of the same month. **This is expected and correct; blank reserved slots
  /// above real content on a sparse day are not a bug** — do not "fix" this
  /// by switching to per-week packing, which would reverse a deliberate
  /// design decision. Each index reserves one [kLayrzCalendarEventSlotHeight]
  /// slot and counts toward [maxVisibleSlots] the same way a chip does, so
  /// the "+N" overflow count and the vertical rhythm of the grid stay correct
  /// regardless of how a day's events are split between single-day chips and
  /// multi-day bars. Defaults to the empty set (no multi-day event occupies
  /// this date).
  ///
  /// This replaces the pass-1 `reservedMultiDaySlots` bare `int` count, which
  /// could only express "reserved densely from slot 0" and could not
  /// represent a sparse reservation like `{2}` — a change to this widget's
  /// public constructor required by per-month lane stability.
  final Set<int> reservedLaneIndices;

  /// The total number of events occupying [date] for semantics purposes,
  /// i.e. [entries] plus every multi-day entry the surface tracks
  /// separately.
  ///
  /// Null falls back to `entries.length` (no multi-day entries occupy this
  /// date), which keeps every caller that never had a "multi-day" concept
  /// unaffected. `LayrzCalendarMonthSurface` always supplies the true total
  /// so a day cell crossed by a multi-day bar still announces the full event
  /// count in [_semanticsLabel], even though that bar's chip never actually
  /// renders inside this cell.
  final int? totalEventCount;

  /// The maximum number of event slots (chips, reserved multi-day
  /// placeholders, and the overflow chip together) this cell may render,
  /// measured once per week row from the row's actual available height.
  ///
  /// Generalizes the pass-1 fixed cap of 3 into a value derived from real
  /// space: `(availableHeight / kLayrzCalendarEventSlotHeight).floor()`,
  /// computed by `LayrzCalendarMonthSurface`'s per-week-row `LayoutBuilder`.
  /// Defaults to `3` only as this constructor's fallback for a caller that
  /// does not compute one (e.g. a standalone test) — `LayrzCalendarMonthSurface`
  /// always supplies the measured value in production.
  ///
  /// **Floor case:** if this is `0` while [entries] or [reservedLaneIndices]
  /// is non-empty, the cell still renders exactly the overflow chip — never
  /// an empty cell with hidden data.
  final int maxVisibleSlots;

  /// Called when the overflow ("+N") chip is tapped, with [date].
  ///
  /// Null renders the chip (when shown) as inert — no hover state, no
  /// pointer cursor, no interactive semantics node. `LayrzCalendar` always
  /// supplies this, wiring it to jump to day view focused on [date] (mirrors
  /// `LayrzCalendarHeader`'s mode-switcher tap handling): `goToDate(date)`
  /// then `setMode(LayrzCalendarMode.day)`.
  ///
  /// **The cell background and individual event chips remain non-interactive
  /// by design** — generalizing tap behaviour to either of those would turn
  /// the whole grid into an implicit selection surface, which is explicitly
  /// out of scope (no day-tap selection, no return value). The date number
  /// (see [onDateNumberTap]) is the one other interactive element this cell
  /// has, and it does the same thing as this chip.
  final void Function(DateTime date)? onOverflowTap;

  /// Whether tapping the day-of-month number navigates to day view for
  /// [date].
  ///
  /// Defaults to `true`. When `false`, the date number renders fully inert —
  /// no hover state, no pointer cursor, and no interactive semantics node —
  /// rather than merely suppressing the callback behind a still-present
  /// [MouseRegion]. Has no effect on the "+N" overflow chip, which is
  /// governed solely by whether [onOverflowTap] is non-null.
  final bool dayNumberOpensDayView;

  /// Called when the day-of-month number is tapped, with [date].
  ///
  /// Only takes effect when [dayNumberOpensDayView] is `true`; `LayrzCalendar`
  /// always supplies this, wiring it identically to [onOverflowTap]:
  /// `goToDate(date)` then `setMode(LayrzCalendarMode.day)`. Null (or
  /// [dayNumberOpensDayView] `false`) renders the number as a plain,
  /// non-interactive label.
  final void Function(DateTime date)? onDateNumberTap;

  /// Called when the cell body is tapped anywhere that is not the date
  /// number, the "+N" overflow chip, or an event chip, with [date].
  ///
  /// Null renders the cell body's empty area inert — no hover state, no
  /// pointer cursor, no interactive semantics node — exactly as it was
  /// before this parameter existed. `LayrzCalendar` supplies this already
  /// normalized to midnight; see [LayrzCalendar.onTap]'s doc.
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);
    final spec = LayrzCalendarDayCellStyleSpec.resolve(
      tokens: tokens,
      isToday: isToday,
      isOutsideMonth: isOutsideMonth,
      isDisabled: isDisabled,
    );

    final reservedCount = reservedLaneIndices.length;
    final totalSlotsUsed = entries.length + reservedCount;
    final overflowCount = totalSlotsUsed > maxVisibleSlots ? totalSlotsUsed - (maxVisibleSlots - 1) : 0;

    // The overflow chip reserves its own slot from the budget rather than
    // being appended after `maxVisibleSlots` chips -- otherwise a cell with
    // exactly `maxVisibleSlots + 1` events would render `maxVisibleSlots`
    // chips plus a chip that no longer fits. When there is no overflow, the
    // full budget is available to reserved lanes and chips.
    final visibleChipBudget = overflowCount > 0
        ? (maxVisibleSlots - 1 - reservedCount).clamp(0, entries.length)
        : (maxVisibleSlots - reservedCount).clamp(0, entries.length);
    final visibleEntries = entries.take(visibleChipBudget).toList();

    // Floor case: a cell whose measured budget is 0 (or otherwise cannot fit
    // even the reserved lanes) still shows the overflow chip when there is
    // real data, rather than rendering nothing -- an empty-looking cell with
    // hidden events would recreate the invisible-data problem the cap exists
    // to avoid.
    final mustForceOverflow = maxVisibleSlots <= 0 && totalSlotsUsed > 0;
    final effectiveOverflowCount = mustForceOverflow ? totalSlotsUsed : overflowCount;
    final showOverflow = effectiveOverflowCount > 0;

    final dateNumberOnTap = dayNumberOpensDayView && onDateNumberTap != null ? () => onDateNumberTap!(date) : null;

    final cellBody = DecoratedBox(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        // Ordinary grid lines are no longer painted per cell -- they come
        // from `LayrzCalendarMonthSurface` wrapping the whole grid in a
        // divider-colored container and spacing cells apart by the
        // border width, so the container's background shows through as a
        // uniform single-width line everywhere (see that class's doc).
        // Today's ring is the one exception: it is a per-cell accent
        // highlight, not a structural grid line, so it still paints here
        // and only for `isToday`.
        border: isToday ? Border.all(color: spec.borderColor) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.sp1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: kLayrzCalendarDateRowHeight,
              child: _DateNumber(
                date: date,
                isToday: isToday,
                color: spec.dateColor,
                onTap: dateNumberOnTap,
              ),
            ),
            SizedBox(height: tokens.spacing.sp1),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < reservedCount; i++) const _ReservedEventSlot(),
                  for (final entry in visibleEntries) _EventChip(entry: entry, fallbackColor: spec.eventColor),
                ],
              ),
            ),
            if (showOverflow)
              SizedBox(
                height: kLayrzCalendarEventSlotHeight,
                child: _OverflowChip(
                  count: effectiveOverflowCount,
                  date: date,
                  l10n: l10n,
                  onTap: onOverflowTap == null ? null : () => onOverflowTap!(date),
                ),
              ),
          ],
        ),
      ),
    );

    // Region 4 of the four-region contract (see class doc): "anywhere else
    // in the cell body." Each event chip carries its own `GestureDetector`
    // reading that entry's own `onTap` (region 3), which Flutter's
    // hit-testing dispatches to before this outer one -- a tap that lands on
    // a chip is consumed there and never reaches this handler, so this
    // cell's `onTap` and an entry's own `onTap` never both fire for the same
    // tap. `HitTestBehavior.opaque` makes the whole padded cell body -- not
    // just its painted children -- a hit target, matching `_DateNumber`'s
    // own opaque region.
    final tappableBody = onTap == null
        ? cellBody
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap!(date),
              child: cellBody,
            ),
          );

    return Semantics(
      // Narrowed to the chrome (background, disabled/today state) only --
      // the date number, the overflow chip and every event chip below carry
      // their own live semantics node when interactive, so the blanket
      // exclusion pass 1 used (wrapping the entire cell body) can no longer
      // cover any of them. See `onDateNumberTap`'s and `onOverflowTap`'s
      // docs, and `LayrzCalendarEntry.onTap`'s doc, for why those are this
      // cell's interactive elements.
      label: _semanticsLabel(),
      container: true,
      child: tappableBody,
    );
  }

  /// Builds the one merged semantics announcement for this cell's chrome,
  /// e.g. "August 28, today, disabled, 2 events" — never separate nodes for
  /// the date number and its event chips (each wrapped in its own
  /// [ExcludeSemantics] in [build]).
  ///
  /// Uses [totalEventCount] (falling back to `entries.length`) so a date
  /// crossed by a multi-day bar still announces its full event count even
  /// though that event never renders as a chip inside this cell.
  String _semanticsLabel() {
    final buffer = StringBuffer(_formatDate());
    if (isToday) buffer.write(', today');
    if (isDisabled) buffer.write(', disabled');
    final eventCount = totalEventCount ?? entries.length;
    if (eventCount > 0) {
      buffer.write(', $eventCount ${eventCount == 1 ? 'event' : 'events'}');
    }
    return buffer.toString();
  }

  String _formatDate() {
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
    return '${monthNames[date.month - 1]} ${date.day}';
  }
}

/// The day-of-month number painted at the top of a [LayrzCalendarDayCell].
///
/// **Interactive by default** (per [LayrzCalendarDayCell.dayNumberOpensDayView]):
/// tapping it calls [onTap], which `LayrzCalendar` wires to open day view for
/// [date] — the same action as the "+N" overflow chip. Renders a hover state
/// and pointer cursor when [onTap] is non-null, varying only text color per
/// decision D15 (interaction states vary colour, never geometry) — the fixed
/// [kLayrzCalendarDateRowHeight] row this occupies must not grow or shift on
/// hover, since `LayrzCalendarMonthSurface` positions multi-day bars against
/// that exact offset. When [onTap] is null the number renders as a plain,
/// non-interactive label with no hover response, no pointer cursor, and no
/// interactive semantics node — matching [_OverflowChip]'s inert branch.
///
/// Renders in [titleWeightedBodyStyle] (`calendar_style_spec.dart`) —
/// `body`'s size with `title`'s weight/family/letterSpacing — rather than the
/// previous plain `label`, so the number reads as the grid's structural
/// content, not muted background texture, without the full `title` size
/// (18px) reading as oversized in a compact month cell. When interactive,
/// the tappable/hoverable region is padded slightly wider than the 1-2 digit
/// glyph's own tight bounds via [HitTestBehavior.opaque] — a PERMANENT hit
/// area, identical in every
/// interaction state, so this does not itself vary with hover and does not
/// violate D15.
class _DateNumber extends StatefulWidget {
  const _DateNumber({required this.date, required this.isToday, required this.color, this.onTap});

  /// The calendar date this number represents.
  final DateTime date;

  /// Whether [date] is today's date, rendered with a bold weight.
  final bool isToday;

  /// The text color resolved by [LayrzCalendarDayCellStyleSpec] for this
  /// cell's current state (today, outside-month, disabled).
  final Color color;

  /// Called when the number is tapped. Null renders it inert.
  final VoidCallback? onTap;

  @override
  State<_DateNumber> createState() => _DateNumberState();
}

class _DateNumberState extends State<_DateNumber> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isInteractive = widget.onTap != null;

    final Color textColor;
    if (!isInteractive) {
      textColor = widget.color;
    } else if (_isHovered) {
      textColor = tokens.colors.primary.shade500;
    } else {
      textColor = widget.color;
    }

    final text = SelectionContainer.disabled(
      child: AnimatedDefaultTextStyle(
        duration: tokens.motion.dHover,
        curve: tokens.motion.easing,
        // Body size with title's weight/family/letterSpacing (see
        // titleWeightedBodyStyle's doc) -- full `title` (18px) read as
        // oversized once actually rendered in a month cell; this reads as the
        // grid's structural content without being oversized. `isToday` still
        // steps the weight up further (to `bold`), since the composed style's
        // weight is already title's w600 and a same-weight "bold" would no
        // longer read as emphasis on top of it.
        style: titleWeightedBodyStyle(tokens).copyWith(
          color: textColor,
          fontWeight: widget.isToday ? FontWeight.bold : null,
        ),
        child: Text('${widget.date.day}'),
      ),
    );

    // Unlike `_OverflowChip` (which only ever renders when there is an
    // overflow, so its inert leaf node cannot collide with anything), this
    // number renders on every cell, including the "no events" baseline that
    // asserts an exact merged cell label. So the inert branch stays wrapped
    // in `ExcludeSemantics` -- its digits fold back into
    // `LayrzCalendarDayCell`'s own merged label instead of announcing
    // themselves a second time as a bare, purposeless leaf node.
    if (!isInteractive) return ExcludeSemantics(child: text);

    final content = Semantics(
      button: true,
      enabled: true,
      label: '${_formatDate(widget.date)}, opens day view',
      onTap: widget.onTap,
      child: ExcludeSemantics(child: text),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      // `HitTestBehavior.opaque` plus this padding widen the hoverable/
      // tappable region beyond the 1-2 digit glyph's own tight intrinsic
      // bounds -- a user's pointer landing just beside the number (still
      // within the date row) now still registers hover/tap, rather than
      // requiring a precise hit on the text itself. This is a PERMANENT hit
      // area, identical in every interaction state (idle, hover, pressed),
      // so it does not violate D15: the visible glyph's own size and the
      // row's fixed `kLayrzCalendarDateRowHeight` are unchanged -- only the
      // invisible tappable padding around it grew.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 / 2),
          child: content,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
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
    return '${monthNames[date.month - 1]} ${date.day}';
  }
}

/// A single event title chip painted inside a [LayrzCalendarDayCell].
///
/// Renders **filled** -- a full-opacity accent background with
/// [Color.contrastColor] text -- matching `LayrzChipStyle.filled` (the
/// `filledTonal` treatment this used to mirror was removed from the design
/// system entirely; see `_MultiDayBar` in `calendar_month_surface.dart`,
/// which must render identically for the same accent color).
///
/// **[LayrzCalendarEntry.isPreview] renders as a ghost of this same chip**:
/// reduced opacity plus a dashed-effect outline substituted for the solid
/// fill, keeping the entry's own [LayrzCalendarEntry.color] so it still
/// reads as *which* event, and identical geometry to a committed chip — no
/// size, padding, or margin difference (decision D15) — so a preview
/// occupies exactly the slot it would occupy once committed, and committing
/// it never shifts anything else in the cell.
///
/// **Interactive when [LayrzCalendarEntry.onTap] is non-null**: renders a
/// hover state and pointer cursor, varying only text/border colour per D15.
/// A tap on the chip is consumed here — its `GestureDetector` sits above
/// [LayrzCalendarDayCell]'s own cell-body detector — so the entry's own
/// `onTap` and the cell's `onTap` never both fire for the same tap. Null
/// renders the chip exactly as before this field existed: no hover, no
/// cursor, no interactive semantics node.
class _EventChip extends StatefulWidget {
  const _EventChip({required this.entry, required this.fallbackColor});

  /// The event this chip represents. Its own [LayrzCalendarEntry.onTap]
  /// drives this chip's interactivity — there is no separate callback
  /// parameter here.
  final LayrzCalendarEntry entry;

  /// The accent color used when [LayrzCalendarEntry.color] is null.
  final Color fallbackColor;

  @override
  State<_EventChip> createState() => _EventChipState();
}

class _EventChipState extends State<_EventChip> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final entry = widget.entry;
    final isInteractive = entry.onTap != null;
    final color = entry.color ?? widget.fallbackColor;
    final contentColor = entry.isPreview ? color : color.contrastColor;

    final pill = Container(
      margin: EdgeInsets.only(bottom: tokens.spacing.sp1 / 2),
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
      decoration: entry.isPreview
          ? BoxDecoration(
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: isInteractive && _isHovered ? 0.9 : 0.6)),
              borderRadius: BorderRadius.circular(tokens.radius.r1),
            )
          : BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(tokens.radius.r1),
            ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tokens.typography.label.copyWith(color: contentColor, fontSize: 10),
        ),
      ),
    );

    final content = isInteractive
        ? Semantics(
            button: true,
            enabled: true,
            label: entry.title,
            onTap: entry.onTap,
            child: ExcludeSemantics(child: pill),
          )
        : pill;

    final chip = !isInteractive
        ? content
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: GestureDetector(onTap: entry.onTap, child: content),
          );

    return SizedBox(height: kLayrzCalendarEventSlotHeight, child: chip);
  }
}

/// A blank placeholder occupying the same height as an [_EventChip], left
/// empty so a multi-day bar painted by `LayrzCalendarMonthSurface` can be
/// positioned on top of it without overlapping a single-day chip.
///
/// Renders nothing visible of its own — the bar is painted by the surface in
/// a layer above this cell, not by this widget.
class _ReservedEventSlot extends StatelessWidget {
  const _ReservedEventSlot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: kLayrzCalendarEventSlotHeight);
  }
}

/// The tappable "+N" overflow chip shown when a [LayrzCalendarDayCell] cannot
/// fit all of a date's events within [LayrzCalendarDayCell.maxVisibleSlots].
///
/// **Interactive by design** (reversing pass 1's inert "+N" chip): tapping it
/// calls [onTap], which `LayrzCalendar` wires to open day view for [date].
/// Renders a hover state and pointer cursor when [onTap] is non-null, varying
/// only text color per decision D15 (interaction states vary colour, never
/// geometry) — a chip that grew on hover would also destabilise the
/// surrounding slot-budget math. When [onTap] is null the chip renders as a
/// plain, non-interactive label with no hover response and the default
/// cursor.
///
/// **Styled as a pill, matching [_EventChip]'s geometry exactly** (same
/// height, corner radius, padding, and text scale) but filled with the
/// neutral [LayrzColorTokens.sf3] surface step rather than an event accent —
/// this reads as "a member of the same stack" while staying visually
/// distinct from a real event. `sf3` was chosen over `sf1`/`sf2` because it
/// is the token this design system already earmarks for "nested containers
/// and secondary elevations" (see [LayrzColorTokens.sf3]'s doc), which is
/// exactly this chip's role: a control sitting on top of the cell, not part
/// of its background. Text uses [LayrzColorTokens.fg2] (secondary text) both
/// at rest and unchanged by the fill — [fg2] is legible against `sf3` and
/// reads as muted-but-readable, matching the "this is a control, not an
/// event" intent, rather than [fg1]'s full-strength contrast which would
/// make the chip compete visually with real event chips. This was resurrected
/// from pass 1's plain-text treatment per the maintainer's report that the
/// bare "+N" read as a caption rather than a list member; it does not
/// reintroduce the inert styling an earlier review rejected, because that
/// ruling predates this chip becoming interactive (tap navigates to day
/// view) — a pill styled like its neighbours is honest now, not misleading.
class _OverflowChip extends StatefulWidget {
  const _OverflowChip({required this.count, required this.date, required this.l10n, required this.onTap});

  /// The number of events hidden by this cell's cap.
  final int count;

  /// The calendar date this chip's overflow belongs to, used to build a
  /// concrete semantics label (e.g. "3 more events, opens day view for
  /// August 28") rather than a bare count.
  final DateTime date;

  /// Localized strings used to format the date portion of the semantics
  /// label.
  final LayrzUiL10n l10n;

  /// Called when the chip is tapped. Null renders the chip inert.
  final VoidCallback? onTap;

  @override
  State<_OverflowChip> createState() => _OverflowChipState();
}

class _OverflowChipState extends State<_OverflowChip> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isInteractive = widget.onTap != null;

    // Text color varies with hover per decision D15 (colour only, never
    // geometry); the pill's fill itself does not change on hover, matching
    // `_EventChip`'s always-solid treatment.
    final Color textColor;
    if (!isInteractive) {
      textColor = tokens.colors.fg2;
    } else if (_isHovered) {
      textColor = tokens.colors.primary.shade500;
    } else {
      textColor = tokens.colors.fg2;
    }

    final label = '+${widget.count}';
    final text = AnimatedDefaultTextStyle(
      duration: tokens.motion.dHover,
      curve: tokens.motion.easing,
      style: tokens.typography.label.copyWith(color: textColor, fontSize: 10),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    // Same pill geometry as `_EventChip`: identical height, margin, padding
    // and corner radius, so the two read as members of the same stack. Only
    // the fill differs -- `sf3` (neutral) here versus an event accent there.
    final pill = Container(
      margin: EdgeInsets.only(bottom: tokens.spacing.sp1 / 2),
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
      decoration: BoxDecoration(
        color: tokens.colors.sf3,
        borderRadius: BorderRadius.circular(tokens.radius.r1),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: text,
      ),
    );

    // `enabled`/`button` are only passed when interactive -- Semantics adds
    // the `hasEnabledState` flag whenever `enabled` is non-null, so a plain
    // (non-interactive) chip must omit both to read as an ordinary static
    // label rather than a "disabled button".
    final content = isInteractive
        ? Semantics(
            button: true,
            enabled: true,
            label:
                '${widget.count} more ${widget.count == 1 ? 'event' : 'events'}, opens day view for '
                '${_formatDate(widget.l10n, widget.date)}',
            onTap: widget.onTap,
            child: ExcludeSemantics(child: pill),
          )
        : pill;

    if (!isInteractive) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: content,
      ),
    );
  }

  static String _formatDate(LayrzUiL10n l10n, DateTime date) {
    final month = switch (date.month) {
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
      _ => '',
    };
    return '$month ${date.day}';
  }
}
