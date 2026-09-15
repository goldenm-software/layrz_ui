/// Web implementation of `LayrzOtpInput`'s six-input DOM OTP field.
///
/// Compiled only on web (selected via the conditional export in `otp_web_field.dart`), so
/// it may freely use `dart:ui_web`, `dart:js_interop`, and `package:web`.
///
/// ## Why six real inputs
/// Unlike `LayrzUsernameInput`/`LayrzPasswordInput` (one DOM `<input>` each), a one-time
/// code reads best as six discrete boxes, and a password manager (Dashlane in particular)
/// decorates and offers to fill each recognized field in place. Rendering six real,
/// visible `<input>` elements — every one an `autocomplete="one-time-code"` field carrying
/// Dashlane's `data-form-type="otp"` SAWF annotation — keeps the manager's own affordance
/// (icon, fill dropdown) anchored to the boxes the user sees, instead of to a single
/// hidden field behind painted slots. See decision D82 in `engineering/decisions.md`.
///
/// ## Auto-advance, backspace, and autofill/paste distribution
/// Each box holds at most one digit. Typing a digit advances focus to the next box;
/// backspace on an empty box moves focus back and clears the previous one. A multi-digit
/// value arriving in a single box at once — from a password-manager autofill or a paste of
/// the whole code — is distributed across the boxes from that box's index forward, and
/// focus lands on the first still-empty box (or the last box when the code completes).
/// Every box carries `autocomplete="one-time-code"`, so whichever box the manager fills,
/// the distribution logic spreads the code across all six.
///
/// ## Value round-trip
/// The concatenation of the six boxes' digits is the value. Any change re-aggregates and
/// forwards it through [onChanged]; [onCompleted] fires once per empty/partial-to-full
/// transition, mirroring `LayrzOtpInput`'s own `_maybeFireCompleted` semantics.
library;

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:web/web.dart' as web;

import '../../login/web/login_web_group.dart';

/// The fixed number of digit inputs this field renders.
const int _kOtpWebLength = 6;

/// Web six-input OTP field backed by real HTML `<input>` elements.
///
/// This is the canonical `LayrzOtpWebField` symbol resolved by `otp_web_field.dart`'s
/// conditional export on web targets. Must only be used behind a `kIsWeb` check — it
/// registers a `dart:ui_web` platform view factory, which has no meaning off web.
class LayrzOtpWebField extends StatefulWidget {
  /// The current OTP code, as a string of digits (up to six characters), used to seed the
  /// DOM inputs once. After that the `<input>`s are the source of truth; changes flow back
  /// out through [onChanged].
  final String value;

  /// Fired with the raw aggregated code every time any digit box changes, including
  /// partial entries.
  final ValueChanged<String>? onChanged;

  /// Fired once the aggregated code reaches all six digits.
  ///
  /// Not fired again for the same completed value; fires again only after the value
  /// becomes incomplete and is then completed again.
  final ValueChanged<String>? onCompleted;

  /// Whether the field is disabled — every box is non-editable and non-focusable.
  final bool disabled;

  /// The list of error messages associated with the field. A non-empty list selects every
  /// box's danger visual state (mirroring [LayrzOtpInput.errors]); the error text itself is
  /// rendered by `LayrzOtpInput`'s own footer, not here.
  final List<String> errors;

  /// Whether the field is read-only — boxes are not editable but stay focusable.
  final bool readOnly;

  /// An explicit HTML `<form>` id override for the boxes.
  ///
  /// Normally left null: resolved from the nearest enclosing [LayrzLoginWebGroup] (itself
  /// normally supplied by a wrapping `LayrzForm`) via [LayrzLoginWebGroup.maybeOf].
  final String? formId;

  /// The resolved design tokens the DOM boxes read for color, radius, and border.
  final LayrzTokens tokens;

  /// Creates a [LayrzOtpWebField].
  const LayrzOtpWebField({
    super.key,
    required this.value,
    this.onChanged,
    this.onCompleted,
    this.disabled = false,
    this.errors = const [],
    this.readOnly = false,
    this.formId,
    required this.tokens,
  });

  @override
  State<LayrzOtpWebField> createState() => _LayrzOtpWebFieldState();
}

