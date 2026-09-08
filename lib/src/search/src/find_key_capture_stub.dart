/// Inert non-web stub for the search module's browser-level Ctrl/Cmd+F
/// capture.
///
/// Selected by `find_key_capture.dart`'s conditional export on every target
/// that is not web (`dart.library.js_interop` unavailable — mobile, desktop).
/// Native targets have no browser `document` to intercept a keydown on, so
/// this is a genuine no-op rather than a throwing placeholder — callers may
/// invoke [installFindKeyCapture] unconditionally without a `kIsWeb` guard,
/// exactly as `register_web_font_stub.dart` does for font registration.
///
/// Material-free: this file imports nothing beyond `package:flutter/foundation.dart`
/// (for [VoidCallback]). Do not import the Material or Cupertino design
/// libraries here — the CI guard checks every file under `lib/`, stub
/// included. Also imports NO `package:web`/`dart:js_interop` — that is the
/// entire point of this stub, and is what keeps those off native build
/// targets.
library;

import 'package:flutter/foundation.dart';

/// A handle to an installed find-key capture, returned by
/// [installFindKeyCapture]. Call [dispose] exactly once, when the capture is
/// no longer needed (typically from a [State.dispose]).
abstract class FindKeyCapture {
  /// Removes the underlying browser event listener (a no-op on native
  /// targets, since none was ever installed).
  void dispose();
}

/// No-op handle returned by [installFindKeyCapture] on non-web targets.
class _NoopFindKeyCapture implements FindKeyCapture {
  @override
  void dispose() {}
}

/// No-op on non-web targets: there is no browser `document` to intercept a
/// keydown on, and no native find-in-page dialog to suppress in the first
/// place — Ctrl/Cmd+F on desktop/mobile is handled entirely by the Flutter
/// focus-based [LayrzShortcut] path (see `lib/src/keyboard/`), which this file
/// does not touch.
///
/// [onFindPressed] is **never invoked** on native targets — see the real
/// implementation in `find_key_capture_web.dart` for the web behavior, where
/// it is invoked exactly when a Ctrl/Cmd+F chord is intercepted.
///
/// Parameters:
///   [onFindPressed] - the callback that would be invoked when a Ctrl/Cmd+F
///     chord is intercepted. Unused here beyond satisfying the shared
///     signature.
///
/// Returns:
///   A [FindKeyCapture] handle whose [FindKeyCapture.dispose] does nothing.
FindKeyCapture installFindKeyCapture({required VoidCallback onFindPressed}) {
  return _NoopFindKeyCapture();
}
