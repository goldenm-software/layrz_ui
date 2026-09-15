import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/input_footer_slot.dart';
import 'otp_slot.dart';
import 'web/otp_web_field.dart';

/// The fixed number of digit slots a [LayrzOtpInput] renders.
const int _kOtpLength = 6;

/// A Material-free, animated 6-digit one-time-passcode (OTP) input.
///
/// [LayrzOtpInput] renders six separated digit slots that mirror the value of a single
/// hidden text field. It follows the "own controller + bare [EditableText] + painted
/// slots on top" pattern rather than composing `LayrzInputChrome` (frozen, built for
/// exactly one child) or `LayrzEditableField` (built to render visible, selectable text):
///
/// - A bare [EditableText] owns the value, focus, keyboard, formatters and autofill. It is
///   painted fully transparent (text, cursor, and selection colors), has no selection
///   handles, and no context menu — nothing about it is meant to be seen or interacted with
///   directly. It sits at the bottom of a [Stack].
/// - On top, an [IgnorePointer]-wrapped [Row] of six [OtpSlot] widgets paints one character
///   each, reading from [value]. Taps fall through the ignored row to a [GestureDetector]
///   covering the whole stack, which requests focus and moves the caret to the end of the
///   text — so tapping anywhere in the row starts (or resumes) typing at the right position.
///
/// **Disposal contract** (mirrors [LayrzNumberInput]): when [controller] or [focusNode] is
/// null, this widget creates its own instance and disposes it in [dispose]. A caller-supplied
/// controller or focus node is never disposed by this widget, and its listeners are always
/// removed — from the outgoing instance — before a new one is attached, both on a
/// [controller]/[focusNode] swap in [didUpdateWidget] and in [dispose] itself.
///
/// **Value contract**: [value] is the current code as plain digits (or `null`/empty for no
/// input yet). [onChanged] fires with the raw code on every change — including partial
/// entries. [onCompleted] fires once, each time the code becomes fully filled (all six
/// slots non-empty), with the completed code.
///
/// **Autofill**: the hidden field always declares `autofillHints: [AutofillHints.oneTimeCode]`
/// — this is not configurable. [LayrzOtpInput] does not create its own `AutofillGroup`; wrap
/// it (or the surrounding form) in a caller-supplied `LayrzForm` to participate in
/// browser/OS one-time-code autofill.
///
/// **Web**: on `kIsWeb`, this widget renders [LayrzOtpWebField] instead of the
/// EditableText-plus-slots stack described above. Flutter web's own text-editing stack
/// exposes no real DOM `<input>` for a password manager to detect, so [LayrzOtpWebField]
/// renders six genuine, password-manager-visible HTML `<input autocomplete="one-time-code">`
/// boxes — one per digit, each carrying Dashlane's `data-form-type="otp"` SAWF annotation
/// (see decision D82 in `engineering/decisions.md`) — with auto-advance, backspace, and
/// autofill/paste distribution across the boxes. The native path described above is
/// completely unaffected by this branch — see [LayrzOtpWebField]'s own documentation for
/// the six-input mechanism. Wrap this widget (or the surrounding form) in a caller-supplied
/// `LayrzForm` on web too, exactly as on native, so the browser groups the boxes with any
/// sibling `LayrzUsernameInput`/`LayrzPasswordInput` into one credential flow.
class LayrzOtpInput extends StatefulWidget {
  /// The current OTP code, as a string of digits (up to 6 characters).
  ///
  /// When null or shorter than 6 characters, the remaining slots render empty.
  final String? value;

  /// Callback fired with the raw code every time the value changes, including partial entries.
  final ValueChanged<String>? onChanged;

  /// Callback fired once the code reaches all 6 digits, with the completed code.
  ///
  /// Not fired again for the same completed value; fires again only after the value becomes
  /// incomplete and is then completed again.
  final ValueChanged<String>? onCompleted;

  /// The label text displayed above the slot row.
  ///
  /// Rendered only when non-null, reproducing the small label markup `LayrzInputChrome` uses
  /// (a [RichText] in `tokens.typography.label`/`tokens.colors.fg2`, wrapped in
  /// [ExcludeSemantics] and [SelectionContainer.disabled]) rather than reusing the chrome
  /// itself, which is frozen and built for exactly one child.
  final String? labelText;

