import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../text/text_input.dart';
import 'password_strength.dart';
import 'password_strength_meter.dart';
import 'web/login_web_field.dart';
import 'web/login_web_group.dart';

/// The default autofill hints applied to [LayrzPasswordInput] when the caller does not
/// supply an override.
///
/// A single hint — `AutofillHints.password` — is enough for password managers to
/// recognize the secret half of a credential pair; unlike the username field, there is
/// no secondary hint needed to disambiguate an email-shaped identifier.
const List<String> kLayrzPasswordInputDefaultAutofillHints = [AutofillHints.password];

/// A login-specialized password input with a show/hide toggle and an optional,
/// informational strength meter.
///
/// [LayrzPasswordInput] is a thin, opinionated wrapper that pre-configures
/// [LayrzTextInput] for the secret half of a login form: a shield-key prefix icon, an
/// obscured value by default with an eye-toggle suffix to reveal it, and the autofill
/// hint browser/OS password managers use to recognize the field as a credential secret.
///
/// **Platform behavior:**
/// - **Native (mobile + desktop):** renders [LayrzTextInput] directly — this is the real
///   `layrz_ui` chrome, pixel-perfect because it *is* the chrome. [LayrzInputChrome] is
///   never modified. The eye toggle is composed as a caller-supplied `suffix` widget
///   (not `suffixIcon`) precisely so it can carry its own accessible name and live-region
///   announcement — the chrome renders any widget slot's own [Semantics] node untouched
///   (see the input-slot documentation, "the caller's own responsibility"), which is the
///   sanctioned way to add an accessible name to a suffix affordance without adding a
///   new parameter to the frozen chrome or to [LayrzTextInput] itself.
/// - **Web:** renders a real HTML `<input>` via [LayrzLoginWebField] (the login
///   sub-module's private web selector), so browser password managers can detect,
///   suggest, and fill the field. The DOM `<input>` owns its own `type` swap and eye
///   toggle on that platform; this widget still renders the Flutter strength meter as a
///   sibling below when [showStrengthMeter] is true.
///
/// Both platforms expose the exact same public API, so callers write one widget and
/// never branch on platform themselves.
///
/// **Strength meter is opt-in, not default.** [showStrengthMeter] defaults to `false`:
/// a login field authenticates against a password the user already chose and cannot
/// edit from that screen, so a strength reading there is noise, not guidance. Pass
/// `showStrengthMeter: true` on a registration/password-creation flow, where the
/// meter's 4-segment bar plus requirement checklist (see [LayrzPasswordStrengthMeter])
/// helps the user pick a stronger password as they type. The rules and colors —
/// including a legitimate danger-red reading for an invalid or very short password —
/// match `layrz_theme`'s `ThemedPasswordInput` exactly; see [LayrzPasswordRequirements]
/// for the precise thresholds.
///
/// **Grouping with the username field:** on native, wrap both login fields in a Flutter
/// `AutofillGroup` (the caller's responsibility — this widget does not invent its own
/// grouping mechanism). On web, wrap both fields in a `LayrzLoginWebGroup` so they share
/// one HTML `<form>` id and the browser treats them as a single credential set.
class LayrzPasswordInput extends StatefulWidget {
  /// The label text displayed above the input field.
  ///
  /// When null, falls back to [LayrzUiL10nPasswordMixin.loginPasswordLabel] ("Password")
  /// resolved from [LayrzUiL10n.of].
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// The text editing controller for the input field.
  ///
  /// If null, a controller is created and disposed by the widget, mirroring
  /// [LayrzTextInput]'s disposal contract.
  final TextEditingController? controller;

  /// The focus node for the input field.
  ///
  /// If null, a focus node is created and disposed by the widget, mirroring
  /// [LayrzTextInput]'s disposal contract.
  final FocusNode? focusNode;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether the field is disabled.
  ///
  /// A disabled field is not editable and not focusable; callbacks do not fire. The
  /// eye-toggle affordance is also disabled and stops responding to taps while this is
  /// true.
  final bool disabled;

