/// Web implementation of [LayrzLoginWebField].
///
/// This file is only ever compiled on web (selected via the conditional export in
/// `login_web_field.dart`), so it may freely use `dart:ui_web`, `dart:js_interop`, and
/// `package:web`.
///
/// ## File layout
/// [_LayrzLoginWebFieldState] is split across several `part` files, grouped by
/// responsibility, since a naive split into separate top-level classes would require
/// exposing the state class's private fields (`_inputElement`, `_placeholderElement`,
/// `_containerElement`, `_applyPlaceholderVisibility`, `_effectiveFormId`, etc.) that
/// its methods share heavily. A `part` file shares its enclosing library's privacy
/// scope, so splitting this way keeps every field genuinely private while still
/// breaking the implementation into focused, independently readable files:
///  - `login_web_field_web_dom.dart` — DOM construction (the platform view factory:
///    container/placeholder/input/icons/selection style) and the empty/filled
///    placeholder-visibility toggle.
///  - `login_web_field_web_theme.dart` — theme colour resolution (sourced from
///    [LayrzTokens]/[LayrzInputStyleSpec], the same resolver [LayrzInputChrome] uses)
///    and `_applyThemeStyles`.
///  - `login_web_field_web_form.dart` — `<form>` association, `aria-hidden` removal,
///    and their deferred connection verification.
///
/// The field's LABEL is rendered once, statically, by this file's own `build()` — an
/// ordinary Flutter `Text` row above the `HtmlElementView`, mirroring exactly where
/// [LayrzInputChrome] places its label (`input_chrome.dart:290-316`). The DOM layer
/// itself renders no label at all; see `login_web_field_web_dom.dart`'s doc comment for
/// why the previous Material-style floating label (ported unmodified from
/// `layrz_session`) was replaced.
///
/// Each `part` above is written as an `extension on _LayrzLoginWebFieldState` rather
/// than literally reopening the class body (Dart has no syntax for the latter):
/// extension methods still resolve private members and call each other across files
/// within the same library, so the effect is the same as one class body split by
/// responsibility, without any member needing to be made public.
///
/// The icon SVG path constants and the inline-`<svg>` builder need none of that shared
/// state — they are plain functions of their arguments — so they live instead in
/// `login_web_field_web_icons.dart` as an ordinary, separately importable library (not
/// a `part`).
///
/// ## Porting notes (U6)
/// Ported from `layrz_session`'s `native_autofill_field_web.dart` family
/// (`NativeAutofillTextField`/`NativeAutofillFieldKind`), mechanism-only per the
/// implementation plan:
///  - Material-free: the source's Material import is replaced with
///    `package:flutter/widgets.dart` throughout this file and every `part`. The only
///    Material-coupled TYPE the source used at this layer was `Color` (which is a
///    `dart:ui`/widgets-layer type regardless, so no substitution was actually needed)
///    — no `Colors.*`/`TextStyle`-from-Material construct survives the port.
///  - `layrz_logging`'s `Log.info`/`Log.warning` are replaced with [debugPrint]
///    (`package:flutter/foundation.dart`, re-exported by `widgets.dart`) — see
///    `login_web_field_web_form.dart`.
///  - `NativeAutofillFieldKind.oneTimeCode` and its `digitsOnly` support are DROPPED
///    entirely — this sub-module renders exactly `{ username, password }` per the "no
///    parallel input engine" hard constraint; there is no third kind and no OTP path.
///  - The visual chrome (colors, border, radius, padding, font) is redirected to read
///    live from [LayrzTokens]/[LayrzInputStyleSpec] instead of `layrz_session`'s
///    hardcoded `ThemedInputBorder`-derived CSS constants — see
///    `login_web_field_web_theme.dart`'s own doc comment for the full rationale. The
///    `isDark`/`accentColor`/`fontFamily` constructor parameters `layrz_session` used to
///    carry that information in are gone; a single `tokens` ([LayrzTokens]) parameter
///    replaces them, per U5's fixed contract.
///  - `PointerInterceptor` (needed to stop Flutter's own gesture/scroll arena from
///    stealing pointer events away from the native `<input>`, flutter/flutter#132183)
///    is preserved.
library;

import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:web/web.dart' as web;

import 'login_web_field.dart';
import 'login_web_field_web_icons.dart';
import 'login_web_group.dart';

part 'login_web_field_web_dom.dart';
part 'login_web_field_web_form.dart';
part 'login_web_field_web_theme.dart';

