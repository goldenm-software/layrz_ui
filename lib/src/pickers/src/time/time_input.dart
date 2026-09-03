import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/time_of_day.dart';
import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'time_surface.dart';

/// A Material-free single-time input field.
///
/// Composes [LayrzInputChrome] directly (D63) and opens [LayrzTimeSurface] in
/// [LayrzEndDrawer] on desktop or [LayrzBottomSheet] below `isCompact`.
///
/// **DESIGN-98: Cancel/Save, not live commit.** Before DESIGN-98, this
/// widget's fields reported continuously via `onChanged` with no discrete
/// commit gesture at all — every field edit fired [onChanged] live (decision
/// D75, `engineering/milestone-4.md`). The maintainer's DESIGN-98 instruction
/// moves this widget onto [LayrzEndDrawer] **with actions**, which
/// supersedes that: [onChanged] now fires only once, on Save, with whatever
/// the fields currently hold; Cancel discards the edits back to [value]. See
/// [LayrzTimeSurfaceState]'s class doc for why Save is always enabled here,
/// unlike the other seven widgets.
///
/// **No Clear action** — see [LayrzDateInput]'s identical doc for why a
/// single-value picker's `actions` row is Cancel/Save only.
///
/// **Zero clock or dial affordance anywhere in the tree** — see
/// [LayrzPickersTimeFieldsPanel]'s class doc, which this widget's surface
/// composes unchanged.
class LayrzTimeInput extends StatefulWidget {
  /// The currently selected time.
  final LayrzTimeOfDay? value;

  /// Called with the new time on every field edit.
  final ValueChanged<LayrzTimeOfDay>? onChanged;

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

  /// Whether the seconds field is shown, without layout reflow when toggled.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form. Defaults to `true` —
  /// reversing the old layrz_theme picker's 12h default.
  final bool use24HourFormat;

  /// A strftime-style pattern used to format [value] for display, when
  /// [formatter] is not supplied. Defaults to `'%H:%M'`.
  final String pattern;

  /// A full-control override for formatting [value] into display text.
  final String Function(LayrzTimeOfDay)? formatter;

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

  /// Creates a new [LayrzTimeInput].
  const LayrzTimeInput({
    super.key,
    this.value,
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
  State<LayrzTimeInput> createState() => _LayrzTimeInputState();
}

class _LayrzTimeInputState extends State<LayrzTimeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  static const _midnight = LayrzTimeOfDay(hour: 0, minute: 0);

  // `build()` re-runs `_updateSummary()` only once per distinct
  // `widget.value`, mirroring `LayrzDurationInput`'s `_lastValue`
  // dirty-check -- but that alone can't tell "never computed" apart from
  // "computed for a `null` value", so `_summaryPrimed` covers the first
  // build explicitly. This exists for a correctness reason, not merely to
  // save work: `_updateSummary()` reads `context.l10n`, an inherited-widget
  // lookup that is illegal from `initState()` -- calling it there throws
  // "dependOnInheritedWidgetOfExactType... called before initState()
  // completed." So the summary is never primed in `initState`; the first
  // `build()` call always computes it instead, once the tree is attached.
  bool _summaryPrimed = false;
  LayrzTimeOfDay? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _lastValue = widget.value;
  }

  @override
  void didUpdateWidget(LayrzTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.value != oldWidget.value) {
      _lastValue = widget.value ?? LayrzTimeOfDay(hour: 0, minute: 0, second: 0);
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
    if (!_summaryPrimed) {
      _controller.text = '';
      _summaryPrimed = true;
      return;
    }
    if (_lastValue == null) {
      _controller.text = '';
      return;
    }

    if (widget.formatter != null) {
      _controller.text = widget.formatter!(_lastValue!);
      return;
    }

    final l10n = context.l10n;
    _controller.text = formatStrftime(_asDateTime(_lastValue!), widget.pattern, l10n);
  }

  void _handleSave(LayrzTimeOfDay time) {
    widget.onChanged?.call(time);
    setState(() {
      _lastValue = time;
      _updateSummary();
    });
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: true, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzTimeSurfaceState>();

    await LayrzBottomSheet.show<void>(
      context,
      // Names the sheet's route for screen readers with this field's own
      // label -- without it LayrzBottomSheet.show adds no route semantics at
      // all (see its own doc comment), so a screen-reader user opening the
      // sheet would hear no name for what they are picking. Falls back to
      // hintText when labelText is null, matching this widget's own
      // labelText-or-hintText constructor assertion.
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzTimeSurface(
        key: surfaceKey,
        value: widget.value ?? _midnight,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onTimeChanged: (time) {
          _handleSave(time);
          LayrzModalRoute.popIfCurrent(context);
        },
        onCancel: () => LayrzModalRoute.popIfCurrent(context),
      ),
      actions: [
        LayrzPickerDrawerActions(
          draftState: draftState,
          onCancel: (drawerContext) => LayrzModalRoute.popIfCurrent(drawerContext),
          onClear: (_) {},
          onSave: (_) => surfaceKey.currentState?.save(),
        ),
      ],
      initialSize: 0.4,
      maxSize: 0.7,
      snapSizes: const [0.4, 0.7],
    );

    draftState.dispose();
  }

  /// Opens [LayrzTimeSurface] in [LayrzEndDrawer] on desktop — see
  /// [LayrzDateRangeInput._openDesktopDrawer]'s identical doc for the full
  /// rationale (DESIGN-98). `draftState` never changes after construction:
  /// [LayrzTimeSurfaceState.canSave] is always `true` (see that class's own
  /// doc), so there is nothing for `onDraftChanged` to report here.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: true, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzTimeSurfaceState>();

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
      builder: (context) => LayrzTimeSurface(
        key: surfaceKey,
        value: widget.value ?? _midnight,
        showSeconds: widget.showSeconds,
        use24HourFormat: widget.use24HourFormat,
        onTimeChanged: (time) {
          _handleSave(time);
          LayrzModalRoute.popIfCurrent(context);
        },
        onCancel: () => LayrzModalRoute.popIfCurrent(context),
      ),
      actions: [
        LayrzPickerDrawerActions(
          draftState: draftState,
          onCancel: (drawerContext) => LayrzModalRoute.popIfCurrent(drawerContext),
          onClear: (_) {},
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
    if (!_summaryPrimed || widget.value != _lastValue) {
      _summaryPrimed = true;
      _lastValue = widget.value;
      _updateSummary();
    }

    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openDesktopDrawer);
  }
}
