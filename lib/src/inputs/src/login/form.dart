import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'web/login_web_group.dart';

/// A behavioural autofill wrapper that commits or discards a browser/OS password
/// manager's pending credential save, based on whether [onSubmit] succeeded.
///
/// [LayrzForm] renders NO chrome and imposes NO layout of its own — it is purely
/// behavioural. The caller arranges [LayrzUsernameInput], [LayrzPasswordInput], and a
/// submit button however it likes inside [child]; [LayrzForm] only wraps that subtree in
/// the platform-appropriate autofill grouping mechanism and drives the save-context
/// commit at the right moment.
///
/// ## Why this exists
/// A platform or browser password manager only offers to save a submitted credential
/// once the app tells it the submission is finished, via
/// `TextInput.finishAutofillContext()`. Calling that eagerly — at submit time, before
/// knowing whether the credential was actually valid — would offer to save a mistyped
/// password. [LayrzForm] exists to make that mistake structurally impossible: it awaits
/// [onSubmit] and only ever calls `finishAutofillContext(shouldSave: true)` when the
/// result is `true`; every other outcome (a `false` result, or the future completing
/// with an error) calls `finishAutofillContext(shouldSave: false)`.
///
/// ## Platform behavior
/// - **Native (mobile + desktop):** wraps [child] in Flutter's own [AutofillGroup], so
///   [LayrzUsernameInput] and [LayrzPasswordInput] fields inside it are associated for
///   autofill the standard Flutter way.
/// - **Web:** wraps [child] in the login sub-module's private `LayrzLoginWebGroup`,
///   which creates one native HTML `<form>` and associates member fields with it by
///   attribute — see that class's own documentation for why `AutofillGroup` alone does
///   not work on Flutter web. [LayrzForm] owns this platform switch internally; the
///   caller never branches on platform itself.
///
/// ## What v1 deliberately excludes
/// - **Validation:** [LayrzForm] does not validate field values itself — that is left to
///   the caller (or a future `LayrzFormField`-style layer). `onSubmit` is the caller's
///   own submit handler; [LayrzForm] only reacts to its boolean result.
/// - **Two-factor / one-time-code flows:** a submit that leads to a second challenge step
///   is out of scope for v1 — model it as a `false` result (nothing to save yet) and
///   drive the second step outside [LayrzForm], or wrap the final successful step in its
///   own [LayrzForm] once the code is confirmed.
/// - **An explicit `commit()`/`discard()` controller** was considered and declined:
///   `onSubmit` returning `true` IS the commit, so it cannot be forgotten.
///
/// ## Platform support caveat
/// On iOS, the app must also declare an Associated Domain entitlement for
/// credential-manager autofill to engage — that is application-level configuration this
/// design system cannot provide. On platforms/browsers with no password-manager
/// integration at all, [LayrzForm] is a silent no-op: [onSubmit] still runs and its
/// result still gates `finishAutofillContext`, but there is no save prompt to show.
class LayrzForm extends StatelessWidget {
  /// The subtree this form wraps, typically the login/signup fields plus a submit
  /// button.
  ///
  /// Rendered unchanged, wrapped only in the platform-appropriate autofill grouping
  /// widget. [LayrzForm] imposes no layout, sizing, or styling of its own.
  final Widget child;

  /// The caller's own submit handler.
  ///
  /// [LayrzForm] does not call this itself — the caller invokes it (typically from a
  /// submit button's `onTap`) and awaits [submit] to drive the autofill commit from its
  /// result. Returning `true` signals a successful submission and commits the pending
  /// credential save; returning `false`, or the future completing with an error,
  /// discards it. See [submit].
  final Future<bool> Function() onSubmit;

  /// Creates a [LayrzForm] wrapping [child] in the platform-appropriate autofill
  /// grouping widget.
  const LayrzForm({super.key, required this.child, required this.onSubmit});

  /// Runs [onSubmit] and commits or discards the pending autofill save based on its
  /// result.
  ///
  /// Call this from the caller's own submit action (e.g. a button's `onTap`) instead of
  /// calling [onSubmit] directly — this is what actually drives
  /// `TextInput.finishAutofillContext()`. On a `true` result,
  /// `finishAutofillContext(shouldSave: true)` is called, offering the credential to the
  /// platform/browser password manager. On a `false` result, OR if [onSubmit] throws,
  /// `finishAutofillContext(shouldSave: false)` is called instead, discarding it —
  /// [submit] never calls `finishAutofillContext` before [onSubmit] has actually
  /// completed, so a mistyped password is never offered for saving. The result of
  /// [onSubmit] (or its error) is returned to the caller unchanged, i.e. a thrown error
  /// still propagates to the caller after the discard has been issued.
  Future<bool> submit() async {
    try {
      final succeeded = await onSubmit();
      TextInput.finishAutofillContext(shouldSave: succeeded);
      return succeeded;
    } catch (_) {
      TextInput.finishAutofillContext(shouldSave: false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return LayrzLoginWebGroup(child: child);
    }

    // Flutter's [AutofillGroup] defaults `onDisposeAction` to
    // [AutofillContextAction.commit], which calls
    // `TextInput.finishAutofillContext(shouldSave: true)` unconditionally whenever the
    // topmost group is disposed (e.g. the route is popped after a failed submission).
    // That default would silently reintroduce the exact must-never failure [submit]
    // exists to prevent, entirely outside [submit]'s own control. [submit] is the sole
    // intended commit path, so disposal itself must never save — hence [cancel] here.
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: child,
    );
  }
}
