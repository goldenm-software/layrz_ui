import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
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
/// showing day, hour, minute, and second fields. The picker adapts to screen size:
/// - **Desktop/wide** (>= 960px, `!context.isCompact`): [LayrzEndDrawer] with a
///   pinned Reset action (DESIGN-98)
/// - **Mobile/compact** (< 960px, `context.isCompact`): bottom sheet covering the lower screen
///
/// **DESIGN-98: moved from the anchored panel to [LayrzEndDrawer].** The
/// maintainer reported the anchored overlay "kinda weird" for this field after
/// live usage. This is a container change only, not a commit-model change --
/// this widget's fields already reported through [onChanged] on every edit
/// with no draft state to buffer, and that live contract is kept completely
/// unchanged. See [_LayrzDurationInputState._openDesktopDrawer]'s own doc for
/// why: the only thing that moves is the existing Reset button, from the
/// panel's own inline footer into the drawer's `actions` slot. No Cancel or
/// Save is added.
///
/// **The fixed 420px drawer width ([LayrzEndDrawer.width]) is narrower than
/// this panel used to render on a wide field, and now forces one field per
/// row.** Before DESIGN-98, the panel's width tracked the anchor field's own
/// rendered width (`LayrzAnchoredPanelWidthPolicy.matchAnchor`), which on a
/// wide field could exceed 900px and comfortably fit all four unit fields on
/// one row using the long-form labels (`_kNarrowFieldWidth`, 280px per
/// field). Inside the drawer, [LayrzDurationPickerPanel]'s own
/// `EdgeInsets.all(sp2)` padding (20px) leaves 372px of measured width for
/// its [LayoutBuilder]; solving `_kFieldMinWidth`'s own
/// `n * 200 + (n-1) * sp1 <= 372` yields `n = 1` -- so with all four default
/// units visible, the panel now stacks day/hour/minute/second into four
/// single-field rows instead of one shared row, and every field renders at
/// its own full 372px width, comfortably above `_kNarrowFieldWidth` (280px),
/// so the **long-form** unit labels stay reachable (unlike
/// [LayrzTimeInput]'s fields panel, whose narrower per-field share inside the
/// same 420px drawer makes its own short-form labels permanently the only
/// option -- see that widget's class doc). The user-visible change here is a
/// taller, single-column picker rather than the previous compact grid, not a
/// loss of the long-form labels.
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

  /// Opens the mobile bottom sheet surface hosting [LayrzDurationPickerPanel].
  ///
  /// **Regression fix (DESIGN-170):** [LayrzDurationPickerPanel.onChanged] fires on
  /// *every* field edit -- each +/- tap or keystroke on day/hour/minute/second, not just
  /// a deliberate reset (see that callback's own doc comment). An earlier version of this
  /// method wired `onChanged` straight to `Navigator.pop(context, duration)`, so the very
  /// first field edit inside the sheet popped it immediately -- the bottom sheet equivalent
  /// of the bug `28c9680` (`fix(duration): stop field edits from closing the panel...`)
  /// already fixed for the desktop anchored panel below, by splitting that panel's
  /// `onChanged` (live updates, panel stays open) from its `onReset` (closes the panel).
  /// That split was never carried over to this mobile branch, so the same failure mode
  /// regressed here: on a compact viewport, interacting with any picker field dismissed
  /// the sheet instead of registering the edit.
  ///
  /// This mirrors the desktop branch's contract exactly: [onChanged] below reports the
  /// live value to the caller and refreshes the anchor's summary text on every field edit,
  /// same as the desktop panel does, but never pops the sheet -- only [onReset] does that,
  /// since Reset is the one action in the picker meant to close it (see the desktop
  /// branch's own `onReset` doc for why). The sheet's return value is used only to detect
  /// "was this dismissed via Reset" versus "was this dismissed some other way" (the
  /// barrier, Escape, drag-to-dismiss, or the system back gesture) -- those other exits
  /// intentionally keep whatever value the live [onChanged] calls already reported, exactly
  /// like closing the desktop panel without pressing Reset keeps its last live value.
  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;

    final resetValue = await LayrzBottomSheet.show<Duration?>(
      context,
      builder: (context) => LayrzDurationPickerPanel(
        initialValue: widget.value,
        visibleUnits: widget.visibleUnits,
        // Field edits (typing, +/- taps) report the new value and refresh the anchor's
        // summary, but deliberately do NOT close the sheet -- see this method's doc
        // comment for why. Mirrors the desktop anchored panel's own `onChanged` below.
        onChanged: (duration) {
          widget.onChanged?.call(duration);
          if (mounted) {
            _updateSummary();
          }
        },
        // Reset is the one action meant to close the sheet -- a deliberate "clear and
        // I'm done" gesture, unlike an in-progress field edit. `LayrzDurationPickerPanel`
        // routes a reset through `onReset` INSTEAD OF `onChanged` (see its own
        // `_handleReset`, which calls `(widget.onReset ?? widget.onChanged)(...)` exactly
        // once), so supplying this callback means the reset value has NOT already been
        // reported by the `onChanged` above -- popping with it here is what reports it,
        // mirrored by the `widget.onChanged?.call(resetValue)` below once the sheet closes.
        onReset: (duration) {
          LayrzModalRoute.popIfCurrent(context, duration);
        },
      ),
      initialSize: 0.5,
      maxSize: 0.9,
      snapSizes: const [0.5, 0.9],
    );

    if (resetValue != null && mounted) {
      widget.onChanged?.call(resetValue);
      _updateSummary();
    }
  }

  /// Opens [LayrzDurationPickerPanel] in [LayrzEndDrawer] on desktop (DESIGN-98),
  /// replacing the previous [LayrzAnchoredPanel] hosting.
  ///
  /// **Commit model reversed (maintainer review, Finding 4): draft-then-Save,
  /// not live commit.** Before this, every field edit inside the drawer
  /// forwarded straight to [LayrzDurationInput.onChanged] with no discrete
  /// commit gesture at all -- the drawer carried Reset alone, on the
  /// reasoning that live reporting left nothing for a Save to commit. The
  /// maintainer's explicit follow-up reverses that: *"it needs the save and
  /// cancel buttons on actions."* [_draft] now buffers every field edit
  /// locally; [widget.onChanged] fires exactly once, when Save is pressed,
  /// mirroring [LayrzTimeInput]/[LayrzDateRangeInput]/every other
  /// Save-carrying picker in this batch rather than leaving Duration as the
  /// one widget whose caller sees values it never confirmed. Cancel discards
  /// [_draft] and closes without reporting anything, restoring
  /// [LayrzDurationInput.value] on the next open (a fresh [_draft] is seeded
  /// from [widget.value] every time this method runs, so nothing needs to be
  /// explicitly rolled back). Reset stays a deliberate "clear and I'm done"
  /// gesture distinct from Save: it zeroes [_draft], reports the zeroed
  /// duration immediately, and closes the drawer, exactly as it did before
  /// this change -- unlike the eight date/time pickers' own Clear (which only
  /// empties the draft and leaves Save to actually commit), Duration's Reset
  /// has always been both the clear-and-commit action in one gesture, and
  /// that stays true here.
  ///
  /// **Save is always enabled.** Unlike the eight date/time pickers (whose
  /// Save is gated on "has the user actually chosen something", since those
  /// widgets start from a genuinely empty state), every duration field
  /// already holds a concrete integer the moment the drawer opens -- there is
  /// no "nothing chosen yet" state for a live field cluster to be in, exactly
  /// the same reasoning [LayrzTimeSurfaceState.canSave] documents for time
  /// fields. `actions` being non-empty means [LayrzEndDrawer.show]'s own
  /// `canDismiss` inference now defaults to `false`; Cancel and Escape/the
  /// barrier tap must still discard the draft exactly like every other
  /// picker in this batch, so `canDismiss: true` is passed explicitly.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;

    final panelKey = GlobalKey<LayrzDurationPickerPanelState>();
    var draft = widget.value;

    await LayrzEndDrawer.show<void>(
      context,
      semanticLabel: widget.labelText == null ? widget.hintText : null,
      // DESIGN-98 Finding 5 (maintainer review): "title should be the
      // labelText of the input" -- see LayrzDateInput's identical doc for the
      // full rationale, including why `semanticLabel` above falls back to
      // `hintText` only rather than doubling this announcement.
      title: widget.labelText != null ? Text(widget.labelText!) : null,
      // Escape and the barrier tap must still cancel the draft even with
      // actions present -- matches every other Save-carrying picker in this
      // batch (see e.g. LayrzTimeInput._openDesktopDrawer's identical
      // override and doc).
      canDismiss: true,
      builder: (context) => LayrzDurationPickerPanel(
        key: panelKey,
        initialValue: widget.value,
        visibleUnits: widget.visibleUnits,
        showInlineFooter: false,
        // Field edits (typing, +/- taps) only update the local draft now --
        // see this method's own doc for why this no longer forwards straight
        // to widget.onChanged.
        onChanged: (duration) => draft = duration,
        // Reset remains its own deliberate commit-and-close gesture, distinct
        // from Save -- see this method's own doc.
        onReset: (duration) {
          widget.onChanged?.call(duration);
          _updateSummary();
          LayrzModalRoute.popIfCurrent(context);
        },
      ),
      // **`actions` is wrapped in its own `Builder` so its `onTap` closures
      // capture a `context` genuinely inside the drawer's route (maintainer
      // review, Finding 2).** `_openDesktopDrawer`'s own `context` -- the
      // anchor field's, captured once when this method runs -- is what an
      // ordinary closure written directly in this list would capture
      // instead, and `ModalRoute.of` on that outer context resolves to the
      // app's base route, not this drawer: `LayrzModalRoute.popIfCurrent`
      // would then read that base route's `isCurrent` (always `false` while
      // the drawer sits on top of it) and silently never pop. This is the
      // structural fix behind the maintainer's reported crash: `'currentConfiguration.isNotEmpty'
      // — You have popped the last page off of the stack`, thrown from this
      // exact `onTap` (`duration_input.dart:497` in the original report) --
      // the previous, unguarded `Navigator.pop(context)` used that same
      // wrong outer context, and popping the *base* route out from under
      // `go_router`'s delegate is exactly what asserts. `Builder` supplies a
      // fresh `context` from inside this subtree -- which [LayrzEndDrawer]
      // renders as a sibling of the scrolling `builder` body, both inside
      // the same pushed route -- so `LayrzModalRoute.popIfCurrent` resolves
      // the drawer's own route and a second call, from any cause, is
      // guaranteed a no-op rather than a double pop.
      actions: [
        Builder(
          builder: (drawerContext) {
            final tokens = drawerContext.tokens;
            // Each button wrapped in Flexible, not left to size itself --
            // mirrors LayrzPickerDrawerActions's identical Cancel/Clear/Save
            // row so Duration's own Cancel/Reset/Save combination never
            // overflows the drawer's padded width the same way that shared
            // widget's own doc explains.
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
                // Matches the picker Clear button's own styling convention
                // (LayrzPickerDrawerFooter: warning type, text style) --
                // Reset here plays the identical "destructive, not the
                // primary action" role.
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

    final isCompact = context.isCompact;

    if (isCompact) {
      // Mobile: display summary in a read-only field row that opens a bottom sheet. Shares
      // [_buildInteractiveField] with the desktop anchor below -- see its doc comment.
      return _buildInteractiveField(
        context: context,
        onTap: widget.disabled ? null : _openMobileSurface,
      );
    } else {
      // Desktop: opens [LayrzDurationPickerPanel] in [LayrzEndDrawer]
      // (DESIGN-98) -- replacing the previous `LayrzAnchoredPanel` hosting.
      // See [_openDesktopDrawer]'s own doc comment for why this is a
      // container change only, with Reset moved into the drawer's `actions`
      // slot and no Cancel/Save added.
      return _buildInteractiveField(
        context: context,
        onTap: widget.disabled ? null : _openDesktopDrawer,
      );
    }
  }
}
