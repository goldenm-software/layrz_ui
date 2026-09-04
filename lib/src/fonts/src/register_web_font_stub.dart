/// Inert non-web stub for the fonts module's `@font-face` registration.
///
/// Selected by `register_web_font.dart`'s conditional export on every target that is
/// not web (`dart.library.js_interop` unavailable — mobile, desktop). Native targets
/// have no DOM to register a font with, so this is a genuine no-op rather than a
/// throwing placeholder — callers may invoke it unconditionally without a `kIsWeb`
/// guard.
///
/// Material-free: this file imports nothing beyond `dart:async`. Do not import the
/// Material or Cupertino design libraries here — the CI guard checks every file under
/// `lib/`, stub included. Also imports NO `package:web` — that is the entire point of
/// this stub, and is what keeps `package:web` off native build targets.
library;

/// No-op on non-web targets: there is no DOM to register a `@font-face` with.
///
/// See the real implementation in `register_web_font_web.dart` for what this does on
/// web.
///
/// Parameters:
///   [family] - the CSS font-family name the `@font-face` would be registered under.
///     Unused here beyond satisfying the shared signature.
///   [url] - the URL the font would be fetched from. Unused here beyond satisfying the
///     shared signature.
///
/// Returns:
///   A [Future] that completes immediately.
Future<void> registerWebFont({required String family, required String url}) async {}
