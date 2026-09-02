import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/month.dart';
import '../shared/picker_anchor.dart';
import 'month_surface.dart';

/// A Material-free month+year input field.
///
/// Composes [LayrzInputChrome] directly (D63) and opens [LayrzMonthSurface]
/// through [LayrzAnchoredPanel] on desktop or [LayrzBottomSheet] below
/// `isCompact`. **Commit on tap; no Cancel/Save footer** — see
/// [LayrzMonthSurface]'s class doc.
class LayrzMonthInput extends StatefulWidget {
  /// The currently selected month.
  final LayrzMonth? value;

  /// Called with the newly selected month on commit.
  final ValueChanged<LayrzMonth>? onChanged;

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

  /// Individually disabled months.
  final Set<LayrzMonth> disabledMonths;

  /// A full-control override for formatting [value] into display text.
  /// Defaults to `"<Full month name> <year>"` when not supplied.
  final String Function(LayrzMonth)? formatter;

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

  /// Creates a new [LayrzMonthInput].
  const LayrzMonthInput({
    super.key,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.minimum,
    this.maximum,
    this.disabledMonths = const {},
    this.formatter,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');

  @override
  State<LayrzMonthInput> createState() => _LayrzMonthInputState();
}

class _LayrzMonthInputState extends State<LayrzMonthInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late MenuController _panelController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateSummary();
  }

  @override
  void didUpdateWidget(LayrzMonthInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.value != oldWidget.value) _updateSummary();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  String _monthName(int month, LayrzUiL10n l10n) {
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
    final value = widget.value;
    if (value == null) {
      _controller.text = '';
      return;
    }
    final l10n = context.l10n;
    _controller.text = widget.formatter?.call(value) ?? '${_monthName(value.month, l10n)} ${value.year}';
  }

  void _handleSelected(LayrzMonth month) {
    widget.onChanged?.call(month);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      builder: (context) => LayrzMonthSurface(
        value: widget.value,
        minimum: widget.minimum,
        maximum: widget.maximum,
        disabledMonths: widget.disabledMonths,
        onMonthSelected: (month) {
          _handleSelected(month);
          Navigator.pop(context);
        },
      ),
      initialSize: 0.6,
      maxSize: 0.9,
      snapSizes: const [0.6, 0.9],
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
        icon: MdiIcons.calendarMonthOutline,
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
      maxHeight: 420.0,
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
      child: LayrzMonthSurface(
        value: widget.value,
        minimum: widget.minimum,
        maximum: widget.maximum,
        disabledMonths: widget.disabledMonths,
        onMonthSelected: (month) {
          _handleSelected(month);
          _panelController.close();
        },
      ),
    );
  }
}
