part of 'login_web_field_web.dart';

/// Form association, `aria-hidden` removal, and the deferred connection verification for
/// [_LayrzLoginWebFieldState].
///
/// Split out of `login_web_field_web.dart` as a `part` (not a standalone library)
/// because every method here reads or writes private instance state shared with the
/// rest of the state class (`_effectiveFormId`, `_inputElement`, `mounted`, `context`) —
/// a `part` file shares its enclosing library's privacy scope, so this state stays
/// private without having to be exposed for a normal cross-file import.
///
/// Ported from `layrz_session`'s `native_autofill_field_web_form.dart`. Every mechanism
/// here — the `form` content-attribute association, the deferred connection check, and
/// the `aria-hidden` strip on the engine's `<flt-platform-view>` wrapper — is preserved
/// VERBATIM in behavior, per the U6 hard constraint that this is a MECHANISM port, not a
/// redesign. `Log.info`/`Log.warning` (from `layrz_logging`, not a layrz_ui dependency)
/// are replaced with [debugPrint] — see each call site below.
extension _LayrzLoginWebFieldFormMixin on _LayrzLoginWebFieldState {
  /// Resolves [_LayrzLoginWebFieldState._effectiveFormId] from, in priority order:
  /// (1) [LayrzLoginWebField.formId] if explicitly given, (2) the nearest ancestor
  /// [LayrzLoginWebGroup] via [LayrzLoginWebGroup.maybeOf], or (3) `null` if neither is
  /// available.
  ///
  /// Always safe to call from [didChangeDependencies] — [LayrzLoginWebGroup.maybeOf]
  /// both reads and subscribes to the inherited scope, which is exactly what
  /// [didChangeDependencies] is for. If the resolved value differs from whatever
  /// `_effectiveFormId` already held (i.e. this isn't the first resolution), the
  /// already-created `<input>` — if one exists yet — is re-associated immediately via
  /// [_associateFormId], so a group that appears/changes after this field's platform
  /// view was already built still takes effect.
  void _resolveEffectiveFormId() {
    final resolved = widget.formId ?? LayrzLoginWebGroup.maybeOf(context);
    if (resolved == _effectiveFormId) return;

    _effectiveFormId = resolved;
    final input = _inputElement;
    if (input != null) _associateFormId(input, resolved);
  }

  /// Removes the `aria-hidden="true"` attribute Flutter's engine unconditionally
  /// stamps on this field's `<flt-platform-view>` wrapper, once [input] is actually
  /// connected to the document.
  ///
  /// ## Why Flutter hides platform views from accessibility at all
  /// The Flutter web engine's `ContentManager.renderContent()` sets `aria-hidden="true"`
  /// on the `<flt-platform-view>` wrapper exactly once, synchronously, right after the
  /// factory's content is appended, with the engine's own doc comment: "By default,
  /// platform views are hidden from accessibility using aria-hidden. The semantics
  /// layer will remove this when a semantic node is created." That default makes sense
  /// for a platform view hosting something decorative or already described by a
  /// Flutter-drawn semantic node elsewhere, but this widget's platform view hosts a
  /// real, focusable, user-facing `<input>` with no such Flutter-side semantic node
  /// standing in for it, so the default instead produces two real problems:
  ///  1. A live accessibility-tree bug the browser itself reports: "Blocked
  ///     aria-hidden on an element because its descendant retained focus. The focus
  ///     must not be hidden from assistive technology users." — logged once the input
  ///     receives real DOM focus while its wrapper is still `aria-hidden`.
  ///  2. Browser password managers rely heavily on the accessibility tree to discover
  ///     and classify form fields — every other autofill signal this widget sets
  ///     (`autocomplete`, `name`, `id`, `<form>` association) is read through a channel
  ///     `aria-hidden` closes for this subtree.
  ///
  /// This is consistent with Flutter's OWN hidden autofill proxy inputs (the ones
  /// inside `<flt-text-editing-host>`, from Flutter's native `TextField`/`AutofillGroup`):
  /// those are NOT nested inside a platform-view wrapper at all, so they are never
  /// `aria-hidden` in the first place — Flutter's own autofill mechanism never needed
  /// this fix because it was never subject to the problem.
  ///
  /// ## Why this cannot run inside the factory closure itself
  /// The factory returns `container` as a detached, orphan subtree — the
  /// `<flt-platform-view>` wrapper doesn't exist yet at that point; the engine creates
  /// it around whatever the factory returns and only attaches the whole thing to the
  /// live document later, during compositing. So the wrapper is only reachable once
  /// [input] is actually connected — the same lifecycle point
  /// [_verifyAssociationOnceConnected] already waits for, via the same bounded
  /// `addPostFrameCallback` retry shape (kept as a separate method rather than folded
  /// into that one: this fix is unconditional for every field instance, while that one
  /// only runs when there is a `formId` to associate).
  ///
  /// ## Whether Flutter can re-apply aria-hidden afterwards — the accepted a11y-on
  /// ## trade-off (dossier §8A.5b)
  /// The engine only re-applies `aria-hidden` via its semantics layer, in response to
  /// real semantic-tree changes — that path never fires against this wrapper while
  /// Flutter's own accessibility/semantics is OFF for the page, so a one-time removal is
  /// sufficient in that case and no [web.MutationObserver] is added to guard against a
  /// re-application that (with semantics off) never happens. If the app or the user
  /// later turns accessibility ON, the semantics layer taking over this attribute for
  /// this view going forward re-hides it, degrading autofill again — this is the
  /// accepted trade-off from the implementation plan (§8A.5b/§4 risk 4): match
  /// `layrz_session`'s behavior, do not block U6 chasing a fix beyond it.
  void _revealFromAssistiveTechnologyOnceConnected(web.HTMLInputElement input, {required int attemptsLeft}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!input.isConnected) {
        if (attemptsLeft > 1) {
          _revealFromAssistiveTechnologyOnceConnected(input, attemptsLeft: attemptsLeft - 1);
        }
        // No warning logged on final failure here (unlike the form-association check):
        // if the input never connects at all, autofill pairing already logged its own
        // failure via [_verifyAssociationOnceConnected], and there is no wrapper to fix
        // regardless.
        return;
      }

