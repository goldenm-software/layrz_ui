/// Inert non-web stub for the login sub-module's DOM field.
///
/// Selected by `login_web_field.dart`'s conditional export on every target that is not
/// web (`dart.library.js_interop` unavailable — mobile, desktop). It exists purely so
/// those targets compile: [LayrzUsernameInput] / [LayrzPasswordInput] import the
/// selector unconditionally and branch on `kIsWeb` at runtime to decide whether to reach
/// for this widget at all, so [LayrzLoginWebField.build] is never actually called in a
/// shipped app — every call site is `kIsWeb`-gated before construction.
///
/// Material-free: this file imports only the base `widgets.dart` layer. Do not import
/// the Material or Cupertino design libraries here — the CI guard checks every file
/// under `lib/`, stub included.
library;

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/src/tokens.dart';

import 'login_web_field.dart';

/// Inert stand-in for the web DOM login field on non-web targets.
///
/// **This is the canonical exported symbol name.** Both this stub and the real web
/// implementation added by U6 (in `login_web_field_web.dart`) MUST be named exactly
/// `LayrzLoginWebField`, so `login_web_field.dart`'s conditional export resolves to a
/// single identifier callers name directly — see [LayrzLoginWebFieldContract] for the
/// full contract both implementations satisfy.
///
/// [build] always throws [UnsupportedError]: this widget is never meant to render
/// anything, because non-web callers never construct it in the first place (they take
/// the native `LayrzTextInput` pass-through branch instead).
class LayrzLoginWebField extends StatefulWidget implements LayrzLoginWebFieldContract {
  /// Which credential field this is — selects the DOM `type`/`autocomplete` pairing on
  /// the web implementation. Unused here beyond satisfying the shared contract.
  final LayrzLoginFieldKind kind;

  /// The current field value, used to seed the DOM `<input>` once on web. Unused here
  /// beyond satisfying the shared contract.
  final String value;

  /// The label displayed above the field, mirroring `LayrzTextInput.labelText`. Unused
  /// here beyond satisfying the shared contract.
  final String? labelText;

  /// Validation error messages displayed below the field, mirroring
  /// `LayrzTextInput.errors`. Unused here beyond satisfying the shared contract.
  final List<String> errors;

  /// Fired with the new value whenever the underlying DOM `<input>` fires its own
  /// `input` event, on the web implementation. Unused here beyond satisfying the shared
  /// contract.
  final ValueChanged<String>? onChanged;

  /// Fired with the current value on submission (DOM `Enter` keydown / form
  /// submission), on the web implementation. Unused here beyond satisfying the shared
  /// contract.
  final ValueChanged<String>? onSubmit;

  /// The `AutofillHints`-style hint strings translated into the DOM `autocomplete`
  /// value on the web implementation. Unused here beyond satisfying the shared
  /// contract.
  final List<String> autofillHints;

  /// The HTML `<form>` id this field's `<input>` should be associated with, on the web
  /// implementation, so the browser groups credential fields together. Unused here
  /// beyond satisfying the shared contract.
  final String? formId;

  /// Mirrors `LayrzTextInput.disabled`. Unused here beyond satisfying the shared
  /// contract.
  final bool disabled;

  /// Mirrors `LayrzTextInput.dense`, selecting the tighter padding scale. Unused here
  /// beyond satisfying the shared contract.
  final bool dense;

  /// The live design tokens the web CSS chrome would read for radius, padding, and
  /// color. Unused here beyond satisfying the shared contract.
  final LayrzTokens tokens;

  /// Creates a [LayrzLoginWebField] (the inert non-web stub).
  ///
  /// All parameters mirror [LayrzLoginWebFieldContract] exactly; none has any effect
  /// here since [build] always throws before using them. They exist only so this stub
  /// type-checks identically to the real web implementation at every call site.
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
  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      'LayrzLoginWebField (non-web stub) cannot be built. It is the non-web '
      'compile-time stand-in for the login sub-module\'s DOM field and must never be '
      'instantiated at runtime — call sites in LayrzUsernameInput/LayrzPasswordInput '
      'are kIsWeb-gated and take the native LayrzTextInput pass-through branch on every '
      'non-web target instead.',
    );
  }
}
