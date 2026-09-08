import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/dialogs/dialogs.dart';
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
/// **Cancel/Save live inside the dialog/bottom sheet, visible from the first
/// frame** — see [LayrzDateRangeSurface]'s class doc for the full range
/// selection state machine this widget's surface implements.
/// **Involuntary close discards the draft** — reopening always starts clean
/// from [value].
///
/// **Opens via [LayrzResponsiveModal.show]**, which resolves to a dialog on
/// wide viewports or a [LayrzBottomSheet] below `isCompact`. [_openPicker]
/// builds the Cancel/Clear/Save actions via [LayrzPickerDrawerFooter.build]
/// and passes them to [LayrzResponsiveModal.show]'s `actions` parameter,
/// reading the surface's live draft state through a [GlobalKey] (the same
/// tool [LayrzDateRangeSurfaceState]'s own class doc explains). Both
/// branches render the same surface with `showInlineFooter: false`, so a
/// wide viewport and a narrow one now present identically.
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

  /// Opens [LayrzDateRangeSurface] via [LayrzResponsiveModal.show], which
  /// resolves to a dialog on wide viewports or a [LayrzBottomSheet] below
  /// `isCompact`, with Cancel/Clear/Save pinned via the modal's own
  /// `actions` parameter on both branches instead of composed inline. Every
  /// open reconstructs [LayrzDateRangeSurface]'s `State` from scratch, so no
  /// generation-key trick is needed.
  ///
  /// **Why a [ValueNotifier], not a single top-level `setState`.**
  /// [LayrzResponsiveModal.show]'s `builder` and `actions` are two separate
  /// parameters, each captured once when `show` is called — there is no
  /// single ancestor `StatefulBuilder` that could rebuild both together short
  /// of restructuring the modal itself. A [ValueNotifier] holding the
  /// surface's live `(canSave, hasSelection)` sidesteps that: the surface
  /// writes to it on every draft mutation, and each of the three actions
  /// wraps itself in a [ValueListenableBuilder] listening to it, so Clear's
  /// visibility and Save's enabled state update independently of one another
  /// and of the body, with no shared rebuild boundary required.
  ///
  /// **Seeded from `widget.value`, not a hardcoded `false` (maintainer
  /// review, Finding 1).** The hosting surface can render behind a routed
  /// transition, so the surface's own post-frame `onDraftChanged` priming
  /// call can land before [surfaceKey.currentState] is attached -- when
  /// that happens, seeding `draftState` from a hardcoded `false` leaves
  /// Save permanently disabled even though [widget.value] was already a
  /// complete range, since nothing else ever re-primes it. Computing the
  /// seed from [widget.value] directly (mirroring
  /// [LayrzDateRangeSurfaceState.canSave]/`.hasSelection`'s own predicates)
  /// makes `draftState` correct from its very first frame, before any
  /// callback runs at all -- `syncDraftState` below then only ever updates an
  /// already-correct value.
  Future<void> _openPicker() async {
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
      builder: (context) => LayrzDateRangeSurface(
        key: surfaceKey,
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        labelText: widget.labelText,
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

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openPicker);
  }
}
