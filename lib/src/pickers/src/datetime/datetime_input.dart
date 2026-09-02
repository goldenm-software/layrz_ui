import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/time_of_day.dart';
import '../shared/picker_anchor.dart';
import 'datetime_presentation.dart';
import 'datetime_surface.dart';

/// A Material-free single-datetime input field.
///
/// **DESIGN-51 collapses into this widget** — covered by, not removed.
/// Composes [LayrzPickersDayGrid] and [LayrzPickersTimeFieldsPanel] inside
/// **one** anchored panel via [LayrzDateTimeSurface], arranged per
/// [presentation].
///
/// **Commit model**: [onChanged] fires only once both the date and the time
/// have been chosen — see [LayrzDateTimeSurface]'s class doc for the full
/// reasoning. There is no Save button; the completing action on whichever
/// part is chosen last is the commit gesture.
class LayrzDateTimeInput extends StatefulWidget {
  /// The currently selected datetime.
  final DateTime? value;

  /// Called with the newly selected datetime once both date and time are
  /// chosen.
  final ValueChanged<DateTime>? onChanged;

  /// Which arrangement this widget's surface uses. Presentation-only — both
  /// values commit at the same moment.
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

  /// Whether the seconds field is shown.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form. Defaults to `true`.
  final bool use24HourFormat;

  /// A strftime-style pattern used to format [value] for display. Defaults
  /// to `'%Y-%m-%d %H:%M'`.
  final String pattern;

  /// A full-control override for formatting [value] into display text.
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
    this.presentation = LayrzDateTimeInputPresentation.tabbed,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.showSeconds = false,
    this.use24HourFormat = true,
    this.pattern = '%Y-%m-%d %H:%M',
    this.formatter,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');

  @override
  State<LayrzDateTimeInput> createState() => _LayrzDateTimeInputState();
}

class _LayrzDateTimeInputState extends State<LayrzDateTimeInput> {
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
    if (widget.value != oldWidget.value) _updateSummary();
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

  void _handleCommit(DateTime date, LayrzTimeOfDay time) {
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute, time.second);
    widget.onChanged?.call(combined);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      builder: (context) => LayrzDateTimeSurface(
        presentation: widget.presentation,
        initialDate: widget.value,
        initialTime: widget.value == null ? null : LayrzTimeOfDay.fromDateTime(widget.value!),
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onCommit: (date, time) {
          _handleCommit(date, time);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
      initialSize: 0.85,
      maxSize: 0.95,
      snapSizes: const [0.85, 0.95],
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
    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    final tokens = context.tokens;
    final hasErrors = widget.errors.isNotEmpty;

    return LayrzAnchoredPanel(
      widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
      maxHeight: 560.0,
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
      child: LayrzDateTimeSurface(
        presentation: widget.presentation,
        initialDate: widget.value,
        initialTime: widget.value == null ? null : LayrzTimeOfDay.fromDateTime(widget.value!),
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onCommit: (date, time) {
          _handleCommit(date, time);
          _panelController.close();
        },
        onCancel: () => _panelController.close(),
      ),
    );
  }
}
