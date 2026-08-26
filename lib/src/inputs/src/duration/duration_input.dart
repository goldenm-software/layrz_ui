import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'duration_format.dart';
import 'duration_picker_panel.dart';
import 'duration_unit.dart';
import '../shared/input_chrome.dart';
import '../shared/input_footer_slot.dart';
import '../shared/input_slot.dart';
import '../shared/input_style_spec.dart';

/// The default set of visible duration units.
const _kDefaultVisibleUnits = {
  LayrzDurationUnit.day,
  LayrzDurationUnit.hour,
  LayrzDurationUnit.minute,
  LayrzDurationUnit.second,
};

/// Returns the smallest [LayrzDurationUnit] present in [visibleUnits].
///
/// "Smallest" is determined by enum declaration order (day, hour, minute,
/// second — largest to smallest), never by [Set] iteration order: a `Set`
/// literal preserves insertion order, so `{second, day}` would iterate
/// `second` first even though `day` is the larger unit. Walking
/// [LayrzDurationUnit.values] in its own fixed order and keeping the last
/// member found in [visibleUnits] sidesteps that entirely — the result never
/// depends on how [visibleUnits] itself was ordered.
///
/// Callers must supply a non-empty [visibleUnits] (enforced by
/// [LayrzDurationInput]'s constructor assertion); when empty this falls back
/// to [LayrzDurationUnit.day] rather than returning null, since that case
/// never occurs in practice.
LayrzDurationUnit _smallestVisibleUnit(Set<LayrzDurationUnit> visibleUnits) {
  var smallest = LayrzDurationUnit.values.first;
  for (final unit in LayrzDurationUnit.values) {
    if (visibleUnits.contains(unit)) {
      smallest = unit;
    }
  }
  return smallest;
}

/// Renders one unit's contribution to the summary text, e.g. `"2 hours"` in
/// [LayrzDurationFormat.long] or `"2h"` in [LayrzDurationFormat.short].
///
/// [count] is the numeric value already extracted for [unit] (day count,
/// `hour % 24`, etc. — computed by the caller). [l10n] supplies both the
/// spelled-out word and the abbreviation, plural or singular depending on
/// [count]; no unit word or abbreviation literal is hardcoded here.
String _formatUnitPart(LayrzUiL10n l10n, LayrzDurationFormat format, LayrzDurationUnit unit, int count) {
  final isSingular = count == 1;
  switch (format) {
    case LayrzDurationFormat.long:
      final word = switch (unit) {
        LayrzDurationUnit.day => isSingular ? l10n.durationUnitDaySingular : l10n.durationUnitDayPlural,
        LayrzDurationUnit.hour => isSingular ? l10n.durationUnitHourSingular : l10n.durationUnitHourPlural,
        LayrzDurationUnit.minute => isSingular ? l10n.durationUnitMinuteSingular : l10n.durationUnitMinutePlural,
        LayrzDurationUnit.second => isSingular ? l10n.durationUnitSecondSingular : l10n.durationUnitSecondPlural,
      };
      return '$count $word';
    case LayrzDurationFormat.short:
      final abbreviation = switch (unit) {
        LayrzDurationUnit.day => isSingular ? l10n.durationUnitDayShortSingular : l10n.durationUnitDayShortPlural,
        LayrzDurationUnit.hour => isSingular ? l10n.durationUnitHourShortSingular : l10n.durationUnitHourShortPlural,
        LayrzDurationUnit.minute =>
          isSingular ? l10n.durationUnitMinuteShortSingular : l10n.durationUnitMinuteShortPlural,
        LayrzDurationUnit.second =>
          isSingular ? l10n.durationUnitSecondShortSingular : l10n.durationUnitSecondShortPlural,
      };
      return '$count$abbreviation';
  }
}

