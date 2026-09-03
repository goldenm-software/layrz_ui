import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/time_of_day.dart';
import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'datetime_presentation.dart';
import 'datetime_surface.dart';

/// A Material-free single-datetime input field.
///
/// **DESIGN-51 collapses into this widget** — covered by, not removed, by
/// [presentation], though [presentation] itself is now deprecated and
/// ignored (see [LayrzDateTimeInputPresentation]'s own doc for the DESIGN-49
/// update). Composes [LayrzPickersDayGrid] and [LayrzPickersTimeFieldsPanel]
/// stacked in **one** scrollable surface via [LayrzDateTimeSurface].
///
/// **DESIGN-98: opens in [LayrzEndDrawer] on desktop, [LayrzBottomSheet]
/// below `isCompact`.** This widget previously opened [LayrzDateTimeSurface]
/// in the picker-private `LayrzPickerDrawer`, composing Cancel/Save inline —
/// see [LayrzDateRangeInput]'s identical doc for the full rationale, which
/// applies here unchanged. The mobile branch is unchanged.
///
/// **Commit model — Cancel/Save inside the surface, not commit-on-tap.** This
/// widget is single-valued by *type* (one [DateTime]) but collects **two
/// coordinated parts**, exactly as the range widgets coordinate two
/// endpoints — see the implementation plan's "commit boundary" section for
/// why the value type is the wrong signal to derive this from. Committing
/// on the date tap would emit a datetime whose time half the user never
/// chose. [onChanged] fires only once, on Save, with both parts combined; a
/// half-chosen datetime is never reported.
///
/// **No midnight default.** The time part seeds from [value]'s own time
/// when [value] is non-null; when [value] is `null` the time part starts
/// genuinely unset, never defaulted to midnight — see
/// [LayrzDateTimeSurface]'s class doc for why a silent default would be
/// exactly the problem the Save boundary exists to remove.
///
/// **Preserves `TZDateTime` zones**: the committed value is built via
/// `sameZoneDateTime` against [value] (or, when [value] is `null`, against
/// whichever date the surface reports first), so a caller passing a
/// `TZDateTime` gets a `TZDateTime` back in the same zone.
class LayrzDateTimeInput extends StatefulWidget {
  /// The currently selected datetime.
  final DateTime? value;

  /// Called with the combined date and time once the user presses Save.
  /// Never called with a value whose time half the user never touched.
  final ValueChanged<DateTime>? onChanged;

  /// Which arrangement this widget's surface uses. Both values share the
  /// identical Cancel/Save commit model and fire [onChanged] at the same
  /// moment — see [LayrzDateTimeInputPresentation]'s own doc for what
  /// genuinely differs between them.
  @Deprecated(
    'Ignored as of DESIGN-49: LayrzEndDrawer always shows the calendar and '
    'time fields together, so there is no longer a tab strip or step sequence '
    'to select between. Safe to drop from call sites.',
  )
  final LayrzDateTimeInputPresentation presentation;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// Whether the field is disabled (not interactive).
  final bool disabled;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Which [DateTime] weekday constant starts each week in the date grid.
  /// Defaults to [DateTime.monday] — deliberately differing from
  /// `LayrzCalendar`'s `DateTime.sunday` default; asserted to be within
  /// `DateTime.monday..DateTime.sunday`.
  final int firstDayOfWeek;

  /// Whether the date grid's ISO week-number gutter renders (cut to a thin
  /// decorative strip below `isCompact`). Defaults to `true`.
  final bool showWeekNumbers;

  /// Whether the seconds field is shown.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form. Defaults to `true`.
  final bool use24HourFormat;

  /// A strftime-style pattern used to format [value] for display, when
  /// [formatter] is not supplied. Defaults to `'%Y-%m-%d %H:%M'`.
  final String pattern;

  /// A full-control override for formatting [value] into display text,
  /// taking precedence over [pattern] when supplied.
  final String Function(DateTime)? formatter;

  /// The text editing controller for the anchor field.
  final TextEditingController? controller;

  /// The focus node for the anchor field.
  final FocusNode? focusNode;

