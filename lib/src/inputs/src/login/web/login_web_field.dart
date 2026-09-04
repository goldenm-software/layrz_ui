/// Compile-time selector for the login sub-module's web DOM field.
///
/// This is a standalone library (not a `part`) because only a top-level library can
/// declare a conditional export. It resolves at compile time to one of two
/// implementations, both exported under the SAME concrete symbol name —
/// `LayrzLoginWebField` — which is the whole point of the
/// `export 'stub' if (...) 'web'` pattern: callers name one identifier and the
/// conditional export decides which implementation answers to it, so no call site ever
/// branches on which one it got.
///
/// - On web (`dart.library.js_interop` available): `login_web_field_web.dart` MUST
///   export a class named EXACTLY `LayrzLoginWebField`, implementing
///   [LayrzLoginWebFieldContract], that renders a real HTML `<input>` via a platform
///   view (built by U6). Its constructor signature MUST match the contract exactly:
///   `kind`, `value`, `labelText`, `errors`, `onChanged`, `onSubmit`, `autofillHints`,
///   `formId`, `disabled`, `dense`, `tokens` (`LayrzTokens`), and `super.key`.
/// - Everywhere else: `login_web_field_stub.dart` exports the same-named
///   `LayrzLoginWebField`, an inert stub whose `build` throws [UnsupportedError]. It
///   exists only so non-web targets compile — every call site is `kIsWeb`-gated, so the
///   stub is never actually instantiated at runtime.
///
/// **Internal to the login sub-module.** Nothing under `lib/src/inputs/src/login/web/`
/// is exported from `lib/src/inputs/inputs.dart` or any other barrel. This selector, its
/// stub, and the eventual web implementation are private plumbing behind
/// `LayrzUsernameInput` / `LayrzPasswordInput` — not a reusable primitive, and not the
/// seed of a general web-input framework. See the "no parallel input engine" hard
/// constraint in the implementation plan: no other `layrz_ui` input gets a web-native
/// path, and [LayrzLoginFieldKind] stays exactly `{ username, password }`.
library;

export 'login_web_field_stub.dart' if (dart.library.js_interop) 'login_web_field_web.dart';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/src/tokens.dart';

/// The credential semantics a [LayrzLoginWebField] renders as a real HTML `<input>`.
///
/// This selects the DOM `type`/`autocomplete` pairing the web implementation assigns to
/// the underlying `<input>` element so browser and OS password managers classify the
/// field correctly:
///
/// - [username] → HTML `type="text"`, `autocomplete="username"`.
/// - [password] → HTML `type="password"`, `autocomplete="current-password"`.
///
/// **Deliberately closed.** This is not an extensible field-kind system — the login
/// sub-module renders exactly two credential fields, and no other kind (email, search,
/// one-time-code, etc.) is in scope. Do not add values "for future use"; see the
/// "no parallel input engine" hard constraint in the implementation plan.
enum LayrzLoginFieldKind {
  /// The credential identifier field — username or email.
  ///
  /// Renders as HTML `type="text"` with `autocomplete="username"` so password managers
  /// recognize it as the identifier half of a credential pair.
  username,

  /// The secret credential field.
  ///
  /// Renders as HTML `type="password"` with `autocomplete="current-password"`, and owns
  /// its own show/hide toggle on the DOM side (the browser-native `<input>` swaps its
  /// `type` attribute between `password` and `text`).
  password,
}

/// Public constructor contract shared by the web DOM implementation and its inert stub.
///
/// [LayrzUsernameInput] and [LayrzPasswordInput] (U2/U4) import this selector library —
/// never `login_web_field_web.dart` or `login_web_field_stub.dart` directly — and
/// construct `LayrzLoginWebField(...)` uniformly; the conditional export resolves which
/// concrete implementation answers at compile time, but both are exported under that
/// SAME name, `LayrzLoginWebField`. Both the stub (U5, this unit) and the web
/// implementation (U6) MUST expose exactly this constructor shape so callers never
/// branch on which one they got.
///
/// This class itself renders nothing — it documents the contract. The concrete
/// implementations are both named `LayrzLoginWebField`: the inert one in
/// `login_web_field_stub.dart` (this unit, throws on build) and the real DOM field in
/// `login_web_field_web.dart` (added by U6). Both extend [StatefulWidget], implement
/// this contract, and accept the same named parameters:
///
/// - `kind` ([LayrzLoginFieldKind], required): which credential field this is; selects
///   the DOM `type`/`autocomplete` pairing.
/// - `value` (`String`, required): the current field value, used to seed the DOM
///   `<input>` once. After that the `<input>` is the source of truth on web; changes
///   flow back out through `onChanged`, not by re-seeding `value` on every rebuild.
/// - `labelText` (`String?`): the label displayed above the field, mirroring
///   `LayrzTextInput.labelText` so the web field reads as the same component.
/// - `errors` (`List<String>`): validation error messages displayed below the field,
///   mirroring `LayrzTextInput.errors`. A non-empty list also selects the chrome's
///   danger/error visual state.
/// - `onChanged` (`ValueChanged<String>?`): fired with the new value whenever the
///   underlying DOM `<input>` fires its own `input` event.
/// - `onSubmit` (`ValueChanged<String>?`): fired with the current value when the user
///   submits from the field (DOM `Enter` keydown / form submission).
/// - `autofillHints` (`List<String>`): the `AutofillHints`-style hint strings the caller
///   would pass to `LayrzTextInput` on native; the web implementation translates these
///   into the DOM `autocomplete` value it assigns (in addition to the base pairing
///   [kind] already selects).
/// - `formId` (`String?`): the HTML `<form>` id this field's `<input>` should be
///   associated with, so the browser groups username + password into one credential
///   set. Resolved by the caller from `login_web_group.dart`'s group provider — this
///   field never invents its own id.
/// - `disabled` (`bool`): mirrors `LayrzTextInput.disabled` — not editable, not
///   focusable, callbacks do not fire.
/// - `dense` (`bool`): mirrors `LayrzTextInput.dense` — selects the tighter padding
///   scale (`pd1`/`pd2` instead of `pd2`/`pd3`) the web CSS chrome must also honor.
/// - `tokens` ([LayrzTokens], required): the live design tokens the web CSS chrome reads
///   for radius (`radius.br2`), padding (`spacing.pd1`–`pd3`), and color
///   (`colors.fg2`/`fg3`/`danger`/`primary`) so the DOM field tracks token changes
///   instead of hardcoding `layrz_session`'s CSS constants. Callers obtain this via
///   `context.tokens`.
/// - `key` (`Key?`, via `super.key`): plain Flutter element identity only — never
///   overloaded to carry field kind or grouping, both of which are already modeled by
///   `kind` and `formId`.
///
/// This documentation block is the single source of truth for the shape; U6 must match
/// it exactly rather than re-deriving it from `layrz_session`.
@immutable
abstract class LayrzLoginWebFieldContract {
  /// Creates a [LayrzLoginWebFieldContract].
  ///
  /// This base constructor takes no parameters — it exists only so the class can be
  /// `const`-extended by documentation purposes; the class is never instantiated.
  const LayrzLoginWebFieldContract();
}
