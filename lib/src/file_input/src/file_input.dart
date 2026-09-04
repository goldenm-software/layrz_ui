import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_footer_slot.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'file_input_drop_target.dart';
import 'file_input_preview.dart';
import 'file_input_result.dart';
import 'file_input_style_spec.dart';

/// A Material-free, drag-and-drop file drop-zone in the layrz_ui design system.
///
/// [LayrzFileInput] is deliberately **not** built on `LayrzInputChrome` --
/// unlike every text-shaped field in `lib/src/inputs/`, it is a box-shaped
/// drop target, not a text field, so it has no chrome, no cursor, and no
/// text-editing concerns to share with them. See `input_chrome.dart`'s own
/// freeze notice for why a field with genuinely different needs is built
/// standalone rather than bent to fit the shared chrome.
///
/// **Click-to-browse is the primary affordance** (Kenny + liliana: drag-and-drop
/// alone is not discoverable). The entire box is a single tap/keyboard target
/// that opens the system file picker via `file_picker`. Dragging a file over
/// the box and dropping it is an additive bonus path, wired via
/// [LayrzFileInputDropTarget] (`desktop_drop`); both paths funnel into the same
/// [onChanged] callback with the same [LayrzFileInputResult] shape.
///
/// **Four visually distinct states** (see [LayrzFileInputStyleSpec]):
/// - **Empty**: no files picked yet, pointer not hovering.
/// - **Hover**: pointer over the box (desktop/mouse), or the box has keyboard focus.
/// - **Dragging**: an OS/browser drag-and-drop operation is currently over the box.
/// - **Populated**: at least one file has been accepted.
///
/// Per decision D15, transitions between these states vary only colour, border
/// colour, and content colour -- never the box's size or padding (`dragging`'s
/// thicker border, resolved by [LayrzFileInputStyleSpec], is the one deliberate
/// exception documented on that spec).
///
/// **Multi-file by default.** [value] and [onChanged] both carry
/// `List<LayrzFileInputResult>`. Set [maxFiles] to `1` for a single-file field --
/// picking or dropping a new file then replaces the list wholesale rather than
/// appending, which is what the populated state's replace affordance uses.
///
/// **Accept filtering.** [allowedExtensions] restricts both the system picker
/// (via `file_picker`'s `FileType.custom`) and drag-and-drop: a dropped file
/// whose extension is not in the list is rejected rather than added.
///
/// **Rejections are persistent, not a toast.** A rejected or oversized file
/// (extension not allowed, or exceeding [maxFileSizeBytes]) surfaces
/// [rejectionMessage] as on-screen text below the box that stays until the
/// next successful pick/drop or until [onClearRejection]-equivalent state is
/// cleared internally -- it does not auto-dismiss on a timer. This mirrors the
/// footer's error-block treatment ([LayrzInputFooterSlot]) rather than a
/// [LayrzSnackbar], per liliana's explicit requirement that a rejection must
/// stay readable, not flash past.
///
/// **Clear/replace is keyboard-reachable.** In the populated state, each file
/// preview carries its own focusable clear button (Tab-reachable, Enter/Space
/// activates it, per the same [ActivateIntent] pattern `LayrzCard` uses for its
/// interactive form) alongside a "replace/add more" affordance that re-opens
/// the picker.
///
/// **Label and error text render outside the box**, exactly like
/// `LayrzSelectInput`/`LayrzComboboxInput`/`LayrzDurationInput`: [labelText] is
/// hoisted above the box and [errors] below it in an outer [Column], never
/// inside a chrome the box does not have.
class LayrzFileInput extends StatefulWidget {
  /// The currently selected files.
  ///
  /// A caller-supplied change reconciles the field's internal display, the same
  /// self-display convention `LayrzSelectInput` documents -- picking or dropping
  /// a file updates the box's own display immediately via [onChanged], whether
  /// or not the caller feeds this back on the next build.
  final List<LayrzFileInputResult> value;

  /// Called when the set of selected files changes -- after a successful pick,
  /// a successful drop, a clear, or a replace.
  ///
  /// Never called for a rejected file; see [rejectionMessage].
  final void Function(List<LayrzFileInputResult>)? onChanged;

  /// The maximum number of files this field accepts.
  ///
  /// Defaults to `null` (unlimited). When `1`, picking or dropping a new file
  /// replaces [value] wholesale instead of appending to it. When set to any
  /// other finite number, a pick/drop that would exceed it is truncated to the
  /// remaining capacity -- files beyond the limit are silently dropped from
  /// that batch rather than rejected with [rejectionMessage], since exceeding
  /// [maxFiles] is a quantity constraint the caller can also enforce via
  /// [errors], not a per-file validation failure.
  final int? maxFiles;

