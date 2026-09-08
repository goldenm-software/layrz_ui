import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/src/avatar_source.dart';
import 'package:layrz_ui/src/inputs/src/text/text_input.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/pickers/src/image/image_input.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';
import 'package:layrz_ui/src/tabs/tabs.dart';

import '../shared/picker_dialog_header.dart';
import 'dynamic_avatar_emoji_tab.dart';
import 'dynamic_avatar_icon_tab.dart';

/// The maximum size, in bytes, an image dropped/picked on the Upload tab may
/// have — `1 MiB`, matching the work-unit brief's constraint for this
/// surface specifically (not [LayrzImageInput]'s own configurable default).
const int kDynamicAvatarMaxUploadBytes = 1024 * 1024;

/// The file extensions accepted by the Upload tab — matching the work-unit
/// brief's constraint for this surface specifically.
const List<String> kDynamicAvatarUploadExtensions = ['gif', 'png', 'jpg'];

/// Resolves which of the four [LayrzDynamicAvatarSurface] tabs an incoming
/// [LayrzAvatarSource] belongs to, so the surface can open on the tab that
/// matches the field's current value rather than always defaulting to the
/// first (URL) tab.
///
/// Returns `0` (URL) for a `null` source, since there is no "None" tab to
/// select — the None/clear affordance lives in the header area instead (see
/// [LayrzDynamicAvatarSurface]'s own class doc).
int dynamicAvatarInitialTabIndex(LayrzAvatarSource? source) {
  return switch (source) {
    null => 0,
    LayrzAvatarUrl() => 0,
    LayrzAvatarBase64() => 1,
    LayrzAvatarIcon() => 2,
    LayrzAvatarEmoji() => 3,
  };
}

/// The tabbed dialog/sheet body for [LayrzDynamicAvatarInput]: a single
/// [LayrzPickerDialogHeader] at the top, and a [LayrzTabView] with four tabs
/// (URL, Upload, Icon, Emoji) filling the rest of the surface.
///
/// **One dialog, one header — this is deliberate, not a simplification left
/// for later.** [LayrzDynamicAvatarInput] does not embed the standalone
/// `LayrzIconInput`/`LayrzEmojiInput`/`LayrzImageInput` *input* widgets
/// (which would each open their own nested dialog on tap) nor does it reuse
/// [LayrzIconSurface]/[LayrzEmojiSurface] wholesale (both carry their own
/// header + close ("X"), which would double up with this surface's own
/// single header). Instead, the Icon and Emoji tabs render their grids
/// **inline** via the shared [LayrzGlyphGrid] primitive — see
/// [LayrzDynamicAvatarIconTab]/[LayrzDynamicAvatarEmojiTab] in
/// `dynamic_avatar_tabs.dart` — and the Upload tab hosts
/// [LayrzImageInput] directly (it renders its own drop/tap tile inline and
/// does not itself open a modal, so nesting it here is safe).
///
/// **Commit-on-tap for Icon/Emoji** (mirrors every other single-glyph picker
/// in this module): tapping a cell fires the corresponding callback and the
/// caller ([LayrzDynamicAvatarInput]) closes the hosting surface immediately.
/// **Commit-on-submit for URL**: the inline [LayrzTextInput] commits on
/// submit or when its own apply affordance is tapped, not on every
/// keystroke. **Commit-on-emit for Upload**: [LayrzImageInput] commits the
/// moment it emits a non-null base64 string.
///
/// **None/clear affordance.** [onClear] is surfaced via the header's
/// [LayrzPickerDialogHeader.middleSlot] would collide with the close button
/// spacing at narrow widths, so instead it renders as a plain text button
/// row directly below the header, visible on every tab — firing it emits
/// `null` and closes the surface, mirroring [LayrzDynamicAvatarInput]'s own
/// nullable [ValueChanged] contract.
class LayrzDynamicAvatarSurface extends StatefulWidget {
  /// The title shown in this surface's own [LayrzPickerDialogHeader],
  /// normally [LayrzDynamicAvatarInput.labelText].
  final String? labelText;

  /// The currently selected avatar source, used only to resolve which tab
  /// opens initially (see [dynamicAvatarInitialTabIndex]) — this surface
  /// otherwise carries no staged draft state of its own.
  final LayrzAvatarSource? value;

  /// Called with a freshly picked [LayrzAvatarSource] when the user commits
  /// one via any of the four tabs. The caller is expected to close the
  /// hosting surface immediately after this fires.
  final ValueChanged<LayrzAvatarSource> onSourceSelected;

