import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/date_range.dart';
import '../models/time_of_day.dart';
import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'datetime_range_surface.dart';

/// A Material-free start/end datetime-range input field.
///
/// **Cancel/Save live inside the hosting surface** — the maintainer ruled
/// this for uniformity across the whole range-widget batch (recorded as R1
/// in the dossier: `simoncito` argued this widget's own complexity favored
/// a dialog; the ruling kept every range widget on the same container).
///
/// **Opens via [LayrzResponsiveModal.show]**, which resolves to a dialog on
/// wide viewports or a [LayrzBottomSheet] below `isCompact` — see
/// [LayrzDateRangeInput]'s identical doc for the full rationale, which
/// applies here unchanged.
///
/// **No midnight default.** Each endpoint's time part seeds from
/// [startValue]/[endValue]'s own time when that value is non-null; when it
/// is `null` the corresponding time part starts genuinely unset, never
/// defaulted to midnight — see [LayrzDateTimeRangeSurface]'s class doc for
/// why a silent default would be exactly the problem the Save boundary
/// exists to remove.
///
/// **Preserves `TZDateTime` zones**: the committed endpoints are built via
/// `sameZoneDateTime`, so a caller passing `TZDateTime` values gets
/// `TZDateTime` values back in the same zone.
class LayrzDateTimeRangeInput extends StatefulWidget {
  /// The currently committed start datetime.
  final DateTime? startValue;

  /// The currently committed end datetime.
  final DateTime? endValue;

  /// Called with the new (start, end) datetimes when the user presses Save.
  /// Never called with a value whose time half the user never touched.
  final void Function(DateTime start, DateTime end)? onChanged;

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

  /// Which [DateTime] weekday constant starts each week in the day grid.
  /// Defaults to [DateTime.monday] — deliberately differing from
  /// `LayrzCalendar`'s `DateTime.sunday` default; asserted to be within
  /// `DateTime.monday..DateTime.sunday`.
  final int firstDayOfWeek;

  /// Whether the day grid's ISO week-number gutter renders. Defaults to
  /// `true`.
  final bool showWeekNumbers;

  /// Whether the seconds fields are shown.
  final bool showSeconds;

  /// Whether the hour fields use 24-hour form. Defaults to `true`.
  final bool use24HourFormat;

  /// A strftime-style pattern used to format each endpoint. Defaults to
  /// `'%Y-%m-%d %H:%M'`.
  final String pattern;

  /// A full-control override for formatting the (start, end) pair.
  final String Function(DateTime start, DateTime end)? formatter;

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

  /// Creates a new [LayrzDateTimeRangeInput].
  const LayrzDateTimeRangeInput({
    super.key,
    this.startValue,
    this.endValue,
    this.onChanged,
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
  }) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.'),
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
       );

  @override
  State<LayrzDateTimeRangeInput> createState() => _LayrzDateTimeRangeInputState();
}

