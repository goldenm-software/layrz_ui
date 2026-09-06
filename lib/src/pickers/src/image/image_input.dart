import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/file_input/file_input.dart';
import 'package:layrz_ui/src/file_input/src/file_input_drop_target.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_footer_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'image_input_preview.dart';

/// The default image extensions [LayrzImageInput] accepts, without the
/// leading dot.
///
/// Passed to [LayrzFileInput]-equivalent machinery (the system picker's
/// `FileType.custom` and drag-and-drop filtering) when the caller does not
/// override [LayrzImageInput.allowedExtensions]. Restricted to the raster and
/// vector formats [LayrzImage] itself knows how to render (see
/// `lib/src/images/src/image.dart`) -- accepting a type the preview cannot
/// display would defeat the "preview" half of this widget's whole purpose.
const List<String> kDefaultImageInputExtensions = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'];

/// A Material-free, single-image avatar-style picker with a live preview, in
/// the layrz_ui design system.
///
/// [LayrzImageInput] presents a compact, tappable **rounded-square tile**
/// (avatar-picker ergonomics, per the user-testing feedback that led to this
/// redesign -- the previous [LayrzFileInput]-shaped wide drop-box read as an
/// unrelated file uploader, not an image field) restricted to exactly one
/// image (`maxFiles: 1` semantics) showing a [LayrzImageInputPreview] of the
/// current value. Tapping the tile at any time -- empty or populated --
/// opens the system picker; a populated tile additionally carries a small
/// camera-icon edit badge (a visual "this is editable" affordance, not an
/// independent tap target -- the whole tile is) and an independently
/// tappable circular clear (X) badge, matching the avatar-picker's own
/// clear-badge convention.
///
/// **Value in, value out is asymmetric by design (dossier §0 DESIGN-58,
/// §8b OQ-9):**
/// - [value] (what this widget *receives*) may be anything `LayrzImage`'s
///   `source` accepts -- an http(s) URL, a `data:` URI, or bare base64. It is
///   passed straight through to [LayrzImageInputPreview] unmodified.
/// - [onChanged] (what this widget *emits*) is **always base64**, carried as
///   a `data:<mime>;base64,<payload>` string via `LayrzFileInputResult.dataUri`
///   -- the same eager-encode machinery [LayrzFileInput] already computes at
///   construction time, reused here rather than re-implemented.
/// - **[onChanged] fires only on a user action** -- a successful pick, a
///   successful drop, or a clear. It is **never** called on mount, and a URL
///   (or any other non-base64 [value]) passed in and never touched by the
///   user is never eagerly re-encoded and re-emitted. Eagerly transcoding an
///   untouched URL would turn a form field into a per-render network fetch
///   plus a silent memory hold -- a caller that genuinely needs "base64 for
///   this URL regardless" is expected to reach for a separate, explicit
///   utility, not this field's normal change notification.
///
/// **Two calm failure states** (dossier §8c, liliana) are load-bearing for
/// this widget, not incidental:
/// - A [value] that fails to load or decode (a broken URL, a malformed
///   `data:` URI, unparseable base64) renders [LayrzImageInputPreview]'s
///   visible "couldn't load image" fallback -- never a blank tile, which reads
///   as "did my upload even register?" and invites a needless re-upload.
/// - A picked or dropped file exceeding [maxFileSizeBytes] is rejected
///   **before** the encode/wait, with a plain-language, persistent message
///   (`LayrzUiL10nImageInputMixin.imageInputTooLarge`) -- never a cryptic
///   failure surfacing only after the user has waited through an encode that
///   was always going to fail.
///
/// **Reuses, does not reimplement:** click-to-browse via `file_picker`,
/// drag-and-drop via [LayrzFileInputDropTarget] (`desktop_drop`), and base64
/// encoding via [LayrzFileInputResult.dataUri] are the exact same machinery
/// [LayrzFileInput] already has -- this widget is a thin tile+preview
/// specialization of that pattern, not a parallel implementation of it.
/// Drag-and-drop onto the tile composes cleanly alongside the tap affordance,
/// so it is kept, but tap-to-pick is the primary, avatar-picker-like
/// ergonomics this widget is built around.
class LayrzImageInput extends StatefulWidget {
  /// The current image value: an http(s) URL, a `data:` URI, or bare base64
  /// -- anything `LayrzImage.source` accepts.
  ///
  /// A caller-supplied change reconciles this field's internal display, the
  /// same self-display convention `LayrzSelectInput`/[LayrzFileInput]
  /// document -- picking or dropping a new image updates the tile's own
  /// preview immediately via [onChanged], whether or not the caller feeds
  /// this back on the next build. Passed straight through to
  /// [LayrzImageInputPreview] with no transformation -- a URL stays a URL
  /// until the user replaces it.
  final String? value;

