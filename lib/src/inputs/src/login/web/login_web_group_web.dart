/// Web implementation of the login sub-module's form-grouping provider.
///
/// This file is only ever compiled on web (selected via the conditional export in
/// `login_web_group.dart`), so it may freely use `dart:js_interop` and `package:web`.
///
/// Ported from `layrz_session`'s `native_autofill_group_web.dart`, Material-free: the
/// source imported the Material design library purely for `StatefulWidget`/
/// `InheritedWidget`/`BuildContext`, none of which are Material-specific — this port
/// uses `package:flutter/widgets.dart` instead, with no behavior change.
library;

import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'login_web_group.dart';

/// Groups a [LayrzLoginWebField] username field and password field so browser password
/// managers can pair them together, even though each field's `<input>` lives in its
/// own, independently-positioned `<flt-platform-view>` subtree.
///
/// ## Why this exists
/// Each [LayrzLoginWebField] renders as its own `dart:ui_web`-registered platform view.
/// Flutter positions every platform view independently, so the username and password
/// `<input>`s end up as SIBLINGS of unrelated DOM subtrees, never nested under a shared
/// parent — there is no `<form>` anywhere, and no DOM ancestor relationship between the
/// two inputs for a password manager to walk. Left unaddressed, this has a confirmed,
/// concrete consequence (observed against `layrz_session`'s port of the same mechanism):
/// a password manager cannot tell a lone `autocomplete="username"` input is meant to
/// pair with a password field and falls back to guessing.
///
/// ## The fix: a shared `<form>`, wired by attribute, not by DOM nesting
/// Since a Flutter-tree ancestor does NOT create a DOM-tree ancestor, this group cannot
/// simply wrap its children in a literal `<form>`. Instead it creates ONE
/// `<form id="...">`, appended directly to `document.body`, and every field inside this
/// group's Flutter subtree sets HTML5's `form` CONTENT ATTRIBUTE on its own `<input>`
/// (`<input form="the-form-id">`). Per the HTML living standard, this associates the
/// input with `<form id="the-form-id">` regardless of DOM position, making it a member
/// of that form's `.elements` — the DOM-nesting requirement is satisfied by attribute,
/// not by physical placement. See `login_web_field_web_form.dart`'s `_associateFormId`
/// for exactly where that attribute is set.
///
/// ## Layout requirements this element depends on — DO NOT reintroduce hiding
/// This `<form>` MUST stay in normal document flow, on-screen, at `0`×`0`, with no
/// `opacity`/`visibility`/`display` hiding property. `layrz_session`'s own hands-on
/// testing (Dashlane on Chrome desktop, documented in its `native_autofill_group_web
/// .dart`) found that `position: fixed`, `overflow: hidden`, off-screen positioning, and
/// any opacity/visibility/display hiding mechanism all made the password manager stop
/// detecting the associated fields entirely — what disqualifies a form is being HIDDEN
/// by some mechanism, not its dimensions. A `0`×`0`, in-flow, unhidden element occupies
/// no layout space and paints nothing (it has no children, background, or border of its
/// own) while still reading as an ordinary, visible element to a password manager's own
/// heuristics. This port preserves that exact configuration.
///
/// ## What this widget renders
/// Nothing of its own — [build] returns [child] unchanged, wrapped only in the
/// inherited scope that exposes the resolved `formId` to descendants.
class LayrzLoginWebGroup extends StatefulWidget implements LayrzLoginWebGroupContract {
  /// The subtree this group wraps — typically the username and password fields plus
  /// whatever layout wraps them.
  final Widget child;

  /// Explicit override for the DOM `<form id>` this group creates and exposes to
  /// descendants.
  ///
  /// When null, a unique id is generated instead — the recommended default. Do NOT rely
  /// on a single hardcoded shared id: if two groups are ever mounted at once (e.g. the
  /// login view plus a dialog), a shared hardcoded id would make every field in both
  /// groups associate with whichever `<form>` happened to be created last, silently
  /// cross-wiring unrelated fields.
  final String? formId;

  /// Creates a [LayrzLoginWebGroup] (the real web form-grouping provider) wrapping
  /// [child].
  const LayrzLoginWebGroup({super.key, this.formId, required this.child});

  /// Resolves the nearest ancestor [LayrzLoginWebGroup]'s resolved form id, or `null` if
  /// this [context] has no such ancestor.
  static String? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LayrzLoginWebGroupScope>()?.formId;
  }

  @override
  State<LayrzLoginWebGroup> createState() => _LayrzLoginWebGroupState();
}

