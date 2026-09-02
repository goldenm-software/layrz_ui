import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/date_range.dart';
import '../shared/picker_anchor.dart';
import 'date_range_surface.dart';

/// A Material-free date-range input field.
///
/// **Cancel/Save live inside the anchored panel/bottom sheet, visible from
/// the first frame** — see [LayrzDateRangeSurface]'s class doc for the full
/// range selection state machine this widget's surface implements.
/// **Involuntary close discards the draft** — reopening always starts clean
/// from [value].
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
  late MenuController _panelController;

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
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
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

    final tokens = context.tokens;
    final hasErrors = widget.errors.isNotEmpty;

    return LayrzAnchoredPanel(
      widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
      maxHeight: 520.0,
      coverAnchor: true,
      childFocusNode: _focusNode,
      builder: (context, controller) {
        _panelController = controller;
        return _buildInteractiveField(context: context, onTap: widget.disabled ? null : controller.open);
      },
      border: LayrzAnchoredPanelBorder(
        color: hasErrors ? tokens.colors.danger : tokens.colors.primary,
        width: tokens.border.base,
      ),
      child: LayrzDateRangeSurface(
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onSave: (range) {
          _handleSave(range);
          _panelController.close();
        },
        onCancel: () => _panelController.close(),
      ),
    );
  }
}
