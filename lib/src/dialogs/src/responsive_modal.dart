import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/dialogs/src/dialog.dart';
import 'package:layrz_ui/src/dialogs/src/modal_presentation.dart';
import 'package:layrz_ui/src/sheets/src/bottom_sheet.dart';

/// Dialog-only configuration for [LayrzResponsiveModal.show].
///
/// Groups the parameters that are only meaningful when [LayrzResponsiveModal]
/// resolves to [LayrzModalPresentation.dialog] and forwards to
/// [LayrzDialog.show]. Kept as its own object (rather than flattening every
/// branch's parameters onto the wrapper) so a caller configuring the dialog
/// branch is never shown parameters — such as [LayrzBottomSheetConfig.snapSizes]
/// or [LayrzBottomSheetConfig.showDragHandle] — that mean nothing for a dialog.
@immutable
class LayrzDialogConfig {
  /// The maximum width the dialog's panel may occupy, in logical pixels.
  ///
  /// Forwarded verbatim to [LayrzDialog.show]'s `maxWidth`. Defaults to `480`.
  final double maxWidth;

  /// The maximum height the dialog's panel may occupy, in logical pixels.
  ///
  /// Forwarded verbatim to [LayrzDialog.show]'s `maxHeight`. Defaults to `640`.
  final double maxHeight;

  /// Creates dialog-branch configuration for [LayrzResponsiveModal.show].
  const LayrzDialogConfig({
    this.maxWidth = 480,
    this.maxHeight = 640,
  });
}

/// Sheet-only configuration for [LayrzResponsiveModal.show].
///
/// Groups the parameters that are only meaningful when [LayrzResponsiveModal]
/// resolves to [LayrzModalPresentation.sheet] and forwards to
/// [LayrzBottomSheet.show]. Kept as its own object (rather than flattening
/// every branch's parameters onto the wrapper) so a caller configuring the
/// sheet branch is never shown parameters — such as [LayrzDialogConfig.maxWidth]
/// or [LayrzDialogConfig.maxHeight] — that mean nothing for a sheet.
@immutable
class LayrzBottomSheetConfig {
  /// Optional list of snap point fractions (0.0 to 1.0) in ascending order.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `snapSizes`. If null,
  /// the sheet defaults to `[0.5, 0.95]`.
  final List<double>? snapSizes;

  /// The fraction of the screen height the sheet initially occupies.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `initialSize`. Defaults
  /// to `0.5` (half the screen).
  final double initialSize;

  /// The minimum fraction of screen height the sheet can be dragged down to.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `minSize`. Defaults to
  /// `0.25` (a quarter of the screen).
  final double minSize;

  /// The maximum fraction of screen height the sheet can occupy.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `maxSize`. Defaults to
  /// `0.95` (leaving minimal space for status bar / app bar).
  final double maxSize;

  /// Whether to render a visual drag handle above the content.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `showDragHandle`.
  /// Defaults to `true`.
  final bool showDragHandle;

  /// Whether the sheet wraps its content in its own scroll view.
  ///
  /// Forwarded verbatim to [LayrzBottomSheet.show]'s `scrollable`. Defaults
  /// to `true`. Set to `false` when the content builder returns its own
  /// scrollable (e.g. a `ListView` or `GridView`).
  final bool scrollable;

  /// Creates sheet-branch configuration for [LayrzResponsiveModal.show].
  const LayrzBottomSheetConfig({
    this.snapSizes,
    this.initialSize = 0.5,
    this.minSize = 0.25,
    this.maxSize = 0.95,
    this.showDragHandle = true,
    this.scrollable = true,
  });
}

