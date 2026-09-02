import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import 'date_surface.dart';

/// A Material-free single-date input field.
///
/// Composes [LayrzInputChrome] directly (D63) and opens [LayrzDateSurface]
/// through [LayrzAnchoredPanel] on desktop (`>= 960px`) or [LayrzBottomSheet]
/// below `isCompact`, mirroring `LayrzDurationInput`'s structure — see that
/// widget's file for the fully-commented template this follows.
///
/// **Commit on tap**: the surface reports the tapped date via [onChanged]
/// and the panel/sheet closes on that same gesture — there is no Save
/// footer for this widget.
///
/// **Preserves `TZDateTime` zones**: [value] and every date [onChanged]
/// reports are constructed via `sameZoneDate`, so a caller passing a
/// `TZDateTime` gets a `TZDateTime` back in the same zone, never silently
/// re-anchored to the host's local zone.
class LayrzDateInput extends StatefulWidget {
  /// The currently selected date.
  final DateTime? value;

  /// Called with the newly selected date on commit.
  final ValueChanged<DateTime>? onChanged;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty and no
  /// [labelText] describes it.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// Whether the field is disabled (not interactive).
  final bool disabled;

  /// The earliest selectable date, inclusive. `null` means no lower bound.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive. `null` means no upper bound.
  final DateTime? lastDay;

  /// Individually disabled dates, beyond [firstDay]/[lastDay].
  final Set<DateTime> disabledDays;

  /// Which [DateTime] weekday constant starts each week in the grid.
  /// Defaults to [DateTime.monday] — deliberately differing from
  /// `LayrzCalendar`'s `DateTime.sunday` default; asserted to be within
  /// `DateTime.monday..DateTime.sunday`.
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders (cut to a thin decorative
  /// strip below `isCompact`). Defaults to `true`.
  final bool showWeekNumbers;

  /// A strftime-style pattern (see `lib/src/formatting/`) used to format
  /// [value] for display, when [formatter] is not supplied. Defaults to
  /// `'%Y-%m-%d'`.
  final String pattern;

  /// A full-control override for formatting [value] into display text,
  /// taking precedence over [pattern] when supplied.
  final String Function(DateTime)? formatter;

  /// The text editing controller for the anchor field. If null, one is
  /// created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the anchor field. If null, one is created and
  /// disposed by the widget.
  final FocusNode? focusNode;

  /// Whether the field uses the dense density variant.
  final bool dense;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Creates a new [LayrzDateInput].
  const LayrzDateInput({
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
  }) : assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
       );

  @override
  State<LayrzDateInput> createState() => _LayrzDateInputState();
}

class _LayrzDateInputState extends State<LayrzDateInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late MenuController _panelController;

  /// The [widget.value] the summary text was last computed for.
  ///
  /// [_updateSummary] reads `context.l10n`, which depends on the
  /// [Localizations] inherited widget — that dependency cannot be
  /// established from `initState` (Flutter throws
  /// "dependOnInheritedWidgetOfExactType() ... called before initState()
  /// completed"). Mirroring `LayrzDurationInput`'s own `_lastValue` cache,
  /// [build] compares [widget.value] against this field and only calls
  /// [_updateSummary] when it actually changed, which is always safe
  /// because [build] runs with a fully established inherited-widget
  /// dependency.
  DateTime? _lastValue;

  /// Bumped immediately before the desktop panel is opened, and used as
  /// [LayrzDateSurface]'s [Key].
  ///
  /// **Involuntary-close fix.** `LayrzAnchoredPanel` takes its `child`
  /// eagerly (`anchored_panel.dart:72`) and never recreates it per open, so
  /// [LayrzDateSurface]'s `State` — specifically its `_displayedMonth`,
  /// which only re-seeds in `didUpdateWidget` when `widget.value` itself
  /// changes — would otherwise survive a tap-outside/Escape close unchanged.
  /// A user who browses to a different month without selecting, then closes
  /// involuntarily, would reopen the panel on that stale browsed-to month
  /// instead of back on the committed [LayrzDateInput.value]. Changing this
  /// key on every open forces Flutter to discard and reconstruct
  /// [LayrzDateSurface]'s `State`, which re-seeds `_displayedMonth` from
  /// [LayrzDateInput.value] in `initState` unconditionally. The mobile
  /// bottom-sheet branch needs no equivalent: [LayrzBottomSheet.show] pushes
  /// a fresh route (and so a fresh `builder` widget) on every call.
  int _surfaceGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT calling `_updateSummary()` here -- see `_lastValue`'s
    // own doc for why: it reads `context.l10n`, which cannot be established
    // from `initState`. `build` performs the initial (and every
    // subsequent) summary computation via the `_lastValue` comparison.
  }

  @override
  void didUpdateWidget(LayrzDateInput oldWidget) {
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
    final l10n = context.l10n;
    _controller.text = widget.formatter?.call(value) ?? formatStrftime(value, widget.pattern, l10n);
  }

  void _handleSelected(DateTime date) {
    widget.onChanged?.call(date);
    _updateSummary();
    setState(() {});
  }

  /// Opens the desktop anchored panel, bumping [_surfaceGeneration] first so
  /// [LayrzDateSurface] is reconstructed fresh on every open — see
  /// [_surfaceGeneration]'s own doc for why this is required.
  void _openDesktopPanel() {
    setState(() => _surfaceGeneration++);
    _panelController.open();
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;
    await LayrzBottomSheet.show<void>(
      context,
      builder: (context) => LayrzDateSurface(
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onDateSelected: (date) {
          _handleSelected(date);
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
        icon: MdiIcons.calendarBlankOutline,
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
    if (widget.value != _lastValue) {
      _lastValue = widget.value;
      _updateSummary();
    }

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
        return _buildInteractiveField(
          context: context,
          onTap: widget.disabled ? null : _openDesktopPanel,
        );
      },
      border: LayrzAnchoredPanelBorder(
        color: hasErrors ? tokens.colors.danger : tokens.colors.primary,
        width: tokens.border.base,
      ),
      child: LayrzDateSurface(
        key: ValueKey(_surfaceGeneration),
        value: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onDateSelected: (date) {
          _handleSelected(date);
          _panelController.close();
        },
      ),
    );
  }
}