  /// Called when the image changes as a direct result of user action -- a
  /// successful pick, a successful drop, or a clear.
  ///
  /// Always carries base64: a `data:<mimeType>;base64,<payload>` string (or
  /// `null` after a clear), via `LayrzFileInputResult.dataUri`. Never called
  /// on mount, and never called for an incoming [value] the user has not
  /// touched -- see the class doc's "value in, value out is asymmetric"
  /// section. Never called for a rejected file; see [rejectionMessage].
  final void Function(String?)? onChanged;

  /// The maximum size, in bytes, a picked or dropped image may have.
  ///
  /// When null, no size limit is enforced. A file exceeding this is rejected
  /// with [rejectionMessage] **before** it is read into a
  /// `LayrzFileInputResult` (and therefore before it is base64-encoded) --
  /// the plain-language, reject-before-the-wait behavior the dossier
  /// requires (§8c). The default oversized message names the limit via
  /// `LayrzUiL10nImageInputMixin.imageInputTooLarge`, formatted by
  /// [maxFileSizeLabel].
  final int? maxFileSizeBytes;

  /// A caller-formatted, human-readable label for [maxFileSizeBytes] (e.g.
  /// `'5 MB'`), used to fill in the default oversized-rejection message.
  ///
  /// Formatting bytes into a unit label is the caller's responsibility,
  /// mirroring `LayrzUiL10nImageInputMixin.imageInputTooLarge`'s own contract
  /// -- this widget never guesses a unit. Ignored when [maxFileSizeBytes] is
  /// null, or when [rejectionMessage] is supplied directly.
  final String? maxFileSizeLabel;

  /// File extensions this field accepts, without the leading dot (e.g.
  /// `['png', 'jpg']`).
  ///
  /// Defaults to [kDefaultImageInputExtensions] -- the raster/vector formats
  /// [LayrzImage] can render. Applied to both the system picker (via
  /// `file_picker`'s `FileType.custom`) and drag-and-drop, exactly like
  /// [LayrzFileInput.allowedExtensions].
  final List<String>? allowedExtensions;

  /// The message shown, persistently, when a picked or dropped file is
  /// rejected (wrong extension or exceeds [maxFileSizeBytes]).
  ///
  /// Defaults to a localized message built from
  /// `LayrzUiL10nImageInputMixin.imageInputTooLarge` (sized rejection) or a
  /// generic extension-mismatch message when null.
  final String? rejectionMessage;

  /// The label text displayed above the tile.
  final String? labelText;

  /// Text announced for the empty tile's semantics label and used as its
  /// accessible hint, inviting the user to tap or drop an image.
  ///
  /// Defaults to the localized `LayrzUiL10nImageInputMixin.imageInputHint`
  /// when null. Unlike the previous drop-box presentation, this text is not
  /// painted inside the tile itself -- the tile is compact, avatar-picker
  /// sized, and shows only an icon in its empty state -- but it is still
  /// used for the semantics label and, when [labelText] is absent, the
  /// visible label row above the tile falls back to showing this text so
  /// sighted users retain the same instruction.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Whether the field is disabled.
  ///
  /// A disabled tile does not open the picker on tap, does not accept drops,
  /// and its clear affordance is not focusable.
  final bool disabled;

  /// The list of error messages to display below the tile.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// The focus node for the tile itself.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The width and height of the square tile, in logical pixels.
  ///
  /// Defaults to 100 -- matching the avatar-picker convention (`references`:
  /// `themed-avatar-picker` skill) this redesign follows, rather than the
  /// previous wide drop-box's 200px height. The tile always occupies this
  /// footprint regardless of state (empty, populated, error), per D15.
  final double size;