/// A Material-free duration input field in the layrz_ui design system.
///
/// [LayrzDurationInput] captures a [Duration] value through a configurable picker
/// showing day, hour, minute, and second fields. The picker adapts to screen size:
/// - **Desktop/wide** (>= 960px, `!context.isCompact`): anchored panel positioned below the field
/// - **Mobile/compact** (< 960px, `context.isCompact`): bottom sheet covering the lower screen
///
/// **Unit bounds and capping:**
/// - **Day**: no upper bound (0 to infinity)
/// - **Hour**: 0–23 (23 represents the final hour of a day)
/// - **Minute**: 0–59
/// - **Second**: 0–59
///
/// The capping ensures a one-to-one mapping between a [Duration] and its field
/// representation. If a caller stores the result and reopens the picker, the
/// duration re-fills into the same field state with no ambiguity.
///
/// **Visible units:**
/// The [visibleUnits] parameter controls which fields appear in the picker.
/// Defaults to all four. Units not in the set are skipped; at least one unit
/// must be present (enforced by assertion).
///
/// **Summary display:**
/// The anchor displays a humanised summary, formatted per [format]. In
/// [LayrzDurationFormat.long] (the default) that reads like "2 days, 3 hours"
/// (zero-valued units omitted, localized unit names and pluralisation); in
/// [LayrzDurationFormat.short] the same duration reads "2d 3h" (localized unit
/// abbreviations, no comma). A null [value] shows empty placeholder text. A
/// non-null [value] equal to [Duration.zero] shows a zero reading of the
/// smallest unit in [visibleUnits] (e.g. "0s" or, with seconds hidden, "0m")
/// rather than empty text, so a chosen zero stays visually distinct from no
/// value at all.
///
/// **Unsupported units:**
/// Year, month, and week are not supported because they are not fixed-length
/// and cannot be reliably mapped to [Duration].
///
/// **Disposal contract:** When `controller` or `focusNode` is null, the widget
/// creates and disposes its own instances. Caller-supplied instances are never disposed.
///
/// **Read-only anchor:** The summary is shown in a read-only text input that opens
/// the picker on tap. The input does not show a lock icon because the picker is
/// interactive, not locked.
class LayrzDurationInput extends StatefulWidget {
  /// The currently selected duration.
  ///
  /// When null, the anchor shows empty text and the picker opens with all fields
  /// at zero (or uninitialized, depending on field visibility).
  final Duration? value;

  /// Callback fired when the duration changes.
  ///
  /// Called with the new [Duration] when the user edits any field or presses reset.
  /// Not called when the picker is opened without changes.
  final ValueChanged<Duration?>? onChanged;

  /// The set of units visible in the picker.
  ///
  /// Defaults to all four ([LayrzDurationUnit.day], [LayrzDurationUnit.hour],
  /// [LayrzDurationUnit.minute], [LayrzDurationUnit.second]). Must be non-empty
  /// (enforced by assertion).
  ///
  /// Units not in the set are omitted from the picker and the summary display.
  final Set<LayrzDurationUnit> visibleUnits;

  /// The format used to render the anchor's summary text.
  ///
  /// Defaults to [LayrzDurationFormat.long], which reproduces the summary
  /// this widget rendered before [LayrzDurationFormat] existed (e.g. "2 days,
  /// 3 hours") — so existing callers see no behavior change. Pass
  /// [LayrzDurationFormat.short] for an abbreviated summary (e.g. "2d 3h").
  final LayrzDurationFormat format;

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

  /// The text editing controller for the anchor field.
  ///
  /// If null, a controller is created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the anchor field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The padding applied inside the anchor field.
  ///
  /// If null, defaults to the value used by [LayrzTextInput].
  final EdgeInsets? padding;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Creates a new [LayrzDurationInput].
  LayrzDurationInput({
    super.key,
    this.value,
    this.onChanged,
    this.visibleUnits = _kDefaultVisibleUnits,
    this.format = LayrzDurationFormat.long,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.controller,
    this.focusNode,
    this.padding,
    this.helpTitleText,
    this.helpContentText,
  }) : assert(
         visibleUnits.isNotEmpty,
         'visibleUnits must not be empty.',
       );

  @override
  State<LayrzDurationInput> createState() => _LayrzDurationInputState();
}

