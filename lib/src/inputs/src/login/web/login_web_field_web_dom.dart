part of 'login_web_field_web.dart';

/// DOM construction (container/placeholder/input/icons/selection style) for
/// [_LayrzLoginWebFieldState].
///
/// Split out of `login_web_field_web.dart` as a `part` (not a standalone library)
/// because [_registerViewFactory] both reads shared instance state (`widget`,
/// `_viewType`) and writes back every stored element reference (`_inputElement`,
/// `_containerElement`, `_placeholderElement`, `_prefixIconPathElement`,
/// `_suffixIconPathElement`, `_selectionStyleElement`) that the rest of the state class
/// depends on — a `part` file shares its enclosing library's privacy scope, so this
/// state stays private without having to be exposed for a normal cross-file import.
///
/// Ported from `layrz_session`'s `native_autofill_field_web_dom.dart`, but the visual
/// mechanism is NOT preserved verbatim: `layrz_session` invented a Material-style
/// floating label (label animates center→top, scales down when focused or filled) that
/// has no equivalent anywhere in layrz_ui — [LayrzInputChrome] (`input_chrome.dart`)
/// renders a STATIC label above the box and, inside the box, a placeholder that is
/// simply shown when the field is empty and hidden the instant it has a value (see
/// `input_chrome.dart:417-449`'s `ValueListenableBuilder`-gated hint `Text`). Animating
/// the label into a shrunken caption on top of the typed value — as the floating
/// mechanism did — produced the reported overlapping/garbled text bug, because both the
/// label and the value shared the same box with no mutual exclusion once a value
/// existed. This file now replicates the REAL chrome behavior instead:
///  - The floating `<label>` is gone. The label is rendered once, statically, by
///    `login_web_field_web.dart`'s `build()` as an ordinary Flutter `Text` row above the
///    `HtmlElementView` — exactly where [LayrzInputChrome] puts it.
///  - A `<span>` placeholder sits inside the box, in the same slot as the `<input>`, and
///    is toggled by CSS `visibility` based on `input.value.isEmpty` — never editable,
///    never focusable, purely decorative, matching the chrome's hint-text overlay.
///  - The honeypot-avoidance rules (never zero-size, never `display: none`, never
///    `opacity: 0` on the `<input>`) and all autofill/event wiring are preserved
///    verbatim; only the label/placeholder visual mechanism changed. Every
///    dimension/color assignment reads from [LayrzTokens]/[LayrzInputStyleSpec] (via
///    `login_web_field_web_theme.dart`) instead of `layrz_session`'s hardcoded
///    `ThemedInputBorder`-derived CSS constants — see that file's own doc comment for
///    the full rationale.
extension _LayrzLoginWebFieldDomMixin on _LayrzLoginWebFieldState {
  /// Registers the platform view factory that builds the real DOM element for this
  /// field instance.
  ///
  /// The built element is never zero-sized and never set to `display: none` — both are
  /// known triggers for Flutter's autofill DOM pruning (flutter/flutter#105485), which
  /// is part of the same bug family this widget works around. Nor is it ever made
  /// transparent (`opacity: 0`) — see `applyPlaceholderVisibility`'s doc comment
  /// (inside this method's body) for why.
  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final isPassword = widget.kind == LayrzLoginFieldKind.password;
      // The one-time-code field renders no chrome of its own: `LayrzOtpInput` paints six
      // digit slots on top of it and this `<input>` only needs to exist, in-flow and
      // real-sized, for the browser's autofill machinery to find and fill — see
      // [LayrzLoginFieldKind.oneTimeCode]'s doc comment and `otp_input_web.dart`'s own
      // overlay documentation for the full mechanism.
      final isOtp = widget.kind == LayrzLoginFieldKind.oneTimeCode;
      final cssFontFamily = _resolveCssFontFamily();
      final tokens = widget.tokens;
      final density = widget.dense ? tokens.spacing.sp1 : tokens.spacing.sp2;

