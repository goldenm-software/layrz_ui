import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/time_of_day.dart';
import '../shared/picker_anchor.dart';
import '../shared/picker_drawer.dart';
import 'time_range_surface.dart';

/// A Material-free start/end time-range input field.
///
/// **Counts as a range and gets Cancel/Save inside its container** — per the
/// implementation plan's explicit ruling that `LayrzTimeRangeInput` follows
/// the range rule despite being built from two single-time clusters rather
/// than a grid.
///
/// **DESIGN-49: opens in [LayrzPickerDrawer] on desktop, [LayrzBottomSheet]
/// below `isCompact`.** This widget previously opened [LayrzTimeRangeSurface]
/// through [LayrzAnchoredPanel] on desktop; the maintainer ruled the anchored
/// panel too cramped for every Save-carrying picker widget (see
/// [LayrzPickerDrawer]'s own class doc for the ruling verbatim) and asked for
/// a fixed-width drawer instead. The mobile branch is unchanged.
class LayrzTimeRangeInput extends StatefulWidget {
  /// The currently committed start time.
  final LayrzTimeOfDay? startValue;

  /// The currently committed end time.
  final LayrzTimeOfDay? endValue;

  /// Called with the new (start, end) pair when the user presses Save.
  final void Function(LayrzTimeOfDay start, LayrzTimeOfDay end)? onChanged;

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

  /// Whether the seconds fields are shown.
  final bool showSeconds;

  /// Whether the hour fields use 24-hour form. Defaults to `true`.
  final bool use24HourFormat;

  /// A strftime-style pattern used to format each endpoint. Defaults to
  /// `'%H:%M'`.
  final String pattern;

  /// A full-control override for formatting the (start, end) pair into
  /// display text.
  final String Function(LayrzTimeOfDay start, LayrzTimeOfDay end)? formatter;

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

  /// Creates a new [LayrzTimeRangeInput].
  const LayrzTimeRangeInput({
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
    this.showSeconds = false,
    this.use24HourFormat = true,
    this.pattern = '%H:%M',
    this.formatter,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');

  @override
  State<LayrzTimeRangeInput> createState() => _LayrzTimeRangeInputState();
}

class _LayrzTimeRangeInputState extends State<LayrzTimeRangeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  // `build()` re-runs `_updateSummary()` only once per distinct
  // (startValue, endValue) pair, mirroring `LayrzTimeInput`'s own
  // `_summaryPrimed`/`_lastValue` dirty-check. `_updateSummary()` reads
  // `context.l10n`, an inherited-widget lookup that is illegal from
  // `initState()` -- calling it there throws
  // "dependOnInheritedWidgetOfExactType... called before initState()
  // completed." So the summary is never primed in `initState`; the first
  // `build()` call computes it instead, once the tree is attached. A plain
  // `_lastStart`/`_lastEnd` check alone can't distinguish "never computed"
  // from "computed for null, null", hence `_summaryPrimed`.
  bool _summaryPrimed = false;
  LayrzTimeOfDay? _lastStart;
  LayrzTimeOfDay? _lastEnd;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzTimeRangeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.startValue != oldWidget.startValue || widget.endValue != oldWidget.endValue) {
      _lastStart = widget.startValue;
      _lastEnd = widget.endValue;
      _updateSummary();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  DateTime _asDateTime(LayrzTimeOfDay time) => DateTime(2000, 1, 1, time.hour, time.minute, time.second);

  void _updateSummary() {
    final start = widget.startValue;
    final end = widget.endValue;
    if (start == null || end == null) {
      _controller.text = '';
      return;
    }
    if (widget.formatter != null) {
      _controller.text = widget.formatter!(start, end);
      return;
    }
    final l10n = context.l10n;
    final startText = formatStrftime(_asDateTime(start), widget.pattern, l10n);
    final endText = formatStrftime(_asDateTime(end), widget.pattern, l10n);
    _controller.text = '$startText${l10n.dateTimePickerRangeSeparator}$endText';
  }

  void _handleSave(LayrzTimeOfDay start, LayrzTimeOfDay end) {
    widget.onChanged?.call(start, end);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      // Names the sheet's route for screen readers with this field's own
      // label -- without it LayrzBottomSheet.show adds no route semantics at
      // all. Falls back to hintText when labelText is null, matching this
      // widget's own labelText-or-hintText constructor assertion.
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzTimeRangeSurface(
        startValue: widget.startValue,
        endValue: widget.endValue,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onSave: (start, end) {
          _handleSave(start, end);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
      initialSize: 0.7,
      maxSize: 0.95,
      snapSizes: const [0.7, 0.95],
    );
  }

  /// Opens [LayrzTimeRangeSurface] in [LayrzPickerDrawer] on desktop —
  /// DESIGN-49's replacement for the previous [LayrzAnchoredPanel] container.
  /// See [LayrzPickerDrawer]'s class doc for why a fresh
  /// [LayrzPickerDrawer.show] call needs no generation-key trick: every open
  /// already reconstructs [LayrzTimeRangeSurface]'s `State` from scratch.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;
    await LayrzPickerDrawer.show<void>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzTimeRangeSurface(
        startValue: widget.startValue,
        endValue: widget.endValue,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onSave: (start, end) {
          _handleSave(start, end);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
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
        icon: MdiIcons.clockTimeFourOutline,
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
    if (!_summaryPrimed || widget.startValue != _lastStart || widget.endValue != _lastEnd) {
      _summaryPrimed = true;
      _lastStart = widget.startValue;
      _lastEnd = widget.endValue;
      _updateSummary();
    }

    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openDesktopDrawer);
  }
}