  /// Whether the field uses the dense density variant.
  ///
  /// Mirrors [LayrzTextInput.dense] on native, and selects the tighter CSS padding
  /// scale on the web DOM field.
  final bool dense;

  /// Callback fired when the input value changes.
  final ValueChanged<String>? onChanged;

  /// Callback fired when the user submits the input (e.g., presses Enter).
  final ValueChanged<String>? onSubmit;

  /// The autofill hints applied to the field.
  ///
  /// Defaults to [kLayrzPasswordInputDefaultAutofillHints] (`[AutofillHints.password]`).
  /// On native this flows straight through to [LayrzTextInput.autofillHints]. On web
  /// these are translated into the DOM `autocomplete` value the underlying `<input>`
  /// carries, in addition to the base password `type`/`autocomplete` pairing
  /// [LayrzLoginFieldKind.password] already selects.
  final List<String> autofillHints;

  /// An explicit HTML `<form>` id override for the web DOM field.
  ///
  /// Normally left null: the widget resolves the group id automatically from the
  /// nearest enclosing [LayrzLoginWebGroup] via `LayrzLoginWebGroup.maybeOf`. Set this
  /// only when the caller needs to force a specific id outside that provider. Has no
  /// effect on native, where grouping is the caller's own Flutter `AutofillGroup`.
  final String? formId;

  /// Whether to render an informational password-strength meter below the field.
  ///
  /// Defaults to `false` — a plain login field with no meter. Set to `true` on a
  /// registration or password-creation flow, where scoring the in-progress value as the
  /// user types is actionable guidance rather than noise. When enabled, the meter reads
  /// the live [controller] text and re-scores on every change, rendering a full-width
  /// 4-segment strength bar followed by a checklist of the four character-class
  /// requirements — see [LayrzPasswordStrengthMeter] and [LayrzPasswordRequirements]
  /// for the exact rules (matching `layrz_theme`'s `ThemedPasswordInput`).
  final bool showStrengthMeter;

  /// Creates a [LayrzPasswordInput].
  const LayrzPasswordInput({
    super.key,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.controller,
    this.focusNode,
    this.errors = const [],
    this.disabled = false,
    this.dense = false,
    this.onChanged,
    this.onSubmit,
    this.autofillHints = kLayrzPasswordInputDefaultAutofillHints,
    this.formId,
    this.showStrengthMeter = false,
  });

  @override
  State<LayrzPasswordInput> createState() => _LayrzPasswordInputState();
}

class _LayrzPasswordInputState extends State<LayrzPasswordInput> {
  late TextEditingController _controller;