/// Web-only text field backed by a real, native HTML `<input>` element.
///
/// This is the canonical `LayrzLoginWebField` symbol resolved by
/// `login_web_field.dart`'s conditional export on web targets. See
/// [LayrzLoginWebFieldContract] for the full constructor contract this class
/// implements, and the module-level doc comment above for the porting notes.
///
/// ## Why this exists
/// Flutter web's own [TextField]/`AutofillGroup` implementation relies on a hidden,
/// framework-managed autofill proxy `<input>` that browser password managers struggle
/// to fill reliably: the proxy element can be zero-sized while unfocused and gets torn
/// down mid-fill, which breaks combined username+password autofill (see
/// flutter/flutter#174773 and the related #105485 DOM-pruning issue). This widget
/// sidesteps the problem on web by rendering a genuine `<input>` via [HtmlElementView]
/// instead of Flutter's own text rendering stack.
///
/// ## Visual-fidelity target
/// Unlike `layrz_session`'s equivalent (which explicitly does not attempt to visually
/// match its Flutter counterpart pixel-for-pixel), this widget's CSS chrome is built to
/// read as a `layrz_ui` input: it mirrors [LayrzInputChrome]'s own token-derived radius,
/// padding, colors, and default/hover/focus/error/disabled state resolution — sourced
/// LIVE from the same [LayrzTokens] the Flutter chrome consumes, via the same
/// [LayrzInputStyleSpec.resolve] call. See `login_web_field_web_theme.dart`.
///
/// This widget must only be used behind a `kIsWeb` check — it registers a
/// `dart:ui_web` platform view factory, which has no meaning outside web.
class LayrzLoginWebField extends StatefulWidget implements LayrzLoginWebFieldContract {
  /// Which credential field this is — selects the DOM `type`/`autocomplete` pairing.
  final LayrzLoginFieldKind kind;

  /// The current field value, used to seed the DOM `<input>` once. After that the
  /// `<input>` is the source of truth on web; changes flow back out through
  /// [onChanged], not by re-seeding [value] on every rebuild.
  final String value;

  /// The label displayed above the field, mirroring `LayrzTextInput.labelText`.
  final String? labelText;

  /// Validation error messages displayed below the field, mirroring
  /// `LayrzTextInput.errors`. A non-empty list also selects the chrome's danger/error
  /// visual state.
  final List<String> errors;

  /// Fired with the new value whenever the underlying DOM `<input>` fires its own
  /// `input` event.
  final ValueChanged<String>? onChanged;

  /// Fired with the current value when the user submits from the field (DOM `Enter`
  /// keydown / form submission).
  final ValueChanged<String>? onSubmit;

  /// The `AutofillHints`-style hint strings the caller would pass to `LayrzTextInput`
  /// on native; translated into the DOM `autocomplete` value this field assigns, in
  /// addition to the base pairing [kind] already selects.
  final List<String> autofillHints;

  /// The HTML `<form>` id this field's `<input>` should be associated with, so the
  /// browser groups username + password into one credential set. Resolved by the
  /// caller from `login_web_group.dart`'s group provider — this field never invents
  /// its own id.
  final String? formId;

  /// Mirrors `LayrzTextInput.disabled` — not editable, not focusable, callbacks do not
  /// fire.
  final bool disabled;

  /// Mirrors `LayrzTextInput.dense` — selects the tighter padding scale the web CSS
  /// chrome also honors.
  final bool dense;

  /// The live design tokens the web CSS chrome reads for radius, padding, and color, so
  /// the DOM field tracks token changes instead of hardcoding CSS constants.
  final LayrzTokens tokens;

  /// Creates a native-HTML-backed autofill login field. Web only.
  const LayrzLoginWebField({
    super.key,
    required this.kind,
    required this.value,
    this.labelText,
    this.errors = const [],
    this.onChanged,
    this.onSubmit,
    this.autofillHints = const [],
    this.formId,
    this.disabled = false,
    this.dense = false,
    required this.tokens,
  });

  @override
  State<LayrzLoginWebField> createState() => _LayrzLoginWebFieldState();
}

class _LayrzLoginWebFieldState extends State<LayrzLoginWebField> {
  /// Incrementing id so every instance of this widget registers its own, uniquely
  /// named platform view factory — reusing a view type across distinct widgets would
  /// make the platform view registry serve the wrong element.
  static int _idCounter = 0;

  late final String _viewType;
  web.HTMLInputElement? _inputElement;

  /// Outer filled-pill container, stored so `_applyThemeStyles` (in
  /// `login_web_field_web_theme.dart`) can restyle its `background`/`border` when the
  /// theme-relevant fields change after the platform view has already been created.
  web.HTMLDivElement? _containerElement;

  /// Decorative placeholder element (shown only while the input is empty), stored so
  /// `_applyThemeStyles` can restyle its `color` (theme change) and re-set its
  /// `textContent` (label-text/locale change) after creation.
  web.HTMLSpanElement? _placeholderElement;

