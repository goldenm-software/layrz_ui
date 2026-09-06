import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';

import '../shared/picker_anchor.dart';
import 'emoji_surface.dart';

/// A Material-free single-emoji input field, sourced from the `emojis`
/// package (`package:emojis/emoji.dart`).
///
/// Composes [LayrzInputChrome] directly (D63, via `picker_anchor.dart`'s
/// helpers) and opens [LayrzEmojiSurface] in [LayrzEndDrawer] on desktop
/// (`>= 960px`) or [LayrzBottomSheet] below `isCompact` — the same adaptive
/// host every other `pickers/` widget uses.
///
/// **Value is `String?` — the raw emoji character** (e.g. `'😀'`), not a
/// domain wrapper type. This is [Emoji.char] from the `emojis` package,
/// which is what a caller actually wants to store/display/send — an emoji
/// character is already a stable, portable, serializable value on its own,
/// unlike the MDI icon picker's [MdiRemapIcon] (which needs a name because a
/// raw `IconData` codepoint is not stable across package versions).
///
/// **Commit-on-tap — no Save row.** Unlike the date/month/time/color/
/// multi-select pickers in this module (all staged-with-Save, per the
/// implementation plan), tapping an emoji in [LayrzEmojiSurface] both fires
/// [onChanged] and closes the hosting surface immediately, via
/// [LayrzModalRoute.popIfCurrent]. This is the maintainer's explicit ruling
/// (see the work-unit brief): picking IS the decision for a single emoji,
/// exactly like [LayrzSelectInput]'s own "commit-on-tap" contract, so no
/// [LayrzEndDrawer]/[LayrzBottomSheet] `actions` list is passed at all — the
/// resulting `null` `actions` also makes `canDismiss` infer `true` on both
/// hosts (barrier tap / Escape / back gesture all close with no value,
/// exactly like backing out without picking).
///
/// **Self-display.** [_LayrzEmojiInputState] keeps no separate internal
/// value cache the way [LayrzDateInput] does for its formatted summary text
/// — the closed field renders [value] directly (a bare emoji character needs
/// no formatting), so `didUpdateWidget` needs no reconciliation logic beyond
/// what [StatefulWidget] already gives for free via `widget.value`.
class LayrzEmojiInput extends StatefulWidget {
  /// The currently selected emoji character, or `null` when nothing has been
  /// picked yet.
  final String? value;

  /// Called with the newly picked emoji character on commit (a tap in
  /// [LayrzEmojiSurface]). Never called with `null` — there is no Clear
  /// affordance on this picker (mirroring [LayrzDateInput]'s identical "no
  /// Clear action" reasoning: picking is the only content-changing gesture,
  /// and backing out via Escape/barrier tap already covers "change nothing").
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

  /// Creates a new [LayrzEmojiInput].
  const LayrzEmojiInput({
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
  State<LayrzEmojiInput> createState() => _LayrzEmojiInputState();
}

class _LayrzEmojiInputState extends State<LayrzEmojiInput> {
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
  void didUpdateWidget(LayrzEmojiInput oldWidget) {
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

  /// Applies a freshly picked emoji: reports it via [onChanged] and updates
  /// [_controller]'s text so the closed field's own display refreshes even
  /// when the caller does not immediately feed a new [LayrzEmojiInput.value]
  /// back in (mirrors [LayrzDateInput]'s identical self-display contract).
  void _handleSelected(String char) {
    widget.onChanged?.call(char);
    setState(() => _controller.text = char);
  }

  /// Opens [LayrzEmojiSurface] in [LayrzBottomSheet] on a compact viewport.
  Future<void> _openMobileSurface() async {
    if (widget.disabled) return;

    await LayrzBottomSheet.show<void>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => LayrzEmojiSurface(
        onEmojiSelected: (char) {
          _handleSelected(char);
          LayrzModalRoute.popIfCurrent(context);
        },
      ),
      initialSize: 0.6,
      maxSize: 0.9,
      snapSizes: const [0.6, 0.9],
    );
  }

  /// Opens [LayrzEmojiSurface] in [LayrzEndDrawer] on a wide viewport.
  Future<void> _openDesktopDrawer() async {
    if (widget.disabled) return;

    await LayrzEndDrawer.show<void>(
      context,
      semanticLabel: widget.labelText == null ? widget.hintText : null,
      title: widget.labelText != null ? Text(widget.labelText!) : null,
      // No `actions` are passed (commit-on-tap, see class doc), so
      // `canDismiss` infers `true` from `LayrzEndDrawer.show`'s own default —
      // barrier tap, Escape, and the back gesture all close this drawer with
      // no value, exactly like backing out of the pick.
      builder: (context) => LayrzEmojiSurface(
        onEmojiSelected: (char) {
          _handleSelected(char);
          LayrzModalRoute.popIfCurrent(context);
        },
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
        icon: MdiIcons.emoticonOutline,
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
    if (context.isCompact) {
      return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openMobileSurface);
    }

    return _buildInteractiveField(context: context, onTap: widget.disabled ? null : _openDesktopDrawer);
  }
}
