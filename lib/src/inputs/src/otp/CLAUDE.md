# otp — LayrzOtpInput

Two completely separate render paths in `otp_input.dart`, chosen by `kIsWeb` in `build()`:
- **Native:** a transparent `EditableText` with six painted `OtpSlot`s on top. The controller listener `_handleControllerChanged` is the only thing that emits `onChanged`/`onCompleted`.
- **Web:** `LayrzOtpWebField` (see `web/`), six real DOM `<input>`s. The web field emits `onChanged` and `onCompleted` itself.

## Web-only double-callback trap (fixed)
The web `onChanged` closure in `_buildWeb` writes `_controller.text = value` so callers can still read the controller. Without a guard, that write tripped the native-path listener, so callers got `onChanged` two to three times and `onCompleted` twice per edit.

The fix, which must stay:
- Wrap the controller write in `_isInternalUpdate = true/false`.
- Sync `_lastEmittedText` and `_wasComplete` by hand afterwards.
- Leave `LayrzOtpWebField` as the only emitter of `onCompleted` on web.

The native path never had this bug. Don't "simplify" the web guard away because native doesn't need it.

## Testing limit
The web branch needs `kIsWeb`, which VM tests can't reach, so the double-fire has no automated regression test. Verify in a browser: type a full code and confirm `onChanged` fires once per keystroke and `onCompleted` fires once.
