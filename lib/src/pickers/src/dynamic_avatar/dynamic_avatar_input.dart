import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/dialogs/dialogs.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_footer_slot.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'dynamic_avatar_surface.dart';
import 'dynamic_avatar_tile.dart';

/// A Material-free, composed avatar picker input, backed by
/// [LayrzAvatarSource], in the layrz_ui design system.
///
/// [LayrzDynamicAvatarInput] presents its closed state as a **tappable
/// avatar tile** ([LayrzDynamicAvatarTile]), per the maintainer's explicit
/// direction that this field's closed state should show the full avatar
/// prominently rather than a compact picker-anchor row. The tile renders
/// the current selection via [LayrzAvatar] — an image (URL or base64), an
/// `MdiRemapIcon`, or a Unicode emoji — or, when [value] is `null`, a
/// centered add-avatar affordance icon. Tapping the tile (empty or
/// populated) opens [LayrzDynamicAvatarSurface] via
/// [LayrzResponsiveModal.show] (a dialog on wide viewports, a
/// [LayrzBottomSheet] below `isCompact`), which lets the user pick from
/// exactly four fixed modes — URL, Upload, Icon, and Emoji — or clear the
/// selection back to `null`. A populated tile additionally carries an
/// independently tappable circular clear (X) badge at its top-right corner
/// (see [LayrzDynamicAvatarTile]'s own clear-badge convention).
///
/// **The tabbed dialog surface is unchanged by this presentation** — only
/// the closed field's own build changed; [LayrzDynamicAvatarSurface] (its
/// four tabs, inline grids, and commit contract) is exactly the same
/// surface a picker-anchor-shaped closed field used to open.
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

  /// A text editing controller, retained for API compatibility with the
  /// previous picker-anchor-row presentation. If null, one is created and
  /// disposed by the widget.
  ///
  /// The tile presentation has no text field of any kind, so this
  /// controller is never attached to anything rendered by this widget — it
  /// is created/disposed following the same lifecycle as before purely so a
  /// caller passing its own [TextEditingController] does not need to change
  /// anything when this field's closed-state presentation changes.
  final TextEditingController? controller;

  /// The focus node the tile itself attaches to. If null, one is created
  /// and disposed by the widget.
  final FocusNode? focusNode;

  /// Retained for API compatibility with the previous picker-anchor-row
  /// presentation.
  ///
  /// The tile presentation has a single fixed size
  /// ([kDynamicAvatarTileSize]) in every state, so there is no dense/regular
  /// density distinction to make
  /// — this flag has no visible effect.
  final bool dense;

  /// Retained for API compatibility with the previous picker-anchor-row
  /// presentation, which rendered this as a help-affordance tooltip title
  /// via [LayrzInputChrome]. The tile presentation has no chrome to host
  /// such a tooltip, so this value is accepted but not rendered anywhere.
  final String? helpTitleText;

  /// Retained for API compatibility — see [helpTitleText]. Accepted but not
  /// rendered anywhere by the tile presentation.
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

  /// Builds the label row above the tile.
  Widget _buildLabel(LayrzTokens tokens) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
      child: ExcludeSemantics(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.labelText,
                style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
              ),
              if (widget.isRequired)
                TextSpan(
                  text: '*',
                  style: tokens.typography.label.copyWith(color: tokens.colors.danger),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) _buildLabel(tokens),
        LayrzDynamicAvatarTile(
          source: _displayedValue,
          onTap: widget.disabled ? null : _openPicker,
          onClear: widget.disabled ? null : _handleCleared,
          disabled: widget.disabled,
          hasErrors: widget.errors.isNotEmpty,
          focusNode: _focusNode,
          semanticLabel: widget.labelText ?? widget.hintText,
        ),
        LayrzInputFooterSlot(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
        ),
      ],
    );
  }
}