class _LayrzDateTimeRangeInputState extends State<LayrzDateTimeRangeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// The (start, end) pair the summary text was last computed for.
  ///
  /// Mirrors `LayrzDateTimeInput`'s identical cache: computing the summary
  /// reads `context.l10n`, which cannot be established from `initState`
  /// (Flutter throws "dependOnInheritedWidgetOfExactType() ... called before
  /// initState() completed"), so the summary is instead computed reactively
  /// from `build` whenever `widget.startValue`/`widget.endValue` have changed
  /// since the last computation. A plain equality check can't distinguish
  /// "never computed" from "computed for null", so [_summaryPrimed] covers
  /// the first build explicitly.
  bool _summaryPrimed = false;
  DateTime? _lastStartValue;
  DateTime? _lastEndValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSummary());
  }

  @override
  void didUpdateWidget(LayrzDateTimeRangeInput oldWidget) {
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
    if (_lastStartValue == null || _lastEndValue == null) {
      _controller.text = '';
      return;
    }
    if (widget.formatter != null) {
      _controller.text = widget.formatter!(_lastStartValue!, _lastEndValue!);
      return;
    }
    final l10n = context.l10n;
    final startText = formatStrftime(_lastStartValue!, widget.pattern, l10n);
    final endText = formatStrftime(_lastEndValue!, widget.pattern, l10n);
    _controller.text = '$startText${l10n.dateTimePickerRangeSeparator}$endText';
  }

  void _handleSave(DateTime start, DateTime end) {
    widget.onChanged?.call(start, end);
    setState(() {
      _lastStartValue = start;
      _lastEndValue = end;
      _updateSummary();
    });
  }

  LayrzDateRange? get _rangeValue => (widget.startValue == null || widget.endValue == null)
      ? null
      : LayrzDateRange(start: widget.startValue!, end: widget.endValue!);

  /// Opens [LayrzDateTimeRangeSurface] via [LayrzResponsiveModal.show] — see
  /// [LayrzDateRangeInput._openPicker]'s identical doc for the full
  /// rationale.
  ///
  /// **Seeded from the widget's own values, not a hardcoded `false`
  /// (maintainer review, Finding 1).** The hosting surface can render behind
  /// a routed transition, so the surface's own post-frame `onDraftChanged`
  /// priming call can land before [surfaceKey.currentState] is attached --
  /// when that happens, seeding `draftState` from a hardcoded `false` leaves
  /// Save permanently disabled for the rest of that open, even once a
  /// complete range already exists, since nothing else ever re-primes it.
  /// Computing the seed from [_rangeValue] directly (mirroring
  /// [LayrzDateTimeRangeSurfaceState.canSave]/`.hasSelection`'s own
  /// predicates) makes `draftState` correct from its very first frame, before
  /// any callback runs at all -- `syncDraftState` below then only ever
  /// updates an already-correct value.
  Future<void> _openPicker() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((
      canSave: _rangeValue != null,
      hasSelection: _rangeValue != null,
    ));
    final surfaceKey = GlobalKey<LayrzDateTimeRangeSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      // Never observed null in practice once the seed above is correct --
      // see this method's own doc. Left unguarded rather than silently
      // swallowed, so a genuine regression here fails loudly instead of
      // permanently stranding `draftState`.
      draftState.value = (canSave: state!.canSave, hasSelection: state.hasSelection);
    }

    await LayrzResponsiveModal.show<void>(
      context,
      // [LayrzResponsiveModal.show] has no `title:` slot -- matches the
      // mobile bottom sheet path's own contract exactly: no visible title
      // anywhere, only a screen-reader `semanticLabel`.
      semanticLabel: widget.labelText ?? widget.hintText,
      // Escape and the barrier tap must still cancel a picker draft even
      // with actions present -- a settled ruling distinct from
      // LayrzDialog's "answered, not escaped" contract (that dialog-level
      // rule is about a DECISION being skipped; a picker's Cancel/Escape/
      // barrier tap are all equally safe "discard the draft" gestures, and
      // Escape=Cancel specifically is required by every picker test in
      // this batch). Explicitly overrides LayrzResponsiveModal.show's own
      // actions-present-infers-false default.
      canDismiss: true,
      // The surface's own Cancel action already sits in `actions` below, so
      // the dialog branch's floating X would be redundant -- and, worse, it
      // would land directly on top of the calendar's own top-right
      // next-month/year chevron, swallowing its tap. Suppressing only the
      // icon's render here does not affect canDismiss: true above -- barrier
      // tap, Escape, and the back gesture still cancel the draft.
      showCloseIcon: false,
      builder: (context) => LayrzDateTimeRangeSurface(
        key: surfaceKey,
        value: _rangeValue,
        startTime: widget.startValue == null ? null : LayrzTimeOfDay.fromDateTime(widget.startValue!),
        endTime: widget.endValue == null ? null : LayrzTimeOfDay.fromDateTime(widget.endValue!),
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        labelText: widget.labelText,
        showInlineFooter: false,
        onDraftChanged: syncDraftState,
        onSave: (start, end) {
          _handleSave(start, end);
          LayrzModalRoute.popIfCurrent(context);
        },
        onCancel: () => LayrzModalRoute.popIfCurrent(context),
      ),
      actions: [
        LayrzPickerDrawerActions(
          draftState: draftState,
          onCancel: (drawerContext) => LayrzModalRoute.popIfCurrent(drawerContext),
          onClear: (_) => surfaceKey.currentState?.clear(),
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
    if (!_summaryPrimed || widget.startValue != _lastStartValue || widget.endValue != _lastEndValue) {
      _summaryPrimed = true;
      _lastStartValue = widget.startValue;
      _lastEndValue = widget.endValue;
      _updateSummary();
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openPicker);
  }
}
