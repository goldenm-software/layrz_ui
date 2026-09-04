/// Compile-time selector for the fonts module's browser `@font-face` registration.
///
/// This is a standalone library (not a `part`) because only a top-level library can
/// declare a conditional export. It resolves at compile time to one of two
/// implementations, both exported under the SAME top-level function name —
/// `registerWebFont` — mirroring the pattern used by the login sub-module's
/// `login_web_field.dart`: callers name one identifier and the conditional export
/// decides which implementation answers to it, so no call site ever branches on which
/// one it got.
///
/// - On web (`dart.library.js_interop` available): `register_web_font_web.dart`
///   registers a real `FontFace` with `document.fonts` via `package:web`.
/// - Everywhere else: `register_web_font_stub.dart` is a no-op — native targets have no
///   DOM to register a font with.
///
/// [LayrzFont.registerOnWeb] implementations call `registerWebFont` from this selector
/// rather than importing either concrete file directly, so they never need to guard
/// against `package:web` reaching a native build themselves.
library;

export 'register_web_font_stub.dart' if (dart.library.js_interop) 'register_web_font_web.dart';