      // Initial colors for construction below. Recomputed by [_applyThemeStyles]
      // whenever theme-relevant fields change after this platform view already exists
      // — see `login_web_field_web_theme.dart` for the resolution logic, sourced from
      // the same [LayrzInputStyleSpec] every other layrz_ui input reads.
      final colors = _resolveThemeColors();
      final fillColor = colors.fillColor;
      final iconColor = colors.iconColor;
      final placeholderColor = colors.labelColor;
      final textColor = colors.textColor;
      final accentHex = colors.accentHex;

      // Outer filled pill, mirroring [LayrzInputChrome]'s own container: radius from
      // `tokens.radius.br2`, border color/width from [LayrzInputStyleSpec] (transparent
      // at rest/hover/disabled/read-only, `colors.primary` when focused, `colors.danger`
      // on error — the same precedence [LayrzInputChrome] resolves; note rest/hover
      // really do resolve to a fully transparent border there too, so the "no visible
      // border at rest" look this produces is CORRECT, not a bug — the fill-color step
      // from `sf2` to `sf3` is what the real chrome uses to signal hover instead), and
      // padding from `tokens.spacing.pd1`/`pd2` (dense) or `pd2`/`pd3` (regular) —
      // approximated here by the single scalar `density` above, since the DOM chrome
      // (unlike the Flutter chrome) has no separate compact/regular viewport distinction
      // to key off of; `dense` alone selects the tighter scale.
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.style.width = '100%';
      container.style.height = '100%';
      container.style.boxSizing = 'border-box';
      container.style.display = 'flex';
      container.style.alignItems = 'center';
      // The one-time-code field paints no fill, border, or radius of its own — six
      // `OtpSlot`s painted on top by `LayrzOtpInput`/`otp_input_web.dart` supply the
      // entire visible chrome; this `<input>` only needs to be real, in-flow, and
      // opaque-sized for autofill purposes (see [LayrzLoginFieldKind.oneTimeCode]).
      if (!isOtp) {
        container.style.borderRadius = '${tokens.radius.r2}px';
        container.style.background = fillColor;
        container.style.border = colors.borderWidthPx > 0
            ? '${colors.borderWidthPx}px solid ${colors.borderColor}'
            : 'none';
        container.style.padding = '${density}px';
        container.style.setProperty('gap', '${tokens.spacing.sp2}px');
      }

      // Icon sits in its own fixed-height cell centered against the FULL field height.
      // Skipped entirely for the one-time-code field — there is no equivalent glyph and
      // the painted slots leave no room for one.
      if (!isOtp) {
        final iconSlot = web.document.createElement('div') as web.HTMLDivElement;
        iconSlot.style.display = 'flex';
        iconSlot.style.alignItems = 'center';
        iconSlot.style.justifyContent = 'center';
        iconSlot.style.alignSelf = 'stretch';
        iconSlot.style.setProperty('flex-shrink', '0');
        final prefixIconPath = isPassword ? kShieldKeyIconPath : kShieldAccountIconPath;
        final prefixIcon = buildLoginIconSvg(prefixIconPath, iconColor);
        iconSlot.appendChild(prefixIcon.svg);
        container.appendChild(iconSlot);
        _prefixIconPathElement = prefixIcon.path;
      }

      // Stack occupying the full field height: the placeholder sits absolutely
      // positioned in the SAME box the `<input>` occupies (mirroring
      // [LayrzInputChrome]'s `Stack` at `input_chrome.dart:415-454`, where the hint
      // `Text` and the child are both aligned into the same cell) and is toggled purely
      // by `visibility`/`display` based on whether the input is empty — it never
      // animates, never shrinks, and is never shown at the same time as a non-empty
      // value. This is what eliminates the overlapping-text bug: exactly one of
      // "placeholder" or "typed value" is ever visible at once, never both.
      final stack = web.document.createElement('div') as web.HTMLDivElement;
      stack.style.position = 'relative';
      stack.style.setProperty('flex', '1 1 auto');
      stack.style.minWidth = '0';
      stack.style.alignSelf = 'stretch';
      stack.style.display = 'flex';
      stack.style.alignItems = 'center';

      final bodyFontSize = tokens.typography.body.fontSize ?? 16.0;

