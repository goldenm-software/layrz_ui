/// Web implementation of [installFindKeyCapture].
///
/// This file is only ever compiled on web (selected via the conditional
/// export in `find_key_capture.dart`), so it may freely use `dart:js_interop`
/// and `package:web`. It installs a real browser-level `keydown` listener on
/// `document` and calls `preventDefault()`/`stopPropagation()` on a
/// Ctrl/Cmd+F chord, so the browser's own native find-in-page UI never opens
/// — the entire point of DESIGN-109 is to replace that native UI with a
/// themed in-app one, which only works if the native one is suppressed first.
library;

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// A handle to an installed find-key capture, returned by
/// [installFindKeyCapture]. Call [dispose] exactly once, when the capture is
/// no longer needed (typically from a [State.dispose]).
abstract class FindKeyCapture {
  /// Removes the underlying `document.removeEventListener('keydown', ...)`
  /// registration. Safe to call at most once — this implementation does not
  /// guard against a double-dispose, matching the simple lifetime a spike
  /// harness needs; a production widget should guard call sites instead
  /// (e.g. via its own `State.dispose`, which Flutter guarantees runs once).
  void dispose();
}

/// The real, web-only [FindKeyCapture]: holds the exact [JSFunction] instance
/// passed to `addEventListener`, since `removeEventListener` matches listeners
/// by function identity — passing a *new* `.toJS`-wrapped closure (even one
/// wrapping an identical Dart closure) would not remove the original
/// registration, silently leaking the listener for the lifetime of the page.
class _WebFindKeyCapture implements FindKeyCapture {
  /// Creates a [_WebFindKeyCapture] that will remove [_listener] on
  /// [dispose].
  _WebFindKeyCapture(this._listener);

  /// The exact `JSFunction` registered with `document.addEventListener` —
  /// retained so [dispose] can pass the identical reference to
  /// `removeEventListener`.
  final web.EventListener _listener;

  @override
  void dispose() {
    web.document.removeEventListener('keydown', _listener);
  }
}

/// Installs a `document`-level `keydown` listener that intercepts Ctrl+F
/// (Windows/Linux) and Cmd+F (macOS), calling `event.preventDefault()` and
/// `event.stopPropagation()` so the browser's native find-in-page dialog
/// never opens, then invokes [onFindPressed] so the caller can show its own
/// in-app find UI instead.
///
/// The chord check is `(ctrlKey || metaKey) && (key == 'f' || key == 'F')` —
/// both modifier keys are accepted (rather than branching on OS) since a
/// Windows/Linux keyboard reports `ctrlKey` and a Mac keyboard reports
/// `metaKey` for the "primary modifier" chord in both the OS-native find
/// shortcut and most apps' in-app equivalent; checking both directly is
/// simpler and more robust than trying to detect the host OS first. Checking
/// both `'f'` and `'F'` guards against a browser or OS keyboard layout that
/// reports the already-shifted character in [web.KeyboardEvent.key] (e.g. a
/// layout where Shift is held for an unrelated reason) — the modifier check
/// already narrows this to the Ctrl/Cmd+F chord specifically, this only
/// widens which case of the letter is accepted.
///
/// Returns a [FindKeyCapture] whose [FindKeyCapture.dispose] removes the
/// listener — callers must call it exactly once, typically from their own
/// [State.dispose], to avoid leaking the listener for the lifetime of the
/// page (this matters especially for a spike harness that may be mounted and
/// unmounted repeatedly while iterating).
///
/// Parameters:
///   [onFindPressed] - invoked once per intercepted Ctrl/Cmd+F chord, after
///     the native browser action has already been suppressed.
///
/// Returns:
///   A [FindKeyCapture] handle for later [FindKeyCapture.dispose].
FindKeyCapture installFindKeyCapture({required VoidCallback onFindPressed}) {
  void handleKeyDown(web.Event event) {
    final keyboardEvent = event as web.KeyboardEvent;
    final isPrimaryModifier = keyboardEvent.ctrlKey || keyboardEvent.metaKey;
    final isFKey = keyboardEvent.key == 'f' || keyboardEvent.key == 'F';
    if (!isPrimaryModifier || !isFKey) {
      return;
    }
    keyboardEvent.preventDefault();
    keyboardEvent.stopPropagation();
    onFindPressed();
  }

  final listener = handleKeyDown.toJS;
  web.document.addEventListener('keydown', listener);
  return _WebFindKeyCapture(listener);
}