      final wrapper = input.closest('flt-platform-view');
      wrapper?.removeAttribute('aria-hidden');
    });
  }

  /// Associates (or dissociates) [input] with a `<form>` by [formId], or does nothing
  /// further beyond leaving it unassociated when [formId] is `null`.
  ///
  /// ## This is THE isolated, swappable association mechanism
  /// Everything about "how one field tells the browser it belongs with the others"
  /// lives in this one method — no other code in this file or `login_web_group_web
  /// .dart` sets or removes the `form` attribute. This is deliberate: whether password
  /// managers in the wild actually HONOR this mechanism is a real, ongoing question, so
  /// keeping the mechanism confined to one well-documented place means it can be
  /// swapped out later without redesigning [LayrzLoginWebGroup] or the rest of this
  /// widget.
  ///
  /// ## The mechanism, currently
  /// Sets HTML5's `form` CONTENT ATTRIBUTE (`input.setAttribute('form', ...)` — a real,
  /// standard HTML attribute, not a JS-interop-only concept) to [formId]. Per the HTML
  /// living standard's form-associated-element algorithm, this associates [input] with
  /// `<form id="formId">` regardless of DOM position, making it a member of that form's
  /// `.elements` — this is how the two fields end up "in the same form" despite living
  /// in unrelated `<flt-platform-view>` subtrees.
  ///
  /// When [formId] is `null`, the `form` attribute is removed instead (if present)
  /// rather than left stale — this matters for [_resolveEffectiveFormId]'s
  /// re-association path, where a previously resolved id can legitimately go back to
  /// `null` (e.g. an ancestor [LayrzLoginWebGroup] is removed from the tree across a
  /// rebuild).
  ///
  /// ## Runtime association assertion — WHY it must run after attachment
  /// The `form` attribute's association algorithm resolves the id against the element's
  /// OWN node tree (`input.getRootNode()`) and cannot cross a shadow-DOM boundary if one
  /// is ever introduced between the input and its form. The read that actually matters —
  /// `input.form`, the IDL property reflecting the LIVE, resolved form owner, as opposed
  /// to the attribute, which is just the string that was set — is only MEANINGFUL once
  /// [input] is connected to a document. This method's main call site is
  /// `_registerViewFactory`'s platform-view factory, which builds `input` (nested inside
  /// the returned `container`) as a detached, ORPHAN subtree — actual attachment to the
  /// document only happens later, during compositing. Reading `input.form` synchronously
  /// inside the factory, before that later attachment, would always report failure even
  /// for a perfectly correct association, purely because of ordering.
  ///
  /// The attribute itself IS still set synchronously and unconditionally, right here,
  /// before any of that — setting it costs nothing, does not depend on attachment, and
  /// an early `form=` on a not-yet-connected element is exactly what the HTML spec
  /// expects to resolve correctly once the element later joins a tree containing that
  /// form id. Only the VERIFICATION is deferred: [_verifyAssociationOnceConnected] waits
  /// for [input] to actually connect — polling across a small, bounded number of
  /// post-frame callbacks — then performs the identity check at a point where the
  /// answer is actually meaningful, forcibly re-running the browser's own form-owner
  /// resolution once as a belt-and-braces step if the first live read still doesn't
  /// resolve, and logs precisely once per association attempt as it settles.
  ///
  /// ## Positive-path diagnostic
  /// A successful association is logged via [debugPrint], and a genuine failure
  /// (attribute set, input connected, `input.form` still doesn't resolve to the
  /// expected element even after a forced re-apply — or the input never connects within
  /// the retry budget) via [debugPrint] as well — never thrown, since a failed
  /// association must degrade gracefully: every other autofill signal (`autocomplete`,
  /// `name`) keeps working regardless. `layrz_session`'s `Log.info`/`Log.warning` (from
  /// `layrz_logging`, not a layrz_ui dependency) are both replaced with [debugPrint] per
  /// the U6 hard constraint.
  void _associateFormId(web.HTMLInputElement input, String? formId) {
    if (formId == null) {
      if (input.hasAttribute('form')) input.removeAttribute('form');
      return;
    }

    input.setAttribute('form', formId);
    _verifyAssociationOnceConnected(
      input,
      formId,
      attemptsLeft: _LayrzLoginWebFieldState._connectionCheckMaxAttempts,
    );
  }

  /// Waits for [input] to connect to a document — via a bounded chain of
  /// [WidgetsBinding.addPostFrameCallback] calls, [attemptsLeft] counting down by one
  /// per callback — then performs the actual `input.form` identity verification and
  /// logs exactly once. See the "Runtime association assertion" section on
  /// [_associateFormId] for why this cannot simply run synchronously right after
  /// `setAttribute('form')`.
  ///
  /// Guarded on [mounted]: if this field's state is disposed before
  /// attachment/verification completes, this simply stops rather than touching a
  /// disposed widget's state or logging a misleading result.
  void _verifyAssociationOnceConnected(web.HTMLInputElement input, String formId, {required int attemptsLeft}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!input.isConnected) {
        if (attemptsLeft > 1) {
          _verifyAssociationOnceConnected(input, formId, attemptsLeft: attemptsLeft - 1);
        } else {
          debugPrint(
            'LayrzLoginWebField: failed to associate input (kind: ${widget.kind.name}) with '
            'form "$formId" — the input never connected to the document after '
            '${_LayrzLoginWebFieldState._connectionCheckMaxAttempts} frame(s). Autofill pairing across fields will not '
            'work; other autofill signals (autocomplete, name) are unaffected and still apply.',
          );
        }
        return;
      }

      if (_resolveAssociatedForm(input, formId) == null) {
        // Belt-and-braces: force the browser to re-run its own "reset the form owner"
        // algorithm now that the input is definitely connected, in case the initial
        // resolution (set while still detached) was never automatically re-run on
        // insertion by this particular browser/engine combination.
        input.removeAttribute('form');
        input.setAttribute('form', formId);
      }

      final expectedForm = _resolveAssociatedForm(input, formId);
      if (expectedForm == null) {
        debugPrint(
          'LayrzLoginWebField: failed to associate input (kind: ${widget.kind.name}) with '
          'form "$formId" — input.form did not resolve to the expected element even after the '
          'input connected and the `form` attribute was re-applied. Autofill pairing across fields '
          'will not work; this can happen if platform views are ever hosted behind a shadow-DOM '
          'boundary, which the `form` attribute cannot cross. Other autofill signals (autocomplete, '
          'name) are unaffected and still apply.',
        );
      } else {
        debugPrint(
          'LayrzLoginWebField: associated input (kind: ${widget.kind.name}, id: ${input.id}, '
          'name: ${input.name}) with form "$formId"',
        );
      }
    });
  }

  /// Resolves the `<form>` element [formId] refers to and returns it only if it is
  /// identically the element [input.form] (the live, resolved form owner) actually
  /// points at — `null` otherwise, covering both "no element with that id exists" and
  /// "one exists, but isn't what [input] resolved to".
  ///
  /// Looks the id up against [input]'s OWN node tree (`input.getRootNode()`) rather
  /// than always querying `document` — spec-correct for the form-owner algorithm, and
  /// the only lookup that remains meaningful if a future engine ever moves platform
  /// views behind a shadow boundary, which `document.getElementById` cannot see into.
  /// The root is narrowed by type (`Document` vs. `ShadowRoot`, the only two connected-
  /// tree root kinds) since `package:web`'s `Node` itself exposes no `querySelector`.
  /// Under today's confirmed topology (light-DOM platform views, form appended to
  /// `document.body`) the root is always `Document`, so this always takes the
  /// `Document` branch in practice — the `ShadowRoot` branch exists purely so this check
  /// keeps working, rather than silently mis-resolving, if that topology ever changes.
  web.Element? _resolveAssociatedForm(web.HTMLInputElement input, String formId) {
    final root = input.getRootNode();
    final web.Element? form;
    if (root.isA<web.Document>()) {
      form = (root as web.Document).getElementById(formId);
    } else if (root.isA<web.ShadowRoot>()) {
      form = (root as web.ShadowRoot).querySelector('#$formId');
    } else {
      // Detached subtree (no document, no shadow root) — fall back to a plain
      // document-wide lookup, which cannot itself be correct (a detached input cannot
      // really be associated with anything) but keeps this helper total instead of
      // throwing on an unexpected root type.
      form = web.document.getElementById(formId);
    }
    if (form == null) return null;
    return input.form?.isSameNode(form) == true ? form : null;
  }
}