      // Decorative placeholder — mirrors [LayrzInputChrome]'s hint-text overlay
      // (`density.textStyle.copyWith(color: tokens.colors.fg3)`, shown only while the
      // controller is empty). Never focusable, never editable, and excluded from
      // accessibility (the accessible label lives on the `<input>` itself via
      // `aria-label`, set below) so assistive tech never announces two labels for one
      // field. Skipped for the one-time-code field: its "empty" look is six empty
      // `OtpSlot`s painted on top, not an in-box hint string.
      web.HTMLSpanElement? placeholder;
      if (!isOtp) {
        placeholder = web.document.createElement('span') as web.HTMLSpanElement;
        placeholder.textContent = widget.labelText ?? '';
        placeholder.style.position = 'absolute';
        placeholder.style.left = '0';
        placeholder.style.right = '0';
        placeholder.style.fontFamily = cssFontFamily;
        placeholder.style.fontWeight = 'inherit';
        placeholder.style.color = placeholderColor;
        placeholder.style.userSelect = 'none';
        placeholder.style.setProperty('pointer-events', 'none');
        placeholder.style.setProperty('line-height', '1.3');
        placeholder.style.setProperty('white-space', 'nowrap');
        placeholder.style.setProperty('overflow', 'hidden');
        placeholder.style.setProperty('text-overflow', 'ellipsis');
        placeholder.style.fontSize = '${bodyFontSize}px';
        placeholder.setAttribute('aria-hidden', 'true');
        placeholder.style.display = widget.value.isEmpty ? 'block' : 'none';
      }