  /// Creates a new [LayrzImageInput] with the given properties.
  const LayrzImageInput({
    super.key,
    this.value,
    this.onChanged,
    this.maxFileSizeBytes,
    this.maxFileSizeLabel,
    this.allowedExtensions,
    this.rejectionMessage,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.focusNode,
    this.size = 100,
  });

  @override
  State<LayrzImageInput> createState() => _LayrzImageInputState();
}

class _LayrzImageInputState extends State<LayrzImageInput> {
  late FocusNode _focusNode;

  /// The value currently displayed, independent of [LayrzImageInput.value]
  /// once a pick/drop/clear has been made locally -- mirrors
  /// `LayrzSelectInput`/[LayrzFileInput]'s `_displayedValue` self-display
  /// convention (see the class doc).
  String? _displayedValue;

  /// Whether an OS/browser drag-and-drop operation is currently over the tile.
  bool _isDragging = false;

  /// Whether the pointer is hovering the tile (desktop/mouse only).
  bool _isHovered = false;

  /// The persistent rejection message currently shown, or null when nothing
  /// has been rejected since the last successful pick/drop/clear.
  String? _rejection;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _displayedValue = widget.value;
  }

  @override
  void didUpdateWidget(LayrzImageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.value != oldWidget.value) {
      _displayedValue = widget.value;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Whether [extension] (without a leading dot) is accepted by
  /// [LayrzImageInput.allowedExtensions] (or [kDefaultImageInputExtensions]
  /// when the caller supplies none).
  bool _isExtensionAllowed(String? extension) {
    final allowed = widget.allowedExtensions ?? kDefaultImageInputExtensions;
    if (allowed.isEmpty) return true;
    if (extension == null) return false;
    return allowed.any((e) => e.toLowerCase() == extension.toLowerCase());
  }

  /// The effective allowed-extensions list, defaulting to
  /// [kDefaultImageInputExtensions].
  List<String> get _effectiveAllowedExtensions => widget.allowedExtensions ?? kDefaultImageInputExtensions;

  /// The default localized rejection message for an oversized file, built
  /// from [LayrzUiL10nImageInputMixin.imageInputTooLarge].
  String _oversizedMessage(BuildContext context) {
    final label = widget.maxFileSizeLabel ?? '${widget.maxFileSizeBytes} bytes';
    return context.l10n.imageInputTooLarge(label);
  }

  /// The default localized rejection message for a disallowed extension.
  String _extensionMessage(BuildContext context) {
    return 'File rejected: allowed types are ${_effectiveAllowedExtensions.join(', ')}.';
  }

  /// Validates [incoming] as a single image -- extension first, then size
  /// **before** any base64 encoding happens (the reject-before-the-wait
  /// requirement, dossier §8c) -- and, if accepted, commits it as the new
  /// value and fires [LayrzImageInput.onChanged] with its `dataUri`.
  ///
  /// A mixed concern deliberately kept in this order: extension and size are
  /// checked against the raw picked/dropped bytes before a
  /// [LayrzFileInputResult] (which base64-encodes eagerly at construction) is
  /// even built, so an oversized file never pays the encode cost.
  void _commitIncoming(String name, String? extension, String mimeType, Uint8List bytes) {
    if (!_isExtensionAllowed(extension)) {
      setState(() => _rejection = widget.rejectionMessage ?? _extensionMessage(context));
      return;
    }

    final maxSize = widget.maxFileSizeBytes;
    if (maxSize != null && bytes.length > maxSize) {
      setState(() => _rejection = widget.rejectionMessage ?? _oversizedMessage(context));
      return;
    }

    final result = LayrzFileInputResult(name: name, mimeType: mimeType, bytes: bytes);
    setState(() {
      _rejection = null;
      _displayedValue = result.dataUri;
    });
    widget.onChanged?.call(result.dataUri);
  }

  /// Opens the system file picker via `file_picker`, validating and
  /// committing the single selected image via [_commitIncoming].
  Future<void> _openPicker() async {
    if (widget.disabled) return;

    final allowed = _effectiveAllowedExtensions;
    final result = await FilePicker.platform.pickFiles(
      type: allowed.isNotEmpty ? FileType.custom : FileType.any,
      allowedExtensions: allowed.isNotEmpty ? allowed : null,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.first;
    final bytes = platformFile.bytes;
    if (bytes == null) return;

    _commitIncoming(
      platformFile.name,
      platformFile.extension,
      mimeTypeForExtension(platformFile.extension),
      bytes,
    );
  }

  /// Extracts the lowercase extension (without the dot) from [name], or null
  /// when [name] has none.
  String? _extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return null;
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// Handles a drag-and-drop of one or more files onto the tile, keeping only
  /// the first one -- this field is single-image, so a multi-file drop
  /// commits just its first entry rather than rejecting the whole drop.
  void _handleFilesDropped(List<LayrzFileInputResult> files) {
    if (files.isEmpty) return;
    final first = files.first;
    _commitIncoming(first.name, _extensionOf(first.name), first.mimeType, first.bytes);
  }

  /// Clears the current image, firing [LayrzImageInput.onChanged] with null.
  void _clear() {
    setState(() {
      _displayedValue = null;
      _rejection = null;
    });
    widget.onChanged?.call(null);
  }

  /// Resolves the tile's current [LayrzFileInputState], in state precedence
  /// order: dragging > hover > populated > empty -- identical to
  /// [LayrzFileInput]'s own resolution.
  LayrzFileInputState _resolveState() {
    if (_isDragging) return LayrzFileInputState.dragging;
    if (_isHovered || _focusNode.hasFocus) return LayrzFileInputState.hover;
    if (_displayedValue != null && _displayedValue!.isNotEmpty) return LayrzFileInputState.populated;
    return LayrzFileInputState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final hasErrors = widget.errors.isNotEmpty || _rejection != null;

    final spec = LayrzFileInputStyleSpec.resolve(
      state: _resolveState(),
      tokens: tokens,
      hasErrors: hasErrors,
      disabled: widget.disabled,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) _buildLabel(tokens),
        _buildTile(context, tokens, l10n, spec),
        if (_rejection != null)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sp2),
            child: Text(
              _rejection!,
              style: tokens.typography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: tokens.colors.danger,
              ),
            ),
          ),
        LayrzInputFooterSlot(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
        ),
      ],
    );
  }

  /// Builds the label row above the tile, mirroring [LayrzFileInput]'s label
  /// composition exactly.
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

  /// Builds the tappable rounded-square tile: [LayrzFileInputDropTarget]
  /// wrapping a focusable, fixed-size square that shows either an empty-state
  /// icon or the populated preview, with overlay badges for the edit and
  /// clear affordances.
  ///
  /// The tile is tappable in **both** states -- unlike the previous drop-box
  /// presentation (whose populated state hosted separate "Replace"/"Clear"
  /// text rows below the box), an avatar-picker-style tile always opens the
  /// picker on tap, whether empty or populated; only the clear badge is a
  /// second, independently focusable tap target layered on top.
  Widget _buildTile(BuildContext context, LayrzTokens tokens, LayrzUiL10n l10n, LayrzFileInputStyleSpec spec) {
    final isEmpty = _displayedValue == null || _displayedValue!.isEmpty;
    final announcedLabel = widget.labelText ?? widget.hintText ?? l10n.imageInputHint;

    // See `LayrzFileInput._buildBox`'s identical comment: the rounded clip is
    // kept as its own non-decorated `ClipRRect` layer, separate from the
    // `AnimatedContainer` that paints the fill/border, to avoid a measured
    // Impeller artifact where a clipped, animated `BoxDecoration` fill paints
    // solid black mid-transition on Linux/Vulkan.
    final content = ClipRRect(
      borderRadius: tokens.radius.br3,
      child: AnimatedContainer(
        duration: tokens.motion.dHover,
        curve: tokens.motion.easing,
        width: widget.size,
        height: widget.size,
        // Belt-and-suspenders alongside the outer `ClipRRect`: without an
        // explicit `clipBehavior`, `Container`/`AnimatedContainer` does NOT
        // clip its child by default, so the populated preview's `Positioned.fill`
        // could still paint past the decoration's rounded corners during the
        // size-change animation between empty and populated states.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: tokens.radius.br3,
          border: Border.all(color: spec.borderColor, width: spec.borderWidth),
        ),
        child: isEmpty ? _buildEmptyContent(tokens, spec) : _buildPopulatedContent(tokens, l10n, spec),
      ),
    );

    final focusable = FocusableActionDetector(
      focusNode: _focusNode,
      enabled: !widget.disabled,
      onShowHoverHighlight: (show) => setState(() => _isHovered = show),
      onShowFocusHighlight: (_) => setState(() {}),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _openPicker();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.disabled ? null : _openPicker,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );

    final tileWithBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: announcedLabel,
          button: true,
          enabled: !widget.disabled,
          hint: isEmpty ? 'Opens the image picker' : 'Opens the image picker to replace the current image',
          child: focusable,
        ),
        if (!isEmpty) _buildClearBadge(tokens, l10n),
      ],
    );

    return LayrzFileInputDropTarget(
      enabled: !widget.disabled,
      onDragEntered: () => setState(() => _isDragging = true),
      onDragExited: () => setState(() => _isDragging = false),
      onFilesDropped: (files) {
        setState(() => _isDragging = false);
        _handleFilesDropped(files);
      },
      child: tileWithBadge,
    );
  }

  /// Builds the empty-state content: a centered image icon, sized to the tile.
  Widget _buildEmptyContent(LayrzTokens tokens, LayrzFileInputStyleSpec spec) {
    return Center(
      child: Icon(MdiIcons.imagePlusOutline, size: widget.size * 0.36, color: spec.contentColor),
    );
  }

  /// Builds the populated-state content: the live [LayrzImageInputPreview]
  /// filling the tile, plus a small camera-icon edit badge overlaid in the
  /// bottom-right corner -- a visual "this is editable" affordance only; it
  /// carries no semantics or gesture of its own, since the whole tile is
  /// already the tap target that opens the picker.
  ///
  /// [spec] is threaded through so the preview's own clip radius and inset
  /// can match the tile's outer border **exactly** -- [tokens.radius.br3] and
  /// [spec.borderWidth], the same values the tile's own `ClipRRect`/`Border`
  /// use in [_buildTile]. Passing anything else here is what previously
  /// produced the "broken border" bug: the preview clipped to a different,
  /// hardcoded radius than the tile's border curve.
  Widget _buildPopulatedContent(LayrzTokens tokens, LayrzUiL10n l10n, LayrzFileInputStyleSpec spec) {
    return Stack(
      children: [
        // Excluded from semantics: the enclosing tile's own `Semantics` node
        // (built in `_buildTile`) already carries the announced label/hint
        // for "open picker to replace" -- without this, `LayrzImage`'s own
        // `isImage` flag merges upward into that same node, muddying its
        // announced role.
        Positioned.fill(
          child: ExcludeSemantics(
            child: LayrzImageInputPreview(
              source: _displayedValue!,
              size: widget.size,
              borderRadius: tokens.radius.br3,
              borderWidth: spec.borderWidth,
            ),
          ),
        ),
        Positioned(
          right: tokens.spacing.sp1,
          bottom: tokens.spacing.sp1,
          child: ExcludeSemantics(
            child: Container(
              padding: EdgeInsets.all(tokens.spacing.sp1),
              decoration: BoxDecoration(
                color: tokens.colors.sf1.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: tokens.shadow.compact1,
              ),
              child: Icon(MdiIcons.cameraOutline, size: widget.size * 0.16, color: tokens.colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the independently tappable circular clear (X) badge overlaid at
  /// the tile's top-right corner, matching the avatar-picker's own
  /// clear-badge convention.
  ///
  /// Kept as a sibling of the tile in the enclosing [Stack] (rather than
  /// nested inside the tile's own tap target) so it carries its own focus
  /// stop and gesture, independent of the tile's "open picker" tap.
  Widget _buildClearBadge(LayrzTokens tokens, LayrzUiL10n l10n) {
    return Positioned(
      right: -tokens.spacing.sp1,
      top: -tokens.spacing.sp1,
      child: Semantics(
        button: true,
        enabled: !widget.disabled,
        label: l10n.imageInputClear,
        excludeSemantics: true,
        child: FocusableActionDetector(
          enabled: !widget.disabled,
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _clear();
                return null;
              },
            ),
          },
          child: MouseRegion(
            cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.disabled ? null : _clear,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(tokens.spacing.sp1),
                decoration: BoxDecoration(
                  color: widget.disabled ? tokens.colors.fg4 : tokens.colors.danger,
                  shape: BoxShape.circle,
                  boxShadow: tokens.shadow.compact1,
                ),
                child: Icon(MdiIcons.close, size: widget.size * 0.14, color: tokens.colors.sf1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
