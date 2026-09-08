import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import 'dynamic_avatar_surface.dart';

/// A Material-free, composed avatar picker input, backed by
/// [LayrzAvatarSource], in the layrz_ui design system.
///
/// [LayrzDynamicAvatarInput] presents a picker anchor whose closed-state
/// preview renders the current selection via [LayrzAvatar] — an image (URL
/// or base64), an `MdiRemapIcon`, a Unicode emoji, or (when [value] is
/// `null`) the field's own [hintText]. Tapping the anchor opens
/// [LayrzDynamicAvatarSurface] via [LayrzResponsiveModal.show] (a dialog on
/// wide viewports, a [LayrzBottomSheet] below `isCompact`), which lets the
/// user pick from exactly four fixed modes — URL, Upload, Icon, and Emoji —
/// or clear the selection back to `null`.
///
/// **The four modes are fixed — there is no `enabledTypes` parameter.**
/// Unlike a caller-configurable subset, every [LayrzDynamicAvatarSurface]
/// always offers all four tabs; a narrower picker built from a subset of
/// [LayrzAvatarSource] variants is a different widget, not a configuration
/// of this one.
///
/// **Value is `LayrzAvatarSource?`.** `null` means "no avatar" — there is no
/// separate "none" variant in the sealed [LayrzAvatarSource] hierarchy,
/// mirroring that hierarchy's own doc ("a `null` source already expresses
/// that state"). [onChanged] is therefore a nullable-argument
/// `ValueChanged` (not one whose type argument forbids `null`) so the
/// surface's None/clear affordance can emit `null` back to the caller.
///
/// **Commit-on-tap for Icon/Emoji, commit-on-submit for URL,
/// commit-on-emit for Upload** — see [LayrzDynamicAvatarSurface]'s own class
/// doc for the full per-tab contract. Every commit path closes the hosting
/// surface immediately via [LayrzModalRoute.popIfCurrent], mirroring
/// [LayrzIconInput]/[LayrzEmojiInput]'s identical "picking IS the decision"
/// ruling — there is no separate Save/Cancel footer.
///
/// **Self-display.** [_LayrzDynamicAvatarInputState] keeps its own
/// `_displayedValue` synchronized with [value] (via `initState`/
/// `didUpdateWidget`, and via `setState` immediately on a fresh commit) so
/// the closed field reflects a freshly committed pick immediately even when
/// the caller does not immediately feed a new [value] back in — the same
/// self-display convention every other picker in this module documents.
class LayrzDynamicAvatarInput extends StatefulWidget {
  /// The currently selected avatar source, or `null` for "no avatar".
  final LayrzAvatarSource? value;

  /// Called when the selection changes as a direct result of user action —
  /// a commit on any of the four tabs, or the None/clear affordance.
  ///
  /// Carries `null` only from the None/clear affordance; every tab commit
  /// carries a non-null [LayrzAvatarSource]. Never called on mount, and
  /// never called for an incoming [value] the user has not touched.
  final ValueChanged<LayrzAvatarSource?>? onChanged;

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
  ///
  /// This field is display-only (the anchor never accepts direct text
  /// entry) — the controller exists only so [LayrzInputFooterSlot] and
  /// [LayrzInputChrome]'s own machinery, which key off a controller's
  /// `hasListeners`/`text` state, behave consistently with every sibling
  /// picker anchor in this module.
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

  /// Creates a new [LayrzDynamicAvatarInput].
  const LayrzDynamicAvatarInput({
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
  State<LayrzDynamicAvatarInput> createState() => _LayrzDynamicAvatarInputState();
}

class _LayrzDynamicAvatarInputState extends State<LayrzDynamicAvatarInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// The value currently displayed, independent of [LayrzDynamicAvatarInput.value]
  /// once a commit/clear has been made locally — mirrors every sibling
  /// picker's own self-display convention (see the class doc).
  LayrzAvatarSource? _displayedValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _displayedValue = widget.value;
  }

  @override
  void didUpdateWidget(LayrzDynamicAvatarInput oldWidget) {
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
      _displayedValue = widget.value;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// Applies a freshly committed source: reports it via [onChanged] and
  /// updates [_displayedValue] so the closed field's own preview refreshes
  /// immediately, mirroring [LayrzIconInput]'s identical `_handleSelected`.
  void _handleSelected(LayrzAvatarSource source) {
    widget.onChanged?.call(source);
    setState(() => _displayedValue = source);
  }

  /// Applies the None/clear affordance: reports `null` via [onChanged] and
  /// clears [_displayedValue].
  void _handleCleared() {
    widget.onChanged?.call(null);
    setState(() => _displayedValue = null);
  }

  /// Opens [LayrzDynamicAvatarSurface] via [LayrzResponsiveModal.show].
  ///
  /// `scrollable: false` on the sheet branch — [LayrzDynamicAvatarSurface]
  /// scrolls its own tab content internally (each tab's own
  /// non-shrink-wrapped [LayrzGlyphGrid] or field filling an `Expanded`
  /// section of the surface's `Column`), so it must not additionally be
  /// wrapped in a default `SingleChildScrollView` — mirrors
  /// [LayrzIconInput]/[LayrzEmojiInput]'s identical reasoning.
  Future<void> _openPicker() async {
    if (widget.disabled) return;

    await LayrzResponsiveModal.show<void>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      showCloseIcon: false,
      sheet: const LayrzBottomSheetConfig(
        scrollable: false,
        initialSize: 0.75,
        maxSize: 0.95,
        snapSizes: [0.75, 0.95],
      ),
      builder: (context) => LayrzDynamicAvatarSurface(
        labelText: widget.labelText,
        value: _displayedValue,
        onSourceSelected: (source) {
          _handleSelected(source);
          LayrzModalRoute.popIfCurrent(context);
        },
        onClear: () {
          _handleCleared();
          LayrzModalRoute.popIfCurrent(context);
        },
      ),
    );
  }

  Widget _buildInteractiveField({required BuildContext context, required VoidCallback? onTap}) {
    final tokens = context.tokens;
    final current = _displayedValue;

    final contentChild = SizedBox(
      width: double.infinity,
      child: current != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayrzAvatar(source: current, size: tokens.typography.body.fontSize! * 1.8),
                SizedBox(width: tokens.spacing.sp2),
                Flexible(
                  child: Text(
                    widget.hintText ?? '',
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
        icon: MdiIcons.accountCircleOutline,
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
