import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/month.dart';
import '../models/month_range.dart';
import '../shared/month_grid.dart';
import '../shared/picker_anchor.dart';
import '../shared/range_draft.dart';
import '../shared/range_policy.dart';

/// A Material-free month-range input field.
///
/// **The sole widget in this batch where a discontinuous selection is
/// reachable.** [consecutive] defaults to `false` (arbitrary multi-select,
/// via [LayrzArbitraryRangePolicy]) per the user's explicit carve-out; pass
/// `true` for consecutive-months mode (via [LayrzContiguousRangePolicy]),
/// which behaves like [LayrzDateRangeInput]'s endpoint-adjust state machine.
///
/// **Value shape depends on mode**: [onArbitraryChanged] fires a sorted
/// `List<LayrzMonth>` in arbitrary mode; [onRangeChanged] fires a
/// [LayrzMonthRange] in consecutive mode. Exactly one of [arbitraryValue]/
/// [rangeValue] and one of [onArbitraryChanged]/[onRangeChanged] is
/// meaningful at a time, selected by [consecutive].
///
/// [disabledMonths] is documented as **ignored in consecutive mode**,
/// matching old layrz_theme behaviour.
class LayrzMonthRangeInput extends StatefulWidget {
  /// Whether this widget operates in consecutive (contiguous) mode rather
  /// than the default arbitrary (non-contiguous) multi-select mode.
  final bool consecutive;

  /// The currently selected months in arbitrary mode. Ignored when
  /// [consecutive] is `true`.
  final List<LayrzMonth> arbitraryValue;

  /// The currently committed range in consecutive mode. Ignored when
  /// [consecutive] is `false`.
  final LayrzMonthRange? rangeValue;

  /// Called with the new sorted month list when the user presses Save in
  /// arbitrary mode.
  final ValueChanged<List<LayrzMonth>>? onArbitraryChanged;

  /// Called with the new range when the user presses Save in consecutive
  /// mode.
  final ValueChanged<LayrzMonthRange>? onRangeChanged;

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

  /// The earliest selectable month, inclusive.
  final LayrzMonth? minimum;

  /// The latest selectable month, inclusive.
  final LayrzMonth? maximum;

  /// Individually disabled months. **Ignored in consecutive mode.**
  final Set<LayrzMonth> disabledMonths;

  /// A full-control override for formatting the arbitrary selection into
  /// display text.
  final String Function(List<LayrzMonth>)? arbitraryFormatter;

  /// A full-control override for formatting the consecutive range into
  /// display text.
  final String Function(LayrzMonthRange)? rangeFormatter;

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

  /// Creates a new [LayrzMonthRangeInput].
  const LayrzMonthRangeInput({
    super.key,
    this.consecutive = false,
    this.arbitraryValue = const [],
    this.rangeValue,
    this.onArbitraryChanged,
    this.onRangeChanged,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.minimum,
    this.maximum,
    this.disabledMonths = const {},
    this.arbitraryFormatter,
    this.rangeFormatter,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');

  @override
  State<LayrzMonthRangeInput> createState() => _LayrzMonthRangeInputState();
}

class _LayrzMonthRangeInputState extends State<LayrzMonthRangeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late MenuController _panelController;

  static const _overflowThreshold = 4;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateSummary();
  }