/// A responsive chooser that presents its content as a [LayrzDialog] on wide
/// viewports and a [LayrzBottomSheet] on narrow ones.
///
/// [LayrzResponsiveModal] adds no behaviour of its own — it resolves a
/// presentation once (see [show]) and delegates entirely to whichever
/// underlying surface was chosen. Both branches return `Future<T?>`, where
/// `null` means the modal was dismissed without a value, so the wrapper's
/// contract is identical to either branch on its own.
///
/// **Name.** Deliberately `LayrzResponsiveModal`, not `LayrzAdaptiveModal`.
/// Flutter reserves "adaptive" for platform-switching (e.g. `Switch.adaptive`),
/// whereas this chooses its surface from viewport *breakpoint* — the same
/// vocabulary already used by [LayrzBreakpoint] and `LayrzRow`.
///
/// **Presentation is decided once, at [show] call time, and is never
/// re-evaluated.** This is an explicit non-goal, not an oversight: there is no
/// [LayoutBuilder], no [MediaQuery] listener, and nothing installed in the
/// widget tree that could rebuild across the breakpoint. A modal opened on a
/// wide window and then resized narrow **stays on the surface it opened
/// with** for the life of that route — neither [LayrzDialog] nor
/// [LayrzBottomSheet] supports being swapped for the other mid-flight, and
/// attempting to re-resolve mid-route is itself a behaviour this component
/// deliberately does not have. This matters more under the name "responsive"
/// than it did under "adaptive", because "responsive" invites the live-resize
/// assumption even harder. There is shipped precedent for the failure this
/// avoids: version 0.0.14 fixed `LayrzScaffoldShell` throwing
/// `setState() or markNeedsBuild() called during build` when the viewport
/// crossed the compact breakpoint while its detail sheet was open — a
/// re-evaluate-on-resize design is exactly the shape of bug that produced.
class LayrzResponsiveModal {
  LayrzResponsiveModal._();