  /// `<path>` node inside the prefix icon `<svg>`, stored so `_applyThemeStyles` can
  /// restyle its `fill` in place.
  web.SVGPathElement? _prefixIconPathElement;

  /// `<path>` node inside the suffix (show/hide password) icon `<svg>`, or null for the
  /// username field, which has no suffix icon.
  web.SVGPathElement? _suffixIconPathElement;

  /// `<path>` node inside the error/alert icon `<svg>`, stored so `_applyThemeStyles`
  /// can restyle its `fill` in place. Present on both username and password fields —
  /// unlike [_suffixIconPathElement], this icon is not password-specific.
  web.SVGPathElement? _errorIconPathElement;

  /// The error/alert icon's own cell `<div>`, stored so `_applyThemeStyles` can toggle
  /// its `display` based on the CURRENT [hasErrors] — this icon's presence, not merely
  /// its tint, depends on error state, which can change after the platform view already
  /// exists (e.g. validation errors appearing after a failed submit).
  web.HTMLDivElement? _errorIconSlotElement;

  /// The injected `<style>` element carrying this instance's `::selection` rule, stored
  /// so `_applyThemeStyles` can rewrite its `textContent` when the accent or text color
  /// changes.
  web.HTMLStyleElement? _selectionStyleElement;

  /// Re-runs the placeholder-visibility check for the current native element, set by
  /// `_registerViewFactory` (in `login_web_field_web_dom.dart`) once the element
  /// exists. Exposed so [didUpdateWidget] can re-sync placeholder visibility after
  /// resetting `input.value` from outside, since that assignment does not itself fire
  /// an `input` event.
  VoidCallback? _applyPlaceholderVisibility;

  /// This field's resolved `<form>` id, or `null` if it should not be associated with
  /// any form.
  ///
  /// Resolved in [didChangeDependencies] (the only lifecycle point where an
  /// [InheritedWidget] lookup — [LayrzLoginWebGroup.maybeOf] — is valid) and cached
  /// here, since `_registerViewFactory`'s callback runs at a point in time controlled
  /// by the Flutter engine, not by this widget's build cycle, where no [BuildContext]
  /// lookup is valid to perform.
  String? _effectiveFormId;

  /// Maximum number of post-frame callbacks the deferred connection checks (in
  /// `login_web_field_web_form.dart`) will wait across for [web.Node.isConnected] to
  /// become `true`, before giving up.
  static const int _connectionCheckMaxAttempts = 10;

  /// Whether this field currently carries validation errors — selects the chrome's
  /// danger/error state, per [LayrzInputStyleSpec.resolve].
  bool get hasErrors => widget.errors.isNotEmpty;

  /// Whether the underlying DOM `<input>` currently has real browser focus.
  ///
  /// Set by the `focus`/`blur` listeners registered in `_registerViewFactory` (see
  /// `login_web_field_web_dom.dart`), and read by [states] so the field's chrome
  /// resolves the same focused border [LayrzInputChrome] paints while focused. Each
  /// listener calls [_applyThemeStyles] directly after updating this field — the DOM
  /// is restyled in place; no Flutter rebuild is needed or triggered.
  bool _isFocused = false;

  /// The [WidgetState] set this field resolves its chrome from.
  ///
  /// Includes [WidgetState.focused] whenever [_isFocused] is true, so
  /// [LayrzInputStyleSpec.resolve] paints the same primary-color focus border
  /// [LayrzInputChrome] does while the native `<input>` has real DOM focus — see the
  /// `focus`/`blur` listeners in `login_web_field_web_dom.dart`.
  Set<WidgetState> get states => {
    if (widget.disabled) WidgetState.disabled,
    if (_isFocused) WidgetState.focused,
  };

  /// The accessible label for the password show/hide toggle while the password is
  /// currently obscured — resolved via [LayrzUiL10n.of], mirroring U4's l10n usage on
  /// the native path.
  String get passwordShowLabel => LayrzUiL10n.of(context).passwordShow;

  /// The accessible label for the password show/hide toggle while the password is
  /// currently revealed.
  String get passwordHideLabel => LayrzUiL10n.of(context).passwordHide;

  @override
  void initState() {
    super.initState();
    _viewType = 'layrz-login-web-field-${_idCounter++}';
    _registerViewFactory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveEffectiveFormId();
  }