class _LayrzOtpWebFieldState extends State<LayrzOtpWebField> {
  /// Incrementing id so every instance registers its own uniquely named platform view
  /// factory.
  static int _idCounter = 0;

  late final String _viewType;

  /// The CSS class shared by this field's six boxes, so the injected `:-webkit-autofill`
  /// override rule targets exactly them and nothing else on the page.
  String get _autofillClass => '$_viewType-autofill';

  /// The CSS class that runs the digit-entry "pop" animation, and the `@keyframes` name it
  /// references — both scoped to this instance's view type.
  String get _popClass => '$_viewType-pop';
  String get _popKeyframes => '$_viewType-pop-kf';

  /// The modifier classes toggled per box for the focused and error visual states. They
  /// are compound-selector rules (`.base.modifier`) with `!important`, so they win over
  /// both the base rule and any style a password manager injects.
  String get _focusedClass => '$_viewType-focused';
  String get _errorClass => '$_viewType-error';

  /// Re-triggers the digit-entry pop animation on [input].
  ///
  /// Removing the class, forcing a reflow, then re-adding it restarts the CSS animation
  /// even when the class is already present (a second digit into the same box), matching
  /// the native `AnimatedSwitcher` re-running its transition on every keyed child change.
  void _pop(web.HTMLInputElement input) {
    input.classList.remove(_popClass);
    // Force a reflow so the browser registers the class removal before it is re-added,
    // which is what actually restarts the animation.
    input.offsetWidth;
    input.classList.add(_popClass);
  }

  /// The six digit `<input>` elements, in order, once the platform view has been built.
  final List<web.HTMLInputElement> _inputs = [];

  /// The digits last written by [_distribute], kept so the follow-up per-box re-injection
  /// a password manager performs after its initial full-code fill can be detected and
  /// reverted rather than allowed to corrupt the distributed value.
  ///
  /// Confirmed from live logging: Dashlane first fills box 0 with the whole code (which
  /// [_distribute] correctly spreads), then immediately goes back and re-injects into each
  /// box individually with SHIFTED digits, scrambling the result. While [_distributeGuardUntilMs]
  /// is in the future, a single-char `input` on a box whose value does not match what
  /// [_distribute] wrote is treated as one of those spurious re-injections and reverted.
  final List<String> _distributedDigits = List<String>.filled(_kOtpWebLength, '');

  /// Wall-clock deadline (ms, `performance.now()`), until which per-box re-injections are
  /// reverted to the distributed value. Zero when no distribute is being protected.
  double _distributeGuardUntilMs = 0;

  /// This field's resolved `<form>` id, cached from [didChangeDependencies] since the
  /// platform view factory runs at a time controlled by the engine, where no
  /// [BuildContext] lookup is valid.
  String? _effectiveFormId;

