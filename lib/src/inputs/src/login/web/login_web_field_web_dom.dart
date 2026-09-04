part of 'login_web_field_web.dart';

/// DOM construction (container/label/input/icons/selection style) and the
/// floating-label state machine for [_LayrzLoginWebFieldState].
///
/// Split out of `login_web_field_web.dart` as a `part` (not a standalone library)
/// because [_registerViewFactory] both reads shared instance state (`widget`,
/// `_viewType`) and writes back every stored element reference (`_inputElement`,
/// `_containerElement`, `_labelElement`, `_prefixIconPathElement`,
/// `_suffixIconPathElement`, `_selectionStyleElement`, `_applyFloatState`) that the rest
/// of the state class depends on — a `part` file shares its enclosing library's privacy
/// scope, so this state stays private without having to be exposed for a normal
/// cross-file import.
///
/// Ported from `layrz_session`'s `native_autofill_field_web_dom.dart`. The DOM
/// construction mechanism (honeypot rules, floating-label state machine, event wiring)
/// is preserved verbatim in behavior; every dimension/color assignment is redirected
/// to read from [LayrzTokens]/[LayrzInputStyleSpec] (via `login_web_field_web_theme
/// .dart`) instead of `layrz_session`'s hardcoded `ThemedInputBorder`-derived CSS
/// constants — see that file's own doc comment for the full rationale.
extension _LayrzLoginWebFieldDomMixin on _LayrzLoginWebFieldState {
  /// Registers the platform view factory that builds the real DOM element for this
  /// field instance.
  ///
  /// The built element is never zero-sized and never set to `display: none` — both are
  /// known triggers for Flutter's autofill DOM pruning (flutter/flutter#105485), which
  /// is part of the same bug family this widget works around. Nor is it ever made
  /// transparent (`opacity: 0`) — see [applyFloatState]'s doc comment for why.
  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final isPassword = widget.kind == LayrzLoginFieldKind.password;
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
      final labelColor = colors.labelColor;
      final textColor = colors.textColor;
      final accentHex = colors.accentHex;

      // Outer filled pill, mirroring [LayrzInputChrome]'s own container: radius from
      // `tokens.radius.br2`, border color/width from [LayrzInputStyleSpec] (transparent
      // at rest/hover, `colors.primary` when focused, `colors.danger` on error — the
      // same precedence [LayrzInputChrome] resolves), padding from `tokens.spacing.pd1`/
      // `pd2` (dense) or `pd2`/`pd3` (regular) — approximated here by the single scalar
      // `density` above, since the DOM chrome (unlike the Flutter chrome) has no
      // separate compact/regular viewport distinction to key off of; `dense` alone
      // selects the tighter scale.
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.style.width = '100%';
      container.style.height = '100%';
      container.style.boxSizing = 'border-box';
      container.style.display = 'flex';
      container.style.alignItems = 'center';
      container.style.borderRadius = '${tokens.radius.r2}px';
      container.style.background = fillColor;
      container.style.border = colors.borderWidthPx > 0
          ? '${colors.borderWidthPx}px solid ${colors.borderColor}'
          : 'none';
      container.style.padding = '${density}px';
      container.style.setProperty('gap', '${tokens.spacing.sp2}px');

      // Icon sits in its own fixed-height cell centered against the FULL field height,
      // independent of the label/value stack next to it, so it never moves when the
      // label floats up.
      final iconSlot = web.document.createElement('div') as web.HTMLDivElement;
      iconSlot.style.display = 'flex';
      iconSlot.style.alignItems = 'center';
      iconSlot.style.justifyContent = 'center';
      iconSlot.style.alignSelf = 'stretch';
      iconSlot.style.setProperty('flex-shrink', '0');
      final prefixIconPath = isPassword ? kShieldKeyIconPath : kShieldAccountIconPath;
      final prefixIcon = buildLoginIconSvg(prefixIconPath, iconColor);
      iconSlot.appendChild(prefixIcon.svg);