  @override
  void didUpdateWidget(covariant LayrzLoginWebField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the native element in sync when the value is changed from outside (e.g.
    // programmatic reset), without clobbering it on every rebuild triggered by the
    // field's own onChanged (which would fight the user's cursor position).
    final input = _inputElement;
    if (input != null && widget.value != input.value && widget.value.isEmpty) {
      input.value = widget.value;
      // Assigning `.value` directly does not dispatch an `input` event, so the
      // placeholder visibility would otherwise go stale.
      _applyPlaceholderVisibility?.call();
    }

    if (input != null) {
      input.disabled = widget.disabled;
    }

    // Re-style the native DOM when any theme-relevant field actually changed — the
    // platform view is created once and never rebuilt by Flutter afterwards, so
    // without this the native element would otherwise keep whatever colors/label text
    // were current at first creation, going stale on a token change, an error-state
    // change, a disabled toggle, or a runtime language switch (which changes
    // `labelText`).
    if (widget.tokens != oldWidget.tokens ||
        widget.disabled != oldWidget.disabled ||
        widget.errors.isNotEmpty != oldWidget.errors.isNotEmpty ||
        widget.labelText != oldWidget.labelText) {
      _applyThemeStyles();
    }

    // `widget.formId` is a plain constructor parameter, not an inherited dependency —
    // a change to it alone does NOT trigger [didChangeDependencies], only this method,
    // so it must be re-resolved here too.
    if (widget.formId != oldWidget.formId) {
      _resolveEffectiveFormId();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final density = _InputComfortableHeight(tokens, dense: widget.dense);

    Widget field = SizedBox(
      height: density.fieldHeight,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );

    // Prevents Flutter's own gesture/scroll arena from stealing pointer events away
    // from the native <input>, which otherwise conflicts with ancestors such as
    // SingleChildScrollView (flutter/flutter#132183 and related issues).
    field = PointerInterceptor(child: field);

    // Static label row above the field, mirroring [LayrzInputChrome]'s own label
    // (`input_chrome.dart`'s `labelText` `Padding`/`RichText`): always `fg2`, never
    // recolored on error — only the box itself (fill/border/icons) changes state. The
    // DOM layer no longer renders any label of its own; see
    // `login_web_field_web_dom.dart`'s doc comment on why the previous
    // absolutely-positioned floating label was removed.
    final labelText = widget.labelText;
    final label = labelText == null || labelText.isEmpty
        ? null
        : Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
            child: ExcludeSemantics(
              child: Text(
                labelText,
                style: tokens.typography.label.copyWith(color: tokens.colors.fg2),
              ),
            ),
          );

    if (widget.errors.isEmpty && label == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?label,
        field,
        if (widget.errors.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sp1, left: tokens.spacing.sp3),
            child: Text(
              widget.errors.first,
              style: tokens.typography.label.copyWith(color: tokens.colors.danger),
            ),
          ),
      ],
    );
  }
}

/// Computes the fixed height of the DOM chrome's [HtmlElementView] box, mirroring
/// [LayrzInputChrome]'s own content-height + padding arithmetic
/// (`_InputComfortableSpec` in `input_chrome.dart`) so the DOM field occupies the same
/// footprint a `LayrzTextInput` would at the same [dense]/token configuration.
///
/// Kept as a tiny private helper local to this file (rather than importing the
/// chrome's own private `_InputComfortableSpec`, which is not exported) since only the
/// single derived `fieldHeight` value is needed here.
class _InputComfortableHeight {
  /// The live design tokens this computation reads padding/typography from.
  final LayrzTokens tokens;

  /// Whether the tighter, dense padding scale applies.
  final bool dense;

  /// Creates a [_InputComfortableHeight] resolver.
  const _InputComfortableHeight(this.tokens, {required this.dense});

  /// The padding applied to all sides, mirroring [LayrzInputChrome]'s own
  /// `_InputComfortableSpec.padding`.
  EdgeInsets get _padding => dense ? tokens.spacing.pd1 : tokens.spacing.pd2;

  /// The icon size, mirroring [LayrzInputChrome]'s own `_InputComfortableSpec
  /// .iconSize`.
  double get _iconSize => 14.0 + tokens.spacing.sp1;

  /// The content height, mirroring [LayrzInputChrome]'s own `_InputComfortableSpec
  /// .contentHeight`: the maximum of icon size and the text line height.
  double get _contentHeight {
    final bodyStyle = tokens.typography.body;
    final fontSize = bodyStyle.fontSize ?? 16.0;
    final lineHeightMultiplier = bodyStyle.height ?? 1.0;
    final textLineHeight = fontSize * lineHeightMultiplier;
    return textLineHeight > _iconSize ? textLineHeight : _iconSize;
  }

  /// The total field height: content height plus top/bottom padding, matching the
  /// chrome's own `SizedBox(height: contentHeight)` inside a `Container` padded by
  /// [_padding].
  double get fieldHeight => _contentHeight + _padding.vertical;
}