  /// File extensions this field accepts, without the leading dot (e.g. `['png', 'jpg']`).
  ///
  /// When null or empty, any file type is accepted. Applied to both the system
  /// picker (via `file_picker`'s `FileType.custom`) and drag-and-drop.
  final List<String>? allowedExtensions;

  /// The maximum size, in bytes, a single file may have.
  ///
  /// When null, no size limit is enforced. A file exceeding this is rejected
  /// with [rejectionMessage], same as an extension mismatch.
  final int? maxFileSizeBytes;

  /// The message shown, persistently, when a file is rejected (wrong extension
  /// or exceeds [maxFileSizeBytes]).
  ///
  /// Defaults to a generic English message when null. This is not localized
  /// through `LayrzUiL10n` -- pass an explicit string for a localized caller.
  final String? rejectionMessage;

  /// The label text displayed above the drop-zone box.
  final String? labelText;

  /// Text shown inside the empty-state box, describing what to do.
  ///
  /// Defaults to a generic English "Click to browse or drag files here" when null.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Whether the field is disabled.
  ///
  /// A disabled box does not open the picker on tap, does not accept drops,
  /// and its clear/replace affordances are not focusable.
  final bool disabled;

  /// The list of error messages to display below the box.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// The focus node for the drop-zone box itself.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The fixed height of the drop-zone box, in logical pixels.
  ///
  /// Defaults to 160. The box always occupies this height regardless of state
  /// or file count, per decision D15 -- populated files scroll within it rather
  /// than growing it.
  final double height;

  /// Creates a new [LayrzFileInput] with the given properties.
  const LayrzFileInput({
    super.key,
    this.value = const [],
    this.onChanged,
    this.maxFiles,
    this.allowedExtensions,
    this.maxFileSizeBytes,
    this.rejectionMessage,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.focusNode,
    this.height = 160,
  });

  @override
  State<LayrzFileInput> createState() => _LayrzFileInputState();
}

class _LayrzFileInputState extends State<LayrzFileInput> {
  late FocusNode _focusNode;

  /// The files currently displayed, independent of [LayrzFileInput.value] once
  /// a pick/drop has been made locally -- mirrors `LayrzSelectInput`'s
  /// `_displayedValue` self-display convention (see the class doc).
  late List<LayrzFileInputResult> _displayedFiles;

  /// Whether an OS/browser drag-and-drop operation is currently over the box.
  bool _isDragging = false;

  /// Whether the pointer is hovering the box (desktop/mouse only).
  bool _isHovered = false;

