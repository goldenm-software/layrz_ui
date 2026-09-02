import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/month.dart';
import '../models/month_range.dart';
import '../shared/picker_anchor.dart';
import 'month_range_surface.dart';

/// A Material-free month-range input field.
///
/// **The sole widget in this batch where a discontinuous selection is
/// reachable.** [consecutive] defaults to `false` (arbitrary multi-select,
/// via `LayrzArbitraryRangePolicy`) per the user's explicit carve-out; pass
/// `true` for consecutive-months mode (via `LayrzContiguousRangePolicy`),
/// which behaves like `LayrzDateRangeInput`'s endpoint-adjust state machine.
/// See [LayrzMonthRangeSurface]'s class doc for the full selection contract
/// of both modes.
///
/// **Value shape depends on mode**: [onArbitraryChanged] fires a sorted
/// `List<LayrzMonth>` in arbitrary mode; [onRangeChanged] fires a
/// [LayrzMonthRange] in consecutive mode. Exactly one of [arbitraryValue]/
/// [rangeValue] and one of [onArbitraryChanged]/[onRangeChanged] is
/// meaningful at a time, selected by [consecutive].
///
/// **Cancel/Save live inside the anchored panel/bottom sheet, visible from
/// the first frame** — this is one of the five widgets in the batch that
/// coordinate multiple parts rather than committing on a single tap.
/// **Involuntary close discards the draft** — reopening always starts clean
/// from [arbitraryValue]/[rangeValue].
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
  /// display text. Takes precedence over [arbitraryPattern] when supplied.
  final String Function(List<LayrzMonth>)? arbitraryFormatter;

  /// A full-control override for formatting the consecutive range into
  /// display text. Takes precedence over [rangePattern] when supplied.
  final String Function(LayrzMonthRange)? rangeFormatter;

  /// A strftime-style pattern used to format each month in the arbitrary
  /// comma-joined summary (see [LayrzMonthRangeInput]'s class doc for the
  /// overflow-to-count fallback). Defaults to `'%b %Y'` (abbreviated month
  /// name), matching the field's need to fit several entries on one line.
  final String arbitraryPattern;

  /// A strftime-style pattern used to format each endpoint of the
  /// consecutive-mode summary. Defaults to `'%B %Y'` (full month name).
  final String rangePattern;

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
    this.arbitraryPattern = '%b %Y',
    this.rangePattern = '%B %Y',
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

  /// The maximum number of months rendered as a comma-joined list in
  /// arbitrary mode before the summary collapses to a count instead.
  ///
  /// **Not a firm ruling** — the maintainer settled the *approach* (a
  /// comma-joined list with an overflow fallback to a count), leaving the
  /// exact threshold for review. `4` was chosen because four abbreviated
  /// entries (`"Jan, Mar, Apr, Sep"`) is roughly the practical limit that
  /// still fits the single-line anchor at typical field widths without
  /// relying on horizontal scrolling or truncation; a fifth entry tips
  /// most reasonably-sized fields into `TextOverflow.ellipsis` territory,
  /// where a count reads better than a silently truncated list. Flagged for
  /// maintainer review per the implementation plan.
  static const _overflowThreshold = 4;

  /// The `(consecutive, arbitraryValue, rangeValue, arbitraryPattern,
  /// rangePattern, arbitraryFormatter, rangeFormatter)` combination the
  /// summary text was last computed for.
  ///
  /// Mirrors `LayrzMonthInput`'s own `_lastValue` guard: [_updateSummary]
  /// reads `context.l10n` (via [formatStrftime]), which asserts if called
  /// before this widget's [BuildContext] has an established `Localizations`
  /// dependency. **The scaffold called `_updateSummary()` directly from
  /// `initState`, which crashes on construction** — this field and the
  /// `build`-time check below are the fix: [build] recomputes the summary
  /// only when the relevant value actually changed since the last build,
  /// which also covers the very first build.
  ///
  /// **Widened beyond `(consecutive, arbitraryValue, rangeValue)` per
  /// DESIGN-45's "pattern changes must reflect immediately" finding** — see
  /// `LayrzDateInput._lastValue`'s own doc for the full rationale. Both
  /// modes' pattern/formatter pairs are included since either can be active
  /// depending on [LayrzMonthRangeInput.consecutive].
  (
    bool,
    List<LayrzMonth>,
    LayrzMonthRange?,
    String,
    String,
    String Function(List<LayrzMonth>)?,
    String Function(LayrzMonthRange)?,
  )?
  _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT calling _updateSummary() here -- see _lastValue's
    // doc. The first build() computes it instead, once context.l10n is safe
    // to read.
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
    // _updateSummary() is driven from build() via the _lastValue guard, not
    // from here, so a controller swap above still gets the correct text
    // without this method also needing to special-case it.
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Formats the active mode's value into the anchor's summary text.
  ///
  /// **Never hand-rolls month names.** Both modes resolve month names
  /// through [formatStrftime] (`%B`/`%b`, backed by [LayrzUiL10n]), never a
  /// private switch statement — the scaffold this replaced did exactly that
  /// and violated the no-`intl`-but-also-no-hardcoded-English rule the same
  /// way `formatStrftime` exists to prevent.
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
      final start = formatStrftime(range.start.toDateTime(), widget.rangePattern, l10n);
      final end = formatStrftime(range.end.toDateTime(), widget.rangePattern, l10n);
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
    // Comma-joined list, falling back to a count on overflow -- see
    // `_overflowThreshold`'s doc for the threshold and its rationale.
    if (months.length > _overflowThreshold) {
      _controller.text = l10n.pickerMonthRangeCount(months.length);
      return;
    }
    final sorted = months.toList()..sort();
    _controller.text = sorted.map((m) => formatStrftime(m.toDateTime(), widget.arbitraryPattern, l10n)).join(', ');
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
      builder: (context) => LayrzMonthRangeSurface(
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
    final currentValue = (
      widget.consecutive,
      widget.arbitraryValue,
      widget.rangeValue,
      widget.arbitraryPattern,
      widget.rangePattern,
      widget.arbitraryFormatter,
      widget.rangeFormatter,
    );
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
      child: LayrzMonthRangeSurface(
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
