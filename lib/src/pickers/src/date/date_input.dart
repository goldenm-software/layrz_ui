import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'date_surface.dart';

/// A Material-free single-date input field.
///
/// Composes [LayrzInputChrome] directly (D63) and opens [LayrzDateSurface] in
/// [LayrzEndDrawer] on desktop (`>= 960px`) or [LayrzBottomSheet] below
/// `isCompact`.
///
/// **DESIGN-98: no longer commits on tap.** Before DESIGN-98 this widget
/// opened [LayrzDateSurface] through [LayrzAnchoredPanel] and closed
/// immediately on the tapped date, with no Save footer at all — see decision
/// D75 (`engineering/milestone-4.md`) for that original "one atomic value,
/// no Save boundary" ruling. The maintainer's DESIGN-98 instruction is
/// explicit and supersedes it: *"All of the date related inputs ... must use
/// the LayrzEndDrawer with actions."* [onChanged] now fires only once, on
/// Save, with the drafted date; a tap alone no longer commits anything, and
/// Cancel discards the draft. See [LayrzDateSurfaceState]'s class doc for the
/// surface-side half of this.
///
/// **No Clear action.** A single-date field's only content is the one value
/// being picked — clearing it back to "nothing selected" is not a
/// draft-editing operation the way it is for a range (there is no partial
/// selection to reset to empty independently of Cancel), and Cancel already
/// covers "back out without changing anything." A Clear button here would
/// duplicate Cancel's own effect from the user's point of view while adding
/// a second, harder-to-justify affordance, so this widget's `actions` row is
/// Cancel/Save only.
///
/// **Preserves `TZDateTime` zones**: [value] and every date [onChanged]
/// reports are constructed via `sameZoneDate`, so a caller passing a
/// `TZDateTime` gets a `TZDateTime` back in the same zone, never silently
/// re-anchored to the host's local zone.
class LayrzDateInput extends StatefulWidget {
  /// The currently selected date.
  final DateTime? value;

  /// Called with the newly selected date on commit.
  final ValueChanged<DateTime>? onChanged;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty and no
  /// [labelText] describes it.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// Whether the field is disabled (not interactive).
  final bool disabled;

  /// The earliest selectable date, inclusive. `null` means no lower bound.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive. `null` means no upper bound.
  final DateTime? lastDay;

  /// Individually disabled dates, beyond [firstDay]/[lastDay].
  final Set<DateTime> disabledDays;

  /// Which [DateTime] weekday constant starts each week in the grid.
  /// Defaults to [DateTime.monday] — deliberately differing from
  /// `LayrzCalendar`'s `DateTime.sunday` default; asserted to be within
  /// `DateTime.monday..DateTime.sunday`.
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders (cut to a thin decorative
  /// strip below `isCompact`). Defaults to `true`.
  final bool showWeekNumbers;

  /// A strftime-style pattern (see `lib/src/formatting/`) used to format
  /// [value] for display, when [formatter] is not supplied. Defaults to
  /// `'%Y-%m-%d'`.
  final String pattern;

  /// A full-control override for formatting [value] into display text,
  /// taking precedence over [pattern] when supplied.
  final String Function(DateTime)? formatter;

  /// The text editing controller for the anchor field. If null, one is
  /// created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the anchor field. If null, one is created and
  /// disposed by the widget.
  final FocusNode? focusNode;

  /// Whether the field uses the dense density variant.
  final bool dense;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Creates a new [LayrzDateInput].
  const LayrzDateInput({
    super.key,
    this.value,
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
    this.pattern = '%Y-%m-%d',
    this.formatter,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
       );

  @override
  State<LayrzDateInput> createState() => _LayrzDateInputState();
}

class _LayrzDateInputState extends State<LayrzDateInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// The `(value, pattern, formatter)` combination the summary text was
  /// last computed for.
  ///
  /// [_updateSummary] reads `context.l10n`, which depends on the
  /// [Localizations] inherited widget — that dependency cannot be
  /// established from `initState` (Flutter throws
  /// "dependOnInheritedWidgetOfExactType() ... called before initState()
  /// completed"). Mirroring `LayrzDurationInput`'s own `_lastValue` cache,
  /// [build] compares this tuple against [widget]'s current
  /// `(value, pattern, formatter)` and only calls [_updateSummary] when it
  /// actually changed, which is always safe because [build] runs with a
  /// fully established inherited-widget dependency.
  ///
  /// **Widened beyond just `value` per DESIGN-45's "pattern changes must
  /// reflect immediately" finding**: the scaffold this replaced compared
  /// only [DateTime.value], so editing [LayrzDateInput.pattern] or
  /// [LayrzDateInput.formatter] on an already-built widget left the old
  /// summary text on screen until the next date selection recomputed it —
  /// the field looked like it ignored the new pattern entirely until the
  /// user picked a new date. Including `pattern`/`formatter` in the tuple
  /// makes a `didUpdateWidget` rebuild with either changed dirty on its
  /// own, with no selection required.
  (DateTime?, String, String Function(DateTime)?)? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT calling `_updateSummary()` here -- see `_lastValue`'s
    // own doc for why: it reads `context.l10n`, which cannot be established
    // from `initState`. `build` performs the initial (and every
    // subsequent) summary computation via the `_lastValue` comparison.
  }

