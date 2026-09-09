import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_editor_selection.dart';
import 'package:layrz_ui/src/code/src/code_error.dart';
import 'package:layrz_ui/src/code/src/code_gutter.dart';
import 'package:layrz_ui/src/code/src/code_surface.dart';
import 'package:layrz_ui/src/code/src/code_tab_indent.dart' as tab_indent;
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/fonts/fonts.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/selection/selection.dart';

/// An editable, syntax-highlighted code editor.
///
/// [LayrzCodeEditor] is the writable counterpart to [LayrzCodeSurface]/the
/// read-only code snippet: it hosts a raw [EditableText] over a
/// [LayrzHighlightingController] so keystrokes are colored live as the user
/// types, adds a line-number gutter with current-line and error highlighting,
/// and preserves Tab/Shift+Tab as indent/outdent instead of letting focus
/// traversal swallow them.
///
/// **Dark always**: like every other code widget in layrz_ui, this editor is
/// always rendered in [LayrzCodeThemeExtension.dark] (or whatever
/// [LayrzCodeThemeExtension] is registered on the active theme) — it never
/// follows the app's own light palette. See [LayrzCodeThemeExtension] for the
/// rationale.
///
/// **Controller contract**: when [controller] is `null`, this widget creates
/// and owns a [LayrzHighlightingController] internally, so live syntax
/// highlighting works out of the box. When the caller supplies their own
/// [controller], it is used as-is: if it happens to already be a
/// [LayrzHighlightingController] its own highlighting keeps working, but a
/// plain [TextEditingController] renders with no highlighting at all — the
/// widget never wraps or replaces a caller-supplied controller. The same
/// create-if-null / dispose-if-owned rule applies to [focusNode], mirroring
/// `LayrzNumberInput`.
///
/// **Read-only rendering**: when [readOnly] or [disabled] is true, this
/// widget does not build an [EditableText] at all — it delegates entirely to
/// [LayrzCodeSurface], so a read-only editor renders pixel-identical to the
/// plain code snippet widget. [disabled] additionally dims the surface.
///
/// **Tab handling**: Tab and Shift+Tab are intercepted by an ancestor
/// [Focus.onKeyEvent] (the same interception mechanism `LayrzNumberInput`
/// uses for its arrow-key stepping) so they indent/outdent the current
/// selection instead of moving focus to the next widget. The actual text
/// transformation is the pure, independently testable [applyTabIndent]
/// function.
///
/// **Gutter/scroll sync**: the line-number gutter and the code both live
/// inside one shared vertical [SingleChildScrollView], side by side in a
/// [Row] — see [LayrzCodeGutter] for why this is the approach that keeps
/// line `N` in the gutter aligned with line `N` of the code, and why the
/// gutter must never introduce a scrollable of its own.
class LayrzCodeEditor extends StatefulWidget {
  /// The current source text displayed in the editor.
  ///
  /// When [controller] is supplied, this is only used to seed it; ongoing
  /// edits are read from the controller. When `null`, the field starts empty.
  final String? value;

  /// Callback fired whenever the edited text changes, including edits made
  /// via Tab/Shift+Tab indentation.
  final ValueChanged<String>? onChanged;

  /// The language used to syntax-highlight the edited text.
  final LayrzCodeLanguage language;

  /// Diagnostics to mark in the gutter (and, per-line, underline in the
  /// code), each keyed to a 1-based line/column.
  ///
  /// Defaults to `const []` (no errors marked).
  final List<LayrzCodeError> errors;

  /// Whether to draw the line-number gutter to the left of the code.
  ///
  /// Defaults to `true`.
  final bool showLineNumbers;

  /// The number of spaces a Tab keystroke inserts when [useSpaces] is `true`.
  ///
  /// Also the maximum number of leading spaces a Shift+Tab keystroke removes
  /// per selected line. Defaults to `4`. Ignored (no effect on Tab's own
  /// insertion) when [useSpaces] is `false`, but Shift+Tab always removes at
  /// most this many leading spaces before falling back to removing a single
  /// leading tab character.
  final int tabSpaces;

  /// Whether Tab inserts [tabSpaces] literal space characters (`true`,
  /// default) or a single `\t` character (`false`).
  final bool useSpaces;

