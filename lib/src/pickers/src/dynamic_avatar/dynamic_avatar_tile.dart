import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/file_input/file_input.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The fixed width/height, in logical pixels, of [LayrzDynamicAvatarTile] --
/// matching [LayrzImageInput]'s own default `size` exactly, per the
/// maintainer's explicit direction to mirror that widget's tile rather than
/// introduce a second, independently configurable tile size for this field.
const double kDynamicAvatarTileSize = 100;

/// The tappable avatar tile presented by `LayrzDynamicAvatarInput`'s closed
/// field, in the layrz_ui design system.
///
/// Mirrors `LayrzImageInput`'s tile presentation (see that widget's class
/// doc) almost exactly: a fixed [kDynamicAvatarTileSize]-square,
/// rounded-corner tile that is tappable in both its empty and populated
/// states, styled via [LayrzFileInputStyleSpec] (the exact same style-spec
/// type `LayrzImageInput` resolves its own tile from -- reused rather than
/// re-derived, since both widgets are "a tappable square that opens a
/// picker surface" with an identical state set: empty/hover/dragging is
/// irrelevant here since this tile has no drag-and-drop, so only
/// empty/hover/populated ever apply).
///
/// Unlike [LayrzImageInput], this tile never renders a preview widget of its
/// own -- the current [LayrzAvatarSource] (URL, base64, icon, or emoji) is
/// rendered by [LayrzAvatar], which already knows how to present every
/// variant plus the empty/initials fallback. Passing `nameText: null` (the
/// tile never has a name to fall back to) means a `null` [source] would
/// render `LayrzAvatar`'s own "NA" initials tile -- **not what this field
/// wants for "no avatar yet"** -- so the empty state is special-cased here
/// (mirroring [LayrzImageInput]'s own empty-content branch) into a centered
/// add-avatar affordance icon instead of ever constructing a [LayrzAvatar]
/// with a null source.
class LayrzDynamicAvatarTile extends StatefulWidget {
  /// The avatar source currently displayed, or `null` for "no avatar".
  final LayrzAvatarSource? source;

  /// Called when the tile (empty or populated) is tapped or activated via
  /// the keyboard, to open the picker surface. `null` when [disabled] is
  /// true, so neither the [Semantics] node nor the gesture reports a tap
  /// handler.
  final VoidCallback? onTap;

  /// Called when the clear (X) badge is tapped or activated, clearing the
  /// current selection. Only rendered when [source] is non-null; `null`
  /// when [disabled] is true.
  final VoidCallback? onClear;

  /// Whether the field is disabled. A disabled tile does not open the
  /// picker on tap and its clear badge is not focusable.
  final bool disabled;

  /// Whether the field currently reports validation errors -- painted as a
  /// danger-colored border on the tile, per [LayrzFileInputStyleSpec].
  final bool hasErrors;

  /// The focus node the tile itself attaches to.
  final FocusNode focusNode;

  /// The label announced by the tile's own [Semantics] node -- normally the
  /// field's `labelText` or `hintText`.
  final String? semanticLabel;

  /// Creates a new [LayrzDynamicAvatarTile].
  const LayrzDynamicAvatarTile({
    super.key,
    required this.source,
    required this.onTap,
    required this.onClear,
    required this.disabled,
    required this.hasErrors,
    required this.focusNode,
    required this.semanticLabel,
  });

  @override
  State<LayrzDynamicAvatarTile> createState() => _LayrzDynamicAvatarTileState();
}

class _LayrzDynamicAvatarTileState extends State<LayrzDynamicAvatarTile> {
  /// Whether the pointer is hovering the tile (desktop/mouse only).
  bool _isHovered = false;

