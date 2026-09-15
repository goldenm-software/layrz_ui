/// Inert non-web stub for `LayrzOtpInput`'s 6-input DOM field.
///
/// Selected by `otp_web_field.dart`'s conditional export on every target that is not web
/// (`dart.library.js_interop` unavailable — mobile, desktop). It exists purely so those
/// targets compile: `otp_input.dart` imports the selector unconditionally and branches on
/// `kIsWeb` at runtime before ever constructing this widget, so [LayrzOtpWebField.build]
/// is never actually called in a shipped non-web app.
///
/// Material-free: this file imports only the base `widgets.dart` layer. Do not import the
/// Material or Cupertino design libraries here — the CI guard checks every file under
/// `lib/`, stub included.
library;

import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// Inert stand-in for the web 6-input DOM OTP field on non-web targets.
///
/// **This is the canonical exported symbol name.** Both this stub and the real web
/// implementation (`otp_web_field_web.dart`) are named exactly `LayrzOtpWebField`, so
/// `otp_web_field.dart`'s conditional export resolves to a single identifier callers name
/// directly.
///
/// [build] always throws [UnsupportedError]: this widget is never meant to render
/// anything, because non-web callers never construct it (they take `otp_input.dart`'s
/// native `EditableText`-plus-painted-slots branch instead).
class LayrzOtpWebField extends StatefulWidget {
  /// The current OTP code, as a string of digits (up to 6 characters). Unused here beyond
  /// satisfying the shared constructor shape.
  final String value;

  /// Fired with the raw aggregated code every time any digit box changes, on the web
  /// implementation. Unused here.
  final ValueChanged<String>? onChanged;

  /// Fired once the code reaches all 6 digits, on the web implementation. Unused here.
  final ValueChanged<String>? onCompleted;

  /// Whether the field is disabled. Unused here beyond satisfying the shared shape.
  final bool disabled;

  /// The list of error messages associated with the field. Unused here.
  final List<String> errors;

  /// Whether the field is read-only. Unused here beyond satisfying the shared shape.
  final bool readOnly;

  /// An explicit HTML `<form>` id override for the underlying DOM inputs. Unused here.
  final String? formId;

  /// The resolved design tokens used for color, spacing, radius, and border. Unused here
  /// beyond satisfying the shared shape.
  final LayrzTokens tokens;

  /// Creates a [LayrzOtpWebField] (the inert non-web stub).
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
  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      'LayrzOtpWebField (non-web stub) cannot be built. It is the non-web compile-time '
      'stand-in for LayrzOtpInput\'s 6-input DOM field and must never be instantiated at '
      'runtime — otp_input.dart is kIsWeb-gated and takes the native '
      'EditableText-plus-painted-slots branch on every non-web target instead.',
    );
  }
}