      final input = web.document.createElement('input') as web.HTMLInputElement;
      if (isOtp) {
        // One-time-code: plain text input (browsers have no dedicated OTP `type`),
        // `autocomplete="one-time-code"` is the actual signal password managers and
        // mobile keyboards key off of, and `inputmode="numeric"` requests the numeric
        // keypad on touch devices without changing `type` (which would otherwise
        // disable text-selection affordances some browsers reserve for `type="number"`).
        input.type = 'text';
        input.autocomplete = 'one-time-code';
        input.inputMode = 'numeric';
        input.name = 'one-time-code';
        input.maxLength = 6;
        input.setAttribute('pattern', '[0-9]*');
      } else {
        input.type = isPassword ? 'password' : 'text';
        input.autocomplete = isPassword ? 'current-password' : 'username';
        // `name` stays the plain, semantic `'username'`/`'password'` — what a password
        // manager's own heuristics read (alongside `autocomplete`/`type`) to classify the
        // field's ROLE.
        input.name = isPassword ? 'password' : 'username';
      }
      // Extra autocomplete tokens from [widget.autofillHints] (translated from the
      // Flutter-style hint strings a caller would otherwise pass to `LayrzTextInput`)
      // are appended space-separated, per the HTML living standard's autocomplete
      // grammar, which allows multiple tokens (e.g. `"username email"`) — this is how
      // `AutofillHints.email` reaches the DOM `autocomplete` value alongside the base
      // `username`/`current-password`/`one-time-code` pairing [kind] already selects.
      final extraHints = widget.autofillHints
          .map(_autofillHintToAutocompleteToken)
          .whereType<String>()
          .where((token) => token != input.autocomplete)
          .toSet();
      if (extraHints.isNotEmpty) {
        input.autocomplete = '${input.autocomplete} ${extraHints.join(' ')}';
      }
      // Unique, stable identifier some password managers require in addition to `name`
      // before they'll pair two fields together. Reuses [_selectionClass] (already
      // guaranteed unique per field instance and stable for its entire lifetime) rather
      // than minting a second derived string.
      input.id = _selectionClass;
      // Dashlane SAWF (Simple Autofill Website Framework) PER-INPUT field-role
      // annotation — the counterpart to the `data-form-type="login"` on the group
      // `<form>` (`login_web_group_web.dart`). This bypasses Dashlane's ML field
      // classifier, which is the documented fix (https://dashlane.github.io/SAWF/) for
      // Dashlane failing to detect/offer a field — especially the one-time-code field,
      // whose own text is transparent and gives the classifier nothing to read. Without
      // it, `autocomplete`/`name`/`id`/`<form>` association alone are not enough for
      // Dashlane to fire on web. `'otp'` is SAWF's own documented value for a one-time
      // password field. Additive to `autocomplete`/`type`/`name`, none of which it
      // replaces. (Ported from `layrz_session`'s working implementation, where dropping
      // this attribute was the reason autofill did not fire — see decision D82.)
      final String sawfFieldType = isOtp
          ? 'otp'
          : isPassword
          ? 'password'
          : 'username';
      input.setAttribute('data-form-type', sawfFieldType);
      input.value = widget.value;
      input.disabled = widget.disabled;
      // An ordinary flex child of `stack` now — not absolutely positioned — since
      // there is no longer a floating label sharing the box that it needs to make room
      // for underneath. `stack`'s own `align-items: center` centers it vertically,
      // matching [LayrzInputChrome]'s `Align(alignment: Alignment.center, child: child)`
      // at `input_chrome.dart:450-453`.
      input.style.width = '100%';
      input.style.boxSizing = 'border-box';
      input.style.border = 'none';
      input.style.outline = 'none';
      input.style.background = 'transparent';
      // These MUST be set as individual longhand properties (matching `placeholder.style
      // .fontFamily` above) — NOT via the `font` shorthand, whose grammar rejects the
      // bare keyword fallback this file's font resolution can produce.
      input.style.fontFamily = cssFontFamily;
      input.style.fontSize = '${bodyFontSize}px';
      input.style.fontWeight = 'inherit';
      input.style.setProperty('line-height', '1.3');
      // The one-time-code field's own glyphs, caret, and text-selection highlight are
      // fully transparent — `LayrzOtpInput` paints the six visible digits itself, on
      // top, via `OtpSlot`. This is TEXT-color transparency, not element opacity: the
      // `<input>` itself stays fully opaque and real-sized (see the honeypot-avoidance
      // note below and on [LayrzLoginFieldKind.oneTimeCode]), so password managers still
      // see and can fill a normal, visible-to-them form field.
      final effectiveTextColor = isOtp ? 'transparent' : textColor;
      input.style.color = effectiveTextColor;
      input.style.setProperty('caret-color', isOtp ? 'transparent' : 'auto');
      input.style.padding = '0';
      input.style.margin = '0';
      if (isOtp) {
        // Text-align center matches the centered digit slots painted on top, so the
        // (invisible) native caret/selection geometry roughly tracks the visible one.
        input.style.textAlign = 'center';
      }
      // Sets the accessible name directly on the input (the placeholder is
      // `aria-hidden`, so this is the ONLY accessible name source for the field, on top
      // of the static label row `login_web_field_web.dart`'s `build()` renders in
      // Flutter — matching how [LayrzTextInput] wraps its own chrome in a
      // `Semantics(label: widget.labelText, ...)`, see `text_input.dart:375-377`).
      if (widget.labelText != null && widget.labelText!.isNotEmpty) {
        input.setAttribute('aria-label', widget.labelText!);
      }
      // Never allow the input to collapse to zero *size* — a zero-sized (width/height 0)
      // or `display: none` input is the exact condition that triggers Flutter's own
      // autofill-proxy DOM pruning bug this widget exists to route around
      // (flutter/flutter#105485). Its `opacity` is likewise NEVER touched — see
      // `applyPlaceholderVisibility` below.
      input.style.height = '${bodyFontSize + 2}px';
      input.style.minHeight = '${bodyFontSize + 2}px';

      // Unique class so the `::selection` rule injected below (and nothing else on the
      // page) targets exactly this input. `::selection` is a pseudo-element and cannot
      // be set via inline `element.style.*`, so it needs a real stylesheet rule scoped
      // by this class.
      input.className = _selectionClass;

      // Forces the text's fill color so the browser's autofill yellow/blue background
      // tint can't also recolor the typed text. Kept transparent on the one-time-code
      // field, matching `input.style.color` above.
      input.style.setProperty('-webkit-text-fill-color', effectiveTextColor);

      // 33% alpha (hex `55`) tint of the accent color, used as the `::selection`
      // background so a selection visibly reads as "selected" without hiding the text
      // underneath. The one-time-code field selects transparently too — there is no
      // visible text underneath to reveal, and the six painted `OtpSlot`s show the
      // focused position instead.
      final selectionBackground = isOtp ? 'transparent' : '${accentHex}55';