  /// Whether the field uses the dense density variant.
  final bool dense;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Creates a new [LayrzDateTimeInput].
  const LayrzDateTimeInput({
    super.key,
    this.value,
    this.onChanged,
    // Not `this.presentation` shorthand: `@Deprecated` on a `this.`-forwarded
    // field only flags READS of the field (e.g. `widget.presentation`), not
    // a caller passing the named argument at the call site — the one place
    // this annotation actually needs to warn. An explicit parameter
    // assigned via the initializer list below is what Flutter's own SDK
    // uses for this exact case (see e.g. AppBarTheme's deprecated `color`
    // parameter) and is what makes `deprecated_member_use` fire on
    // `LayrzDateTimeInput(presentation: ...)` itself.
    @Deprecated(
      'Ignored as of DESIGN-49: LayrzEndDrawer always shows the calendar and '
      'time fields together, so there is no longer a tab strip or step sequence '
      'to select between. Safe to drop from call sites.',
    )
    LayrzDateTimeInputPresentation presentation = LayrzDateTimeInputPresentation.tabbed,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    this.showSeconds = false,
    this.use24HourFormat = true,
    this.pattern = '%Y-%m-%d %H:%M',
    this.formatter,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.helpTitleText,
    this.helpContentText,
  }) : // Deliberate: `this.presentation` shorthand would not let `presentation`
       // carry its own `@Deprecated` distinct from the field's (see the
       // parameter's own comment above).
       // ignore: prefer_initializing_formals
       presentation = presentation,
       assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
       );

  @override
  State<LayrzDateTimeInput> createState() => _LayrzDateTimeInputState();
}

