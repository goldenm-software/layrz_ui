/// Compile-time selector for the fonts module's browser `@font-face` registration.
///
/// This is a standalone library (not a `part`) because only a top-level library can
/// declare a conditional export. It resolves at compile time to one of two
/// implementations, exposing TWO top-level entry points under the same names in
/// both — `registerWebFont` (URL-hosted fonts) and `registerWebFontFromBytes`
/// (bundled-asset fonts, registered from raw bytes) — mirroring the pattern used by
/// the login sub-module's `login_web_field.dart`: callers name one identifier and the
/// conditional export decides which implementation answers to it, so no call site
/// ever branches on which one it got.
///
/// - On web (`dart.library.js_interop` available): `register_web_font_web.dart`
///   registers a real `FontFace` with `document.fonts` via `package:web`, either from
///   a URL or from bytes.
/// - Everywhere else: `register_web_font_stub.dart` provides no-ops for both — native
///   targets have no DOM to register a font with.
///
/// [LayrzFont.registerOnWeb] implementations call `registerWebFont` or
/// `registerWebFontFromBytes` from this selector rather than importing either
/// concrete file directly, so they never need to guard against `package:web`
/// reaching a native build themselves.
library;

export 'register_web_font_stub.dart' if (dart.library.js_interop) 'register_web_font_web.dart';