      // The `<style>` element carries both the `::selection` rule and the autofill-override
      // rule, built together by `_buildStyleSheet` (see its doc comment in
      // `login_web_field_web_theme.dart`). Building them in one place is load-bearing:
      // `_applyThemeStyles` rewrites this element's contents on every restyle, so if the two
      // rules were not built together, a restyle would erase the autofill override and let
      // the password manager's fill styling reappear.
      final selectionStyle = web.document.createElement('style') as web.HTMLStyleElement;
      selectionStyle.textContent = _buildStyleSheet(
        selectionBackground: selectionBackground,
        selectionTextColor: effectiveTextColor,
        colors: colors,
        isOtp: isOtp,
      );

      // `placeholder` is absolutely positioned so it overlays `input` in the same cell
      // (append order doesn't matter for stacking since `position: absolute` already
      // takes it out of flex flow), and it is only ever visible while `input` is empty
      // — see `applyPlaceholderVisibility` below. Null for the one-time-code field,
      // which has no in-box placeholder — see where it is (conditionally) created above.
      if (placeholder != null) {
        stack.appendChild(placeholder);
      }
      stack.appendChild(input);

      container.appendChild(selectionStyle);
      // `iconSlot` is only appended here for username/password — see where it is
      // (conditionally) created and appended above for the one-time-code field, which
      // has no prefix icon.
      container.appendChild(stack);

      web.HTMLSpanElement? suffixButton;
      if (isPassword) {
        // Suffix button sits in its own full-height cell so it never shifts as the
        // input's value changes.
        suffixButton = web.document.createElement('span') as web.HTMLSpanElement;
        suffixButton.style.display = 'flex';
        suffixButton.style.alignItems = 'center';
        suffixButton.style.justifyContent = 'center';
        suffixButton.style.alignSelf = 'stretch';
        suffixButton.style.cursor = 'pointer';
        suffixButton.style.setProperty('flex-shrink', '0');
        suffixButton.setAttribute('role', 'button');
        suffixButton.setAttribute('tabindex', '0');
        // Accessible label + live state mirror U4's l10n usage (dossier §6/§12A —
        // liliana's point): the DOM eye toggle needs a real accessible name AND its
        // current state announced, not just an icon swap.
        suffixButton.setAttribute('aria-label', passwordShowLabel);
        suffixButton.setAttribute('aria-pressed', 'false');
        final suffixIcon = buildLoginIconSvg(kEyeIconPath, iconColor);
        suffixButton.appendChild(suffixIcon.svg);
        _suffixIconPathElement = suffixIcon.path;

        void toggleVisibility() {
          // Reads the CURRENT icon color (via [_resolveThemeColors]) rather than the
          // `iconColor` closed over above, so a click that happens after a theme change
          // still rebuilds the icon in the up-to-date color instead of momentarily
          // reintroducing a stale one. This rebuild only ever changes which path DATA
          // (eye vs. eye-off) is shown — `input.type`, which is what the toggle's
          // shown/hidden STATE actually lives in, is set the line below and is never
          // touched by [_applyThemeStyles], so a later theme change can never reset a
          // currently-revealed password back to hidden.
          final showing = input.type == 'text';
          input.type = showing ? 'password' : 'text';
          suffixButton!.textContent = '';
          final rebuiltIcon = buildLoginIconSvg(
            showing ? kEyeIconPath : kEyeOffIconPath,
            _resolveThemeColors().iconColor,
          );
          suffixButton.appendChild(rebuiltIcon.svg);
          _suffixIconPathElement = rebuiltIcon.path;
          final nowShowing = !showing;
          suffixButton.setAttribute('aria-label', nowShowing ? passwordHideLabel : passwordShowLabel);
          suffixButton.setAttribute('aria-pressed', nowShowing.toString());
        }

        suffixButton.addEventListener(
          'click',
          (web.Event event) {
            toggleVisibility();
          }.toJS,
        );
        suffixButton.addEventListener(
          'keydown',
          (web.Event event) {
            final keyboardEvent = event as web.KeyboardEvent;
            if (keyboardEvent.key == 'Enter' || keyboardEvent.key == ' ') {
              keyboardEvent.preventDefault();
              toggleVisibility();
            }
          }.toJS,
        );

        container.appendChild(suffixButton);
      }