class _LayrzDateTimeInputState extends State<LayrzDateTimeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// The [widget.value] the summary text was last computed for.
  ///
  /// Mirrors `LayrzDateInput`/`LayrzTimeInput`'s identical cache: computing
  /// the summary reads `context.l10n`, which cannot be established from
  /// `initState` (Flutter throws "dependOnInheritedWidgetOfExactType() ...
  /// called before initState() completed"), so the summary is instead
  /// computed reactively from `build` whenever `widget.value` has changed
  /// since the last computation. A plain `_lastValue` check can't
  /// distinguish "never computed" from "computed for `null`", so
  /// [_summaryPrimed] covers the first build explicitly, mirroring
  /// `LayrzTimeInput`'s identical need.
  bool _summaryPrimed = false;
  DateTime? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT calling the summary computation here -- see
    // `_summaryPrimed`'s own doc above.
  }

  @override
  void didUpdateWidget(LayrzDateTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _updateSummary() {
    final value = widget.value;
    if (value == null) {
      _controller.text = '';
      return;
    }
    final l10n = context.l10n;
    _controller.text = widget.formatter?.call(value) ?? formatStrftime(value, widget.pattern, l10n);
  }

  /// Combines [date] and [time] via `sameZoneDateTime`, threaded through
  /// [widget.value] (or, when that is `null`, through [date] itself) so a
  /// `TZDateTime` value round-trips in its own zone rather than being
  /// silently re-anchored to the host's local zone.
  DateTime _combine(DateTime date, LayrzTimeOfDay time) {
    final reference = widget.value ?? date;
    return sameZoneDateTime(reference, date.year, date.month, date.day, time.hour, time.minute, time.second);
  }

  void _handleSave(DateTime date, LayrzTimeOfDay time) {
    final combined = _combine(date, time);
    widget.onChanged?.call(combined);
    setState(() {
      _lastValue = combined;
      _updateSummary();
    });
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      // Names the sheet's route for screen readers with this field's own
      // label, mirroring `LayrzTimeInput`'s identical fallback -- without
      // it the sheet carries no name for what is being picked.
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzDateTimeSurface(
        presentation: widget.presentation,
        initialDate: widget.value,
        initialTime: widget.value == null ? null : LayrzTimeOfDay.fromDateTime(widget.value!),
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onSave: (date, time) {
          _handleSave(date, time);
          LayrzModalRoute.popIfCurrent(context);
        },
        onCancel: () => LayrzModalRoute.popIfCurrent(context),
      ),
      initialSize: 0.85,
      maxSize: 0.95,
      snapSizes: const [0.85, 0.95],
    );
  }

  /// Opens [LayrzDateTimeSurface] in [LayrzEndDrawer] on desktop — see
  /// [LayrzDateRangeInput._openDesktopDrawer]'s identical doc for the full
  /// rationale (DESIGN-98). This surface has no Clear affordance, so
  /// `hasSelection` is always `false`.
  ///
  /// **The race that made Save appear to do nothing (maintainer review,
  /// Finding 1).** `draftState` used to seed `canSave` from a hardcoded
  /// `false`, relying entirely on [LayrzDateTimeSurfaceState.initState]'s own
  /// post-frame callback to correct it via `syncDraftState`. [LayrzEndDrawer]
  /// hosts the surface behind a 300ms routed slide transition, so that
  /// callback can fire before [surfaceKey.currentState] is attached --
  /// `syncDraftState` then silently returned on a `null` state, and nothing
  /// else ever re-primed `draftState`: Save rendered permanently disabled
  /// for the rest of that open, even after the user picked both a date and a
  /// time. Reopening won because a fresh `State` wins the race the next
  /// time. Computing the seed from [widget.value] directly (mirroring
  /// [LayrzDateTimeSurfaceState.canSave]'s own `_date != null && _time !=
  /// null` predicate) makes `draftState` correct from its very first frame,
  /// before any callback runs at all -- `syncDraftState` below then only
  /// ever updates an already-correct value, so losing the race no longer
  /// matters.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((
      canSave: widget.value != null,
      hasSelection: false,
    ));
    final surfaceKey = GlobalKey<LayrzDateTimeSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      // Never observed null in practice once the seed above is correct --
      // see this method's own doc. Left unguarded rather than silently
      // swallowed, so a genuine regression here fails loudly instead of
      // permanently stranding `draftState` the way the hardcoded seed did.
      draftState.value = (canSave: state!.canSave, hasSelection: false);
    }

    await LayrzEndDrawer.show<void>(
      context,
      // `title` below carries `labelText` visibly, so `semanticLabel` falls
      // back to `hintText` only -- see LayrzDateInput's identical doc for
      // why passing `labelText` to both would double the announcement.
      semanticLabel: widget.labelText == null ? widget.hintText : null,
      // Escape and the barrier tap must still cancel a picker draft even
      // with actions present -- a settled ruling distinct from
      // LayrzDialog's "answered, not escaped" contract (that dialog-level
      // rule is about a DECISION being skipped; a picker's Cancel/Escape/
      // barrier tap are all equally safe "discard the draft" gestures, and
      // Escape=Cancel specifically is required by every picker test in
      // this batch). Explicitly overrides LayrzEndDrawer.show's own
      // actions-present-infers-false default.
      canDismiss: true,
      // DESIGN-98 Finding 5: the maintainer's explicit ruling is "title
      // should be the labelText of the input" -- see LayrzDateInput's
      // identical doc for the full rationale.
      title: widget.labelText != null ? Text(widget.labelText!) : null,
      builder: (context) => LayrzDateTimeSurface(
        key: surfaceKey,
        presentation: widget.presentation,
        initialDate: widget.value,
        initialTime: widget.value == null ? null : LayrzTimeOfDay.fromDateTime(widget.value!),
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        showInlineFooter: false,
        onDraftChanged: syncDraftState,
        onSave: (date, time) {
          _handleSave(date, time);
          LayrzModalRoute.popIfCurrent(context);
        },
        onCancel: () => LayrzModalRoute.popIfCurrent(context),
      ),
      actions: [
        LayrzPickerDrawerActions(
          draftState: draftState,
          onCancel: (drawerContext) => LayrzModalRoute.popIfCurrent(drawerContext),
          onClear: (_) {},
          onSave: (_) => surfaceKey.currentState?.save(),
        ),
      ],
    );

    draftState.dispose();
  }

  Widget _buildInteractiveField({required BuildContext context, required VoidCallback? onTap}) {
    final tokens = context.tokens;
    final displayText = _controller.text.isEmpty ? (widget.hintText ?? '') : _controller.text;

    final contentChild = SizedBox(
      width: double.infinity,
      child: Text(displayText, style: tokens.typography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    final states = <WidgetState>{if (widget.disabled) WidgetState.disabled};
    final hasErrors = widget.errors.isNotEmpty;
    final spec = LayrzInputStyleSpec.resolve(states: states, tokens: tokens, hasErrors: hasErrors);

    final fieldRow = buildPickerFieldRow(
      context: context,
      tokens: tokens,
      contentChild: contentChild,
      states: states,
      errors: widget.errors,
      disabled: widget.disabled,
      isRequired: widget.isRequired,
      hintText: widget.hintText,
      controller: _controller,
      dense: widget.dense,
      helpTitleText: widget.helpTitleText,
      helpContentText: widget.helpContentText,
      affordanceIcon: buildPickerAffordanceIcon(
        tokens: tokens,
        spec: spec,
        hasErrors: hasErrors,
        icon: MdiIcons.calendarClockOutline,
      ),
    );

    return buildPickerAnchorColumn(
      context: context,
      tokens: tokens,
      labelText: widget.labelText,
      isRequired: widget.isRequired,
      fieldRow: fieldRow,
      errors: widget.errors,
      hideDetails: widget.hideDetails,
      controller: _controller,
      focusNode: _focusNode,
      onTap: onTap,
      disabled: widget.disabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_summaryPrimed || widget.value != _lastValue) {
      _summaryPrimed = true;
      _lastValue = widget.value;
      _updateSummary();
    }

    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openDesktopDrawer);
  }
}