  /// Whether the editor is read-only.
  ///
  /// A read-only editor renders via [LayrzCodeSurface] instead of an
  /// [EditableText] — see the class-level "Read-only rendering" note.
  final bool readOnly;

  /// Whether the editor is disabled.
  ///
  /// Like [readOnly], a disabled editor renders via [LayrzCodeSurface], with
  /// the surface additionally dimmed.
  final bool disabled;

  /// Whether the editor should request focus as soon as it is built.
  final bool autofocus;

  /// The text editing controller backing the editable text.
  ///
  /// See the class-level "Controller contract" note for ownership and
  /// highlighting behavior when this is `null` versus supplied.
  final TextEditingController? controller;

  /// The focus node backing the editable text.
  ///
  /// When `null`, a [FocusNode] is created and disposed by this widget,
  /// mirroring [controller]'s ownership rule.
  final FocusNode? focusNode;

  /// The label text displayed above the editor.
  final String? labelText;

  /// Hint text displayed as placeholder when the editor is empty.
  final String? hintText;

  /// Helper text displayed below the editor.
  final String? helperText;

  /// Whether to overlay a [LayrzCodeCopyButton] in the top-right corner.
  ///
  /// Defaults to `true`. Shown in both the editable and read-only branches.
  final bool showCopyButton;

  /// The maximum height of the code area before it scrolls internally.
  ///
  /// `null` (the default) leaves the height unconstrained.
  final double? maxHeight;

  /// The font size, in logical pixels, used to render the code.
  ///
  /// Defaults to `14`.
  final double fontSize;

  /// Whether the editor uses the dense density variant, reducing outer
  /// padding by one spacing level.
  final bool dense;

  /// Callback fired when the editor is tapped.
  final VoidCallback? onTap;

  /// Callback fired when the editor gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Creates a new [LayrzCodeEditor].
  const LayrzCodeEditor({
    super.key,
    this.value,
    this.onChanged,
    required this.language,
    this.errors = const [],
    this.showLineNumbers = true,
    this.tabSpaces = 4,
    this.useSpaces = true,
    this.readOnly = false,
    this.disabled = false,
    this.autofocus = false,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.showCopyButton = true,
    this.maxHeight,
    this.fontSize = 14,
    this.dense = false,
    this.onTap,
    this.onFocusChanged,
  });

  @override
  State<LayrzCodeEditor> createState() => _LayrzCodeEditorState();

  /// Applies a Tab or Shift+Tab keystroke to [value], returning the resulting
  /// [TextEditingValue].
  ///
  /// A thin, stable-name forwarder to the top-level `applyTabIndent` function
  /// in `code_tab_indent.dart`, where the actual pure transformation lives —
  /// split out because it has no dependency on this widget and carries most
  /// of the editor's test coverage on its own. Kept as a static method here
  /// too so callers (and this widget's own tests) can keep referring to
  /// `LayrzCodeEditor.applyTabIndent` rather than an implementation-detail
  /// import. See that function's doc comment for the full behavior.
  static TextEditingValue applyTabIndent(
    TextEditingValue value, {
    required int tabSpaces,
    required bool useSpaces,
    required bool outdent,
  }) {
    return tab_indent.applyTabIndent(
      value,
      tabSpaces: tabSpaces,
      useSpaces: useSpaces,
      outdent: outdent,
    );
  }
}

