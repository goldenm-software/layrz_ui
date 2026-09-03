import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/date_range.dart';
import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'date_range_surface.dart';

/// A Material-free date-range input field.
///
/// **Cancel/Save live inside the drawer/bottom sheet, visible from the first
/// frame** — see [LayrzDateRangeSurface]'s class doc for the full range
/// selection state machine this widget's surface implements.
/// **Involuntary close discards the draft** — reopening always starts clean
/// from [value].
///
/// **DESIGN-98: opens in [LayrzEndDrawer] on desktop, [LayrzBottomSheet]
/// below `isCompact`.** This widget previously opened [LayrzDateRangeSurface]
/// in the picker-private `LayrzPickerDrawer`, composing its Cancel/Clear/Save
/// footer inline as a trailing child of the scrolling body — which is exactly
/// why the maintainer's screenshot showed the footer stranded under short
/// content instead of pinned to the drawer's bottom edge. [_openDesktopDrawer]
/// now builds those actions via [LayrzPickerDrawerFooter.build] and passes
/// them to [LayrzEndDrawer.show]'s `actions` parameter, reading the surface's
/// live draft state through [_surfaceKey] (a [GlobalKey], the same tool
/// [LayrzDateRangeSurfaceState]'s own class doc explains). The mobile branch
/// is unchanged: [LayrzDateRangeSurface] still renders its own footer inline
/// there via [LayrzDateRangeSurface.showInlineFooter]'s default.
class LayrzDateRangeInput extends StatefulWidget {
  /// The currently committed range.
  final LayrzDateRange? value;

  /// Called with the new range when the user presses Save.
  final ValueChanged<LayrzDateRange>? onChanged;

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

  /// Which weekday starts each week. Defaults to [DateTime.monday].
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders.
  final bool showWeekNumbers;

  /// A strftime-style pattern used to format each endpoint for display.
  /// Defaults to `'%Y-%m-%d'`.
  final String pattern;

  /// A full-control override for formatting [value] into display text.
  final String Function(LayrzDateRange)? formatter;

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

  /// Creates a new [LayrzDateRangeInput].
  const LayrzDateRangeInput({
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
  }) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');

  @override
  State<LayrzDateRangeInput> createState() => _LayrzDateRangeInputState();
}