  @override
  void didUpdateWidget(LayrzDateInput oldWidget) {
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

  void _handleSelected(DateTime date) {
    widget.onChanged?.call(date);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: false, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzDateSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      if (state == null) return;
      draftState.value = (canSave: state.canSave, hasSelection: false);
    }

    await LayrzBottomSheet.show<void>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzDateSurface(
        key: surfaceKey,
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onDraftChanged: syncDraftState,
        onDateSelected: (date) {
          _handleSelected(date);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
      actions: [
        LayrzPickerDrawerActions(
          draftState: draftState,
          onCancel: () => Navigator.pop(context),
          onClear: () {},
          onSave: () => surfaceKey.currentState?.save(),
        ),
      ],
      initialSize: 0.6,
      maxSize: 0.9,
      snapSizes: const [0.6, 0.9],
    );

    draftState.dispose();
  }

  /// Opens [LayrzDateSurface] in [LayrzEndDrawer] on desktop — see
  /// [LayrzDateRangeInput._openDesktopDrawer]'s identical doc for the full
  /// rationale (DESIGN-98). This surface has no Clear affordance (see this
  /// widget's own class doc), so `hasSelection` is always `false`.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: false, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzDateSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      if (state == null) return;
      draftState.value = (canSave: state.canSave, hasSelection: false);
    }

    await LayrzEndDrawer.show<void>(
      context,
      // DESIGN-98 Finding 5: the maintainer's explicit ruling is
      // "title should be the labelText of the input" -- before this, the
      // label reached the drawer only as `semanticLabel` (screen-reader
      // only), so a sighted user saw no visible title at all. `title` below
      // now carries `labelText` visibly whenever it is set. `semanticLabel`
      // is passed only as a fallback for the `hintText`-only case (no
      // `title`) -- when `title` is non-null, its own rendered `Text`
      // already produces a Semantics node with that exact label, so also
      // passing it as `semanticLabel` would announce it a second time (see
      // end_drawer.dart's own doc: "passing both usually reads as a
      // duplicate title, not a title plus a caption").
      semanticLabel: widget.labelText == null ? widget.hintText : null,
      title: widget.labelText != null ? Text(widget.labelText!) : null,
      // Escape and the barrier tap must still cancel a picker draft even
      // with actions present -- a settled ruling distinct from
      // LayrzDialog's "answered, not escaped" contract (that dialog-level
      // rule is about a DECISION being skipped; a picker's Cancel/Escape/
      // barrier tap are all equally safe "discard the draft" gestures, and
      // Escape=Cancel specifically is required by every picker test in
      // this batch). Explicitly overrides LayrzEndDrawer.show's own
      // actions-present-infers-false default.
      canDismiss: true,
      builder: (context) => LayrzDateSurface(
        key: surfaceKey,
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onDraftChanged: syncDraftState,
        onDateSelected: (date) {
          _handleSelected(date);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
      actions: [
        LayrzPickerDrawerActions(
          draftState: draftState,
          onCancel: () => Navigator.pop(context),
          onClear: () {},
          onSave: () => surfaceKey.currentState?.save(),
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
        icon: MdiIcons.calendarBlankOutline,
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
    final currentValue = (widget.value, widget.pattern, widget.formatter);
    if (_lastValue != currentValue) {
      _lastValue = currentValue;
      _updateSummary();
    }

    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openDesktopDrawer);
  }
}