  /// Resolves the tile's current [LayrzFileInputState] -- this tile never
  /// enters [LayrzFileInputState.dragging] (it has no drop-target
  /// machinery, only [LayrzImageInput] does), so only hover/populated/empty
  /// ever apply.
  LayrzFileInputState _resolveState() {
    if (_isHovered || widget.focusNode.hasFocus) return LayrzFileInputState.hover;
    if (widget.source != null) return LayrzFileInputState.populated;
    return LayrzFileInputState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isEmpty = widget.source == null;

    final spec = LayrzFileInputStyleSpec.resolve(
      state: _resolveState(),
      tokens: tokens,
      hasErrors: widget.hasErrors,
      disabled: widget.disabled,
    );

    // See `LayrzImageInput._buildTile`'s identical comment: the rounded clip
    // is kept as its own non-decorated `ClipRRect` layer, separate from the
    // `AnimatedContainer` that paints the fill/border, to avoid a measured
    // Impeller artifact where a clipped, animated `BoxDecoration` fill
    // paints solid black mid-transition on Linux/Vulkan.
    final content = ClipRRect(
      borderRadius: tokens.radius.br3,
      child: AnimatedContainer(
        duration: tokens.motion.dHover,
        curve: tokens.motion.easing,
        width: kDynamicAvatarTileSize,
        height: kDynamicAvatarTileSize,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: tokens.radius.br3,
          border: Border.all(color: spec.borderColor, width: spec.borderWidth),
        ),
        child: isEmpty ? _buildEmptyContent(spec) : _buildPopulatedContent(),
      ),
    );

    final focusable = FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: !widget.disabled,
      onShowHoverHighlight: (show) => setState(() => _isHovered = show),
      onShowFocusHighlight: (_) => setState(() {}),
      actions: <Type, Action<Intent>>{
        if (widget.onTap != null)
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap!.call();
              return null;
            },
          ),
      },
      child: MouseRegion(
        cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: widget.semanticLabel,
          button: true,
          enabled: !widget.disabled,
          hint: isEmpty ? 'Opens the avatar picker' : 'Opens the avatar picker to replace the current avatar',
          child: focusable,
        ),
        if (!isEmpty) _buildClearBadge(tokens, l10n),
      ],
    );
  }

  /// Builds the empty-state content: a centered add-avatar icon, sized to
  /// the tile -- mirroring [LayrzImageInput]'s own `_buildEmptyContent`.
  Widget _buildEmptyContent(LayrzFileInputStyleSpec spec) {
    return Center(
      child: Icon(
        MdiIcons.accountPlusOutline,
        size: kDynamicAvatarTileSize * 0.36,
        color: spec.contentColor,
      ),
    );
  }

  /// Builds the populated-state content: [LayrzAvatar] filling the tile.
  ///
  /// `borderRadius: 0` and `elevation: 0` -- [LayrzAvatar] normally paints
  /// its own rounded corners and drop shadow, but here it fills the tile
  /// edge-to-edge (the tile's own `ClipRRect`/border, built in [build],
  /// already supplies both), so [LayrzAvatar]'s own chrome is suppressed to
  /// avoid a double-rounded, double-shadowed nested box.
  ///
  /// Excluded from semantics: the enclosing tile's own [Semantics] node
  /// (built in [build]) already carries the announced label/hint for "open
  /// picker to replace" -- without this, [LayrzAvatar]'s own semantics
  /// (when it carries a label) would merge upward into that same node.
  Widget _buildPopulatedContent() {
    return ExcludeSemantics(
      child: LayrzAvatar(
        source: widget.source,
        size: kDynamicAvatarTileSize,
        borderRadius: 0,
        elevation: 0,
      ),
    );
  }

  /// Builds the independently tappable circular clear (X) badge overlaid at
  /// the tile's top-right corner, matching [LayrzImageInput]'s own
  /// `_buildClearBadge` exactly.
  Widget _buildClearBadge(LayrzTokens tokens, LayrzUiL10n l10n) {
    return Positioned(
      right: -tokens.spacing.sp1,
      top: -tokens.spacing.sp1,
      child: Semantics(
        button: true,
        enabled: !widget.disabled,
        label: l10n.dynamicAvatarClear,
        excludeSemantics: true,
        child: FocusableActionDetector(
          enabled: !widget.disabled,
          actions: <Type, Action<Intent>>{
            if (widget.onClear != null)
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onClear!.call();
                  return null;
                },
              ),
          },
          child: MouseRegion(
            cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onClear,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(tokens.spacing.sp1),
                decoration: BoxDecoration(
                  color: widget.disabled ? tokens.colors.fg4 : tokens.colors.danger,
                  shape: BoxShape.circle,
                  boxShadow: tokens.shadow.compact1,
                ),
                child: Icon(MdiIcons.close, size: kDynamicAvatarTileSize * 0.14, color: tokens.colors.sf1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
