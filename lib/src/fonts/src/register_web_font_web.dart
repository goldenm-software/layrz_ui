/// Web implementation of `registerWebFont`.
///
/// This file is only ever compiled on web (selected via the conditional export in
/// `register_web_font.dart`), so it may freely use `dart:js_interop` and
/// `package:web`. It registers a browser `FontFace` for a URL-hosted font, so
/// DOM-rendered content (for example, the login sub-module's native `<input>`
/// elements) can resolve CSS `font-family` against it, not just the Flutter engine.
library;

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// The CSS font-family names this session has already registered with the browser.
///
/// [web.FontFaceSet] (`document.fonts`) is a JS `Set`-like object that
/// `package:web`'s binding does not expose as a Dart-iterable, so idempotency is
/// tracked here instead of by inspecting `document.fonts` directly. This is
/// per-isolate state, which is exactly the lifetime a registered `@font-face` has
/// anyway — it does not need to survive a full page reload, only repeated calls
/// within one running app.
final Set<String> _registeredFamilies = <String>{};

/// Registers a `@font-face` with the browser's [web.FontFaceSet] so DOM elements can
/// use [family] via CSS `font-family`.
///
/// This is idempotent: calling it again with the same [family] within the same app
/// session returns immediately without adding a duplicate `FontFace`. Font loading
/// failures (network error, malformed font, CORS rejection) are caught and reported
/// via [debugPrint] rather than thrown — a missing custom font should degrade to
/// whatever fallback the CSS `font-family` stack provides, not crash the caller.
///
/// Parameters:
///   [family] - the CSS font-family name to register the `@font-face` under. Must
///     match the family name used both by [LayrzFont.name] and by any DOM element's
///     `font-family` CSS that expects to use this font.
///   [url] - the URL to fetch the font's bytes from (typically a CDN URL for a
///     `.ttf`/`.woff2` file).
///
/// Returns:
///   A [Future] that completes once the font has either been registered or its load
///   has failed and been reported.
Future<void> registerWebFont({required String family, required String url}) async {
  if (_registeredFamilies.contains(family)) {
    return;
  }

  final fontFace = web.FontFace(family, 'url($url)'.toJS);
  try {
    await fontFace.load().toDart;
    web.document.fonts.add(fontFace);
    _registeredFamilies.add(family);
  } catch (error) {
    debugPrint('registerWebFont: failed to load "$family" from "$url": $error');
  }
}
