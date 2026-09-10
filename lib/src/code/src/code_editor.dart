import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_editor_selection.dart';
import 'package:layrz_ui/src/code/src/code_error.dart';
import 'package:layrz_ui/src/code/src/code_gutter.dart';
import 'package:layrz_ui/src/code/src/code_suggestions.dart';
import 'package:layrz_ui/src/code/src/code_surface.dart';
import 'package:layrz_ui/src/code/src/code_tab_indent.dart' as tab_indent;
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/constants/constants.dart';
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

  /// The fixed height of the code area, in logical pixels.
  ///
  /// The editor is always exactly this tall and never grows or shrinks with
  /// the number of lines — content taller than the box scrolls, and a short
  /// document leaves empty editable space below it. The caller owns this
  /// dimension; change it to resize the editor. Defaults to `220`.
  final double height;

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

  /// Called when the user taps the run action.
  ///
  /// When non-null, a run (play) [LayrzButton] is shown in the editor's
  /// top-right action row alongside the copy button. When `null`, no run
  /// button is rendered. Wiring what "run" does is the caller's responsibility.
  final VoidCallback? onRun;

  /// Called when the user taps the lint action.
  ///
  /// When non-null, a lint [LayrzButton] is shown in the editor's top-right
  /// action row. When `null`, no lint button is rendered.
  final VoidCallback? onLint;

  /// Extra autocomplete suggestions supplied by the caller, merged with the
  /// language's built-in symbols.
  ///
  /// As the user types an identifier, a popup lists every built-in symbol for
  /// [language] (Layrz Compute Language function names; Python keywords and
  /// builtins) plus these entries whose text starts with the partial word
  /// (case-insensitive). Use it for context-specific completions the editor
  /// cannot know on its own — most importantly the Layrz Markup Language
  /// `{{variable}}` names available in the current document, which have no
  /// built-in list. Each accepted entry is inserted verbatim, so pass entries
  /// in the exact form they should appear (e.g. `assetName` or `{{assetName}}`).
  final List<String> suggestions;

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
    this.height = 220,
    this.fontSize = 14,
    this.dense = false,
    this.onTap,
    this.onFocusChanged,
    this.onRun,
    this.onLint,
    this.suggestions = const [],
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

  /// The autocomplete matches currently offered, or empty when the popup is
  /// closed. Recomputed on every selection/text change from the word under the
  /// caret; the popup renders only while this is non-empty.
  List<String> _suggestionMatches = const [];

  /// The index into [_suggestionMatches] highlighted for keyboard selection.
  int _suggestionIndex = 0;

  /// The source range the active completion would replace (the caret word).
  LayrzCaretWord? _suggestionWord;

  /// Links the caret anchor in the editor to the popup rendered in the root
  /// [Overlay], so the floating suggestion list follows the caret and is never
  /// clipped by the editor's rounded chrome or `maxHeight`.
  final LayerLink _suggestionLink = LayerLink();

  /// The live overlay entry hosting the suggestion popup, or `null` when the
  /// popup is closed.
  OverlayEntry? _suggestionOverlay;

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
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
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
  /// Also recomputes the autocomplete matches for the word under the caret.
  void _handleSelectionOrTextChange() {
    setState(_recomputeSuggestions);
  }

  /// Recomputes [_suggestionMatches]/[_suggestionWord] from the identifier
  /// under the caret. Clears them (closing the popup) when the field is
  /// read-only/disabled, the selection is not a collapsed caret, or no
  /// candidate completes the current word. Must run inside a `setState`.
  void _recomputeSuggestions() {
    if (widget.readOnly || widget.disabled) {
      _suggestionMatches = const [];
      _suggestionWord = null;
      return;
    }
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      _suggestionMatches = const [];
      _suggestionWord = null;
      return;
    }
    final caretWord = LayrzCodeSuggestions.caretWord(_controller.text, selection.baseOffset);
    if (caretWord.word.isEmpty) {
      _suggestionMatches = const [];
      _suggestionWord = null;
      return;
    }
    final matches = LayrzCodeSuggestions.matches(
      caretWord.word,
      builtins: LayrzCodeSuggestions.builtinsFor(widget.language),
      extras: widget.suggestions,
    );
    _suggestionMatches = matches;
    _suggestionWord = matches.isEmpty ? null : caretWord;
    if (_suggestionIndex >= matches.length) {
      _suggestionIndex = 0;
    }
  }

  /// Replaces the caret word with [completion] and closes the popup, moving the
  /// caret to the end of the inserted text and firing [LayrzCodeEditor.onChanged].
  void _acceptSuggestion(String completion) {
    final word = _suggestionWord;
    if (word == null) {
      return;
    }
    final text = _controller.text;
    final newText = text.replaceRange(word.start, word.end, completion);
    final caret = word.start + completion.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    widget.onChanged?.call(newText);
    setState(() {
      _suggestionMatches = const [];
      _suggestionWord = null;
      _suggestionIndex = 0;
    });
  }

  /// Closes the popup without inserting anything. Must run inside a `setState`.
  void _closeSuggestions() {
    _suggestionMatches = const [];
    _suggestionWord = null;
    _suggestionIndex = 0;
  }

  /// Force-opens the popup at the caret in response to Ctrl/Cmd+Space, showing
  /// the full built-in + caller list when there is no partial word, or the
  /// prefix-filtered list when there is. Returns whether anything opened.
  bool _openSuggestionsManually() {
    if (widget.readOnly || widget.disabled) {
      return false;
    }
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      return false;
    }
    final caretWord = LayrzCodeSuggestions.caretWord(_controller.text, selection.baseOffset);
    final matches = LayrzCodeSuggestions.matches(
      caretWord.word,
      builtins: LayrzCodeSuggestions.builtinsFor(widget.language),
      extras: widget.suggestions,
      includeAllOnEmpty: true,
    );
    if (matches.isEmpty) {
      return false;
    }
    setState(() {
      _suggestionMatches = matches;
      // With no partial word there is nothing to replace, so the completion is
      // inserted at the caret (an empty-range word at the caret offset).
      _suggestionWord = caretWord;
      _suggestionIndex = 0;
    });
    return true;
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

    // Ctrl/Cmd+Space force-opens the autocomplete popup at the caret, showing
    // the full list when there is no partial word. Handled before everything
    // else so the space is never inserted into the text.
    if (event.logicalKey == LogicalKeyboardKey.space &&
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
      final opened = _openSuggestionsManually();
      return opened ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    // Autocomplete navigation takes priority while the popup is open — but
    // ONLY over its own keys (arrows/Enter/Escape). Tab is never consumed by
    // the popup, so it keeps indenting even mid-completion.
    if (_suggestionMatches.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _suggestionIndex = (_suggestionIndex + 1) % _suggestionMatches.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(
          () => _suggestionIndex = (_suggestionIndex - 1 + _suggestionMatches.length) % _suggestionMatches.length,
        );
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        _acceptSuggestion(_suggestionMatches[_suggestionIndex]);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(_closeSuggestions);
        return KeyEventResult.handled;
      }
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

    // Sync the root-overlay popup after the frame, once the caret anchor's
    // geometry for this build is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSuggestionOverlay());

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
    final surface = SizedBox(
      height: widget.height,
      child: LayrzCodeSurface(
        code: _controller.text,
        language: widget.language,
        showLineNumbers: widget.showLineNumbers,
        maxHeight: widget.height,
        fontSize: widget.fontSize,
        reservedTrailingSpace: _actionRowReserve(context.tokens.spacing.sp1),
      ),
    );

    return Stack(
      children: [
        widget.disabled ? Opacity(opacity: 0.5, child: surface) : surface,
        _buildActionRow(),
      ],
    );
  }

  /// The number of buttons rendered in the top-right action row (lint, run,
  /// copy), used to reserve enough horizontal space so code never runs behind
  /// any of them.
  int get _actionButtonCount =>
      (widget.onLint != null ? 1 : 0) + (widget.onRun != null ? 1 : 0) + (widget.showCopyButton ? 1 : 0);

  /// The horizontal space, in logical pixels, to reserve on the code content's
  /// right so no line's resting right edge runs under the action row. Each
  /// button is at most [kLayrzButtonCompactHeight] wide (Fab buttons are
  /// square); a trailing gap of one spacing level keeps text clear of the
  /// left-most button.
  double _actionRowReserve(double gap) =>
      _actionButtonCount == 0 ? 0 : _actionButtonCount * kLayrzButtonCompactHeight + gap;

  /// Builds the top-right action row overlaid on the code box: the optional
  /// lint and run buttons (shown only when their callback is provided) and the
  /// copy button (shown when [LayrzCodeEditor.showCopyButton] is true), in that
  /// order. Returns an empty [SizedBox] when nothing is shown so the [Stack]
  /// stays cheap.
  Widget _buildActionRow() {
    final hasRun = widget.onRun != null;
    final hasLint = widget.onLint != null;
    if (!hasRun && !hasLint && !widget.showCopyButton) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 0,
      right: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasLint)
            LayrzButton(
              labelText: 'Lint',
              icon: MdiIcons.checkAll,
              color: const Color(0xFFFFFFFF),
              style: LayrzButtonStyle.textFab,
              onTap: widget.onLint,
            ),
          if (hasRun)
            LayrzButton(
              labelText: 'Run',
              icon: MdiIcons.play,
              color: const Color(0xFFFFFFFF),
              style: LayrzButtonStyle.textFab,
              onTap: widget.onRun,
            ),
          if (widget.showCopyButton) LayrzCodeCopyButton(text: _controller.text),
        ],
      ),
    );
  }

  /// Builds the editable branch: gutter + [EditableText], sharing a single
  /// vertical [_scrollController] so line numbers never drift out of sync
  /// with the code — see the class-level "Gutter/scroll sync" note.
  ///
  /// Wrapped in the same outer chrome [LayrzCodeSurface] uses — a
  /// [DecoratedBox] painted with [LayrzCodeThemeExtension.background] and
  /// rounded with `tokens.radius.br2`, clipped by a matching [ClipRRect] —
  /// so an editable editor renders with the same rounded corners and outer
  /// padding as the read-only surface/snippet. The [ClipRRect] sits outside
  /// the scrolling content (mirroring [LayrzCodeSurface.build]) so the
  /// rounded clip never interferes with the gutter/text scroll-sync.
  Widget _buildEditable() {
    const font = LayrzJetBrainsMonoFont();
    // An explicit `height` is mandatory here: without it, `EditableText`
    // lays out each line at the font's intrinsic metric height while the
    // gutter (and the error-line bands) are positioned on a fixed
    // `lineHeight`, so the line numbers drift progressively out of sync down
    // the file. Pinning `height` to [kCodeLineHeightFactor] makes every
    // `EditableText` line box exactly `factor * fontSize` tall, matching the
    // gutter. The [StrutStyle] on the `EditableText` below enforces that same
    // box height even for lines whose glyphs (tall Unicode, emoji) would
    // otherwise stretch the line — so alignment holds regardless of content.
    final baseStyle = font.body.copyWith(
      fontSize: widget.fontSize,
      color: _codeTheme.foreground,
      height: kCodeLineHeightFactor,
    );
    final strutStyle = StrutStyle(
      fontFamily: baseStyle.fontFamily,
      fontSize: widget.fontSize,
      height: kCodeLineHeightFactor,
      forceStrutHeight: true,
    );
    // The gutter rows and the per-line error/current-line bands must advance
    // by the EXACT height `EditableText` lays each line out at — which is NOT
    // simply `kCodeLineHeightFactor * fontSize`. Flutter derives the final
    // line box from the font's own metrics plus the strut and rounds it, so
    // e.g. factor 1.4 at fontSize 14 renders 20.0px per line, not 19.6. Using
    // the computed value drifts by that fraction every line. Measuring one
    // laid-out line with the identical style + strut yields the real advance,
    // so gutter numbers and bands stay locked to the code no matter the font.
    final lineHeight = (TextPainter(
      text: TextSpan(text: 'A', style: baseStyle),
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
    )..layout()).preferredLineHeight;
    final lineCount = '\n'.allMatches(_controller.text).length + 1;
    final tokens = context.tokens;
    final resolvedPadding = tokens.spacing.pd3;
    // Mirrors `LayrzCodeSurface.reserveCopyButtonSpace`: when the copy button
    // is shown, the code content's right inset grows by the widest a
    // Fab-styled `LayrzButton` ever renders (`kLayrzButtonCompactHeight`)
    // plus a small gap, so a long line's resting right edge never runs under
    // the overlaid button. Only the code content's padding grows — the
    // gutter (left side) is never touched.
    final actionReserve = _actionRowReserve(tokens.spacing.sp1);
    final contentPadding = actionReserve > 0
        ? resolvedPadding.copyWith(right: resolvedPadding.right + actionReserve)
        : resolvedPadding;

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
      // The very same strut used to measure `lineHeight` above, so the text's
      // real line advance and the gutter/band positioning are guaranteed
      // identical. `forceStrutHeight: true` makes the strut win over any
      // taller glyph so line numbers never drift.
      strutStyle: strutStyle,
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
                    Padding(
                      padding: EdgeInsets.only(top: resolvedPadding.top, bottom: resolvedPadding.bottom),
                      child: LayrzCodeGutter(
                        lineCount: lineCount,
                        currentLine: _focusNode.hasFocus ? _currentLine() : null,
                        lineHeight: lineHeight,
                        fontSize: widget.fontSize,
                        errors: widget.errors,
                        codeTheme: _codeTheme,
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        ..._buildErrorLineBackgrounds(
                          lineCount: lineCount,
                          lineHeight: lineHeight,
                          topInset: contentPadding.top,
                        ),
                        Padding(
                          padding: contentPadding,
                          child: tappableEditable,
                        ),
                        _buildCaretAnchor(contentPadding, lineHeight),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Fixed height: the editor is always exactly `widget.height` tall and never
    // grows with the line count. A short document leaves empty editable space
    // below the code (the box's own background fills it); a tall one scrolls
    // inside the shared vertical `SingleChildScrollView`.
    final constrained = SizedBox(height: widget.height, child: content);

    // Same outer chrome as `LayrzCodeSurface`: a rounded, colored
    // `DecoratedBox` clipped by a matching `ClipRRect`, with the
    // `ClipRRect` outside the scrolling content so the rounded clip never
    // has to interact with the gutter/text scroll-sync — see this method's
    // doc comment.
    final chrome = DecoratedBox(
      decoration: BoxDecoration(
        color: _codeTheme.background,
        borderRadius: tokens.radius.br2,
      ),
      child: ClipRRect(
        borderRadius: tokens.radius.br2,
        child: constrained,
      ),
    );

    // The caret anchor: a zero-size `CompositedTransformTarget` positioned at
    // the caret, which the root-overlay popup follows via [_suggestionLink].
    // Sitting inside the scroll content, it moves with the caret as the code
    // scrolls, and — being in the overlay — the popup escapes the editor's
    // `ClipRRect`/`maxHeight` so it is never clipped.
    return Stack(
      children: [
        chrome,
        _buildActionRow(),
      ],
    );
  }

  /// A zero-size [CompositedTransformTarget] positioned at the caret inside the
  /// code area's [Stack] (the same coordinate space the [EditableText] and the
  /// error bands live in), so the root-overlay popup follows it exactly.
  ///
  /// The caret rectangle from the live [RenderEditable] is in the editable
  /// text's own local space; the text is inset by [contentPadding] within this
  /// Stack, so the anchor is offset by that padding to land on the real caret.
  Widget _buildCaretAnchor(EdgeInsets contentPadding, double lineHeight) {
    final renderEditable = _editableTextKey.currentState?.renderEditable;
    Offset caret = Offset(contentPadding.left, contentPadding.top);
    if (renderEditable != null) {
      final caretLocal = renderEditable.getLocalRectForCaret(_controller.selection.extent).bottomLeft;
      caret = Offset(contentPadding.left + caretLocal.dx, contentPadding.top + caretLocal.dy);
    }
    return Positioned(
      left: caret.dx,
      top: caret.dy,
      child: CompositedTransformTarget(
        link: _suggestionLink,
        child: const SizedBox.shrink(),
      ),
    );
  }

  /// Inserts, updates, or removes the root-overlay suggestion popup to match
  /// the current [_suggestionMatches]. Scheduled after the frame so the caret
  /// anchor's geometry is up to date when the follower reads it.
  void _syncSuggestionOverlay() {
    if (!mounted) {
      return;
    }
    if (_suggestionMatches.isEmpty) {
      _suggestionOverlay?.remove();
      _suggestionOverlay = null;
      return;
    }
    if (_suggestionOverlay == null) {
      _suggestionOverlay = OverlayEntry(builder: _buildSuggestionOverlay);
      Overlay.of(context, rootOverlay: true).insert(_suggestionOverlay!);
    } else {
      _suggestionOverlay!.markNeedsBuild();
    }
  }

  /// Builds the floating suggestion list, following the caret anchor via
  /// [_suggestionLink] and offset just below it.
  Widget _buildSuggestionOverlay(BuildContext context) {
    return Positioned(
      width: 280,
      child: CompositedTransformFollower(
        link: _suggestionLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        child: Align(
          alignment: Alignment.topLeft,
          child: LayrzCodeSuggestionList(
            matches: _suggestionMatches,
            selectedIndex: _suggestionIndex,
            codeTheme: _codeTheme,
            fontSize: widget.fontSize,
            onAccept: _acceptSuggestion,
          ),
        ),
      ),
    );
  }

  /// Builds the code-area half of the full-width error band for every line in
  /// [widget.errors], as a list of independently-[Positioned] widgets meant
  /// to be inserted into a [Stack] beneath the editable text.
  ///
  /// [LayrzCodeGutter] paints the matching left half behind the line numbers;
  /// these widgets paint the right half behind the code itself so together
  /// they read as one continuous tonal-red row — see the class-level
  /// "Gutter/scroll sync" note and [LayrzCodeGutter]'s "Precedence" note
  /// (an error always wins over the current-line highlight, which this
  /// method does not paint at all — the current-line highlight is a gutter-
  /// only affordance, matching prior behavior).
  ///
  /// Each returned widget is independently positioned at
  /// `topInset + (line - 1) * lineHeight`, [lineHeight] tall, spanning the
  /// full width — rather than one [Column] sized to the sum of every line —
  /// so this never has to match the [Stack]'s own height exactly (which is
  /// derived from the editable text and can differ from the estimated
  /// [lineHeight] by a fractional pixel).
  List<Widget> _buildErrorLineBackgrounds({
    required int lineCount,
    required double lineHeight,
    required double topInset,
  }) {
    final errorByLine = LayrzCodeGutter.errorsByLine(widget.errors);
    if (errorByLine.isEmpty) {
      return const [];
    }

    final errorBackground = _codeTheme.errorColor.withValues(alpha: 0.12);

    return [
      for (var line = 1; line <= lineCount; line++)
        if (errorByLine.containsKey(line))
          Positioned(
            top: topInset + (line - 1) * lineHeight,
            left: 0,
            right: 0,
            height: lineHeight,
            child: ColoredBox(color: errorBackground),
          ),
    ];
  }
}