  /// Whether the last-observed aggregate value was fully filled, so [_emit] fires
  /// [LayrzOtpWebField.onCompleted] only on the empty/partial-to-full transition.
  bool _wasComplete = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'layrz-otp-web-field-${_idCounter++}';
    _wasComplete = widget.value.length >= _kOtpWebLength;
    _registerViewFactory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effectiveFormId = widget.formId ?? LayrzLoginWebGroup.maybeOf(context);
    _associateForm();
  }

  @override
  void didUpdateWidget(covariant LayrzOtpWebField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formId != oldWidget.formId) {
      _effectiveFormId = widget.formId ?? LayrzLoginWebGroup.maybeOf(context);
      _associateForm();
    }
    if (_inputs.isNotEmpty) {
      // A programmatic reset from outside (value cleared) re-seeds the boxes; a non-empty
      // external value is not pushed back down (the boxes are the source of truth while
      // the user types), matching the single-field web fields' seed-once contract.
      if (widget.value.isEmpty && _aggregate().isNotEmpty) {
        for (final input in _inputs) {
          input.value = '';
        }
        _restyleAll();
      }
      for (final input in _inputs) {
        input.disabled = widget.disabled;
        input.readOnly = widget.readOnly;
      }
      if (widget.tokens != oldWidget.tokens || widget.errors.isNotEmpty != oldWidget.errors.isNotEmpty) {
        _restyleAll();
      }
    }
  }

  /// Associates every box with the resolved `<form>` id (or removes the association when
  /// there is none), so a password manager groups the boxes with any sibling
  /// username/password fields into one credential flow.
  void _associateForm() {
    final formId = _effectiveFormId;
    for (final input in _inputs) {
      if (formId == null) {
        if (input.hasAttribute('form')) input.removeAttribute('form');
      } else {
        input.setAttribute('form', formId);
      }
    }
  }

  /// The current aggregate code: the six boxes' values concatenated.
  String _aggregate() {
    final buffer = StringBuffer();
    for (final input in _inputs) {
      buffer.write(input.value);
    }
    return buffer.toString();
  }

  /// Re-aggregates the boxes, forwards the value through [onChanged], and fires
  /// [onCompleted] on the transition into a complete code.
  void _emit() {
    final value = _aggregate();
    widget.onChanged?.call(value);
    final isComplete = value.length >= _kOtpWebLength;
    if (isComplete && !_wasComplete) {
      widget.onCompleted?.call(value);
    }
    _wasComplete = isComplete;
  }

  /// Distributes a whole [digits] code across the boxes from the first box onward, one
  /// digit per box, and focuses the last filled box (or the first still-empty one).
  ///
  /// This is the path both a paste and a password-manager autofill take: the manager fills
  /// the whole code into box 0, and its `input` listener routes the multi-char value here
  /// so it spreads across all six from index 0 — mirroring the canonical six-field OTP
  /// interception (fill `boxes[i] = digits[i]`), which is more robust than spreading from
  /// whichever box happened to receive it.
  void _distribute(String digits, int startIndex) {
    final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
    final count = clean.length < _kOtpWebLength ? clean.length : _kOtpWebLength;
    for (var i = 0; i < _kOtpWebLength; i++) {
      final next = i < count ? clean[i] : '';
      if (_inputs[i].value != next) {
        _inputs[i].value = next;
        if (next.isNotEmpty) _pop(_inputs[i]);
      }
      _distributedDigits[i] = next;
    }
    // Protect the freshly-distributed values from the password manager's follow-up
    // per-box re-injection burst (see [_distributedDigits]). 1000ms covers the burst
    // observed in logging (all six re-injections landed within ~750ms of the initial fill,
    // spaced ~100-300ms apart) with margin, without lingering long enough to interfere with
    // the user then editing a box by hand.
    _distributeGuardUntilMs = web.window.performance.now() + 1000;
    _restyleAll();
    final firstEmpty = _inputs.indexWhere((input) => input.value.isEmpty);
    final focusTarget = firstEmpty == -1 ? _kOtpWebLength - 1 : firstEmpty;
    _inputs[focusTarget].focus();
    _emit();
  }

  /// Registers the platform view factory that builds the six-input DOM row for this
  /// instance.
  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final tokens = widget.tokens;
      final gapPx = tokens.spacing.sp2;

      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.style.display = 'flex';
      container.style.setProperty('gap', '${gapPx}px');
      container.style.alignItems = 'center';
      container.style.justifyContent = 'center';
      container.style.width = '100%';
      container.style.height = '100%';

      // Override the browser's `:-webkit-autofill` styling, which a password manager
      // triggers on fill: it paints its own (light-theme) yellow background and text
      // color, which leaves the digit invisible in dark mode. The large inset `box-shadow`
      // repaints the box's interior with the resting fill, and `-webkit-text-fill-color`
      // forces the digit to the resting text color — both resolved from tokens, so this
      // is correct in light AND dark. Scoped to `_autofillClass` so it targets only this
      // field's boxes. The `transition` delay keeps the browser from re-flashing its own
      // background on top after the fill.
      // The browser paints its own light-yellow `:-webkit-autofill` background when a
      // password manager fills the field, and that yellow cannot be reliably removed (the
      // `box-shadow` override loses to it in current Chromium). So rather than fight the
      // yellow, we WORK WITH it: force the autofilled digit to a near-black text color so
      // it contrasts against the light-yellow highlight — in BOTH light and dark mode,
      // since the autofill background is always light regardless of the app theme. The
      // dark text is the design system's own light-surface foreground (`LayrzColorTokens
      // .light().fg1`), so it stays token-driven rather than a magic hex. Once the box's
      // value is next set via JS (`_distribute`, backspace, etc.) the `:-webkit-autofill`
      // state clears and the box returns to its normal token styling.
      // Dashlane overrides our INLINE styles by injecting its own author stylesheet rule
      // with `!important` (an inline style loses to an author `!important`). The only way to
      // win is our OWN class rule that is also `!important`. So we repaint the box entirely
      // in our own token colors here — winning the fill (`background` + the
      // `:-webkit-autofill` inset `box-shadow`) AND the text (`color` +
      // `-webkit-text-fill-color`) with `!important`, so a Dashlane-filled box reads exactly
      // like our own box (dark token surface, light token digit) instead of Dashlane's
      // light-yellow-with-its-own-text. Because we win the background, the digit stays the
      // normal light token color — it is legible on our dark surface, in dark AND light
      // mode. The values here are the RESTING token colors; the per-box focused/error
      // variants are still applied inline by `_styleInput` (which Dashlane does not touch,
      // since it only overrides the fill/text of a field it filled).
      final restSpec = LayrzInputStyleSpec.resolve(
        states: const <WidgetState>{},
        tokens: tokens,
        hasErrors: widget.errors.isNotEmpty,
        readOnly: widget.readOnly,
      );
      final restText = _toCssColor(restSpec.textColor);
      final restFill = _toCssColor(restSpec.backgroundColor);
      final primaryCss = _toCssColor(tokens.colors.primary);
      // Focused fill: the same subtle primary-tonal wash the native OtpSlot uses.
      final focusFill = _toCssColor(
        tokens.colors.primary.withOpacityValue(tokens.colors.tonalOpacity).flattenOn(restSpec.backgroundColor),
      );
      // Error colors: resolved from the same spec with an error state.
      final errorSpec = LayrzInputStyleSpec.resolve(
        states: const <WidgetState>{},
        tokens: tokens,
        hasErrors: true,
        readOnly: widget.readOnly,
      );
      final errorText = _toCssColor(errorSpec.textColor);
      final errorFill = _toCssColor(errorSpec.backgroundColor);
      final errorBorder = _toCssColor(errorSpec.borderColor);
      final boxStyle = web.document.createElement('style') as web.HTMLStyleElement;
      final popMs = tokens.motion.dTransition.inMilliseconds;
      boxStyle.textContent =
          '.$_autofillClass,'
          '.$_autofillClass:-webkit-autofill,'
          '.$_autofillClass:-webkit-autofill:hover,'
          '.$_autofillClass:-webkit-autofill:focus,'
          '.$_autofillClass:-webkit-autofill:active {'
          'color: $restText !important;'
          '-webkit-text-fill-color: $restText !important;'
          'background-color: $restFill !important;'
          '-webkit-box-shadow: inset 0 0 0 1000px $restFill !important;'
          'box-shadow: inset 0 0 0 1000px $restFill !important;'
          'caret-color: $primaryCss !important; }'
          // Focused modifier — a compound selector (`.class.focused`) so it is MORE
          // specific than the base rule above and its `!important` fill wins, giving the
          // caret box the subtle primary-tonal highlight without an inline style Dashlane
          // could override.
          '.$_autofillClass.$_focusedClass,'
          '.$_autofillClass.$_focusedClass:-webkit-autofill {'
          'background-color: $focusFill !important;'
          '-webkit-box-shadow: inset 0 0 0 1000px $focusFill !important;'
          'box-shadow: inset 0 0 0 1000px $focusFill !important;'
          'border-color: $primaryCss !important; }'
          // Error modifier — every box paints danger together.
          '.$_autofillClass.$_errorClass,'
          '.$_autofillClass.$_errorClass:-webkit-autofill {'
          'color: $errorText !important;'
          '-webkit-text-fill-color: $errorText !important;'
          'background-color: $errorFill !important;'
          '-webkit-box-shadow: inset 0 0 0 1000px $errorFill !important;'
          'box-shadow: inset 0 0 0 1000px $errorFill !important;'
          'border-color: $errorBorder !important; }'
          // The digit "pop" keyframes, mirroring the native OtpSlot's `AnimatedSwitcher`.
          '@keyframes $_popKeyframes {'
          'from { transform: scale(0.6); opacity: 0; }'
          'to { transform: scale(1); opacity: 1; } }'
          '.$_popClass { animation: $_popKeyframes ${popMs}ms ease-out; }';
      container.appendChild(boxStyle);

      _inputs.clear();
      for (var i = 0; i < _kOtpWebLength; i++) {
        final input = web.document.createElement('input') as web.HTMLInputElement;
        input.type = 'text';
        // Canonical six-field OTP pattern: ONLY the first box carries
        // `autocomplete="one-time-code"`, and every box is `maxlength="1"`. The password
        // manager / browser recognizes the single one-time-code field (box 0), fills the
        // code, and spreads it across the following `maxlength="1"` inputs in DOM order.
        // (Six one-time-code fields instead produce six copies of the whole value — an
        // empirically confirmed failure mode, which is why only box 0 is tagged.)
        final isAutofillTarget = i == 0;
        if (isAutofillTarget) {
          input.autocomplete = 'one-time-code';
          // Dashlane SAWF classifier-bypass annotation (https://dashlane.github.io/SAWF/)
          // — on the single autofill target only. See decision D82.
          input.setAttribute('data-form-type', 'otp');
        } else {
          input.autocomplete = 'off';
        }
        input.inputMode = 'numeric';
        // Boxes 1-5 hold exactly one digit. Box 0 is left UNCAPPED so a password manager's
        // autofill or a paste of the whole code lands in it intact and reaches the `input`
        // listener as a multi-char value, which `_distribute` then spreads across all six
        // (confirmed necessary: with `maxlength=1` on box 0 the browser truncates the fill
        // to one digit before the listener ever sees it, and Dashlane-on-desktop does not
        // spread the code across the following boxes on its own the way iOS Safari does).
        if (i != 0) {
          input.maxLength = 1;
        }
        input.name = 'otp-${i + 1}';
        input.id = '$_viewType-$i';
        input.setAttribute('pattern', '[0-9]');
        input.setAttribute('aria-label', 'Digit ${i + 1} of $_kOtpWebLength');
        input.className = _autofillClass;
        input.value = i < widget.value.length ? widget.value[i] : '';
        input.disabled = widget.disabled;
        input.readOnly = widget.readOnly;

        _styleInput(input);

        final index = i;
        input.addEventListener(
          'input',
          (web.Event event) {
            final digitsOnly = input.value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly.length > 1) {
              // A multi-digit value in one box = autofill or paste of the whole code:
              // distribute it across the boxes from here.
              _distribute(digitsOnly, index);
              return;
            }
            // Guard against the password manager's post-fill per-box re-injection burst:
            // within the guard window, if this box's incoming value disagrees with what
            // `_distribute` just wrote here, it is a spurious re-injection — revert it and
            // bail, keeping the correctly-distributed code intact. A user editing the box
            // by hand after the window closes is unaffected.
            if (web.window.performance.now() < _distributeGuardUntilMs && digitsOnly != _distributedDigits[index]) {
              input.value = _distributedDigits[index];
              return;
            }
            // Clamp this box to a single digit; a second keystroke replaces the digit
            // rather than growing the box's value.
            if (input.value != digitsOnly) {
              input.value = digitsOnly;
            }
            _styleInput(input, focused: true);
            if (input.value.isNotEmpty) {
              _pop(input);
              if (index < _kOtpWebLength - 1) {
                _inputs[index + 1].focus();
              }
            }
            _emit();
          }.toJS,
        );

        input.addEventListener(
          'keydown',
          (web.Event event) {
            final keyboardEvent = event as web.KeyboardEvent;
            if (keyboardEvent.key == 'Backspace' && input.value.isEmpty && index > 0) {
              keyboardEvent.preventDefault();
              _inputs[index - 1].value = '';
              _styleInput(_inputs[index - 1]);
              _inputs[index - 1].focus();
              _emit();
            } else if (keyboardEvent.key == 'ArrowLeft' && index > 0) {
              keyboardEvent.preventDefault();
              _inputs[index - 1].focus();
            } else if (keyboardEvent.key == 'ArrowRight' && index < _kOtpWebLength - 1) {
              keyboardEvent.preventDefault();
              _inputs[index + 1].focus();
            }
          }.toJS,
        );

        input.addEventListener(
          'paste',
          (web.Event event) {
            final clipboardEvent = event as web.ClipboardEvent;
            final pasted = clipboardEvent.clipboardData?.getData('text') ?? '';
            if (pasted.isNotEmpty) {
              clipboardEvent.preventDefault();
              _distribute(pasted, index);
            }
          }.toJS,
        );

        input.addEventListener(
          'focus',
          (web.Event event) {
            _styleInput(input, focused: true);
          }.toJS,
        );
        input.addEventListener(
          'blur',
          (web.Event event) {
            _styleInput(input);
          }.toJS,
        );

        _inputs.add(input);
        container.appendChild(input);
      }

      _associateForm();
      return container;
    });
  }

  /// Applies the token-derived per-box styling, resolved from [LayrzInputStyleSpec] so the
  /// DOM boxes track the same fill/border/text colors as the native [OtpSlot]s.
  void _styleInput(web.HTMLInputElement input, {bool focused = false}) {
    final tokens = widget.tokens;
    // Geometry and font are set inline — a password manager never overrides these, only
    // the fill/text COLORS of a field it filled. Every color is handled by the `!important`
    // class rules instead (base + `_focusedClass`/`_errorClass` modifiers), toggled below,
    // which win over Dashlane's injected `!important` styling. The base border color is set
    // inline as the resting transparent; the focused/error border comes from the modifier
    // rules.
    input.style.width = '${tokens.spacing.sp5}px';
    input.style.height = '${tokens.spacing.sp5 * 1.25}px';
    input.style.boxSizing = 'border-box';
    input.style.textAlign = 'center';
    input.style.padding = '0';
    input.style.margin = '0';
    input.style.outline = 'none';
    input.style.borderRadius = '${tokens.radius.r2}px';
    input.style.borderStyle = 'solid';
    input.style.borderWidth = '${tokens.border.base}px';
    input.style.borderColor = 'transparent';
    input.style.fontFamily = _cssFontFamily();
    input.style.fontSize = '${tokens.typography.headline.fontSize ?? 24}px';
    // Animate the fill/border color change on focus/blur, matching the native OtpSlot's
    // `AnimatedContainer` on `motion.dHover`. Color/border only — no geometry — per D15.
    final hoverMs = tokens.motion.dHover.inMilliseconds;
    input.style.setProperty(
      'transition',
      'background-color ${hoverMs}ms ease-in-out, border-color ${hoverMs}ms ease-in-out',
    );

    // Toggle the color-state modifier classes; the `!important` class rules paint the
    // fill/text/border so they win over any password-manager override.
    final hasErrors = widget.errors.isNotEmpty;
    if (hasErrors) {
      input.classList.add(_errorClass);
    } else {
      input.classList.remove(_errorClass);
    }
    if (focused && !hasErrors && !widget.disabled) {
      input.classList.add(_focusedClass);
    } else {
      input.classList.remove(_focusedClass);
    }
  }

  /// Re-applies [_styleInput] to every box (used after a bulk value change).
  void _restyleAll() {
    for (final input in _inputs) {
      // Preserve the focused box's focused styling.
      final isFocused = web.document.activeElement == input;
      _styleInput(input, focused: isFocused);
    }
  }

  /// The CSS `font-family` value derived from the theme's body style.
  String _cssFontFamily() {
    final bodyStyle = widget.tokens.typography.body;
    final families = <String>[
      if (bodyStyle.fontFamily != null && bodyStyle.fontFamily!.isNotEmpty) bodyStyle.fontFamily!,
      ...(bodyStyle.fontFamilyFallback ?? const <String>[]),
    ];
    if (families.isEmpty) return 'sans-serif';
    return [...families.map((f) => "'$f'"), 'sans-serif'].join(', ');
  }

  /// Converts a Flutter [Color] to a CSS hex string, threading the alpha channel through
  /// explicitly so a transparent color renders as genuinely invisible.
  String _toCssColor(Color color) {
    final argb = color.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    final rgb =
        '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    if (a == 0xFF) return rgb;
    return '$rgb${a.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: SizedBox(
        height: widget.tokens.spacing.sp5 * 1.25,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
