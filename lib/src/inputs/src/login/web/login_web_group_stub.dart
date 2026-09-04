/// Inert non-web stub for the login sub-module's web form-grouping provider.
///
/// Selected by `login_web_group.dart`'s conditional export on every target that is not
/// web. Unlike `login_web_field_stub.dart`, this stub is safe to actually build and
/// mount: on native targets grouping is the caller's own Flutter `AutofillGroup`, not
/// this provider, but [LayrzUsernameInput] / [LayrzPasswordInput] may still wrap
/// themselves in this widget unconditionally (for API symmetry across platforms)
/// without it doing anything meaningful. It simply renders its [child] and resolves no
/// `formId`.
///
/// Material-free: this file imports only the base `widgets.dart` layer. Do not import
/// the Material or Cupertino design libraries here — the CI guard checks every file
/// under `lib/`, stub included.
library;

import 'package:flutter/widgets.dart';

import 'login_web_group.dart';

/// Inert stand-in for the web form-grouping provider on non-web targets.
///
/// **This is the canonical exported symbol name.** Both this stub and the real web
/// implementation added by U6 (in `login_web_group_web.dart`) MUST be named exactly
/// `LayrzLoginWebGroup`, so `login_web_group.dart`'s conditional export resolves to a
/// single identifier callers name directly — see [LayrzLoginWebGroupContract] for the
/// full contract both implementations satisfy.
///
/// [child] is rendered unchanged and [maybeOf] always returns `null`, since no non-web
/// caller has a `formId` to resolve — native grouping goes through Flutter's own
/// `AutofillGroup` instead.
class LayrzLoginWebGroup extends StatelessWidget implements LayrzLoginWebGroupContract {
  /// An explicit `formId` override.
  ///
  /// Accepted only so this stub's constructor matches the real web provider's shape;
  /// it has no effect here since this stub never associates an HTML `<form>`.
  final String? formId;

  /// The subtree wrapped by this group.
  ///
  /// Rendered unchanged — this stub adds no behavior around it.
  final Widget child;

  /// Creates a [LayrzLoginWebGroup] (the inert non-web stub) wrapping [child].
  const LayrzLoginWebGroup({super.key, this.formId, required this.child});

  /// Resolves the nearest enclosing group's `formId`.
  ///
  /// Always `null` on non-web targets: this stub never registers an inherited scope, so
  /// there is nothing to find. Mirrors the real web provider's `maybeOf` signature so
  /// callers can invoke it unconditionally regardless of platform.
  static String? maybeOf(BuildContext context) => null;

  @override
  Widget build(BuildContext context) => child;
}