class _LayrzDurationInputState extends State<LayrzDurationInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late MenuController _panelController;
  Duration? _lastValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzDurationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _updateSummary() {
    final l10n = context.l10n;
    final duration = widget.value;

    if (duration == null) {
      _controller.text = '';
      return;
    }

    final parts = <String>[];

    if (widget.visibleUnits.contains(LayrzDurationUnit.day)) {
      final days = duration.inDays;
      if (days > 0) {
        parts.add(_formatUnitPart(l10n, widget.format, LayrzDurationUnit.day, days));
      }
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.hour)) {
      final hours = (duration.inHours % 24);
      if (hours > 0) {
        parts.add(_formatUnitPart(l10n, widget.format, LayrzDurationUnit.hour, hours));
      }
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.minute)) {
      final minutes = (duration.inMinutes % 60);
      if (minutes > 0) {
        parts.add(_formatUnitPart(l10n, widget.format, LayrzDurationUnit.minute, minutes));
      }
    }

    if (widget.visibleUnits.contains(LayrzDurationUnit.second)) {
      final seconds = (duration.inSeconds % 60);
      if (seconds > 0) {
        parts.add(_formatUnitPart(l10n, widget.format, LayrzDurationUnit.second, seconds));
      }
    }

    if (parts.isEmpty) {
      // Every visible unit is zero. Rather than showing empty text — which a
      // caller cannot distinguish from `value == null` — render a zero
      // reading of the smallest unit currently visible, so an explicit zero
      // duration stays visually distinct from "no value set".
      final zeroUnit = _smallestVisibleUnit(widget.visibleUnits);
      parts.add(_formatUnitPart(l10n, widget.format, zeroUnit, 0));
    }

    final separator = widget.format == LayrzDurationFormat.short ? ' ' : ', ';
    _controller.text = parts.join(separator);
  }

  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;

    final result = await LayrzBottomSheet.show<Duration?>(
      context,
      builder: (context) => LayrzDurationPickerPanel(
        initialValue: widget.value,
        visibleUnits: widget.visibleUnits,
        onChanged: (duration) {
          Navigator.pop(context, duration);
        },
      ),
      initialSize: 0.5,
      maxSize: 0.9,
      snapSizes: const [0.5, 0.9],
    );

    if (result != null && mounted) {
      widget.onChanged?.call(result);
      _updateSummary();
    }
  }

  /// Builds the clock-style icon that identifies this field as a duration picker.
  ///
  /// Rendered as an **external sibling** of [LayrzInputChrome] — inside [_buildFieldRow]'s
  /// `Row`, never in `prefixSlot`/`suffixSlot` — so both slots stay free for a caller to use.
  /// This follows the same governance-approved pattern `LayrzNumberInput` uses for its step
  /// buttons (`number_input.dart`'s `NumberFieldControl`): the widget's own affordance lives
  /// beside the chrome, not inside it.
  ///
  /// [tokens] supplies spacing, color, and border tokens. [spec] is the
  /// [LayrzInputStyleSpec] already resolved for the field's current interaction state, so the
  /// glyph color always matches the field (e.g. dims to `fg4` when disabled) with no
  /// separate state tracking of its own. [hasErrors] selects the divider's error-aware color,
  /// mirroring [NumberFieldControl]'s divider treatment between its cap and the chrome.
  ///
  /// Purely decorative: the field's own [Semantics] node (set by [_buildInteractiveField])
  /// already carries the label and enabled state, so this is wrapped in [ExcludeSemantics] to
  /// avoid announcing the icon a second time.
  Widget _buildAffordanceIcon({
    required LayrzTokens tokens,
    required LayrzInputStyleSpec spec,
    required bool hasErrors,
  }) {
    final dividerColor = hasErrors ? tokens.colors.danger : tokens.colors.divider.withValues(alpha: 0.3);

    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: dividerColor, width: tokens.border.stroke2),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
        child: Align(
          alignment: Alignment.center,
          child: Icon(
            MdiIcons.clockOutline,
            size: tokens.typography.body.fontSize,
            color: spec.textColor,
          ),
        ),
      ),
    );
  }

  /// Builds the bordered field row: [LayrzInputChrome] plus the affordance icon.
  ///
  /// Mirrors `number_input.dart:869-924`'s composition — a `Row` of `[chrome, control]`
  /// wrapped in one outer `Container` that draws the unified border and radius, with the
  /// chrome itself given `showBorder: false` and `borderRadius: BorderRadius.zero` so its own
  /// box never paints a competing border. `LayrzInputChrome` needed no change to support
  /// this: `showBorder` and `borderRadius` already exist on it for exactly this purpose.
  ///
  /// [labelText] and the error/helper footer are deliberately **not** passed to the inner
  /// chrome here (`labelText: null`, `hideDetails: true`) — [_buildInteractiveField] renders
  /// both outside this row instead, so the affordance icon sits only beside the field box
  /// itself, not stretched across the label above or the footer below it.
  ///
  /// [context] is the current [BuildContext]. [tokens] is the resolved [LayrzTokens] for this
  /// build. [contentChild] is the (non-editable) summary text widget shown inside the chrome.
  /// [states] is the widget's current interaction states, forwarded to both the chrome and the
  /// affordance icon so they always agree on disabled/enabled styling.
  Widget _buildFieldRow({
    required BuildContext context,
    required LayrzTokens tokens,
    required Widget contentChild,
    required Set<WidgetState> states,
  }) {
    final hasErrors = widget.errors.isNotEmpty;
    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: true,
    );

    return Container(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        border: Border.all(
          color: spec.borderColor,
          width: spec.borderWidth,
        ),
        borderRadius: tokens.radius.br2,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayrzInputChrome(
                labelText: null,
                hintText: widget.hintText,
                isRequired: widget.isRequired,
                prefixSlot: const LayrzInputPrefixSlot(),
                suffixSlot: const LayrzInputSuffixSlot(),
                disabled: widget.disabled,
                readOnly: true,
                errors: widget.errors,
                hideDetails: true,
                states: states,
                suppressReadOnlyLock: true,
                controller: _controller,
                padding: widget.padding,
                helpTitleText: widget.helpTitleText,
                helpContentText: widget.helpContentText,
                borderRadius: BorderRadius.zero,
                showBorder: false,
                child: contentChild,
              ),
            ),
            _buildAffordanceIcon(tokens: tokens, spec: spec, hasErrors: hasErrors),
          ],
        ),
      ),
    );
  }

  /// Builds the interactive anchor shared by the desktop and compact bands.
  ///
  /// Both bands render the same composition — an optional label, the bordered field row from
  /// [_buildFieldRow] (chrome + affordance icon), and the error/helper footer — and differ only
  /// in what [onTap] does: open the desktop anchored panel's `MenuController`, or open the
  /// mobile bottom sheet. Factoring this out keeps that composition defined exactly once
  /// instead of duplicated per band.
  ///
  /// [context] is the current [BuildContext]. [onTap] is invoked on tap; callers pass `null`
  /// when [LayrzDurationInput.disabled] is true so the [GestureDetector] and the [Semantics]
  /// node both report no tap handler.
  Widget _buildInteractiveField({
    required BuildContext context,
    required VoidCallback? onTap,
  }) {
    final tokens = context.tokens;

    // Display summary text or placeholder
    final displayText = _controller.text.isEmpty ? (widget.hintText ?? '') : _controller.text;

    // Build the content display widget
    final contentChild = Padding(
      padding: tokens.spacing.pd2,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          displayText,
          style: tokens.typography.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // Compute widget states
    final states = <WidgetState>{};
    if (widget.disabled) {
      states.add(WidgetState.disabled);
    }

    final fieldRow = _buildFieldRow(
      context: context,
      tokens: tokens,
      contentChild: contentChild,
      states: states,
    );

    return Semantics(
      label: widget.labelText,
      button: true,
      enabled: !widget.disabled,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Attaches `_focusNode` to the focus tree. `LayrzInputChrome` is
        // purely visual and never does this itself, and passing the node to
        // `LayrzAnchoredPanel.childFocusNode` alone only tells the panel where
        // to restore focus -- it does not attach the node anywhere on its own.
        child: Focus(
          focusNode: _focusNode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label rendered outside the chrome -- see the doc comment on
              // [_buildFieldRow] for why.
              if (widget.labelText != null)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
                  child: ExcludeSemantics(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: widget.labelText,
                            style: tokens.typography.label.copyWith(
                              color: tokens.colors.fg2,
                            ),
                          ),
                          if (widget.isRequired)
                            TextSpan(
                              text: '*',
                              style: tokens.typography.label.copyWith(
                                color: tokens.colors.danger,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              fieldRow,
              // Error block, rendered outside the chrome -- see the doc comment on
              // [_buildFieldRow] for why.
              LayrzInputFooterSlot(
                errors: widget.errors,
                hideDetails: widget.hideDetails,
                controller: _controller,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the anchor widget for desktop anchored panel.
  Widget _buildAnchor(BuildContext context, MenuController controller) {
    return _buildInteractiveField(
      context: context,
      onTap: widget.disabled ? null : controller.open,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != _lastValue) {
      _lastValue = widget.value;
      _updateSummary();
    }

    final isCompact = context.isCompact;

    if (isCompact) {
      // Mobile: display summary in a read-only field row that opens a bottom sheet. Shares
      // [_buildInteractiveField] with the desktop anchor below -- see its doc comment.
      return _buildInteractiveField(
        context: context,
        onTap: widget.disabled ? null : _openMobileSurface,
      );
    } else {
      // Desktop: return an anchored panel that covers the field itself, mirroring
      // `LayrzSelectInput`'s "elevated field" illusion (DESIGN-145) -- see the
      // `border` argument below for why. `widthPolicy: matchAnchor` -- the panel
      // spans the field's full rendered width, exactly like `LayrzSelectInput`.
      //
      // This REVERSES an earlier decision (device-tested and reported by the
      // maintainer): the panel previously stayed `contentSized` within
      // 280.0-480.0 on the reasoning that `LayrzDurationPickerPanel`'s
      // two-column grid depended on that exact width range (the measured
      // 227px/7-character constraint documented on that widget's class doc).
      // On a wide anchor field, `contentSized` made the panel occupy only a
      // small fraction of the field -- visually wrong, and rejected on sight.
      // `LayrzDurationPickerPanel` no longer depends on a capped width: its own
      // per-unit fields now carry a minimum width and wrap to additional rows
      // via a `LayoutBuilder` that reads the panel's own measured width,
      // instead of the old fixed two-column `LayrzRow`/`LayrzCol` grid, so
      // they stay legible at whatever width `matchAnchor` actually provides --
      // see that widget's class doc for the new mechanism.
      final tokens = context.tokens;
      final hasErrors = widget.errors.isNotEmpty;

      return LayrzAnchoredPanel(
        widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
        maxHeight: 400.0,
        coverAnchor: true,
        childFocusNode: _focusNode,
        builder: (context, controller) {
          _panelController = controller;
          return _buildAnchor(context, controller);
        },
        // Painted by the panel around its own capped viewport, not by this
        // widget around its content -- see `LayrzAnchoredPanelBorder`'s own doc
        // comment for why that distinction matters. Mirrors
        // `select_input.dart`'s identical border, colored the same way
        // (primary, or danger when the field has errors).
        border: LayrzAnchoredPanelBorder(
          color: hasErrors ? tokens.colors.danger : tokens.colors.primary,
          width: tokens.border.base,
        ),
        child: LayrzDurationPickerPanel(
          initialValue: widget.value,
          visibleUnits: widget.visibleUnits,
          // Field edits (typing, +/- taps) report the new value and update the
          // anchor's summary, but deliberately do NOT close the panel -- a user
          // composing a duration across multiple fields (day, then hour, then
          // minute) needs the panel to stay open between edits. Only `onReset`
          // below closes it; see that callback's wiring for why.
          onChanged: (duration) {
            widget.onChanged?.call(duration);
            _updateSummary();
          },
          // Reset is the one action in the panel meant to close it: it is a
          // deliberate "clear and I'm done" gesture, unlike an in-progress field
          // edit. Wiring this separately from `onChanged` above is what stops
          // every +/- tap and keystroke from closing the panel too -- they used
          // to share one callback that always closed it.
          onReset: (duration) {
            widget.onChanged?.call(duration);
            _updateSummary();
            _panelController.close();
          },
        ),
      );
    }
  }
}