  /// The persistent rejection message currently shown, or null when nothing
  /// has been rejected since the last successful pick/drop/clear.
  String? _rejection;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _displayedFiles = List.of(widget.value);
  }

  @override
  void didUpdateWidget(LayrzFileInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.value != oldWidget.value) {
      _displayedFiles = List.of(widget.value);
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
  /// [LayrzFileInput.allowedExtensions].
  ///
  /// Returns true when no filter is configured.
  bool _isExtensionAllowed(String? extension) {
    final allowed = widget.allowedExtensions;
    if (allowed == null || allowed.isEmpty) return true;
    if (extension == null) return false;
    return allowed.any((e) => e.toLowerCase() == extension.toLowerCase());
  }

  /// Validates and, if accepted, commits [incoming] on top of the current
  /// selection -- replacing it outright when [LayrzFileInput.maxFiles] is 1,
  /// otherwise appending and truncating to remaining capacity.
  ///
  /// The first file in [incoming] that fails extension or size validation
  /// sets [_rejection] and stops the whole batch from being committed -- a
  /// mixed batch of valid and invalid files is rejected as a whole rather than
  /// silently dropping just the bad entries, so the user is not left guessing
  /// which of several dropped files went missing.
  void _commitIncoming(List<LayrzFileInputResult> incoming) {
    if (incoming.isEmpty) return;

    for (final file in incoming) {
      final extension = file.name.contains('.') ? file.name.split('.').last : null;
      if (!_isExtensionAllowed(extension)) {
        setState(() => _rejection = widget.rejectionMessage ?? _defaultRejectionMessage(context));
        return;
      }
      final maxSize = widget.maxFileSizeBytes;
      if (maxSize != null && file.size > maxSize) {
        setState(() => _rejection = widget.rejectionMessage ?? _defaultRejectionMessage(context));
        return;
      }
    }

    setState(() {
      _rejection = null;
      if (widget.maxFiles == 1) {
        _displayedFiles = [incoming.first];
      } else {
        final combined = [..._displayedFiles, ...incoming];
        final cap = widget.maxFiles;
        _displayedFiles = cap == null ? combined : combined.take(cap).toList();
      }
    });
    widget.onChanged?.call(_displayedFiles);
  }

  /// The default English rejection message, used when
  /// [LayrzFileInput.rejectionMessage] is null.
  String _defaultRejectionMessage(BuildContext context) {
    final allowed = widget.allowedExtensions;
    if (allowed != null && allowed.isNotEmpty) {
      return 'File rejected: allowed types are ${allowed.join(', ')}.';
    }
    final maxSize = widget.maxFileSizeBytes;
    if (maxSize != null) {
      return 'File rejected: exceeds the maximum size of $maxSize bytes.';
    }
    return 'File rejected.';
  }

  /// Opens the system file picker via `file_picker`, converting the result
  /// into [LayrzFileInputResult]s and committing them via [_commitIncoming].
  Future<void> _openPicker() async {
    if (widget.disabled) return;

    final allowed = widget.allowedExtensions;
    final result = await FilePicker.platform.pickFiles(
      type: allowed != null && allowed.isNotEmpty ? FileType.custom : FileType.any,
      allowedExtensions: allowed != null && allowed.isNotEmpty ? allowed : null,
      allowMultiple: widget.maxFiles != 1,
      withData: true,
    );

    if (result == null) return;

    final incoming = <LayrzFileInputResult>[];
    for (final platformFile in result.files) {
      final bytes = platformFile.bytes;
      if (bytes == null) continue;
      incoming.add(
        LayrzFileInputResult(
          name: platformFile.name,
          mimeType: mimeTypeForExtension(platformFile.extension),
          bytes: bytes,
        ),
      );
    }
    _commitIncoming(incoming);
  }

  /// Removes the file at [index] from the current selection.
  void _removeAt(int index) {
    setState(() {
      _displayedFiles = List.of(_displayedFiles)..removeAt(index);
    });
    widget.onChanged?.call(_displayedFiles);
  }

  /// Clears every currently selected file.
  void _clearAll() {
    setState(() {
      _displayedFiles = const [];
      _rejection = null;
    });
    widget.onChanged?.call(_displayedFiles);
  }

  /// Resolves the box's current [LayrzFileInputState], in state precedence
  /// order: dragging > hover > populated > empty. Disabled is handled
  /// separately by [LayrzFileInputStyleSpec.resolve] itself.
  LayrzFileInputState _resolveState() {
    if (_isDragging) return LayrzFileInputState.dragging;
    if (_isHovered || _focusNode.hasFocus) return LayrzFileInputState.hover;
    if (_displayedFiles.isNotEmpty) return LayrzFileInputState.populated;
    return LayrzFileInputState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
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
        _buildBox(context, tokens, spec),
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

  /// Builds the label row above the box, mirroring `LayrzSelectInput`'s label
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

  /// Builds the drop-zone box itself: the [LayrzFileInputDropTarget] wrapping a
  /// focusable, fixed-height container that shows either the empty hint or the
  /// populated file list.
  ///
  /// **Only the empty state is one big tap/keyboard target.** In the empty
  /// state, the whole box IS the "open picker" affordance, so it gets a single
  /// [Semantics] button wrapping everything -- there is no other content
  /// underneath to preserve. In the populated state, the box is a *container*
  /// for independently-actionable rows (each file's clear button, "Add more",
  /// "Clear all") -- wrapping the whole thing in one more [Semantics] button
  /// would merge every row's label into a single announced string (measured:
  /// "Remove a.png, Add more files" as ONE node), which is both wrong for
  /// assistive technology and breaks `find.bySemanticsLabel`-style lookups on
  /// any individual row. So the populated state carries no box-level
  /// [Semantics] or whole-box tap handler at all -- each row wires its own.
  Widget _buildBox(BuildContext context, LayrzTokens tokens, LayrzFileInputStyleSpec spec) {
    final isEmpty = _displayedFiles.isEmpty;

    // The rounded clip is deliberately its own `ClipRRect` layer, separate from
    // the `AnimatedContainer` that carries the fill/border decoration.
    // Combining `clipBehavior: Clip.antiAlias` with an animated `BoxDecoration`
    // fill+border on the SAME container is a known Impeller artifact (observed
    // on Linux/Vulkan): the clip region paints solid black instead of the
    // decoration's fill during the animated transition. Splitting the clip out
    // into its own non-decorated `ClipRRect` wrapper -- with the fill/border
    // painted by the `AnimatedContainer` it wraps, not by itself -- avoids the
    // combination entirely while keeping the same rounded corners, the same
    // colour/border transition (D15), and the same geometry.
    final content = ClipRRect(
      borderRadius: tokens.radius.br2,
      child: AnimatedContainer(
        duration: tokens.motion.dHover,
        curve: tokens.motion.easing,
        height: widget.height,
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: tokens.radius.br2,
          border: Border.all(color: spec.borderColor, width: spec.borderWidth),
        ),
        padding: EdgeInsets.all(tokens.spacing.sp3),
        child: isEmpty ? _buildEmptyContent(tokens, spec) : _buildPopulatedContent(context, tokens, spec),
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
            if (isEmpty) _openPicker();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: (widget.disabled || !isEmpty) ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: (widget.disabled || !isEmpty) ? null : _openPicker,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );

    final withSemantics = isEmpty
        ? Semantics(
            label: widget.labelText ?? widget.hintText,
            button: true,
            enabled: !widget.disabled,
            hint: 'Opens the file picker',
            child: focusable,
          )
        : focusable;

    return LayrzFileInputDropTarget(
      enabled: !widget.disabled,
      onDragEntered: () => setState(() => _isDragging = true),
      onDragExited: () => setState(() => _isDragging = false),
      onFilesDropped: (files) {
        setState(() => _isDragging = false);
        _commitIncoming(files);
      },
      child: withSemantics,
    );
  }

  /// Builds the empty-state content: an upload icon and hint text, centered.
  Widget _buildEmptyContent(LayrzTokens tokens, LayrzFileInputStyleSpec spec) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MdiIcons.cloudUploadOutline, size: 32, color: spec.contentColor),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            widget.hintText ?? 'Click to browse or drag files here',
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(color: spec.contentColor),
          ),
        ],
      ),
    );
  }

  /// Builds the populated-state content: a scrollable list of file previews,
  /// each with its own keyboard-reachable clear affordance, plus a trailing
  /// "add more" row that re-opens the picker, and -- when more than one file
  /// is selected -- a "clear all" row.
  Widget _buildPopulatedContent(BuildContext context, LayrzTokens tokens, LayrzFileInputStyleSpec spec) {
    final showClearAll = _displayedFiles.length > 1;
    final trailingRowCount = showClearAll ? 2 : 1;

    return ListView.separated(
      itemCount: _displayedFiles.length + trailingRowCount,
      separatorBuilder: (context, index) => SizedBox(height: tokens.spacing.sp2),
      itemBuilder: (context, index) {
        if (index == _displayedFiles.length) {
          return _AddMoreRow(disabled: widget.disabled, onTap: _openPicker, tokens: tokens);
        }
        if (showClearAll && index == _displayedFiles.length + 1) {
          return _ClearAllRow(disabled: widget.disabled, onTap: _clearAll, tokens: tokens);
        }
        final file = _displayedFiles[index];
        return _FilePreviewRow(
          result: file,
          disabled: widget.disabled,
          onRemove: () => _removeAt(index),
          tokens: tokens,
        );
      },
    );
  }
}

