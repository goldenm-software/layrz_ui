import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import '../shared/picker_drawer_actions.dart';
import 'color_surface.dart';

/// A Material-free color input field, resolving to a single [Color].
///
/// Composes [LayrzInputChrome] directly (D63, via `picker_anchor.dart`) and
/// opens [LayrzColorSurface] via [LayrzResponsiveModal.show], which resolves
/// to a dialog on wide viewports (`>= 960px`) or a [LayrzBottomSheet] below
/// `isCompact` — the same adaptive-surface pattern every other `pickers/`
/// input uses (see [LayrzDateInput] for the canonical reference this widget
/// mirrors).
///
/// **Two tabs, no `enabledTypes`-style parameter (Decision, OQ-1).** The
/// opened surface always offers exactly two ways to choose a color:
/// - **Palette** — renders [palette] (a caller-supplied `Set<Color>`) as a
///   grid of selectable swatches. Hidden entirely when [palette] is empty
///   (OQ-2) — the surface opens on Wheel instead rather than showing a dead
///   empty grid.
/// - **Wheel** — a from-scratch HSV color wheel disc plus a value/
///   brightness slider (Decision D-wheel; see [LayrzColorWheel]).
///
/// Both tabs, plus a HEX readout and a visible "Paste" button (Decision
/// D-paste: never an ambient clipboard read), live in [LayrzColorSurface].
///
/// **Staged-with-Save**, exactly like [LayrzDateInput]: tapping a swatch,
/// dragging the wheel, or pasting a valid hex color only updates the
/// surface's own draft — [onChanged] fires exactly once, when Save is
/// pressed, with the drafted color. Cancel discards the draft entirely.
///
/// **No Clear action.** A color field's only content is the one color
/// currently selected — there is no "nothing selected" state to clear back
/// to (unlike a date, which can be genuinely unset), so this widget's
/// `actions` row is Cancel/Save only, mirroring [LayrzDateInput]'s
/// identical reasoning.
class LayrzColorInput extends StatefulWidget {
  /// The currently-selected color.
  final Color value;

  /// Called with the newly-selected color when the user presses Save.
  /// Never called on mount, and never called merely by opening the surface
  /// — only an actual Save commits a change.
  final ValueChanged<Color>? onChanged;

  /// The caller-supplied set of swatches rendered by the Palette tab. An
  /// empty set (the default) hides the Palette tab entirely; the surface
  /// opens on Wheel in that case (OQ-2).
  final Set<Color> palette;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when no [labelText] describes the
  /// field.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// Whether the field is disabled (not interactive).
  final bool disabled;

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

  /// Creates a new [LayrzColorInput].
  const LayrzColorInput({
    super.key,
    required this.value,
    this.onChanged,
    this.palette = const {},
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
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       );

  @override
  State<LayrzColorInput> createState() => _LayrzColorInputState();
}

class _LayrzColorInputState extends State<LayrzColorInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    // Deliberately NOT reading context.l10n/context.theme here -- mirrors
    // LayrzDateInput's identical initState comment: an inherited-widget
    // dependency cannot be established before initState completes. build()
    // computes the displayed hex text on every build instead, which is
    // cheap (a pure string format) and needs no cached-comparison guard the
    // way LayrzDateInput's strftime formatting does.
  }

  @override
  void didUpdateWidget(LayrzColorInput oldWidget) {
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

  void _handleSelected(Color color) {
    widget.onChanged?.call(color);
    setState(() {});
  }

  /// Opens [LayrzColorSurface] via [LayrzResponsiveModal.show] — see
  /// [LayrzDateInput._openPicker]'s identical doc for the full rationale
  /// (no visible title, `canDismiss: true` even with actions present, the
  /// seeded-not-hardcoded draftState fix).
  ///
  /// `draftState` is seeded directly from `canSave`'s own predicate (draft
  /// != widget.value) -- always `false` at open time since the draft is
  /// seeded from the current value -- mirroring [LayrzDateInput._openPicker]'s
  /// identical race-avoidance reasoning for why this is computed rather than
  /// hardcoded blindly.
  Future<void> _openPicker() async {
    if (widget.disabled) return;
    final draftState = ValueNotifier<({bool canSave, bool hasSelection})>((canSave: false, hasSelection: false));
    final surfaceKey = GlobalKey<LayrzColorSurfaceState>();

    void syncDraftState() {
      final state = surfaceKey.currentState;
      draftState.value = (canSave: state!.canSave, hasSelection: false);
    }

    await LayrzResponsiveModal.show<void>(
      context,
      // [LayrzResponsiveModal.show] has no `title:` slot -- matches the
      // mobile bottom sheet path's own contract exactly: no visible title
      // anywhere, only a screen-reader `semanticLabel`.
      semanticLabel: widget.labelText ?? widget.hintText,
      canDismiss: true,
      // The surface's own header (LayrzPickerDialogHeader) already renders a
      // close X next to the title, so the dialog branch's floating X would
      // be a redundant second X -- suppressing only the icon's render here
      // does not affect canDismiss: true above -- barrier tap, Escape, and
      // the back gesture still cancel the draft.
      showCloseIcon: false,
      sheet: const LayrzBottomSheetConfig(
        initialSize: 0.7,
        maxSize: 0.95,
        snapSizes: [0.7, 0.95],
      ),
      builder: (context) => LayrzColorSurface(
        key: surfaceKey,
        value: widget.value,
        palette: widget.palette,
        labelText: widget.labelText,
        onDraftChanged: syncDraftState,
        onColorSelected: (color) {
          _handleSelected(color);
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
    _controller.text = widget.value.toHex();

    final contentChild = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: widget.value,
            borderRadius: tokens.radius.br1,
            border: Border.all(color: tokens.colors.divider),
          ),
          child: SizedBox(width: tokens.spacing.sp4, height: tokens.spacing.sp4),
        ),
        SizedBox(width: tokens.spacing.sp2),
        Expanded(
          child: Text(
            widget.value.toHex(),
            style: tokens.typography.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
        icon: MdiIcons.paletteOutline,
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
    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openPicker);
  }
}