  @override
  void didUpdateWidget(LayrzMonthRangeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.arbitraryValue != oldWidget.arbitraryValue ||
        widget.rangeValue != oldWidget.rangeValue ||
        widget.consecutive != oldWidget.consecutive) {
      _updateSummary();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  String _monthLabel(int month, LayrzUiL10n l10n) {
    return switch (month) {
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
      _ => l10n.monthDecember,
    };
  }

  void _updateSummary() {
    final l10n = context.l10n;
    if (widget.consecutive) {
      final range = widget.rangeValue;
      if (widget.rangeFormatter != null && range != null) {
        _controller.text = widget.rangeFormatter!(range);
        return;
      }
      if (range == null) {
        _controller.text = '';
        return;
      }
      final start = '${_monthLabel(range.start.month, l10n)} ${range.start.year}';
      final end = '${_monthLabel(range.end.month, l10n)} ${range.end.year}';
      _controller.text = '$start${l10n.dateTimePickerRangeSeparator}$end';
      return;
    }

    final months = widget.arbitraryValue;
    if (widget.arbitraryFormatter != null) {
      _controller.text = widget.arbitraryFormatter!(months);
      return;
    }
    if (months.isEmpty) {
      _controller.text = '';
      return;
    }
    // Comma-joined list, falling back to a count on overflow -- the one
    // sub-question the plan left without a firm ruling (Q5b). Threshold
    // documented here: beyond `_overflowThreshold` entries, a comma-joined
    // list risks overflowing the anchor's single-line summary, so the
    // display collapses to a count instead of truncating mid-list.
    if (months.length > _overflowThreshold) {
      _controller.text = '${months.length} months selected';
      return;
    }
    _controller.text = months.map((m) => '${_monthLabel(m.month, l10n)} ${m.year}').join(', ');
  }

  void _handleArbitrarySave(List<LayrzMonth> months) {
    widget.onArbitraryChanged?.call(months);
    _updateSummary();
    setState(() {});
  }

  void _handleRangeSave(LayrzMonthRange range) {
    widget.onRangeChanged?.call(range);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      builder: (context) => _LayrzMonthRangeSurface(
        consecutive: widget.consecutive,
        arbitraryValue: widget.arbitraryValue,
        rangeValue: widget.rangeValue,
        minimum: widget.minimum,
        maximum: widget.maximum,
        disabledMonths: widget.disabledMonths,
        onArbitrarySave: (months) {
          _handleArbitrarySave(months);
          Navigator.pop(context);
        },
        onRangeSave: (range) {
          _handleRangeSave(range);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
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
        icon: MdiIcons.calendarMultiselectOutline,
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
      child: _LayrzMonthRangeSurface(
        consecutive: widget.consecutive,
        arbitraryValue: widget.arbitraryValue,
        rangeValue: widget.rangeValue,
        minimum: widget.minimum,
        maximum: widget.maximum,
        disabledMonths: widget.disabledMonths,
        onArbitrarySave: (months) {
          _handleArbitrarySave(months);
          _panelController.close();
        },
        onRangeSave: (range) {
          _handleRangeSave(range);
          _panelController.close();
        },
        onCancel: () => _panelController.close(),
      ),
    );
  }
}

/// Private surface backing [LayrzMonthRangeInput], switching policy by
/// [consecutive] — [LayrzArbitraryRangePolicy] (default) or
/// [LayrzContiguousRangePolicy].
class _LayrzMonthRangeSurface extends StatefulWidget {
  final bool consecutive;
  final List<LayrzMonth> arbitraryValue;
  final LayrzMonthRange? rangeValue;
  final LayrzMonth? minimum;
  final LayrzMonth? maximum;
  final Set<LayrzMonth> disabledMonths;
  final ValueChanged<List<LayrzMonth>> onArbitrarySave;
  final ValueChanged<LayrzMonthRange> onRangeSave;
  final VoidCallback onCancel;

  const _LayrzMonthRangeSurface({
    required this.consecutive,
    required this.arbitraryValue,
    required this.rangeValue,
    required this.minimum,
    required this.maximum,
    required this.disabledMonths,
    required this.onArbitrarySave,
    required this.onRangeSave,
    required this.onCancel,
  });

  @override
  State<_LayrzMonthRangeSurface> createState() => _LayrzMonthRangeSurfaceState();
}

class _LayrzMonthRangeSurfaceState extends State<_LayrzMonthRangeSurface> {
  late LayrzRangeDraft<LayrzMonth> _draft;
  late int _displayedYear;
  final _contiguousPolicy = LayrzContiguousRangePolicy<LayrzMonth>(compare: (a, b) => a.compareTo(b));
  final _arbitraryPolicy = const LayrzArbitraryRangePolicy<LayrzMonth>();

  LayrzRangePolicy<LayrzMonth> get _policy => widget.consecutive ? _contiguousPolicy : _arbitraryPolicy;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(_LayrzMonthRangeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arbitraryValue != widget.arbitraryValue ||
        oldWidget.rangeValue != widget.rangeValue ||
        oldWidget.consecutive != widget.consecutive) {
      _seed();
    }
  }

  void _seed() {
    if (widget.consecutive) {
      final range = widget.rangeValue;
      _draft = range == null
          ? const LayrzRangeDraft<LayrzMonth>.empty()
          : LayrzRangeDraft<LayrzMonth>.complete(anchor: range.start, end: range.end);
      _displayedYear = range?.start.year ?? DateTime.now().year;
    } else {
      _draft = LayrzRangeDraft<LayrzMonth>.arbitrary(widget.arbitraryValue.toSet());
      _displayedYear = widget.arbitraryValue.isEmpty ? DateTime.now().year : widget.arbitraryValue.first.year;
    }
  }

  void _handleTap(DateTime monthDate) {
    final month = LayrzMonth.fromDateTime(monthDate);
    setState(() => _draft = _policy.onTap(_draft, month));
  }

  void _handleReset() => setState(() => _draft = const LayrzRangeDraft<LayrzMonth>.empty());

  bool get _canSave => widget.consecutive ? _draft.isComplete : _draft.arbitrarySelection.isNotEmpty;

  void _handleSave() {
    if (!_canSave) return;
    if (widget.consecutive) {
      widget.onRangeSave(LayrzMonthRange(start: _draft.anchor as LayrzMonth, end: _draft.end as LayrzMonth));
    } else {
      final sorted = _draft.arbitrarySelection.toList()..sort();
      widget.onArbitrarySave(sorted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final visibleMonths = [for (var m = 1; m <= 12; m++) LayrzMonth(year: _displayedYear, month: m)];
    final rejected = widget.consecutive
        ? {
            for (final m in visibleMonths)
              if (_policy.isRejected(_draft, m)) m.toDateTime(),
          }
        : <DateTime>{};

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayrzPickersMonthGrid(
            displayedYear: _displayedYear,
            onYearChanged: (year) => setState(() => _displayedYear = year),
            reference: DateTime.now(),
            selectedMonth: null,
            rangeStart: widget.consecutive ? _draft.anchor?.toDateTime() : null,
            rangeEnd: widget.consecutive ? _draft.end?.toDateTime() : null,
            arbitrarySelection: widget.consecutive
                ? const {}
                : _draft.arbitrarySelection.map((m) => m.toDateTime()).toSet(),
            rejectedMonths: rejected,
            minimum: widget.minimum?.toDateTime(),
            maximum: widget.consecutive ? widget.maximum?.toDateTime() : widget.maximum?.toDateTime(),
            disabledMonths: widget.consecutive ? const {} : widget.disabledMonths.map((m) => m.toDateTime()).toSet(),
            onMonthTap: _handleTap,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              if (_draft.anchor != null || _draft.arbitrarySelection.isNotEmpty)
                Expanded(
                  child: LayrzButton(
                    labelText: l10n.pickerRangeReset,
                    onTap: _handleReset,
                    type: LayrzButtonType.warning,
                  ),
                ),
              if (_draft.anchor != null || _draft.arbitrarySelection.isNotEmpty) SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: LayrzButton.cancel(labelText: l10n.actionCancel, onTap: widget.onCancel),
              ),
              SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: LayrzButton.save(labelText: l10n.actionSave, onTap: _handleSave, isDisabled: !_canSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