/// A single row in the populated state: [LayrzFileInputPreview] plus the file
/// name, and a keyboard-reachable clear button.
class _FilePreviewRow extends StatelessWidget {
  /// The file this row represents.
  final LayrzFileInputResult result;

  /// Whether the parent field is disabled -- when true, the clear button is
  /// neither focusable nor tappable.
  final bool disabled;

  /// Called when the clear button is activated (tap, Enter, or Space).
  final VoidCallback onRemove;

  /// Design tokens, threaded from the parent build to avoid a second
  /// `context.tokens` lookup per row.
  final LayrzTokens tokens;

  /// Creates a new [_FilePreviewRow].
  const _FilePreviewRow({
    required this.result,
    required this.disabled,
    required this.onRemove,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    // `explicitChildNodes: true` is load-bearing: without it, the file name
    // `Text` (a bare leaf with no `Semantics` of its own) merges upward into
    // whichever descendant DOES have an explicit node -- measured to combine
    // with `_RowIconButton`'s "Remove <name>" node into one single button
    // labeled "<name>\nRemove <name>". This forces each descendant `Semantics`
    // node (the icon button) and the plain `Text` to remain distinct siblings
    // under this row instead.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.colors.sf1,
          borderRadius: tokens.radius.br1,
          border: Border.all(color: tokens.colors.divider),
        ),
        padding: EdgeInsets.all(tokens.spacing.sp2),
        child: Row(
          children: [
            LayrzFileInputPreview(result: result, size: 40),
            SizedBox(width: tokens.spacing.sp2),
            Expanded(
              child: Text(
                result.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tokens.typography.body.copyWith(color: tokens.colors.fg1),
              ),
            ),
            SizedBox(width: tokens.spacing.sp2),
            _RowIconButton(
              icon: MdiIcons.close,
              label: 'Remove ${result.name}',
              disabled: disabled,
              onTap: onRemove,
              tokens: tokens,
            ),
          ],
        ),
      ),
    );
  }
}

