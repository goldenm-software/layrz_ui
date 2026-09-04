import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../text/text_input.dart';
import 'web/login_web_field.dart';
import 'web/login_web_group.dart';

/// The default autofill hints applied to [LayrzUsernameInput] when the caller does not
/// supply an override.
///
/// Both hints are set together — `AutofillHints.username` marks the field as the
/// credential identifier, and `AutofillHints.email` is additionally required by some
/// password managers (Dashlane, confirmed in the `layrz_session` prior art) to match the
/// field when the identifier is an email address.
const List<String> kLayrzUsernameInputDefaultAutofillHints = [AutofillHints.username, AutofillHints.email];

/// A login-specialized text input for the credential identifier (username or email).
///
/// [LayrzUsernameInput] is a thin, opinionated wrapper that pre-configures
/// [LayrzTextInput] for the username/email half of a login form: a shield-account
/// prefix icon, the email keyboard (so `@` is easily reachable), autocorrect disabled,
/// and the autofill hints browser/OS password managers use to recognize the field as a
/// credential identifier.
///
/// **Platform behavior:**
/// - **Native (mobile + desktop):** renders [LayrzTextInput] directly — this is the real
///   `layrz_ui` chrome, pixel-perfect because it *is* the chrome. [LayrzInputChrome] is
///   never modified; every login-specific concern (icon, keyboard, autofill hints) is a
///   parameter [LayrzTextInput] already exposes.
/// - **Web:** renders a real HTML `<input>` via [LayrzLoginWebField] (the login
///   sub-module's private web selector), so browser password managers can detect and
///   fill the field — something Flutter web's own text rendering cannot reliably trigger
///   (see the implementation plan's engine-limitation findings). The web field's visual
///   chrome mirrors [LayrzTextInput]'s token-derived appearance and state resolution; it
///   is not expected to be pixel-identical, only recognizably a `layrz_ui` input.
///
/// Both platforms expose the exact same public API, so callers write one widget and
/// never branch on platform themselves.
///
/// **Grouping with the password field:** on native, wrap both login fields in a Flutter
/// `AutofillGroup` (the caller's responsibility — this widget does not invent its own
/// grouping mechanism). On web, wrap both fields in a [LayrzLoginWebGroup] so they share
/// one HTML `<form>` id and the browser treats them as a single credential set.
class LayrzUsernameInput extends StatefulWidget {
  /// The label text displayed above the input field.
  ///
  /// When null, falls back to [LayrzUiL10nPasswordMixin.loginUsernameLabel] ("Username")
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
  /// A disabled field is not editable and not focusable; callbacks do not fire.
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
  /// Defaults to [kLayrzUsernameInputDefaultAutofillHints]
  /// (`[AutofillHints.username, AutofillHints.email]`). On native this flows straight
  /// through to [LayrzTextInput.autofillHints]. On web these are translated into the DOM
  /// `autocomplete` value the underlying `<input>` carries, in addition to the base
  /// username `type`/`autocomplete` pairing [LayrzLoginFieldKind.username] already
  /// selects. Override only if the login form's identifier semantics differ from the
  /// username/email default (e.g. a phone-number identifier).
  final List<String> autofillHints;

  /// An explicit HTML `<form>` id override for the web DOM field.
  ///
  /// Normally left null: the widget resolves the group id automatically from the
  /// nearest enclosing [LayrzLoginWebGroup] via `LayrzLoginWebGroup.maybeOf`. Set this
  /// only when the caller needs to force a specific id outside that provider. Has no
  /// effect on native, where grouping is the caller's own Flutter `AutofillGroup`.
  final String? formId;

  /// Creates a [LayrzUsernameInput].
  const LayrzUsernameInput({
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
    this.autofillHints = kLayrzUsernameInputDefaultAutofillHints,
    this.formId,
  });

  @override
  State<LayrzUsernameInput> createState() => _LayrzUsernameInputState();
}

class _LayrzUsernameInputState extends State<LayrzUsernameInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(LayrzUsernameInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final resolvedLabel = widget.labelText ?? l10n.loginUsernameLabel;

    if (kIsWeb) {
      return LayrzLoginWebField(
        kind: LayrzLoginFieldKind.username,
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
    }

    return LayrzTextInput(
      labelText: resolvedLabel,
      hintText: widget.hintText,
      isRequired: widget.isRequired,
      prefixIcon: MdiIcons.shieldAccountOutline,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      controller: _controller,
      focusNode: widget.focusNode,
      errors: widget.errors,
      disabled: widget.disabled,
      dense: widget.dense,
      onChanged: widget.onChanged,
      onSubmit: widget.onSubmit,
    );
  }
}