      // Error/alert icon cell — mirrors [LayrzInputChrome]'s own trailing-icon
      // canonical order `shortcut → suffix → lock → help → error`
      // (`input_chrome.dart:497,552`), where the error icon (`MdiIcons.alertOutline`) is
      // always rendered LAST/rightmost, alongside whatever suffix content already
      // exists rather than replacing it — on the password field this sits to the right
      // of the eye toggle, both visible together, exactly as the chrome renders its
      // suffix slot and error icon side by side. Always created (so [_applyThemeStyles]
      // has a stable element to toggle later, since unlike the prefix/suffix icons this
      // one's very presence — not just its tint — depends on error state, which can
      // change after this platform view already exists), but only shown when
      // [hasErrors] is currently true.
      final errorIconSlot = web.document.createElement('div') as web.HTMLDivElement;
      errorIconSlot.style.display = hasErrors ? 'flex' : 'none';
      errorIconSlot.style.alignItems = 'center';
      errorIconSlot.style.justifyContent = 'center';
      errorIconSlot.style.alignSelf = 'stretch';
      errorIconSlot.style.setProperty('flex-shrink', '0');
      errorIconSlot.setAttribute('aria-hidden', 'true');
      final errorIcon = buildLoginIconSvg(kAlertIconPath, colors.iconColor);
      errorIconSlot.appendChild(errorIcon.svg);
      _errorIconPathElement = errorIcon.path;
      _errorIconSlotElement = errorIconSlot;
      container.appendChild(errorIconSlot);

      /// Shows or hides the decorative placeholder based purely on whether [input] is
      /// currently empty — mirroring [LayrzInputChrome]'s own hint-text
      /// `ValueListenableBuilder` (`input_chrome.dart:417-434`), which shows the hint
      /// only while `value.text.isEmpty` and hides it the instant a value exists. No
      /// animation, no transform, no scaling: exactly one of "placeholder" or "typed
      /// value" is visible at any time, which is what makes overlap impossible — unlike
      /// the previous floating-label mechanism, where the shrunken label and the input's
      /// own value both occupied the same box simultaneously once focused-or-filled.
      ///
      /// ## The input is NEVER made transparent — not even at rest
      /// Browser password managers treat a fully transparent (`opacity: 0`) form field
      /// as a hidden/decoy "honeypot" field and skip it outright as part of their
      /// standard hidden-field heuristics — exactly the class of problem this widget
      /// otherwise goes to great lengths to avoid (see the zero-size/`display: none`
      /// note above, and flutter/flutter#105485). An input a password manager cannot
      /// see cannot be offered for autofill, no matter how correct every other signal
      /// (`autocomplete`, `name`, `id`, `<form>` association) is. `input.style.opacity`
      /// is therefore never set anywhere in this file — the element simply keeps the
      /// browser's default (fully opaque) at all times.
      void applyPlaceholderVisibility() {
        placeholder?.style.display = input.value.isEmpty ? 'block' : 'none';
      }