  /// Shows the content as a dialog or a bottom sheet, chosen once at call time.
  ///
  /// Returns `Future<T?>` that completes with the value passed to
  /// [Navigator.pop] in whichever surface was presented, or `null` if it was
  /// dismissed without a value (barrier tap, Escape, or a close action that
  /// pops with no value). This matches both [LayrzDialog.show] and
  /// [LayrzBottomSheet.show] exactly, so callers do not need to branch on
  /// which surface was actually used.
  ///
  /// **Navigator**: both branches always push on the root navigator — see
  /// [LayrzDialog]'s and [LayrzBottomSheet]'s own class docs. This is
  /// intrinsic to each branch, not a choice this wrapper makes or forwards.
  ///
  /// **Parameters:**
  /// - [context]: the build context from which to show the modal. Must
  ///   contain a Navigator.
  /// - [builder]: a builder function that constructs the modal's content. The
  ///   builder receives the surface's own context as an argument, matching
  ///   [LayrzBottomSheet.show]'s `builder` shape. For the dialog branch, the
  ///   built widget ends up inside [LayrzDialog.show]'s `child` escape hatch
  ///   (see [actions]'s own doc for exactly how, once [actions] is also
  ///   supplied) — [LayrzResponsiveModal] does not compose the dialog's
  ///   `title`/`content` slots, since a single [builder] must describe one
  ///   piece of content usable on both surfaces. **This remains a deliberate
  ///   API limitation for `title`/`content` specifically, not an oversight**:
  ///   a caller that wants the dialog branch's structured `title`/`content`
  ///   slots — rather than one freeform widget — cannot get them through this
  ///   wrapper, because the same [builder] result is also handed to
  ///   [LayrzBottomSheet.show], which has no equivalent slotted shape to
  ///   receive them. Call [LayrzDialog.show] directly when those two slots
  ///   matter more than responsive presentation. [actions], unlike `title`/
  ///   `content`, is available on this wrapper — see its own doc.
  /// - [isCompact]: overrides which surface is chosen, regardless of viewport
  ///   width. Defaults to `context.isCompact` (`true` below the `sm`/`md`
  ///   breakpoint boundary at 960 logical pixels — see
  ///   [resolveLayrzModalPresentation]). Pass `true` to force
  ///   [LayrzModalPresentation.sheet] or `false` to force
  ///   [LayrzModalPresentation.dialog] regardless of the actual viewport —
  ///   useful, for example, when a picker with a long option list wants the
  ///   sheet even at a wider breakpoint than a two-button confirm would.
  /// - [canDismiss]: whether the modal can be dismissed by any route other than an
  ///   explicit action (barrier tap, Escape, the X icon on the dialog branch, drag-dismiss
  ///   on the sheet branch, and the system/Android back gesture on both).
  ///
  ///   `null` (the default) **infers from [actions]**, mirroring [LayrzDialog.show]'s own
  ///   rule exactly: dismissable (`true`) when [actions] is null or empty (nothing to answer
  ///   with), not dismissable (`false`) when [actions] is a non-empty list (a decision-bearing
  ///   modal should not be escapable by anything other than answering it). This resolved value
  ///   — computed once, before branching, as `canDismiss ?? (actions == null || actions.isEmpty)`
  ///   — is forwarded to **both** branches: [LayrzDialog.show]'s `canDismiss` and
  ///   [LayrzBottomSheet.show]'s `canDismiss` (non-nullable there, so it receives the resolved
  ///   `bool` directly). An explicit `true`/`false` from the caller always wins over the
  ///   inference in either direction — only the unset (`null`) case infers.
  ///
  ///   **This used to be different and was corrected.** Earlier versions composed [actions]
  ///   into the dialog branch's `child` (see [_DialogBodyWithPinnedActions]) rather than
  ///   forwarding them to [LayrzDialog.show]'s own `actions` parameter, so that method always
  ///   saw `actions: null` and inferred a freely-dismissable default regardless of whether
  ///   this wrapper's own [actions] were supplied — the "lock in" a caller expected from
  ///   passing [actions] silently did not happen on either branch. The sheet branch
  ///   separately hardcoded `canDismiss ?? true`, with no inference from [actions] at all.
  ///   Both gaps are closed: the inference above is computed from this wrapper's own
  ///   [actions] (not from what either branch happens to receive) and applied uniformly, so
  ///   the resolved presentation no longer changes what "pass [actions] to lock in" means.
  ///   See [LayrzDialog.show]'s own `canDismiss` doc for the four-route dialog contract, and
  ///   [LayrzBottomSheet.show]'s for how the equivalent three-route sheet contract composes
  ///   with `isPersistent` and drag-to-dismiss — drag-to-dismiss included, since
  ///   [LayrzBottomSheet.show]'s single `canDismiss` flag already gates that route too.
  /// - [semanticLabel]: semantic label describing the modal's purpose for
  ///   screen readers, forwarded to whichever branch is chosen. Must be
  ///   equivalent regardless of which surface is presented, since an
  ///   assistive-technology user must hear the same description whether the
  ///   breakpoint put them on a dialog or a sheet.
  /// - [dialog]: dialog-branch-only configuration (max width/height). Ignored
  ///   when the sheet branch is chosen. Defaults to `const LayrzDialogConfig()`.
  /// - [sheet]: sheet-branch-only configuration (snap sizes, initial/min/max
  ///   size, drag handle, scrollable). Ignored when the dialog branch is
  ///   chosen. Defaults to `const LayrzBottomSheetConfig()`.
  /// - [actions]: optional list of widgets (typically `LayrzButton`s), rendered in a row
  ///   **pinned below [builder]'s content, on both branches**. `null` (the default, or an
  ///   empty list) renders nothing and changes no layout, matching every existing caller
  ///   today.
  ///
  ///   **This closes the API limitation this wrapper previously documented and shipped
  ///   with**: both [LayrzDialog.show] and [LayrzBottomSheet.show] already offer their own
  ///   `actions` slot, each pinned outside that branch's own scrollable content area, but
  ///   [LayrzResponsiveModal.show] used to expose neither — a caller wanting a "locked in"
  ///   footer row had no way to get one without abandoning responsive presentation and
  ///   calling one branch directly.
  ///
  ///   **Sheet branch**: [actions] is forwarded verbatim to [LayrzBottomSheet.show]'s own
  ///   `actions` parameter, which already pins it below the sheet's content — scrollable or
  ///   not, per [LayrzBottomSheetConfig.scrollable] — and clear of both the keyboard and the
  ///   device's bottom safe-area inset. See [LayrzBottomSheet.show]'s own `actions` doc for
  ///   the full contract.
  ///
  ///   **Dialog branch**: [actions] is **not** forwarded to [LayrzDialog.show]'s own
  ///   `actions` parameter, because that parameter is mutually exclusive with `child` at
  ///   [LayrzDialog.show]'s own call site — an assertion fires if both are supplied — and
  ///   `child` is what [builder]'s result is always passed as (see [builder]'s own doc for
  ///   why `child`, not `content`, is required to keep fill-height builder content such as
  ///   `Expanded`/`ListView` working on this branch). Instead, this method composes the row
  ///   itself: `child` becomes a `Column` (`mainAxisSize: MainAxisSize.min`) whose children
  ///   are the built widget, wrapped in a `Flexible` (loose fit, not `Expanded`'s tight fit —
  ///   see [_DialogBodyWithPinnedActions]'s own doc for why the distinction matters: a tight
  ///   fit would force the panel to `maxHeight` even for a couple of lines of content),
  ///   followed by the actions row — built with the same spacing, right alignment, and
  ///   inter-button gap [LayrzDialog.show]'s own `actions` slot uses, so the two read as the
  ///   same row regardless of which path produced them. Because this row is a sibling of the
  ///   `Flexible` builder content in that `Column` — not nested inside it — it is pinned
  ///   below the content and is never pushed off-screen or scrolled away by it, exactly like
  ///   [LayrzDialog.show]'s own `actions` sits outside its `content` scroll view.
  ///
  ///   **[canDismiss]'s inference is computed from this wrapper's own [actions], not from
  ///   what either branch happens to receive.** Because [actions] is composed into `child`
  ///   here rather than forwarded to [LayrzDialog.show]'s own `actions` parameter, that
  ///   method always sees `actions: null` from this wrapper and — left to its own inference —
  ///   would default to freely dismissable regardless of whether this wrapper's [actions]
  ///   were supplied. [show] does not rely on that: it resolves `canDismiss` itself, from
  ///   this wrapper's own [actions], and passes the already-resolved value to
  ///   [LayrzDialog.show]'s `canDismiss` — so the dialog branch locks in exactly when a
  ///   caller of *this* method supplies non-empty [actions], not only when a caller of
  ///   [LayrzDialog.show] directly does. See [canDismiss]'s own doc for the exact rule.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    List<Widget>? actions,
    bool? isCompact,
    bool? canDismiss,
    String? semanticLabel,
    LayrzDialogConfig dialog = const LayrzDialogConfig(),
    LayrzBottomSheetConfig sheet = const LayrzBottomSheetConfig(),
  }) {
    final effectiveIsCompact = isCompact ?? context.isCompact;

    // Single source of truth for canDismiss's inference, mirroring LayrzDialog.show's own
    // rule exactly (see dialog.dart's effectiveCanDismiss) -- computed once, here, from this
    // wrapper's own `actions`, and forwarded to BOTH branches below. An empty list is treated
    // the same as null: there are no buttons to answer with, so it must not lock the caller
    // in with no way out -- matching _DialogBodyWithPinnedActions's own `hasActions` check
    // (actions != null && actions.isNotEmpty), which is exactly when that widget renders a row
    // at all. An explicit canDismiss from the caller always wins in either direction; only the
    // unset (null) case infers.
    final effectiveCanDismiss = canDismiss ?? (actions == null || actions.isEmpty);

    if (effectiveIsCompact) {
      return LayrzBottomSheet.show<T>(
        context,
        builder: builder,
        actions: actions,
        // LayrzBottomSheet.show's canDismiss is non-nullable, so it receives the already-
        // resolved value directly -- see effectiveCanDismiss's own comment above and
        // canDismiss's doc for the full rule. This used to hardcode `canDismiss ?? true`,
        // which never locked the sheet in even when actions were present.
        canDismiss: effectiveCanDismiss,
        semanticLabel: semanticLabel,
        snapSizes: sheet.snapSizes,
        initialSize: sheet.initialSize,
        minSize: sheet.minSize,
        maxSize: sheet.maxSize,
        showDragHandle: sheet.showDragHandle,
        scrollable: sheet.scrollable,
        isPersistent: false,
      );
    }

    return LayrzDialog.show<T>(
      context,
      // actions cannot be forwarded to LayrzDialog.show's own `actions` parameter here --
      // that parameter is mutually exclusive with `child` at LayrzDialog.show's own call
      // site (an assertion fires if both are non-null), and `child` is what builder's result
      // is always passed as, to preserve fill-height builder content on this branch (see
      // this method's own `builder` doc). _DialogBodyWithPinnedActions composes the pinned
      // row itself instead -- see `actions`'s own doc above for the full reasoning.
      child: _DialogBodyWithPinnedActions(builder: builder, actions: actions),
      // LayrzDialog.show's own `canDismiss` would infer from its OWN `actions` parameter,
      // which this call site always passes as null (see the comment on `child` above) -- so
      // passing the raw, possibly-null `canDismiss` through here would always resolve to
      // freely dismissable, regardless of whether THIS wrapper's `actions` were supplied.
      // effectiveCanDismiss is resolved from this wrapper's own `actions` instead (see its
      // own comment above), so the dialog branch locks in exactly when a caller of
      // LayrzResponsiveModal.show supplies non-empty actions.
      canDismiss: effectiveCanDismiss,
      semanticLabel: semanticLabel,
      maxWidth: dialog.maxWidth,
      maxHeight: dialog.maxHeight,
    );
  }
}

