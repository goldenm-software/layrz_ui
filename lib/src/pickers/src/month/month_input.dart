import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../models/month.dart';
import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'month_surface.dart';

/// Sentinel distinguishing "no summary computed yet" from a real `null`
/// [LayrzMonth] value in [_LayrzMonthInputState._lastValue] — `widget.value`
/// itself is nullable, so `null` cannot double as the "unset" marker.
const Object _unset = Object();

/// A Material-free month+year input field.
///
/// Composes [LayrzInputChrome] directly (D63) and opens [LayrzMonthSurface]
/// in [LayrzEndDrawer] on desktop or [LayrzBottomSheet] below `isCompact`.
///
/// **DESIGN-98: no longer commits on tap.** See [LayrzMonthSurface]'s class
/// doc and [LayrzDateInput]'s identical doc for the full rationale — a tap
/// now only drafts a month; [onChanged] fires once, on Save. **No Clear
/// action** — see [LayrzDateInput]'s doc for why a single-value picker's
/// `actions` row is Cancel/Save only.
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

  /// The `(value, formatter)` combination the summary text was last
  /// computed for, or [_unset] before the first build.
  ///
  /// Mirrors `LayrzDurationInput`'s own `_lastValue` guard
  /// (`duration_input.dart`'s `build()`): [_updateSummary] reads
  /// `context.l10n`, which asserts if called before this widget's
  /// [BuildContext] has an established `Localizations` dependency. Calling
  /// it eagerly from [initState] throws exactly that assertion, so instead
  /// [build] recomputes the summary only when this tuple has actually
  /// changed since the last build -- which also covers the very first
  /// build.
  ///
  /// **Widened beyond just `value` per DESIGN-45's "pattern changes must
  /// reflect immediately" finding** — see `LayrzDateInput._lastValue`'s own
  /// doc for the full rationale. This widget has no `pattern` field (only
  /// [LayrzMonthInput.formatter]), so `formatter` is the only addition
  /// needed here.
  Object? _lastValue = _unset;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT calling _updateSummary() here -- see _lastValue's doc.
    // The first build() computes it instead, once context.l10n is safe to read.
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

  /// Formats [value] into the anchor's summary text.
  ///
  /// [widget.formatter] takes precedence when supplied. Otherwise falls back
  /// to `formatStrftime(value.toDateTime(), '%B %Y', context.l10n)` — the
  /// house strftime-style formatter (Python `datetime` directives, not
  /// `intl`/`DateFormat` patterns), so month names resolve through
  /// [LayrzUiL10n] rather than a hardcoded English switch.
  void _updateSummary() {
    final value = widget.value;
    if (value == null) {
      _controller.text = '';
      return;
    }
    _controller.text = widget.formatter?.call(value) ?? formatStrftime(value.toDateTime(), '%B %Y', context.l10n);
  }

  void _handleSelected(LayrzMonth month) {
    widget.onChanged?.call(month);
    _updateSummary();
    setState(() {});
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: false, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzMonthSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      if (state == null) return;
      draftState.value = (canSave: state.canSave, hasSelection: false);
    }

    await LayrzBottomSheet.show<void>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzMonthSurface(
        key: surfaceKey,
        value: widget.value,
        minimum: widget.minimum,
        maximum: widget.maximum,
        disabledMonths: widget.disabledMonths,
        onDraftChanged: syncDraftState,
        onMonthSelected: (month) {
          _handleSelected(month);
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

  /// Opens [LayrzMonthSurface] in [LayrzEndDrawer] on desktop — see
  /// [LayrzDateRangeInput._openDesktopDrawer]'s identical doc for the full
  /// rationale (DESIGN-98). This surface has no Clear affordance, so
  /// `hasSelection` is always `false`.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: false, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzMonthSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      if (state == null) return;
      draftState.value = (canSave: state.canSave, hasSelection: false);
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
      builder: (context) => LayrzMonthSurface(
        key: surfaceKey,
        value: widget.value,
        minimum: widget.minimum,
        maximum: widget.maximum,
        disabledMonths: widget.disabledMonths,
        onDraftChanged: syncDraftState,
        onMonthSelected: (month) {
          _handleSelected(month);
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
    final currentValue = (widget.value, widget.formatter);
    if (!identical(_lastValue, currentValue) && _lastValue != currentValue) {
      _lastValue = currentValue;
      _updateSummary();
    }

    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openDesktopDrawer);
  }
}
