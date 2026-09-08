/// Compile-time selector for the search module's browser-level Ctrl/Cmd+F
/// capture.
///
/// This is a standalone library (not a `part`) because only a top-level
/// library can declare a conditional export. It resolves at compile time to
/// one of two implementations, both exposing the same top-level entry point
/// — `installFindKeyCapture` — and the same [FindKeyCapture] handle type,
/// mirroring the pattern used by the fonts module's `register_web_font.dart`:
/// callers name one identifier and the conditional export decides which
/// implementation answers to it, so no call site ever branches on which one
/// it got.
///
/// - On web (`dart.library.js_interop` available): `find_key_capture_web.dart`
///   installs a real `document.addEventListener('keydown', ...)` via
///   `package:web`, calling `preventDefault()`/`stopPropagation()` on a
///   Ctrl/Cmd+F chord so the browser's native find-in-page dialog never opens.
/// - Everywhere else: `find_key_capture_stub.dart` provides a no-op handle —
///   native targets have no browser-level find to suppress; the Flutter
///   [LayrzShortcut] focus-based path (see `lib/src/keyboard/`) is what
///   handles Ctrl/Cmd+F on those platforms, and is unaffected by this file.
///
/// `LayrzFindSpike` (the spike harness widget) calls `installFindKeyCapture`
/// from this selector rather than importing either concrete file directly, so
/// it never needs to guard against `package:web` reaching a native build
/// itself.
library;

export 'find_key_capture_stub.dart' if (dart.library.js_interop) 'find_key_capture_web.dart';