/// Composes [builder]'s content with a pinned [actions] row for
/// [LayrzResponsiveModal.show]'s dialog branch.
///
/// Exists because [LayrzDialog.show]'s own `actions` parameter cannot be used here: it is
/// mutually exclusive with `child` at that method's own call site, and `child` is required
/// (rather than `content`) to keep fill-height builder content such as `Expanded` or a bare
/// `ListView`/`GridView` working — see [LayrzResponsiveModal.show]'s own `actions` and
/// `builder` docs for the full reasoning.
///
/// [builder]'s result sits in a [Flexible] (loose fit, not [Expanded]'s tight fit) inside
/// this widget's own `Column`, which is itself sized with `mainAxisSize: MainAxisSize.min`.
/// [Flexible] is what lets the panel shrink-wrap to short content instead of always
/// growing to fill [LayrzDialog.show]'s `maxHeight`-bounded `child` slot: a tight
/// [Expanded] would force the built content — and therefore this whole `Column`, and
/// therefore the panel — to that full height regardless of how little the builder
/// actually produced, stranding the action row far below a few lines of text. [Flexible]
/// still caps the built content at whatever height remains once the action row and its
/// gap are laid out, so a builder taller than the dialog's `maxHeight` (e.g. a bare
/// `ListView`, matching this method's own `builder` doc) is still bounded and scrolls
/// internally rather than overflowing — mirroring exactly how [LayrzDialog.show]'s own
/// `content` slot uses a [Flexible] around its scroll view (see `dialog.dart`'s
/// `_buildSlots`) to get the same shrink-wrap-or-scroll behaviour. [actions] is a sibling
/// of that [Flexible], not nested inside it, so a tall or scrolling [builder] never pushes
/// the row off-screen or carries it away in its own scroll — the row is genuinely pinned
/// below the content, not merely placed after it in a list that could still scroll as a
/// whole. The row's own spacing (a gap above, right alignment, and an inter-button gap)
/// matches [LayrzDialog.show]'s own `actions` slot exactly, so the two read as the same
/// component regardless of which path built them.
class _DialogBodyWithPinnedActions extends StatelessWidget {
  /// Builds the modal's own body content, exactly as passed to
  /// [LayrzResponsiveModal.show]'s `builder`.
  final WidgetBuilder builder;

  /// The pinned action row's widgets, exactly as passed to
  /// [LayrzResponsiveModal.show]'s `actions`. `null` or empty renders no row at all, so
  /// this widget's layout is unchanged from before [actions] existed on that method.
  final List<Widget>? actions;

  /// Creates a dialog body that pins [actions] below [builder]'s content.
  const _DialogBodyWithPinnedActions({
    required this.builder,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = actions != null && actions!.isNotEmpty;
    if (!hasActions) {
      // No actions at all: preserve the exact widget this method built before `actions`
      // existed on LayrzResponsiveModal.show, so a caller that never passes it sees no
      // layout change whatsoever -- no Column, no Expanded, just the built content.
      return Builder(builder: builder);
    }

    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(child: Builder(builder: builder)),
        SizedBox(height: tokens.spacing.sp3),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (int i = 0; i < actions!.length; i++) ...[
              if (i > 0) SizedBox(width: tokens.spacing.sp2),
              actions![i],
            ],
          ],
        ),
      ],
    );
  }
}