  /// Whether the password value is currently rendered obscured (native path).
  ///
  /// Starts `true` — a login/password field is obscured by default until the user
  /// explicitly reveals it via the eye toggle.
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(LayrzPasswordInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleControllerChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Rebuilds on every controller mutation so the live strength meter — when
  /// [LayrzPasswordInput.showStrengthMeter] is true — re-scores against the value as the
  /// user types, even though this widget does not otherwise read `_controller.text` in
  /// its own layout.
  void _handleControllerChanged() {
    if (widget.showStrengthMeter) {
      setState(() {});
    }
  }

  /// Flips [_obscure].
  ///
  /// The state-change announcement itself is fired by the sibling
  /// [_LiveAnnouncement] node built in [build] — see its class doc for why a
  /// dedicated live-region node, rather than an imperative announce call, is the
  /// approach used here.
  void _toggleObscure() {
    if (widget.disabled) {
      return;
    }
    setState(() {
      _obscure = !_obscure;
    });
  }

  /// Builds the eye-toggle affordance as a `suffix` widget (never `suffixIcon`).
  ///
  /// [LayrzInputChrome] renders a caller-supplied widget slot's own [Semantics] node
  /// untouched — see the input-slot documentation, "the caller's own responsibility" —
  /// so composing the toggle this way is how it gets a named button without adding a
  /// parameter to the frozen chrome or to [LayrzTextInput]. [Semantics.label] carries
  /// the toggle's stable accessible name — [LayrzUiL10nPasswordMixin.passwordShow] while
  /// obscured, [LayrzUiL10nPasswordMixin.passwordHide] once revealed — describing what
  /// tapping the button does NEXT. The state-change announcement (what JUST happened)
  /// is a separate concern, handled by [_LiveAnnouncement] in [build].
  Widget _buildEyeToggle(LayrzUiL10n l10n) {
    final label = _obscure ? l10n.passwordShow : l10n.passwordHide;
    final onTap = widget.disabled ? null : _toggleObscure;
    return Semantics(
      container: true,
      button: true,
      enabled: !widget.disabled,
      label: label,
      onTap: onTap,
      child: MouseRegion(
        cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Icon(
            _obscure ? MdiIcons.eyeOutline : MdiIcons.eyeOffOutline,
            size: 20,
            color: context.tokens.colors.fg2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final resolvedLabel = widget.labelText ?? l10n.loginPasswordLabel;
    final announcement = _obscure ? l10n.passwordHiddenAnnouncement : l10n.passwordShownAnnouncement;

    final strengthMeter = widget.showStrengthMeter
        ? Padding(
            padding: EdgeInsets.only(top: context.tokens.spacing.sp2),
            child: LayrzPasswordStrengthMeter.fromPassword(password: _controller.text),
          )
        : null;

    if (kIsWeb) {
      final webField = LayrzLoginWebField(
        kind: LayrzLoginFieldKind.password,
        value: _controller.text,
        labelText: resolvedLabel,
        errors: widget.errors,
        onChanged: (value) {
          _controller.text = value;
          widget.onChanged?.call(value);
        },
        onSubmit: widget.onSubmit,
        autofillHints: widget.autofillHints,
        formId: widget.formId ?? LayrzLoginWebGroup.maybeOf(context),
        disabled: widget.disabled,
        dense: widget.dense,
        tokens: context.tokens,
      );

      if (strengthMeter == null) {
        return webField;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [webField, strengthMeter],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            LayrzTextInput(
              labelText: resolvedLabel,
              hintText: widget.hintText,
              isRequired: widget.isRequired,
              prefixIcon: MdiIcons.shieldKeyOutline,
              obscureText: _obscure,
              suffix: _buildEyeToggle(l10n),
              autofillHints: widget.autofillHints,
              controller: _controller,
              focusNode: widget.focusNode,
              errors: widget.errors,
              disabled: widget.disabled,
              dense: widget.dense,
              onChanged: widget.onChanged,
              onSubmit: widget.onSubmit,
            ),
            _LiveAnnouncement(message: announcement, obscure: _obscure),
          ],
        ),
        ?strengthMeter,
      ],
    );
  }
}

/// A visually invisible, near-zero-size live-region announcer for the password
/// visibility toggle.
///
/// Assistive technology announces a [Semantics] node's [Semantics.liveRegion] text
/// when that text changes, without requiring focus to move to it. The child is a
/// 1x1 [SizedBox] rather than [SizedBox.shrink] (0x0) — a fully zero-size subtree can
/// be pruned from the compiled semantics tree before its live-region label is
/// considered, which would silently drop the announcement. A single logical pixel is
/// visually indistinguishable from nothing while remaining large enough to keep its
/// [Semantics] node in the compiled tree. This widget is keyed by [obscure] so a
/// fresh element — and a fresh liveRegion announcement — is produced on every toggle,
/// even though consecutive announcements never repeat the same [message] here (since
/// [obscure] alternates the message string on each toggle).
class _LiveAnnouncement extends StatelessWidget {
  /// The text announced to assistive technology.
  final String message;

  /// The current obscure state, used only as this widget's [Key] so a new element (and
  /// therefore a fresh announcement) is produced on every toggle.
  final bool obscure;

  /// Creates a new [_LiveAnnouncement].
  const _LiveAnnouncement({required this.message, required this.obscure});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(obscure),
      child: Semantics(
        liveRegion: true,
        label: message,
        child: const SizedBox(width: 1, height: 1),
      ),
    );
  }
}
