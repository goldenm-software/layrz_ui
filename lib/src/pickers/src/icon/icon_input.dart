import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';

import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import 'icon_surface.dart';

/// A Material-free single-icon input field, sourced from the
/// `flutter_mdi_remap` package's ~7,447-entry Material Design Icons registry.
///
/// Composes [LayrzInputChrome] directly (D63, via `picker_anchor.dart`'s
/// helpers) and opens [LayrzIconSurface] via [LayrzResponsiveModal.show],
/// which resolves to a dialog on wide viewports (`>= 960px`) or a
/// [LayrzBottomSheet] below `isCompact` — the same adaptive host every other
/// `pickers/` widget uses.
///
/// **Value is `String?` — the icon's stable `'mdi-...'` name**, e.g.
/// `'mdi-account'`, NOT [MdiRemapIcon] itself and NOT a raw [IconData]. This
/// mirrors [LayrzEmojiInput]'s own "store what a caller actually
/// persists" contract, but resolves the opposite way for the opposite
/// reason: an emoji's [String] character IS the stable, portable value on
/// its own, while an MDI icon's renderable [IconData] carries a codepoint
/// that is **not** stable across `flutter_material_design_icons` package
/// versions — only [MdiRemapIcon.name] is guaranteed stable, since it is the
/// registry's own lookup key ([findMdiRemapIconByName]). Storing the name
/// string (rather than the [MdiRemapIcon] value type) keeps this widget's
/// public contract a plain, directly-serializable [String] — exactly what a
/// caller round-trips through a form model, a GraphQL mutation, or local
/// storage — while [findMdiRemapIconByName] resolves it back to a
/// renderable icon whenever this widget (or any other caller) needs to
/// display it.
///
/// **Commit-on-tap — no Save row.** Unlike the date/month/time/color/
/// multi-select pickers in this module (all staged-with-Save), tapping an
/// icon in [LayrzIconSurface] both fires [onChanged] and closes the hosting
/// surface immediately, via [LayrzModalRoute.popIfCurrent] — mirroring
/// [LayrzEmojiInput]'s identical "picking IS the decision for a single
/// icon" ruling. No `actions` list is passed to [LayrzResponsiveModal.show],
/// so `canDismiss` infers `true` on both branches (barrier tap / Escape /
/// back gesture all close with no value, exactly like backing out without
/// picking).
///
/// **Self-display.** [_LayrzIconInputState] keeps `_controller.text`
/// synchronized with [value] (via `initState`/`didUpdateWidget`, and via
/// `setState` immediately on a fresh pick — mirroring [LayrzEmojiInput]'s
/// identical self-display contract) and resolves that text to a renderable
/// [MdiRemapIcon] via [findMdiRemapIconByName] on every build, so the closed
/// field reflects a freshly committed pick immediately even when the caller
/// does not immediately feed a new [value] back in, and equally reflects a
/// name a caller feeds back in from persisted storage that this widget
/// never itself produced.
class LayrzIconInput extends StatefulWidget {
  /// The currently selected icon's stable `'mdi-...'` name, or `null` when
  /// nothing has been picked yet. Round-trips through
  /// [findMdiRemapIconByName] to resolve back to a renderable
  /// [MdiRemapIcon].
  final String? value;

  /// Called with the newly picked icon's stable `'mdi-...'` name on commit
  /// (a tap in [LayrzIconSurface]). Never called with `null` — there is no
  /// Clear affordance on this picker (mirroring [LayrzEmojiInput]'s
  /// identical "no Clear action" reasoning: picking is the only
  /// content-changing gesture, and backing out via Escape/barrier tap
  /// already covers "change nothing").
  final ValueChanged<String>? onChanged;

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

  /// Creates a new [LayrzIconInput].
  const LayrzIconInput({
    super.key,
    this.value,
    this.onChanged,
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
  State<LayrzIconInput> createState() => _LayrzIconInputState();
}

class _LayrzIconInputState extends State<LayrzIconInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.text = widget.value ?? '';
  }

  @override
  void didUpdateWidget(LayrzIconInput oldWidget) {
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
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Applies a freshly picked icon name: reports it via [onChanged] and
  /// updates [_controller]'s text so the closed field's own display
  /// refreshes even when the caller does not immediately feed a new
  /// [LayrzIconInput.value] back in (mirrors [LayrzEmojiInput]'s identical
  /// self-display contract).
  void _handleSelected(String name) {
    widget.onChanged?.call(name);
    setState(() => _controller.text = name);
  }

  /// Opens [LayrzIconSurface] via [LayrzResponsiveModal.show].
  ///
  /// **`scrollable: false`** (on the sheet branch, via
  /// [LayrzBottomSheetConfig]) — [LayrzIconSurface] scrolls its own icon
  /// grid internally (a lazy, non-shrink-wrapped `LayrzGlyphGrid` filling
  /// an `Expanded` section of the surface's `Column`), so it must not
  /// additionally be wrapped in a default `SingleChildScrollView`: that
  /// would hand the surface's `Column` unbounded height, which its
  /// `Expanded` grid section cannot resolve against — mirrors
  /// [LayrzEmojiInput]'s identical reasoning.
  ///
  /// No `actions` are passed (commit-on-tap, see class doc), so
  /// `canDismiss` infers `true` from [LayrzResponsiveModal.show]'s own
  /// default — barrier tap, Escape, and the back gesture all close the
  /// modal with no value, exactly like backing out of the pick.
  Future<void> _openPicker() async {
    if (widget.disabled) return;

    await LayrzResponsiveModal.show<void>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      // The surface's own header (LayrzPickerDialogHeader) already renders a
      // close X next to the title, so the dialog branch's floating X would
      // be a redundant second X -- suppressing only the icon's render here
      // does not affect canDismiss's own inference (still `true`, since no
      // `actions` are passed) -- barrier tap, Escape, and the back gesture
      // all still close the modal with no value.
      showCloseIcon: false,
      sheet: const LayrzBottomSheetConfig(
        scrollable: false,
        initialSize: 0.6,
        maxSize: 0.9,
        snapSizes: [0.6, 0.9],
      ),
      builder: (context) => LayrzIconSurface(
        labelText: widget.labelText,
        onIconSelected: (name) {
          _handleSelected(name);
          LayrzModalRoute.popIfCurrent(context);
        },
      ),
    );
  }

  Widget _buildInteractiveField({required BuildContext context, required VoidCallback? onTap}) {
    final tokens = context.tokens;
    // Resolved from `_controller.text` (mirrors `_handleSelected`'s own
    // self-display update) rather than `widget.value` directly, so the
    // closed field reflects a freshly committed pick immediately even when
    // the caller has not yet fed a new `LayrzIconInput.value` back in --
    // see the class doc's "Self-display" section.
    final currentName = _controller.text.isEmpty ? null : _controller.text;
    final selected = currentName == null ? null : findMdiRemapIconByName(currentName);

    final contentChild = SizedBox(
      width: double.infinity,
      child: selected != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected.data, size: tokens.typography.body.fontSize, color: tokens.colors.fg1),
                SizedBox(width: tokens.spacing.sp2),
                Flexible(
                  child: Text(
                    selected.name,
                    style: tokens.typography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Text(
              widget.hintText ?? '',
              style: tokens.typography.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
        icon: MdiIcons.shapeOutline,
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