      input.addEventListener(
        'input',
        (web.Event event) {
          if (isOtp) {
            // Strips anything that isn't a digit (a paste, an IME composition, or a
            // password manager filling non-numeric junk) before it ever reaches
            // `onChanged` — mirrors `LayrzOtpInput`'s own native
            // `FilteringTextInputFormatter.digitsOnly` behavior, since this DOM `<input>`
            // has no formatter pipeline of its own. `maxLength`/`pattern` above are
            // browser-side hints only; this is the actual enforcement.
            final digitsOnly = input.value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly != input.value) {
              input.value = digitsOnly;
            }
          }
          widget.onChanged?.call(input.value);
          // Autofill (and other programmatic value changes) can populate the field and
          // fire `input` without ever dispatching a user-driven `focus` first, so the
          // placeholder check must run here too, not just be seeded once at creation.
          applyPlaceholderVisibility();
        }.toJS,
      );
      input.addEventListener(
        'keydown',
        (web.Event event) {
          final keyboardEvent = event as web.KeyboardEvent;
          if (keyboardEvent.key == 'Enter') {
            widget.onSubmit?.call(input.value);
            return;
          }
          // Ctrl+A (Cmd+A on macOS) must select this input's own text, not the whole
          // page. Flutter web's platform-view/pointer-interceptor layer otherwise lets
          // the shortcut escape to the document, which the browser then resolves as
          // "select all" over the entire page instead of this field's content.
          // `stopPropagation` keeps it from bubbling up to Flutter/the document at all,
          // and `preventDefault` suppresses the browser's own document-wide fallback;
          // `input.select()` performs the actual field-scoped selection. Every other
          // key (typing, Enter above) is left untouched.
          final isSelectAll = (keyboardEvent.ctrlKey || keyboardEvent.metaKey) && keyboardEvent.key == 'a';
          if (isSelectAll) {
            keyboardEvent.preventDefault();
            keyboardEvent.stopPropagation();
            input.select();
          }
        }.toJS,
      );
      // Drives the focused [WidgetState] on the Dart side (see
      // [_LayrzLoginWebFieldState.states]) so the chrome's primary-color focus border
      // paints while this native `<input>` has real DOM focus, matching
      // [LayrzInputChrome]'s own focused resolution. `_applyThemeStyles` mutates the
      // already-built DOM in place — no Flutter rebuild is involved or needed.
      input.addEventListener(
        'focus',
        (web.Event event) {
          _isFocused = true;
          _applyThemeStyles();
          widget.onFocusChanged?.call(true);
        }.toJS,
      );
      input.addEventListener(
        'blur',
        (web.Event event) {
          _isFocused = false;
          _applyThemeStyles();
          widget.onFocusChanged?.call(false);
        }.toJS,
      );

      // Seed the initial placeholder visibility from the value the widget was created
      // with, in case it starts non-empty.
      applyPlaceholderVisibility();

      _inputElement = input;
      _applyPlaceholderVisibility = applyPlaceholderVisibility;
      _containerElement = container;
      _placeholderElement = placeholder;
      // `_prefixIconPathElement` is already assigned above, inside the `!isOtp` branch
      // that creates `prefixIcon` — there is no prefix icon (and no `prefixIcon` local)
      // for the one-time-code field.
      _selectionStyleElement = selectionStyle;
      // Re-derives colors from the CURRENT widget (rather than trusting the
      // `fillColor`/`iconColor`/etc. locals already assigned above during this same
      // construction) so this call and every later call from [didUpdateWidget] apply
      // styling through the exact same code path — see `login_web_field_web_theme
      // .dart`.
      _applyThemeStyles();
      // `_effectiveFormId` is guaranteed already resolved by this point — see the doc
      // comment on that field for exactly why no race is possible here.
      _associateFormId(input, _effectiveFormId);
      // Unlike `_associateFormId` (only meaningful when there is a form to join), this
      // must run unconditionally for every instance — see its doc comment for why
      // Flutter's own aria-hidden wrapper must be corrected regardless of whether a
      // [LayrzLoginWebGroup] is present.
      _revealFromAssistiveTechnologyOnceConnected(
        input,
        attemptsLeft: _LayrzLoginWebFieldState._connectionCheckMaxAttempts,
      );
      return container;
    });
  }

  /// Translates one Flutter `AutofillHints`-style hint string into an HTML
  /// `autocomplete` token, or `null` when there is no direct equivalent.
  ///
  /// Only hints relevant to a login credential pair are mapped — this field is
  /// deliberately not a general Flutter-hint-to-HTML-token translator (see
  /// [LayrzLoginFieldKind]'s doc comment: this widget renders exactly the three
  /// authentication field kinds). `AutofillHints.email` is the concrete case the
  /// implementation plan calls
  /// out (dossier `layrz_session` commit `a421381`: "added `AutofillHints.email` which
  /// Dashlane needs to match the field"), so it is the one mapped; `AutofillHints
  /// .username`/`.password` are already covered by the base [kind] pairing and are
  /// skipped via the `where` filter in the caller (appending them again would be a
  /// harmless but redundant duplicate token).
  String? _autofillHintToAutocompleteToken(String hint) {
    switch (hint) {
      case 'email':
        return 'email';
      case 'username':
        return 'username';
      case 'password':
      case 'current-password':
        return 'current-password';
      default:
        return null;
    }
  }
}
