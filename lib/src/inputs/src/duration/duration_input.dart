import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
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
/// showing day, hour, minute, and second fields. The picker opens via
/// [LayrzResponsiveModal.show], which resolves to a dialog on wide viewports
/// (`>= 960px`) or a bottom sheet below `isCompact` (`< 960px`) — but the two
/// branches deliberately keep **different commit models**, computed by
/// [_LayrzDurationInputState._openPicker] before that single call: the wide
/// branch carries a pinned Cancel/Reset/Save action row over a buffered
/// draft, while the compact branch stays live-commit with Reset as its only
/// closing action — see [_openPicker]'s own doc for why this genuine
/// divergence is preserved rather than forced into one shape.
///
/// **DESIGN-98: moved from the anchored panel to a dialog on wide viewports.**
/// The maintainer reported the anchored overlay "kinda weird" for this field
/// after live usage. This is a container change only for the wide branch's
/// underlying surface — see [_openPicker]'s own doc for why: the only thing
/// that moves is the existing Reset button, from the panel's own inline
/// footer into the modal's `actions` slot.
///
/// **The fixed dialog width is narrower than this panel used to render on a
/// wide field, and now forces multiple fields per row instead of one.**
/// Before DESIGN-98, the panel's width tracked the anchor field's own
/// rendered width (`LayrzAnchoredPanelWidthPolicy.matchAnchor`), which on a
/// wide field could exceed 900px and comfortably fit all four unit fields on
/// one row using the long-form labels (`_kNarrowFieldWidth`, 280px per
/// field). Inside the dialog ([LayrzDialogConfig.maxWidth]'s `480` default,
/// minus [LayrzDialog]'s own `2*sp3` panel padding), [LayrzDurationPickerPanel]'s
/// own `EdgeInsets.all(sp2)` padding leaves ~432px of measured width for its
/// [LayoutBuilder]; solving `_kFieldMinWidth`'s own `n * 200 + (n-1) * sp1 <=
/// 432` yields `n = 2` -- so with all four default units visible, the panel
/// now stacks day/hour/minute/second into two-field rows instead of one
/// four-field row, and every field renders at roughly half that width
/// (~213px) -- **below** `_kNarrowFieldWidth` (280px), so the **short-form**
/// unit labels are what actually render at the dialog's default width, not
/// the long-form ones (see [LayrzDurationPickerPanel]'s own
/// `fieldsPerRow`/label-switch doc for the exact threshold this resolves
/// against). The user-visible change here is a more compact, two-column
/// picker rather than the previous single wide row, not a change to the
/// commit model.
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

  /// Whether the field uses the dense density variant.
  ///
  /// When false (default), the field's internal padding is 14px on compact
  /// viewports and 10px on regular viewports. When true, padding drops one
  /// spacing level: 10px compact, 6px regular. No other dimension changes.
  final bool dense;

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
    this.dense = false,
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

  /// Opens [LayrzDurationPickerPanel] via [LayrzResponsiveModal.show].
  ///
  /// **The two branches deliberately keep different commit models — computed
  /// here, before the single `show` call, rather than forced into one
  /// shape.** [LayrzResponsiveModal.show] takes one `builder` and one
  /// `actions` list forwarded to whichever surface it resolves to, but
  /// nothing requires those values to be computed the same way for both —
  /// this method branches on `context.isCompact` once, up front, to build
  /// the pair the existing per-platform contract needs, then makes exactly
  /// one presentation call:
  /// - **Compact (sheet)**: live-commit, matching the pre-existing mobile
  ///   contract exactly (DESIGN-170 regression fix preserved verbatim). Every
  ///   field edit forwards straight to [LayrzDurationInput.onChanged] and
  ///   refreshes the anchor's summary; there is no discrete commit gesture
  ///   and no buffered draft. `actions` is `null` (nothing to answer with,
  ///   matching the old sheet's own bare Reset-in-panel-footer shape) and
  ///   Reset is the sheet's only closing action, reported by popping with the
  ///   reset value and applying it once the sheet closes below.
  /// - **Wide (dialog)**: draft-then-Save (maintainer review, Finding 4):
  ///   *"it needs the save and cancel buttons on actions."* [draft] buffers
  ///   every field edit locally; [widget.onChanged] fires exactly once, when
  ///   Save is pressed, mirroring [LayrzTimeInput]/[LayrzDateRangeInput]/
  ///   every other Save-carrying picker in this batch. Cancel discards
  ///   [draft] and closes without reporting anything (a fresh [draft] seeds
  ///   from [widget.value] on every open, so nothing needs rolling back).
  ///   Reset stays a deliberate "clear and I'm done" gesture distinct from
  ///   Save: it zeroes the panel, reports the zeroed duration immediately,
  ///   and closes — unlike the eight date/time pickers' own Clear (which
  ///   only empties the draft and leaves Save to actually commit), Duration's
  ///   Reset has always been both the clear-and-commit action in one
  ///   gesture. **Save is always enabled** — unlike the eight date/time
  ///   pickers (whose Save is gated on "has the user actually chosen
  ///   something"), every duration field already holds a concrete integer
  ///   the moment the dialog opens, exactly the same reasoning
  ///   [LayrzTimeSurfaceState.canSave] documents for time fields.
  ///
  /// **`actions` is wrapped in its own `Builder` (wide branch) so its
  /// `onTap` closures capture a `context` genuinely inside the modal's route
  /// (maintainer review, Finding 2).** This method's own `context` -- the
  /// anchor field's, captured once when this method runs -- is what an
  /// ordinary closure written directly in this list would capture instead,
  /// and `ModalRoute.of` on that outer context resolves to the app's base
  /// route, not this modal: `LayrzModalRoute.popIfCurrent` would then read
  /// that base route's `isCurrent` (always `false` while the modal sits on
  /// top of it) and silently never pop. This is the structural fix behind
  /// the maintainer's originally reported crash (`'currentConfiguration.isNotEmpty'
  /// — You have popped the last page off of the stack`): the previous,
  /// unguarded `Navigator.pop(context)` used that same wrong outer context,
  /// and popping the *base* route out from under `go_router`'s delegate is
  /// exactly what asserts. `Builder` supplies a fresh `context` from inside
  /// this subtree -- which [LayrzResponsiveModal.show]'s dialog branch
  /// renders as a sibling of the scrolling `builder` body, both inside the
  /// same pushed route -- so `LayrzModalRoute.popIfCurrent` resolves the
  /// modal's own route and a second call, from any cause, is guaranteed a
  /// no-op rather than a double pop.
  Future<void> _openPicker() async {
    if (widget.disabled) return;
    final isCompact = context.isCompact;

    final panelKey = GlobalKey<LayrzDurationPickerPanelState>();
    var draft = widget.value;

    final resetValue = await LayrzResponsiveModal.show<Duration?>(
      context,
      // [LayrzResponsiveModal.show] has no `title:` slot -- matches the
      // mobile bottom sheet path's own contract exactly: no visible title
      // anywhere, only a screen-reader `semanticLabel`.
      semanticLabel: widget.labelText ?? widget.hintText,
      // Escape and the barrier tap must still cancel the draft even with
      // actions present on the wide branch -- matches every other
      // Save-carrying picker in this batch. The compact branch passes no
      // `actions` at all, so this has no effect there either way.
      canDismiss: true,
      // The panel's own header (LayrzPickerDialogHeader) already renders a
      // close X next to the title, so the dialog branch's floating X would
      // be a redundant second X -- suppressing only the icon's render here
      // does not affect canDismiss: true above, and is silently ignored on
      // the compact (sheet) branch, which has no such icon at all.
      showCloseIcon: false,
      sheet: const LayrzBottomSheetConfig(
        initialSize: 0.5,
        maxSize: 0.9,
        snapSizes: [0.5, 0.9],
      ),
      builder: (context) => LayrzDurationPickerPanel(
        key: panelKey,
        initialValue: widget.value,
        visibleUnits: widget.visibleUnits,
        labelText: widget.labelText,
        // Compact keeps its own inline Reset button (the default,
        // preserving the pre-existing mobile contract exactly); wide
        // renders it via the `actions` row below instead.
        showInlineFooter: isCompact,
        onChanged: isCompact
            // Compact: live-commit -- see this method's own doc.
            ? (duration) {
                widget.onChanged?.call(duration);
                if (mounted) {
                  _updateSummary();
                }
              }
            // Wide: buffer into the local draft only -- see this method's
            // own doc for why this no longer forwards straight to
            // widget.onChanged.
            : (duration) => draft = duration,
        onReset: isCompact
            // Compact: Reset is the one action meant to close the sheet --
            // LayrzDurationPickerPanel routes a reset through `onReset`
            // INSTEAD OF `onChanged` (see its own `_handleReset`), so
            // popping with the reset value here is what reports it, mirrored
            // by the `widget.onChanged?.call(resetValue)` below once the
            // sheet closes.
            ? (duration) => LayrzModalRoute.popIfCurrent(context, duration)
            // Wide: Reset remains its own deliberate commit-and-close
            // gesture, distinct from Save -- see this method's own doc.
            : (duration) {
                widget.onChanged?.call(duration);
                _updateSummary();
                LayrzModalRoute.popIfCurrent(context);
              },
      ),
      actions: isCompact
          ? null
          : [
              Builder(
                builder: (drawerContext) {
                  final tokens = drawerContext.tokens;
                  // Each button wrapped in Flexible, not left to size itself
                  // -- mirrors LayrzPickerDrawerActions's identical
                  // Cancel/Clear/Save row so Duration's own
                  // Cancel/Reset/Save combination never overflows the
                  // modal's padded width the same way that shared widget's
                  // own doc explains.
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: LayrzButton.cancel(
                          labelText: drawerContext.l10n.actionCancel,
                          onTap: () => LayrzModalRoute.popIfCurrent(drawerContext),
                          style: LayrzButtonStyle.text,
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sp2),
                      // Matches the picker Clear button's own styling
                      // convention (LayrzPickerDrawerFooter: warning type,
                      // text style) -- Reset here plays the identical
                      // "destructive, not the primary action" role.
                      Flexible(
                        child: LayrzButton(
                          labelText: drawerContext.l10n.durationReset,
                          onTap: () => panelKey.currentState?.reset(),
                          type: LayrzButtonType.warning,
                          style: LayrzButtonStyle.text,
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sp2),
                      Flexible(
                        child: LayrzButton.save(
                          labelText: drawerContext.l10n.actionSave,
                          onTap: () {
                            widget.onChanged?.call(draft);
                            _updateSummary();
                            LayrzModalRoute.popIfCurrent(drawerContext);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
    );

    // The return value only ever carries a meaningful `Duration` on the
    // compact branch's Reset pop (see `onReset` above) -- the wide branch's
    // Cancel/Save/Reset all pop with no value (`void`), having already
    // reported through `widget.onChanged` themselves, mirroring the
    // pre-existing end-drawer contract exactly.
    if (resetValue != null && mounted) {
      widget.onChanged?.call(resetValue);
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
  /// chrome itself given `showBorder: false` so its own box never paints a competing
  /// border. `LayrzInputChrome` needed no change to support this: `showBorder` and
  /// `borderRadius` already exist on it for exactly this purpose. Unlike an earlier
  /// version of this row, the chrome's `borderRadius` is NOT `BorderRadius.zero`
  /// on the left: the chrome sits flush against this Row's physical left edge and
  /// paints its own opaque fill there, so it needs the same inset-corrected corner
  /// radius on that side that `NumberFieldControl` and `_SelectFieldCaret` give
  /// their own outer-edge caps — otherwise the outer `Container`'s `Clip.antiAlias`
  /// alone does not reshape the chrome's own square-cornered fill, and the left
  /// corners render flat instead of rounded. The right side (facing the affordance
  /// icon below) stays square — that edge is an internal seam, not a physical corner.
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
    // `readOnly` is deliberately NOT passed here (defaults to false): this
    // anchor is read-only only in the sense that it never accepts typed
    // input (it opens a picker on tap instead, see the class doc's
    // "Read-only anchor" note) -- that is a behavioral fact, not something a
    // caller ever set (`LayrzDurationInput` exposes no `readOnly` parameter
    // at all). `LayrzInputStyleSpec.resolve`'s own precedence table ranks
    // readOnly ABOVE error ("disabled > readOnly > error > ..."), so passing
    // `readOnly: true` here silently suppressed the danger border/background
    // whenever `hasErrors` was also true -- the field rendered in its neutral
    // resting colors even with an error present. Confirmed by the maintainer
    // from a device screenshot: label, error icon and footer text all showed
    // correctly, but the field's own border stayed grey instead of red.
    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
    );

    // The chrome sits at the Row's physical LEFT edge and paints its own opaque
    // fill (`spec.backgroundColor`) right up to that edge -- `Clip.antiAlias` on
    // the outer `Container` below clips content that overflows its bounds, but
    // does not reach inside to reshape an inner child's own square-cornered
    // fill that already sits flush within those bounds, so the chrome's
    // corners painted through unclipped and square. Mirrors the fix already
    // applied to `NumberFieldControl` (`number_field_edge.dart:80-93`) and
    // `_SelectFieldCaret`, both of which round their own outer-facing corners
    // for the same reason instead of relying on the outer clip. The inner
    // (right) edge, facing `_buildAffordanceIcon`, stays square -- it is an
    // internal seam, not a physical corner.
    final leftInnerR = Radius.circular(
      tokens.radius.innerRadiusValue(
        outerRadius: tokens.radius.r2,
        spacer: spec.borderWidth,
      ),
    );
    final chromeRadius = BorderRadius.only(topLeft: leftInnerR, bottomLeft: leftInnerR);

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
                // See the doc comment on `spec` above -- same reasoning: this
                // chrome's own internal `LayrzInputStyleSpec.resolve` call
                // would otherwise rank this false "readOnly" fact above a
                // real error state. `suppressReadOnlyLock: true` below
                // already independently keeps the lock icon from ever
                // showing (this field was never locked, just non-editable),
                // so this has no other effect than restoring error styling.
                readOnly: false,
                errors: widget.errors,
                hideDetails: true,
                states: states,
                suppressReadOnlyLock: true,
                controller: _controller,
                dense: widget.dense,
                helpTitleText: widget.helpTitleText,
                helpContentText: widget.helpContentText,
                borderRadius: chromeRadius,
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

    // Build the content display widget.
    //
    // Deliberately NOT wrapped in its own `Padding` -- unlike an earlier version of this
    // widget, which wrapped `Text` in `Padding(tokens.spacing.pd2)` here. `_buildFieldRow`
    // (below) already places this `child` inside `LayrzInputChrome`'s `Stack`/`Align`, which
    // is constrained to a fixed-height box sized by `LayrzInputChrome`'s own
    // `_InputComfortableSpec.contentHeight` (the text line height, with no allowance for a
    // caller-added Padding on top of it) -- the same box every other input's summary content
    // (e.g. `LayrzSelectInput`'s `selectedItem.child`) renders into with no padding of its
    // own. The chrome's outer `Container` already applies the field's real padding once
    // (`resolvedPadding`, outside this constrained box), so a second, inner `Padding` here
    // doesn't add visual breathing room -- it silently eats into the fixed content-height box
    // instead, squeezing the text's available height down to a sliver too small to paint,
    // even though the text itself renders with the correct content (verified live: the
    // summary "2 hours, 30 minutes" was present in the widget tree and the `RenderParagraph`
    // had the right text, but was laid out with `0.0<=h<=4.0`, rendering nothing visible).
    // `width: double.infinity` is kept so `TextOverflow.ellipsis`/wrapping still has a bounded
    // width to measure against.
    final contentChild = SizedBox(
      width: double.infinity,
      child: Text(
        displayText,
        style: tokens.typography.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    if (widget.value != _lastValue) {
      _lastValue = widget.value;
      _updateSummary();
    }

    // [_openPicker] itself branches on `context.isCompact` to pick the right
    // commit model before making its single LayrzResponsiveModal.show call
    // -- see that method's own doc.
    return _buildInteractiveField(
      context: context,
      onTap: widget.disabled ? null : _openPicker,
    );
  }
}