  /// Whether the field is marked as required.
  ///
  /// When true and [labelText] is set, a danger-colored `*` is appended to the label, and the
  /// hidden field's semantic label is suffixed with the localized required indicator.
  final bool isRequired;

  /// Whether the field is disabled (not editable, not focusable).
  final bool disabled;

  /// Whether the field is read-only (not editable, but still focusable).
  final bool readOnly;

  /// The list of error messages to display below the slot row.
  ///
  /// A non-empty list also paints every slot in its danger state, regardless of caret
  /// position.
  final List<String> errors;

  /// Helper text displayed below the slot row.
  ///
  /// Hidden whenever [errors] is non-empty (errors take precedence) or [hideDetails] is true.
  final String? helperText;

  /// Whether to hide the error message block and helper text entirely.
  final bool hideDetails;

  /// Whether the field should request focus as soon as it is built.
  final bool autofocus;

  /// Callback fired when the hidden field gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// The text editing controller backing the hidden field.
  ///
  /// If null, a controller is created and disposed by this widget. See the disposal contract
  /// documented on [LayrzOtpInput].
  final TextEditingController? controller;

  /// The focus node backing the hidden field.
  ///
  /// If null, a focus node is created and disposed by this widget. See the disposal contract
  /// documented on [LayrzOtpInput].
  final FocusNode? focusNode;

  /// An explicit HTML `<form>` id override for the underlying DOM field on web.
  ///
  /// Normally left null: the web path resolves the group id automatically from the
  /// nearest enclosing `LayrzLoginWebGroup` (itself normally supplied by wrapping this
  /// widget in a `LayrzForm`) via `LayrzLoginWebGroup.maybeOf`. Set this only when the
  /// caller needs to force a specific id outside that provider. Has no effect on native,
  /// where autofill grouping is `LayrzForm`'s own `AutofillGroup`.
  final String? formId;

  /// Creates a new [LayrzOtpInput] with the given properties.
  const LayrzOtpInput({
    super.key,
    this.value,
    this.onChanged,
    this.onCompleted,
    this.labelText,
    this.isRequired = false,
    this.disabled = false,
    this.readOnly = false,
    this.errors = const [],
    this.helperText,
    this.hideDetails = false,
    this.autofocus = false,
    this.onFocusChanged,
    this.controller,
    this.focusNode,
    this.formId,
  });

  @override
  State<LayrzOtpInput> createState() => _LayrzOtpInputState();
}