class _LayrzDateRangeInputState extends State<LayrzDateRangeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// The `(value, pattern, formatter)` combination the summary text was
  /// last computed for.
  ///
  /// [_updateSummary] reads `context.l10n`, which depends on the
  /// [Localizations] inherited widget — that dependency cannot be
  /// established from `initState` (Flutter throws
  /// "dependOnInheritedWidgetOfExactType() ... called before initState()
  /// completed"). Mirroring `LayrzDateInput`'s own `_lastValue` cache,
  /// [build] compares this tuple against [widget]'s current
  /// `(value, pattern, formatter)` and only calls [_updateSummary] when it
  /// actually changed, which is always safe because [build] runs with a
  /// fully established inherited-widget dependency. **The scaffold called
  /// `_updateSummary()` directly from `initState`, which crashes on
  /// construction with any non-null [value]** — this field and the
  /// `build`-time check below are the fix.
  ///
  /// **Widened beyond just `value` per DESIGN-45's "pattern changes must
  /// reflect immediately" finding** — see `LayrzDateInput._lastValue`'s own
  /// doc for the full rationale, which applies identically here: without
  /// `pattern`/`formatter` in the tuple, editing either on an already-built
  /// widget left the old summary text on screen until the next range was
  /// saved.
  (LayrzDateRange?, String, String Function(LayrzDateRange)?)? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT calling `_updateSummary()` here -- see `_lastValue`'s
    // own doc for why: it reads `context.l10n`, which cannot be established
    // from `initState`. `build` performs the initial (and every subsequent)
    // summary computation via the `_lastValue` comparison.
  }

  @override
  void didUpdateWidget(LayrzDateRangeInput oldWidget) {
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
    if (widget.formatter != null) {
      _controller.text = widget.formatter!(value);
      return;
    }
    final l10n = context.l10n;
    final start = formatStrftime(value.start, widget.pattern, l10n);
    final end = formatStrftime(value.end, widget.pattern, l10n);
    _controller.text = '$start${l10n.dateTimePickerRangeSeparator}$end';
  }

  void _handleSave(LayrzDateRange range) {
    widget.onChanged?.call(range);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      builder: (context) => LayrzDateRangeSurface(
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onSave: (range) {
          _handleSave(range);
          LayrzModalRoute.popIfCurrent(context);
        },
        onCancel: () => LayrzModalRoute.popIfCurrent(context),
      ),
      // Names the sheet for screen readers -- omitting this leaves it
      // unannounced, a defect this batch's mobile branches shipped once
      // already (see the implementation plan's known scaffold defects).
      semanticLabel: widget.labelText ?? widget.hintText,
      initialSize: 0.8,
      maxSize: 0.95,
      snapSizes: const [0.8, 0.95],
    );
  }

  /// Opens [LayrzDateRangeSurface] in [LayrzEndDrawer] on desktop — DESIGN-98's
  /// replacement for the previous picker-private `LayrzPickerDrawer`, now
  /// with Cancel/Clear/Save pinned via [LayrzEndDrawer.show]'s `actions`
  /// parameter instead of composed inline. See [LayrzEndDrawer]'s class doc
  /// for why a fresh [LayrzEndDrawer.show] call needs no generation-key
  /// trick: every open already reconstructs [LayrzDateRangeSurface]'s `State`
  /// from scratch.
  ///
  /// **Why a [ValueNotifier], not a single top-level `setState`.**
  /// [LayrzEndDrawer.show]'s `builder` and `actions` are two separate
  /// parameters, each captured once when `show` is called — there is no
  /// single ancestor `StatefulBuilder` that could rebuild both together short
  /// of restructuring the drawer itself. A [ValueNotifier] holding the
  /// surface's live `(canSave, hasSelection)` sidesteps that: the surface
  /// writes to it on every draft mutation, and each of the three actions
  /// wraps itself in a [ValueListenableBuilder] listening to it, so Clear's
  /// visibility and Save's enabled state update independently of one another
  /// and of the body, with no shared rebuild boundary required.
  ///
  /// **Seeded from `widget.value`, not a hardcoded `false` (maintainer
  /// review, Finding 1).** [LayrzEndDrawer] hosts this surface behind a
  /// 300ms routed slide transition, so the surface's own post-frame
  /// `onDraftChanged` priming call can land before [surfaceKey.currentState]
  /// is attached -- when that happens, seeding `draftState` from a hardcoded
  /// `false` leaves Save permanently disabled even though [widget.value] was
  /// already a complete range, since nothing else ever re-primes it.
  /// Computing the seed from [widget.value] directly (mirroring
  /// [LayrzDateRangeSurfaceState.canSave]/`.hasSelection`'s own predicates)
  /// makes `draftState` correct from its very first frame, before any
  /// callback runs at all -- `syncDraftState` below then only ever updates an
  /// already-correct value.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((
      canSave: widget.value != null,
      hasSelection: widget.value != null,
    ));
    final surfaceKey = GlobalKey<LayrzDateRangeSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      // Never observed null in practice once the seed above is correct --
      // see this method's own doc. Left unguarded rather than silently
      // swallowed, so a genuine regression here fails loudly instead of
      // permanently stranding `draftState`.
      draftState.value = (canSave: state!.canSave, hasSelection: state.hasSelection);
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
      builder: (context) => LayrzDateRangeSurface(
        key: surfaceKey,
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        showInlineFooter: false,
        onDraftChanged: syncDraftState,
        onSave: (range) {
          _handleSave(range);
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
        icon: MdiIcons.calendarRangeOutline,
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