/// The trailing "add more" row rendered after every file preview in the
/// populated state -- re-opens the picker, same action as tapping the empty
/// box.
class _AddMoreRow extends StatelessWidget {
  /// Whether the parent field is disabled.
  final bool disabled;

  /// Called when this row is activated.
  final VoidCallback onTap;

  /// Design tokens, threaded from the parent build.
  final LayrzTokens tokens;

  /// Creates a new [_AddMoreRow].
  const _AddMoreRow({
    required this.disabled,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled ? tokens.colors.fg4 : tokens.colors.primary;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: 'Add more files',
      // Excludes the visible Row's own semantics (the icon and "Add more"
      // Text would otherwise merge into this node's label, producing "Add
      // more files\nAdd more" -- see `_FilePreviewRow`'s doc for the same
      // merging behavior observed on a sibling case).
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: !disabled,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: disabled ? null : onTap,
            behavior: HitTestBehavior.opaque,
            // `width: double.infinity` matters here, not just for a larger hit
            // target: `Semantics` reports this row's geometry from its render
            // box's own size in the `ListView` item slot, which spans the full
            // row width -- while `Row(mainAxisSize: MainAxisSize.min)` alone
            // would shrink-wrap to the icon+text's actual (much narrower,
            // left-aligned) width. Tapping the CENTER of the wider reported
            // semantics rect then misses the real, narrower `GestureDetector`
            // entirely (measured: `tester.tap` on the correct finder, at the
            // correct rect, produced zero taps). Filling the width keeps the
            // painted, hit-testable, and announced geometry all in agreement.
            child: SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MdiIcons.plusCircleOutline, size: 18, color: color),
                  SizedBox(width: tokens.spacing.sp2),
                  Text('Add more', style: tokens.typography.label.copyWith(color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The trailing "clear all" row rendered after [_AddMoreRow] whenever more
/// than one file is selected -- clears the entire selection in one action,
/// distinct from [_RowIconButton]'s per-file removal.
class _ClearAllRow extends StatelessWidget {
  /// Whether the parent field is disabled.
  final bool disabled;

  /// Called when this row is activated.
  final VoidCallback onTap;

  /// Design tokens, threaded from the parent build.
  final LayrzTokens tokens;

  /// Creates a new [_ClearAllRow].
  const _ClearAllRow({
    required this.disabled,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled ? tokens.colors.fg4 : tokens.colors.danger;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: 'Clear all files',
      // See `_AddMoreRow`'s identical note: without this, the visible Row's
      // icon and "Clear all" Text would merge into this node's label.
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: !disabled,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: disabled ? null : onTap,
            behavior: HitTestBehavior.opaque,
            // See `_AddMoreRow`'s identical note on why this must fill the
            // width rather than shrink-wrap.
            child: SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(MdiIcons.trashCanOutline, size: 18, color: color),
                  SizedBox(width: tokens.spacing.sp2),
                  Text('Clear all', style: tokens.typography.label.copyWith(color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small, focusable icon button used for the per-file clear affordance.
///
/// Follows the same [ActivateIntent]/[FocusableActionDetector] pattern
/// `LayrzCard` uses for its interactive form, so Tab reaches it and Enter/Space
/// activates it independently of the row's own (non-interactive) container.
class _RowIconButton extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The accessibility label announced for this button.
  final String label;

  /// Whether the button is disabled.
  final bool disabled;

  /// Called when the button is activated (tap, Enter, or Space).
  final VoidCallback onTap;

  /// Design tokens, threaded from the parent build.
  final LayrzTokens tokens;

  /// Creates a new [_RowIconButton].
  const _RowIconButton({
    required this.icon,
    required this.label,
    required this.disabled,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: FocusableActionDetector(
        enabled: !disabled,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp1),
              child: Icon(icon, size: 18, color: disabled ? tokens.colors.fg4 : tokens.colors.fg3),
            ),
          ),
        ),
      ),
    );
  }
}
