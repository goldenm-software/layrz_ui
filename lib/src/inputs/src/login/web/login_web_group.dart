/// Compile-time selector for the login sub-module's web form-grouping provider.
///
/// Mirrors `login_web_field.dart`'s split exactly, for the separate concern of
/// associating a username field and a password field into one HTML `<form>` so browser
/// password managers treat them as a single credential set. This is a standalone
/// library (not a `part`) because only a top-level library can declare a conditional
/// export. Both branches export the SAME concrete symbol name — `LayrzLoginWebGroup` —
/// so callers name one identifier regardless of platform.
///
/// - On web (`dart.library.js_interop` available): `login_web_group_web.dart` MUST
///   export a class named EXACTLY `LayrzLoginWebGroup`, implementing
///   [LayrzLoginWebGroupContract], that provides the real `formId` resolution (built by
///   U6). Its shape MUST match the contract exactly: a `formId` (`String?`) + `child`
///   (`Widget`) constructor, and a static `maybeOf(BuildContext)` accessor.
/// - Everywhere else: `login_web_group_stub.dart` exports the same-named
///   `LayrzLoginWebGroup`, an inert passthrough — it never needs to do anything real,
///   since [LayrzLoginWebFieldContract]'s `formId` is only ever consumed by the web
///   field implementation.
///
/// **Internal to the login sub-module** — not exported from any barrel, not a reusable
/// primitive. See the "no parallel input engine" hard constraint in the implementation
/// plan.
library;

export 'login_web_group_stub.dart' if (dart.library.js_interop) 'login_web_group_web.dart';

import 'package:flutter/widgets.dart';

/// Public contract for the login sub-module's web form-grouping provider.
///
/// [LayrzUsernameInput] and [LayrzPasswordInput] wrap themselves in this provider's
/// widget (when the caller wants web-side grouping) to resolve a shared `formId` for
/// their [LayrzLoginWebFieldContract.formId] parameter, mirroring how native callers
/// wrap the same pair in Flutter's `AutofillGroup`. Both the stub (U5, this unit) and
/// the web implementation (U6) MUST expose exactly this shape under the SAME concrete
/// symbol name, `LayrzLoginWebGroup`:
///
/// - A widget named `LayrzLoginWebGroup`, taking a required `child` (`Widget`) and an
///   optional `formId` (`String?`) override — when omitted, the provider generates a
///   stable id for the lifetime of its `State`.
/// - A static `maybeOf(BuildContext)` accessor returning the resolved `formId` (`
///   String?`) from the nearest enclosing group, or `null` if there is none — mirroring
///   the `InheritedWidget` lookup convention already used elsewhere in `layrz_ui`
///   (e.g. `LayrzTheme.maybeOf`).
///
/// This class itself renders nothing — it documents the contract. Both concrete
/// implementations are named `LayrzLoginWebGroup`: the inert passthrough in
/// `login_web_group_stub.dart` (this unit) and the real web grouping provider added by
/// U6 in `login_web_group_web.dart`.
@immutable
abstract class LayrzLoginWebGroupContract {
  /// Creates a [LayrzLoginWebGroupContract].
  ///
  /// This base constructor takes no parameters — it exists only so the class can be
  /// `const`-extended by documentation purposes; the class is never instantiated.
  const LayrzLoginWebGroupContract();
}
