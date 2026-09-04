/// Web implementation of `registerWebFont` and `registerWebFontFromBytes`.
///
/// This file is only ever compiled on web (selected via the conditional export in
/// `register_web_font.dart`), so it may freely use `dart:js_interop` and
/// `package:web`. It registers a browser `FontFace` for either a URL-hosted font or
/// a bundled-asset font's raw bytes, so DOM-rendered content (for example, the login
/// sub-module's native `<input>` elements) can resolve CSS `font-family` against it,
/// not just the Flutter engine.
library;

import 'dart:js_interop';
import 'dart:typed_data';

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

/// Registers a `@font-face` with the browser's [web.FontFaceSet] from raw font
/// [bytes], so DOM elements can use [family] via CSS `font-family`.
///
/// This is the bundled-asset counterpart of [registerWebFont]: a font declared under
/// `pubspec.yaml`'s `flutter: fonts:` section has no network URL to build a `url(...)`
/// source from, but its bytes are available via `rootBundle.load(...)`, and a
/// [web.FontFace] can be constructed directly from those bytes as a `BufferSource`.
/// [bytes.buffer] (a [ByteBuffer]) is converted to a [JSArrayBuffer] via
/// `dart:js_interop`'s `ByteBufferToJSArrayBuffer.toJS` extension, which the
/// [web.FontFace] constructor accepts as its `source` argument in place of a CSS
/// `url(...)` string.
///
/// This shares the same [_registeredFamilies] idempotency guard as [registerWebFont]
/// — calling either function again with an already-registered [family] returns
/// immediately. Font loading failures (malformed bytes, an unsupported format) are
/// caught and reported via [debugPrint] rather than thrown, for the same reason as
/// [registerWebFont]: a missing custom font should degrade to the CSS fallback stack,
/// not crash the caller.
///
/// Parameters:
///   [family] - the CSS font-family name to register the `@font-face` under. Must
///     match the family name used both by [LayrzFont.name] and by any DOM element's
///     `font-family` CSS that expects to use this font.
///   [bytes] - the font's raw bytes, typically loaded via `rootBundle.load(assetPath)`
///     for a font declared under `pubspec.yaml`'s `flutter: fonts:` section.
///
/// Returns:
///   A [Future] that completes once the font has either been registered or its load
///   has failed and been reported.
Future<void> registerWebFontFromBytes({required String family, required ByteData bytes}) async {
  if (_registeredFamilies.contains(family)) {
    return;
  }

  final fontFace = web.FontFace(family, bytes.buffer.toJS);
  try {
    await fontFace.load().toDart;
    web.document.fonts.add(fontFace);
    _registeredFamilies.add(family);
  } catch (error) {
    debugPrint('registerWebFontFromBytes: failed to load "$family" from bytes: $error');
  }
}