class _LayrzOtpInputState extends State<LayrzOtpInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  /// True while this widget is writing to [_controller] itself, so the resulting
  /// [_handleControllerChanged] call is known to be an echo of our own write rather than
  /// user input or an external controller mutation — mirrors `_isInternalUpdate` in
  /// `LayrzNumberInput`. Without this guard, a [value] prop change flowing through
  /// [didUpdateWidget] into [_updateControllerFromValue] would re-emit [onChanged] and
  /// [onCompleted] for a change the caller itself just made.
  bool _isInternalUpdate = false;

  /// The set of interaction states (focused/disabled) fed to [LayrzInputStyleSpec.resolve]
  /// for every slot, mirroring `_states` in `LayrzNumberInput`.
  final Set<WidgetState> _states = {};

  /// Whether the last-observed value was fully filled, so [_maybeFireCompleted] fires
  /// [LayrzOtpInput.onCompleted] only on the empty/partial-to-full transition, not on every
  /// rebuild while already complete.
  bool _wasComplete = false;

  /// The text last forwarded to [LayrzOtpInput.onChanged]/[_maybeFireCompleted], so
  /// [_handleControllerChanged] can tell an actual value edit apart from a
  /// selection-only or composing-region-only controller notification.
  ///
  /// [TextEditingController] notifies its listeners on ANY [TextEditingValue] change,
  /// not just a text edit — moving the caret, or a focus-driven selection update with no
  /// text change, fires the same listener. Without this guard, gaining focus (which
  /// collapses/sets the selection) could re-emit [LayrzOtpInput.onChanged] with the
  /// CURRENT text even though nothing was typed — spuriously firing `onChanged('')` on a
  /// bare focus gain when the field starts empty. Seeded in [initState] from the
  /// controller's starting text so the very first real edit is the first change this
  /// tracks against, not against an implicit empty string.
  late String _lastEmittedText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateControllerFromValue(widget.value);
    _wasComplete = _digitsOf(_controller.text).length >= _kOtpLength;
    _lastEmittedText = _controller.text;
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(LayrzOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      // The listener must always come off the outgoing controller, regardless of ownership —
      // see the identical reasoning in LayrzNumberInput's didUpdateWidget.
      _controller.removeListener(_handleControllerChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleControllerChanged);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChanged);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
    }

    if (widget.value != oldWidget.value) {
      _updateControllerFromValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Extracts up to [_kOtpLength] digit characters from arbitrary text.
  String _digitsOf(String text) {
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length > _kOtpLength ? digitsOnly.substring(0, _kOtpLength) : digitsOnly;
  }

  /// Writes [value] into [_controller], guarding the write with [_isInternalUpdate] so the
  /// resulting notification does not re-emit [onChanged]/[onCompleted].
  void _updateControllerFromValue(String? value) {
    final digits = _digitsOf(value ?? '');
    if (_controller.text == digits) {
      return;
    }
    _isInternalUpdate = true;
    _controller.value = TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
    _isInternalUpdate = false;
    // Keeps [_lastEmittedText] truthful about what the caller already knows, even though
    // this internally-driven write never calls [_handleControllerChanged]'s emitting
    // branch — otherwise a later REAL edit that happens to retype this same text would
    // be wrongly treated as "no change" by that method's gate.
    _lastEmittedText = digits;
  }

  /// Handles every change notification from [_controller], including caret-only moves
  /// and selection-only changes (e.g. a bare focus gain, which collapses/sets the
  /// selection without editing any text).
  ///
  /// Rebuilds unconditionally (cheap: six slots) so the focused-slot highlight tracks the
  /// caret, but forwards to [widget.onChanged] / [_maybeFireCompleted] only when the
  /// DIGITS actually changed since the last time they were forwarded (tracked in
  /// [_lastEmittedText]) — not on every notification. Without this gate, a focus-only
  /// notification on an otherwise-untouched field would spuriously re-emit `onChanged`
  /// with the current (possibly unchanged, or empty) text. Internally-driven writes are
  /// still skipped entirely via [_isInternalUpdate], exactly as before.
  void _handleControllerChanged() {
    if (!_isInternalUpdate && _controller.text != _lastEmittedText) {
      _lastEmittedText = _controller.text;
      widget.onChanged?.call(_controller.text);
      _maybeFireCompleted(_controller.text);
    }
    setState(() {});
  }

  /// Fires [LayrzOtpInput.onCompleted] exactly on the transition into a fully-filled code.
  void _maybeFireCompleted(String text) {
    final isComplete = text.length >= _kOtpLength;
    if (isComplete && !_wasComplete) {
      widget.onCompleted?.call(text);
    }
    _wasComplete = isComplete;
  }

  /// Keeps [_states] in sync with [WidgetState.focused] and forwards to
  /// [LayrzOtpInput.onFocusChanged].
  void _handleFocusChanged() {
    setState(() {
      if (_focusNode.hasFocus) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
      }
    });
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  /// Requests focus on the hidden field and moves the caret to the end of the current text,
  /// so a tap anywhere in the slot row resumes typing at the right position.
  void _handleTap() {
    if (widget.disabled) {
      return;
    }
    _focusNode.requestFocus();
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (kIsWeb) {
      return _buildWeb(tokens);
    }

    final l10n = LayrzUiL10n.of(context);
    final hasErrors = widget.errors.isNotEmpty;
    final isDisabled = widget.disabled;

    if (isDisabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    final isFocused = _focusNode.hasFocus;
    final caretIndex = _controller.text.length.clamp(0, _kOtpLength - 1);

    final semanticLabel = widget.isRequired && widget.labelText != null
        ? '${widget.labelText}, ${l10n.inputsRequiredIndicator}'
        : widget.labelText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) _buildLabel(tokens),
        if (widget.labelText != null) SizedBox(height: tokens.spacing.sp2),
        Semantics(
          label: semanticLabel,
          textField: true,
          enabled: !isDisabled,
          readOnly: widget.readOnly,
          value: _controller.text,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildHiddenField(tokens),
                IgnorePointer(
                  // The painted slots are purely decorative: the outer [Semantics] node
                  // above already carries this field's accessible label/value (mirroring
                  // how [LayrzInputChrome] excludes its own visual-only children), so
                  // without this the six [OtpSlot] [Text] widgets would otherwise leak a
                  // second, redundant "1\n2\n3"-style label onto the hidden
                  // [EditableText]'s own semantics node underneath them.
                  child: ExcludeSemantics(
                    child: _buildSlotRow(
                      tokens: tokens,
                      hasErrors: hasErrors,
                      isFocused: isFocused,
                      caretIndex: caretIndex,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        LayrzInputFooterSlot(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
          helperText: widget.helperText,
        ),
      ],
    );
  }

  /// Builds the web presentation: [LayrzOtpWebField] (six real, password-manager-visible
  /// DOM `<input>` boxes, one per digit), wrapped in the same label/footer chrome the
  /// native path above uses — see [LayrzOtpInput]'s class doc, "Web" section, and
  /// [LayrzOtpWebField]'s own documentation for the six-input mechanism. This is a purely
  /// additive branch: nothing in the native `build()` path above is read or altered by
  /// this method.
  Widget _buildWeb(LayrzTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) _buildLabel(tokens),
        if (widget.labelText != null) SizedBox(height: tokens.spacing.sp2),
        SizedBox(
          height: tokens.spacing.sp5 * 1.25,
          child: LayrzOtpWebField(
            value: _controller.text,
            onChanged: (value) {
              // Mirrors `LayrzUsernameInput`/`LayrzPasswordInput`'s own web `onChanged`
              // pattern: the DOM `<input>` is the source of truth on web, so `_controller`
              // is updated directly (not via `_updateControllerFromValue`, which exists
              // for the native path's prop-vs-controller reconciliation and would apply
              // an irrelevant internal-update guard here) purely so `_controller.text`
              // stays available to callers reading it directly (e.g. `LayrzForm` demos).
              _controller.text = value;
              widget.onChanged?.call(value);
            },
            onCompleted: widget.onCompleted,
            disabled: widget.disabled,
            errors: widget.errors,
            readOnly: widget.readOnly,
            formId: widget.formId,
            tokens: tokens,
          ),
        ),
        LayrzInputFooterSlot(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
          helperText: widget.helperText,
        ),
      ],
    );
  }

  /// Reproduces the small label markup `LayrzInputChrome` uses, without modifying that
  /// frozen file. See the class doc on [LayrzOtpInput.labelText].
  Widget _buildLabel(LayrzTokens tokens) {
    return ExcludeSemantics(
      child: SelectionContainer.disabled(
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

  /// Builds the bottom-of-stack hidden [EditableText] that owns the value, focus, keyboard
  /// input, formatters and autofill. Fully transparent so no glyph, cursor, or selection
  /// paints through the [OtpSlot] row on top of it.
  Widget _buildHiddenField(LayrzTokens tokens) {
    return SizedBox(
      height: tokens.spacing.sp5 * 2,
      child: EditableText(
        controller: _controller,
        focusNode: _focusNode,
        style: tokens.typography.headline.copyWith(color: const Color(0x00000000)),
        cursorColor: const Color(0x00000000),
        backgroundCursorColor: const Color(0x00000000),
        selectionColor: const Color(0x00000000),
        showCursor: false,
        rendererIgnoresPointer: true,
        readOnly: widget.readOnly || widget.disabled,
        autofocus: widget.autofocus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(_kOtpLength),
        ],
        autofillHints: const [AutofillHints.oneTimeCode],
        selectionControls: null,
        contextMenuBuilder: null,
        enableSuggestions: false,
        autocorrect: false,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the top-of-stack row of six [OtpSlot] widgets, one per digit position.
  Widget _buildSlotRow({
    required LayrzTokens tokens,
    required bool hasErrors,
    required bool isFocused,
    required int caretIndex,
  }) {
    final digits = _controller.text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _kOtpLength; i++) ...[
          if (i > 0) SizedBox(width: tokens.spacing.sp2),
          SizedBox(
            width: tokens.spacing.sp5,
            height: tokens.spacing.sp5 * 1.25,
            child: OtpSlot(
              character: i < digits.length ? digits[i] : null,
              isFocused: isFocused && i == caretIndex,
              hasErrors: hasErrors,
              readOnly: widget.readOnly,
              disabled: widget.disabled,
              tokens: tokens,
            ),
          ),
        ],
      ],
    );
  }
}