class _LayrzLoginWebGroupState extends State<LayrzLoginWebGroup> {
  /// Incrementing counter backing the generated id fallback — `static` so ids stay
  /// unique across every group instance ever created in this page's lifetime, not just
  /// within one instance.
  static int _idCounter = 0;

  /// This instance's resolved form id — either [LayrzLoginWebGroup.formId] verbatim, or
  /// a freshly generated one. Resolved once, in [initState], and never changed
  /// afterwards: the underlying `<form>` element is created with this id and never
  /// renamed, so the resolved id must stay stable for the lifetime of the state object
  /// too.
  late final String _formId;

  /// The `<form>` element this group owns, or `null` before [initState] has run / after
  /// [dispose] has already removed it.
  web.HTMLFormElement? _formElement;

  @override
  void initState() {
    super.initState();
    _formId = _resolveFormId();
    _createFormElement();
  }

  /// Resolves this instance's form id: [LayrzLoginWebGroup.formId] if given, otherwise
  /// a freshly generated, process-lifetime-unique id.
  String _resolveFormId() {
    final explicit = widget.formId;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return 'layrz-login-form-${_idCounter++}';
  }

  /// Creates this group's `<form>`, appends it to `document.body`, and wires up
  /// submission prevention.
  ///
  /// Guarded three ways against an actual browser submit (a stray Enter keypress
  /// inside an associated `<input>` is already handled by the field's own `keydown`
  /// listener, so a real submit here would be redundant at best and destructive at
  /// worst — navigating/reloading the page): `noValidate = true` skips constraint
  /// validation, `action = '#'` makes a submit a same-page no-op even if one ever slips
  /// through, and an unconditional `event.preventDefault()` in the `submit` listener is
  /// the actual, authoritative stop.
  ///
  /// `data-form-type="login"` is Dashlane's documented Simple Autofill Website Framework
  /// (SAWF) annotation for marking a `<form>` as a login form — see
  /// https://dashlane.github.io/SAWF/. Kept ADDITIVE to the `form`-attribute association
  /// and to `autocomplete`; none of the existing mechanisms are replaced by it.
  ///
  /// Sized `0`×`0`, in normal document flow (not `position: fixed`), on-screen (not
  /// off-screen at a negative offset), and with no opacity/visibility/display hiding
  /// property — see this class's own doc comment for why every one of these properties
  /// is load-bearing for password-manager detection and must not be changed.
  void _createFormElement() {
    final form = web.document.createElement('form') as web.HTMLFormElement;
    form.id = _formId;
    form.noValidate = true;
    form.method = 'post';
    form.action = '#';
    form.setAttribute('data-form-type', 'login');
    form.style.left = '0';
    form.style.top = '0';
    form.style.width = '0';
    form.style.height = '0';
    form.style.setProperty('pointer-events', 'none');

    form.addEventListener(
      'submit',
      (web.Event event) {
        event.preventDefault();
      }.toJS,
    );

    web.document.body?.appendChild(form);
    _formElement = form;
  }

  @override
  void dispose() {
    final form = _formElement;
    if (form != null) {
      form.remove();
      _formElement = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget renders no visual output of its own — the `<form>` it owns lives
    // directly on `document.body`, entirely outside Flutter's own render tree, so there
    // is nothing here to lay the form out relative to. `child` is exposed to
    // descendants purely through `_LayrzLoginWebGroupScope` below, not through any DOM
    // nesting.
    return _LayrzLoginWebGroupScope(formId: _formId, child: widget.child);
  }
}

/// Inherited-widget plumbing exposing a [LayrzLoginWebGroup]'s resolved form id to
/// descendant [LayrzLoginWebField]s via [LayrzLoginWebGroup.maybeOf].
///
/// Kept private and minimal on purpose: this is pure lookup plumbing, not a widget
/// callers construct directly.
class _LayrzLoginWebGroupScope extends InheritedWidget {
  /// The nearest ancestor [LayrzLoginWebGroup]'s resolved form id.
  final String formId;

  /// Creates the scope. Only ever constructed by [_LayrzLoginWebGroupState.build].
  const _LayrzLoginWebGroupScope({required this.formId, required super.child});

  @override
  bool updateShouldNotify(_LayrzLoginWebGroupScope oldWidget) => formId != oldWidget.formId;
}