class _LayrzCodeEditorState extends State<LayrzCodeEditor> implements TextSelectionGestureDetectorBuilderDelegate {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};
  final ScrollController _scrollController = ScrollController();
  late final EditableTextContextMenuBuilder _cachedContextMenuBuilder;
  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey<EditableTextState>();
  late final TextSelectionGestureDetectorBuilder _gestureDetectorBuilder;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableTextKey;

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => !widget.readOnly && !widget.disabled;

  /// The code theme most recently resolved in [build].
  ///
  /// Captured so the internally-created [LayrzHighlightingController]'s
  /// `resolveStyle` closure (created once in [initState]) can always read the
  /// *current* theme rather than the one active when the controller was
  /// constructed.
  LayrzCodeThemeExtension _codeTheme = const LayrzCodeThemeExtension.dark();

  bool get _ownsController => widget.controller == null;

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _createHighlightingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleSelectionOrTextChange);
    _cachedContextMenuBuilder = (context, editableTextState) =>
        buildCodeEditorContextMenu(context, editableTextState, readOnly: widget.readOnly);
    _gestureDetectorBuilder = CodeEditorGestureDetectorBuilder(delegate: this, onUserTapCallback: () => widget.onTap);
  }

  /// Builds a [LayrzHighlightingController] seeded with [LayrzCodeEditor.value],
  /// resolving each scope's style from [_codeTheme] at paint time rather than
  /// at construction time (see [_codeTheme]'s doc comment).
  LayrzHighlightingController _createHighlightingController() {
    return LayrzHighlightingController(
      language: widget.language,
      resolveStyle: (scope) => _codeTheme.styleForScope(scope, fontSize: widget.fontSize),
      text: widget.value ?? '',
    );
  }

  @override
  void didUpdateWidget(LayrzCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleSelectionOrTextChange);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? _createHighlightingController();
      _controller.addListener(_handleSelectionOrTextChange);
    } else if (widget.language != oldWidget.language && _ownsController) {
      // We own the controller and the language changed: recreate it so its
      // highlighter re-tokenizes under the new grammar, preserving the
      // current text.
      final currentText = _controller.text;
      _controller.removeListener(_handleSelectionOrTextChange);
      _controller.dispose();
      _controller = LayrzHighlightingController(
        language: widget.language,
        resolveStyle: (scope) => _codeTheme.styleForScope(scope, fontSize: widget.fontSize),
        text: currentText,
      );
      _controller.addListener(_handleSelectionOrTextChange);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }

    if (widget.value != oldWidget.value && widget.value != null && widget.value != _controller.text) {
      _controller.text = widget.value!;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSelectionOrTextChange);
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      if (_focusNode.hasFocus) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
      }
    });
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  /// Rebuilds so the current-line highlight tracks caret movement, and so a
  /// programmatic text change (e.g. Tab indentation) repaints immediately.
  void _handleSelectionOrTextChange() {
    setState(() {});
  }

  /// Returns the 1-based line number the caret currently sits on, or `null`
  /// if the controller has no valid selection yet.
  int? _currentLine() {
    final offset = _controller.selection.baseOffset;
    if (offset < 0) {
      return null;
    }
    final clamped = offset.clamp(0, _controller.text.length);
    final before = _controller.text.substring(0, clamped);
    return '\n'.allMatches(before).length + 1;
  }

  /// Handles Tab/Shift+Tab, delegating the actual text transformation to
  /// [LayrzCodeEditor.applyTabIndent].
  ///
  /// Installed as the [Focus.onKeyEvent] handler of an ancestor [Focus] that
  /// never itself requests focus (`canRequestFocus: false`) or participates
  /// in traversal (`skipTraversal: true`) — the same interception pattern
  /// `LayrzNumberInput` uses for its arrow-key stepping.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    if (widget.readOnly || widget.disabled) {
      return KeyEventResult.ignored;
    }

    final outdent = HardwareKeyboard.instance.isShiftPressed;
    final newValue = LayrzCodeEditor.applyTabIndent(
      _controller.value,
      tabSpaces: widget.tabSpaces,
      useSpaces: widget.useSpaces,
      outdent: outdent,
    );
    _controller.value = newValue;
    widget.onChanged?.call(newValue.text);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _codeTheme = context.maybeThemeExtension<LayrzCodeThemeExtension>() ?? const LayrzCodeThemeExtension.dark();
    final tokens = context.tokens;
    final isDisabledOverall = widget.readOnly || widget.disabled;

    final Widget body = isDisabledOverall ? _buildReadOnly() : _buildEditable();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp1),
            child: ExcludeSemantics(
              child: Text(
                widget.labelText!,
                style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
              ),
            ),
          ),
        Focus(
          onKeyEvent: _handleKeyEvent,
          skipTraversal: true,
          canRequestFocus: false,
          child: body,
        ),
        if (widget.helperText != null)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sp1),
            child: Text(
              widget.helperText!,
              style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
            ),
          ),
      ],
    );
  }

  /// Builds the read-only/disabled branch: a [LayrzCodeSurface] with the copy
  /// button overlaid, optionally dimmed when [LayrzCodeEditor.disabled].
  Widget _buildReadOnly() {
    final surface = LayrzCodeSurface(
      code: _controller.text,
      language: widget.language,
      showLineNumbers: widget.showLineNumbers,
      maxHeight: widget.maxHeight,
      fontSize: widget.fontSize,
    );

    return Stack(
      children: [
        widget.disabled ? Opacity(opacity: 0.5, child: surface) : surface,
        if (widget.showCopyButton)
          Positioned(
            top: 0,
            right: 0,
            child: LayrzCodeCopyButton(text: _controller.text, color: _codeTheme.gutterForeground),
          ),
      ],
    );
  }

  /// Builds the editable branch: gutter + [EditableText], sharing a single
  /// vertical [_scrollController] so line numbers never drift out of sync
  /// with the code — see the class-level "Gutter/scroll sync" note.
  Widget _buildEditable() {
    const font = LayrzJetBrainsMonoFont();
    final baseStyle = font.body.copyWith(fontSize: widget.fontSize, color: _codeTheme.foreground);
    final lineHeight = (baseStyle.height ?? 1.4) * widget.fontSize;
    final lineCount = '\n'.allMatches(_controller.text).length + 1;

    final editable = EditableText(
      key: _editableTextKey,
      // `rendererIgnoresPointer: true` hands all pointer handling to the
      // wrapping `TextSelectionGestureDetectorBuilder` below instead of
      // `EditableText`'s own internal recognizer — the same split
      // `LayrzEditableField` uses. Without it, a caller `onTap` wrapped in a
      // plain `GestureDetector` around this widget loses every gesture-arena
      // contest to `EditableText`'s own recognizer and never fires.
      rendererIgnoresPointer: true,
      controller: _controller,
      focusNode: _focusNode,
      style: baseStyle,
      cursorColor: _codeTheme.foreground,
      backgroundCursorColor: _codeTheme.gutterForeground,
      selectionColor: _codeTheme.foreground.withValues(alpha: 0.24),
      selectionControls: LayrzTextSelectionControls.instance,
      contextMenuBuilder: _cachedContextMenuBuilder,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: null,
      minLines: 3,
      expands: false,
      autofocus: widget.autofocus,
      readOnly: false,
      onChanged: widget.onChanged,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      textAlign: TextAlign.start,
    );

    // Explicit `enabled` because `EditableText` never sets it itself — it is
    // always an ancestor's responsibility (`LayrzEditableField` does the same
    // around its own `EditableText`). Wrapped tightly around the gesture
    // detector, not further out, so this field's own semantics node stays
    // distinct from the ancestor `SingleChildScrollView`'s scroll-container
    // node once the whole row scrolls.
    final tappableEditable = Semantics(
      enabled: !widget.readOnly && !widget.disabled,
      child: _gestureDetectorBuilder.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: editable,
      ),
    );

    final content = ColoredBox(
      color: _codeTheme.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // `SingleChildScrollView` gives its child unbounded width (it only
          // scrolls vertically), which a `Row`/`Expanded` cannot resolve —
          // `Expanded` needs a bounded main axis to divide. Pinning the row
          // to a concrete width lets `Expanded` claim "everything but the
          // gutter" for the editable text while the whole row still scrolls
          // vertically as one unit with the gutter — see the class-level
          // "Gutter/scroll sync" note. `constraints.maxWidth` is used
          // whenever the ancestor actually bounds this widget (the normal
          // case — a form field, a dialog, a sized container); the viewport
          // width is the fallback for the rarer case of an unbounded
          // ancestor (e.g. centered in a test harness with no width of its
          // own), so layout never receives an infinite width either way.
          final resolvedWidth = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
          return SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              width: resolvedWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showLineNumbers)
                    LayrzCodeGutter(
                      lineCount: lineCount,
                      currentLine: _focusNode.hasFocus ? _currentLine() : null,
                      lineHeight: lineHeight,
                      fontSize: widget.fontSize,
                      errors: widget.errors,
                      codeTheme: _codeTheme,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: tappableEditable,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final constrained = widget.maxHeight != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight!),
            child: content,
          )
        : content;

    return Stack(
      children: [
        constrained,
        if (widget.showCopyButton)
          Positioned(
            top: 0,
            right: 0,
            child: LayrzCodeCopyButton(text: _controller.text, color: _codeTheme.gutterForeground),
          ),
      ],
    );
  }
}