      // Stack occupying the full field height: the label is absolutely positioned
      // inside it so it can animate between "centered, scale 1" (idle) and "pinned to
      // the top, scaled down to a small caption" (floated) without reflowing or
      // resizing the input underneath it. The input always keeps its natural, real
      // size — see the note on [applyFloatState] below for why it must never be shrunk
      // to animate the transition.
      final stack = web.document.createElement('div') as web.HTMLDivElement;
      stack.style.position = 'relative';
      stack.style.setProperty('flex', '1 1 auto');
      stack.style.minWidth = '0';
      stack.style.alignSelf = 'stretch';

      final label = web.document.createElement('label') as web.HTMLLabelElement;
      label.textContent = widget.labelText ?? '';
      label.style.position = 'absolute';
      label.style.left = '0';
      label.style.right = '0';
      label.style.fontFamily = cssFontFamily;
      label.style.fontWeight = 'inherit';
      label.style.color = labelColor;
      label.style.userSelect = 'none';
      label.style.setProperty('line-height', '1.3');
      label.style.setProperty('white-space', 'nowrap');
      label.style.setProperty('overflow', 'hidden');
      label.style.setProperty('text-overflow', 'ellipsis');
      label.style.transition = _LayrzLoginWebFieldState._labelTransitionCss;
      // Matches [LayrzInputChrome]'s own body text size (`tokens.typography.body
      // .fontSize`) for both label and input — the floated ("small") look is achieved
      // purely via `transform: scale()`, never by changing `fontSize` (see
      // [_LayrzLoginWebFieldState._labelTransitionCss] for why animating font-size is
      // avoided).
      final bodyFontSize = tokens.typography.body.fontSize ?? 16.0;
      label.style.fontSize = '${bodyFontSize}px';
      label.style.setProperty('transform-origin', 'left top');
      // `top` is assigned exactly ONCE, here, and is never touched again — see
      // [applyFloatState] below for why all vertical motion instead happens purely via
      // `transform: translateY(...) scale(...)`.
      label.style.top = '0';
      label.style.setProperty('transform', 'translateY(${bodyFontSize * 0.6}px) scale(1)');

      final input = web.document.createElement('input') as web.HTMLInputElement;
      input.type = isPassword ? 'password' : 'text';
      input.autocomplete = isPassword ? 'current-password' : 'username';
      // `name` stays the plain, semantic `'username'`/`'password'` — what a password
      // manager's own heuristics read (alongside `autocomplete`/`type`) to classify the
      // field's ROLE.
      input.name = isPassword ? 'password' : 'username';
      // Extra autocomplete tokens from [widget.autofillHints] (translated from the
      // Flutter-style hint strings a caller would otherwise pass to `LayrzTextInput`)
      // are appended space-separated, per the HTML living standard's autocomplete
      // grammar, which allows multiple tokens (e.g. `"username email"`) — this is how
      // `AutofillHints.email` reaches the DOM `autocomplete` value alongside the base
      // `username`/`current-password` pairing [kind] already selects.
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
      input.value = widget.value;
      input.disabled = widget.disabled;
      input.style.position = 'absolute';
      input.style.left = '0';
      input.style.right = '0';
      input.style.width = '100%';
      input.style.boxSizing = 'border-box';
      input.style.border = 'none';
      input.style.outline = 'none';
      input.style.background = 'transparent';
      // These MUST be set as individual longhand properties (matching `label.style
      // .fontFamily` above) — NOT via the `font` shorthand, whose grammar rejects the
      // bare keyword fallback this file's font resolution can produce.
      input.style.fontFamily = cssFontFamily;
      input.style.fontSize = '${bodyFontSize}px';
      input.style.fontWeight = 'inherit';
      input.style.setProperty('line-height', '1.3');
      input.style.color = textColor;
      input.style.padding = '0';
      input.style.margin = '0';
      // Bottom-aligned so the value line sits on the field's lower half once the label
      // floats up to the top, leaving room for both without overflowing the field
      // height.
      input.style.bottom = '2px';
      // Never allow the input to collapse to zero *size*, and never resize or
      // reposition it as part of the float transition — a zero-sized (width/height 0)
      // or `display: none` input is the exact condition that triggers Flutter's own
      // autofill-proxy DOM pruning bug this widget exists to route around
      // (flutter/flutter#105485). The input's box therefore stays constant at all
      // times, and its `opacity` is likewise NEVER touched — see [applyFloatState].
      input.style.height = '${bodyFontSize + 2}px';
      input.style.minHeight = '${bodyFontSize + 2}px';