  /// Called when the user chooses the None/clear affordance, requesting the
  /// value be reset to `null`. The caller is expected to close the hosting
  /// surface immediately after this fires.
  final VoidCallback onClear;

  /// Creates a new [LayrzDynamicAvatarSurface].
  const LayrzDynamicAvatarSurface({
    super.key,
    this.labelText,
    this.value,
    required this.onSourceSelected,
    required this.onClear,
  });

  @override
  State<LayrzDynamicAvatarSurface> createState() => LayrzDynamicAvatarSurfaceState();
}

/// The [State] for [LayrzDynamicAvatarSurface] — public so a caller can
/// attach a [GlobalKey] to it, mirroring the sibling pickers' own
/// `GlobalKey<...State>` convention.
class LayrzDynamicAvatarSurfaceState extends State<LayrzDynamicAvatarSurface> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _urlController = TextEditingController(text: value is LayrzAvatarUrl ? value.url : '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Commits the URL field's current text as a [LayrzAvatarUrl], ignoring an
  /// empty/whitespace-only value (there is nothing meaningful to commit).
  void _commitUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    widget.onSourceSelected(LayrzAvatarUrl(trimmed));
  }

  /// Builds the URL tab: a single inline [LayrzTextInput] that commits on
  /// submit (pressing Enter/Done) — there is no separate "Apply" button
  /// needed on most platforms, but the field's `hintText` and the
  /// surrounding help text make the submit gesture discoverable.
  Widget _buildUrlTab(BuildContext context, LayrzUiL10n l10n) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.sp2),
      child: LayrzTextInput(
        controller: _urlController,
        hintText: l10n.dynamicAvatarUrlHint,
        onSubmit: _commitUrl,
      ),
    );
  }

  /// Builds the Upload tab: [LayrzImageInput] hosted inline, constrained to
  /// `gif`/`png`/`jpg` and `1 MiB` per the work-unit brief. Commits the
  /// moment a non-null base64 string is emitted — a clear (`null`) emission
  /// from the tile itself is not forwarded as a commit, since that tile's
  /// own clear badge only resets its own local preview, not this surface's
  /// selection.
  Widget _buildUploadTab(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spacing.sp2),
      child: Align(
        alignment: Alignment.topCenter,
        child: LayrzImageInput(
          allowedExtensions: kDynamicAvatarUploadExtensions,
          maxFileSizeBytes: kDynamicAvatarMaxUploadBytes,
          onChanged: (base64) {
            if (base64 == null || base64.isEmpty) return;
            widget.onSourceSelected(LayrzAvatarBase64(base64));
          },
        ),
      ),
    );
  }

  /// Builds the None/clear row shown beneath the header on every tab.
  Widget _buildClearRow(BuildContext context, LayrzUiL10n l10n) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: l10n.dynamicAvatarClear,
          onTap: widget.onClear,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: widget.onClear,
            behavior: HitTestBehavior.opaque,
            child: Text(
              l10n.dynamicAvatarClear,
              style: tokens.typography.label.copyWith(color: tokens.colors.danger),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final initialIndex = dynamicAvatarInitialTabIndex(widget.value);

    return Padding(
      padding: tokens.spacing.pd3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayrzPickerDialogHeader(
            labelText: widget.labelText,
            onClose: () => LayrzModalRoute.popIfCurrent(context),
          ),
          _buildClearRow(context, l10n),
          Expanded(
            child: LayrzTabView(
              initialIndex: initialIndex,
              tabs: [
                LayrzTab(
                  labelText: l10n.dynamicAvatarTypesURLUrl,
                  child: Expanded(child: _buildUrlTab(context, l10n)),
                ),
                LayrzTab(
                  labelText: l10n.dynamicAvatarTypesBASE64,
                  child: Expanded(child: _buildUploadTab(context)),
                ),
                LayrzTab(
                  labelText: l10n.dynamicAvatarTabIcon,
                  child: Expanded(
                    child: LayrzDynamicAvatarIconTab(
                      onIconSelected: (icon) => widget.onSourceSelected(LayrzAvatarIcon(icon)),
                    ),
                  ),
                ),
                LayrzTab(
                  labelText: l10n.dynamicAvatarTabEmoji,
                  child: Expanded(
                    child: LayrzDynamicAvatarEmojiTab(
                      onEmojiSelected: (emoji) => widget.onSourceSelected(LayrzAvatarEmoji(emoji.char)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
