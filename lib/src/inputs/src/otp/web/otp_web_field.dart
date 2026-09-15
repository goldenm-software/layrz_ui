/// Compile-time selector for `LayrzOtpInput`'s web 6-input DOM field.
///
/// A standalone library (not a `part`) because only a top-level library can declare a
/// conditional export. It resolves at compile time to one of two implementations, both
/// exported under the SAME concrete symbol name — `LayrzOtpWebField`:
///
/// - On web (`dart.library.js_interop` available): `otp_web_field_web.dart`, which renders
///   six real HTML `<input>` elements (one per digit) via a `dart:ui_web` platform view,
///   each carrying `autocomplete="one-time-code"` and Dashlane's `data-form-type="otp"`
///   SAWF annotation so a password manager recognizes and fills each box.
/// - Everywhere else: `otp_web_field_stub.dart`, an inert stub whose `build` throws
///   [UnsupportedError]. Every call site is `kIsWeb`-gated, so the stub is never
///   instantiated at runtime — it exists only so non-web targets compile.
///
/// ## Why six real inputs instead of one hidden input
/// `LayrzOtpInput`'s native path is a single, fully-transparent `EditableText` with six
/// painted slots on top. That single-field approach also works on web (a password manager
/// fills the one field), but shows the password manager's own affordance — icon, autofill
/// background — anchored to that one field, spilling around the painted slots. Rendering
/// six real, visible `<input>` boxes instead — each a genuine one-time-code field the
/// password manager decorates and fills in place — keeps the manager's UI aligned to the
/// boxes the user actually sees. See `otp_web_field_web.dart` for the DOM/auto-advance/
/// paste-distribution mechanism and decision D82 in `engineering/decisions.md`.
library;

export 'otp_web_field_stub.dart' if (dart.library.js_interop) 'otp_web_field_web.dart';