      // Unique class so the `::selection` rule injected below (and nothing else on the
      // page) targets exactly this input. `::selection` is a pseudo-element and cannot
      // be set via inline `element.style.*`, so it needs a real stylesheet rule scoped
      // by this class.
      input.className = _selectionClass;

      // Forces the text's fill color so the browser's autofill yellow/blue background
      // tint can't also recolor the typed text.
      input.style.setProperty('-webkit-text-fill-color', textColor);

      // 33% alpha (hex `55`) tint of the accent color, used as the `::selection`
      // background so a selection visibly reads as "selected" without hiding the text
      // underneath.
      final selectionBackground = '${accentHex}55';

      final selectionStyle = web.document.createElement('style') as web.HTMLStyleElement;
      selectionStyle.textContent =
          '.$_selectionClass::selection { background: $selectionBackground; color: $textColor; }';

      stack.appendChild(label);
      stack.appendChild(input);

      container.appendChild(selectionStyle);
      container.appendChild(iconSlot);
      container.appendChild(stack);

      web.HTMLSpanElement? suffixButton;
      if (isPassword) {
        // Suffix button sits in its own full-height cell too, for the same reason as
        // the prefix icon: it must stay put while the label floats.
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

      // Tracks focus state independently of `document.activeElement`, so the float
      // check works identically from all three events without extra DOM reads. Updated
      // first by `focus`/`blur`, then read by the shared [applyFloatState] below
      // (including from the `input` event, since autofill can populate `input.value`
      // and fire an `input` event without ever dispatching a user-driven `focus`
      // first).
      var isFocused = false;

      /// Applies (or removes) the floated — label-at-top — visual state.
      ///
      /// The floated state is `focused || value.isNotEmpty`, matching Material's
      /// `floatingLabelBehavior: auto`: a filled-but-unfocused field (e.g. autofilled,
      /// then tabbed away from) must keep its label floated rather than snapping back
      /// to the centered idle look.
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
      /// browser's default (fully opaque) at all times, in both the resting and
      /// floated states.
      ///
      /// The centered-label-as-placeholder look this widget wants at rest falls out for
      /// free from the input simply being EMPTY there: combined with `background:
      /// transparent` and no border/outline, a resting, opaque, empty input is visually
      /// indistinguishable from no input being there at all.
      void applyFloatState() {
        final shouldFloat = isFocused || input.value.isNotEmpty;
        if (shouldFloat) {
          label.style.setProperty('transform', 'translateY(1px) scale(0.75)');
        } else {
          label.style.setProperty('transform', 'translateY(${bodyFontSize * 0.6}px) scale(1)');
        }
      }

      input.addEventListener(
        'focus',
        (web.Event event) {
          isFocused = true;
          applyFloatState();
        }.toJS,
      );
      input.addEventListener(
        'blur',
        (web.Event event) {
          isFocused = false;
          applyFloatState();
        }.toJS,
      );
      input.addEventListener(
        'input',
        (web.Event event) {
          widget.onChanged?.call(input.value);
          // Autofill (and other programmatic value changes) can populate the field and
          // fire `input` without ever focusing it first, so the float check must also
          // run here, not just on focus/blur.
          applyFloatState();
        }.toJS,
      );
      input.addEventListener(
        'keydown',
        (web.Event event) {
          final keyboardEvent = event as web.KeyboardEvent;
          if (keyboardEvent.key == 'Enter') {
            widget.onSubmit?.call(input.value);
          }
        }.toJS,
      );

      // Seed the initial float state from the value the widget was created with, in
      // case it starts non-empty.
      applyFloatState();

      _inputElement = input;
      _applyFloatState = applyFloatState;
      _containerElement = container;
      _labelElement = label;
      _prefixIconPathElement = prefixIcon.path;
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
  /// deliberately not a general Flutter-hint-to-HTML-token translator (see the "no
  /// parallel input engine" hard constraint: this widget renders exactly two credential
  /// fields). `AutofillHints.email` is the concrete case the implementation plan calls
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
