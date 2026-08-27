import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/scrollbar/scrollbar.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// A modal dialog surface for presenting focused, page-relative interruptions.
///
/// [LayrzDialog] provides a centered, size-bounded panel behind a modal barrier —
/// distinct from [LayrzBottomSheet] (which drops in from the bottom edge, sized to
/// the viewport height) and from an anchored overlay (which is field-relative and
/// tethered to the widget that opened it). A dialog interrupts the whole page; it
/// never adapts into another surface based on viewport size — see [show] for why.
///
/// Built on [LayrzModalRoute], the same shared base [LayrzBottomSheet] uses, so the
/// barrier, reduce-motion handling, and — critically — the double-pop guard are
/// shared by construction rather than reimplemented. See [LayrzModalRoute.popIfCurrent]
/// for the release-only data-loss bug this guards against.
///
/// **Navigator**: [show] always pushes on the root navigator ([Navigator.of] with
/// `rootNavigator: true`). This is intrinsic, not caller-configurable — a dialog
/// shown from a context whose nearest navigator is nested inside the page body
/// (e.g. a `go_router` `ShellRoute`) would otherwise land inside that page's own
/// layout instead of covering the whole screen, with a barrier that does not
/// cover chrome (such as a top bar) living outside the nested navigator. Every
/// real call site needs the root navigator, so there is no configuration to get
/// wrong.
///
/// **Structure**: the dialog offers named [title], [content], and [actions] slots
/// covering the overwhelmingly common shape ("title + body + confirm/cancel"), plus
/// a [child] escape hatch for content that fits none of them. Supplying [child]
/// together with any of [title]/[content]/[actions] is not supported — an assertion
/// enforces the choice at the call site.
///
/// **Dismiss ("X") affordance**: every dialog renders a tappable close icon that
/// dismisses it through [LayrzModalRoute.popIfCurrent] — the same guard the barrier
/// and Escape handler use. When [title] is supplied, the icon sits at the trailing
/// edge of the title row, vertically centered with the title text. When it is not
/// (including the [child] escape hatch), the icon instead floats over the panel's
/// top-right corner, inset from the edge, so every dialog keeps a visible close
/// affordance regardless of which slots are used. This is currently always shown —
/// see [show] for why that is not yet caller-configurable.
///
/// **Example usage** (a confirm/cancel dialog):
/// ```dart
/// final confirmed = await LayrzDialog.show<bool>(
///   context,
///   title: const Text('Delete item?'),
///   content: const Text('This cannot be undone.'),
///   actions: [
///     LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.of(context).pop(false)),
///     LayrzButton.delete(labelText: 'Delete', onTap: () => Navigator.of(context).pop(true)),
///   ],
/// );
/// ```
class LayrzDialog {
  LayrzDialog._();

  /// Shows a dialog and returns the result.
  ///
  /// Returns `Future<T?>` that completes with the value passed to [Navigator.pop]
  /// in the dialog, or `null` if the dialog is dismissed without a value (barrier
  /// tap, Escape, or a close action that pops with no value).
  ///
  /// **Parameters:**
  /// - [context]: the build context from which to show the dialog. Must contain a Navigator.
  /// - [title]: optional widget rendered in the dialog's title slot, above [content].
  ///   Typically a [Text] styled by the caller, or any widget.
  /// - [content]: optional widget rendered in the dialog's body slot, below [title] and
  ///   above [actions]. Wrapped in a [LayrzScrollbar] over a scroll view so content taller
  ///   than the dialog's max height scrolls internally instead of overflowing, and in its
  ///   own [SelectableRegion] so text inside it is selectable and copyable -- matching
  ///   `DetailPane`'s pattern (always on, no opt-out), since dialog content is presented,
  ///   read-oriented text rather than an interactive canvas that selection gestures could
  ///   conflict with. Touch selection handles and the copy toolbar are gated to Android/iOS
  ///   only, per DESIGN-147 (see [LayrzPlatform.isTouchOS]).
  /// - [actions]: optional list of widgets (typically `LayrzButton`s) rendered in a row
  ///   at the bottom of the dialog, right-aligned with spacing between them.
  /// - [child]: an escape hatch for content that does not fit the [title]/[content]/[actions]
  ///   shape. When supplied, it replaces the entire body — [title], [content], and [actions]
  ///   must all be null. An assertion enforces this at the call site, because mixing the two
  ///   composition modes would leave it ambiguous which one governs layout.
  /// - [barrierDismissible]: whether tapping the barrier outside the dialog dismisses it.
  ///   Defaults to `true` when [actions] is null (an informational dialog with nothing to
  ///   lose), and `false` when [actions] is non-null (a dialog offering a decision should not
  ///   silently discard it on a stray click outside it — the caller can still pass `true`
  ///   explicitly to opt back in, e.g. for a non-destructive confirm/cancel pair). This is a
  ///   deliberate default, not a guess: a dialog holding meaningful input or an unmade
  ///   decision must not treat an accidental barrier tap the same as an explicit dismissal.
  ///   **Note**: the dismiss ("X") icon described below is currently always rendered and
  ///   always dismisses on tap, regardless of this value — a decision-bearing dialog that
  ///   sets `barrierDismissible: false` still exposes a one-tap way out via the X, which
  ///   bypasses the protection this parameter is meant to give. There is no parameter yet
  ///   to suppress the X independently; treat this as a known gap rather than an oversight.
  /// - [semanticLabel]: optional semantic label describing the dialog's purpose for screen
  ///   readers, announced alongside the barrier label when the dialog opens. If not provided,
  ///   only the barrier label (from [BuildContext.l10n]) is announced.
  /// - [maxWidth]: the maximum width the dialog's panel may occupy, in logical pixels.
  ///   Defaults to `480`. The panel also respects the viewport, so a narrow window still
  ///   clamps below this value.
  /// - [maxHeight]: the maximum height the dialog's panel may occupy, in logical pixels.
  ///   Defaults to `640`. Content taller than this scrolls internally rather than growing
  ///   the panel or overflowing.
  ///
  /// **Stacking**: opening a second [LayrzDialog] while one is already open is not
  /// supported in this version — an assertion fires rather than silently stacking two
  /// barriers into one visually-compounded overlay. Dismiss the current dialog before
  /// opening another.
  static Future<T?> show<T>(
    BuildContext context, {
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    Widget? child,
    bool? barrierDismissible,
    String? semanticLabel,
    double maxWidth = 480,
    double maxHeight = 640,
  }) {
    assert(
      child == null || (title == null && content == null && actions == null),
      'LayrzDialog.show: child is an escape hatch that replaces the entire body. '
      'Pass either child alone, or title/content/actions — not both.',
    );

    final navigator = Navigator.of(context, rootNavigator: true);

    // Stacking guard: a second LayrzDialog opened while one is already the
    // current route would compound two semi-transparent barriers into one
    // visually darker layer (each Stack paints its own scrim), which is
    // confusing and was called out explicitly as something to avoid rather
    // than leave undefined. v1 does not support dialog-over-dialog, so this
    // fails loudly instead of silently rendering it.
    assert(() {
      final current = ModalRoute.of(context);
      if (current is _DialogRoute) {
        throw FlutterError(
          'LayrzDialog.show was called while a LayrzDialog is already open. '
          'Stacking dialogs is not supported in this version — dismiss the '
          'current dialog before opening another.',
        );
      }
      return true;
    }());

    final effectiveBarrierDismissible = barrierDismissible ?? (actions == null);

    return navigator.push<T>(
      _DialogRoute<T>(
        title: title,
        content: content,
        actions: actions,
        child: child,
        barrierDismissible: effectiveBarrierDismissible,
        barrierLabel: context.l10n.dialogsBarrierLabel,
        semanticLabel: semanticLabel,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
    );
  }
}

/// Internal route class for managing the dialog presentation.
///
/// Extends [LayrzModalRoute] to share the barrier, reduce-motion, and
/// double-pop-guard machinery common to every modal surface in the design
/// system. Dialog-specific behaviour — the centered panel, its size bounds,
/// and the slot composition — stays here rather than in the shared base,
/// because it is meaningless for a non-dialog modal surface such as the sheet.
class _DialogRoute<T> extends LayrzModalRoute<T> {
  /// Optional title slot content.
  final Widget? title;

  /// Optional body slot content.
  final Widget? content;

  /// Optional action row content.
  final List<Widget>? actions;

  /// Escape-hatch content replacing the entire body.
  final Widget? child;

  /// Optional semantic label for screen readers (caller-supplied).
  final String? semanticLabel;

  /// Maximum panel width in logical pixels.
  final double maxWidth;

  /// Maximum panel height in logical pixels.
  final double maxHeight;

  /// Creates a new dialog route.
  _DialogRoute({
    required this.title,
    required this.content,
    required this.actions,
    required this.child,
    required super.barrierDismissible,
    required super.barrierLabel,
    required this.semanticLabel,
    required this.maxWidth,
    required this.maxHeight,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) {
           return _DialogContent(
             title: title,
             content: content,
             actions: actions,
             semanticLabel: semanticLabel,
             maxWidth: maxWidth,
             maxHeight: maxHeight,
             child: child,
           );
         },
         barrierColor: const Color(0x00000000), // Transparent initially; real color painted below.
         transitionDuration: const Duration(milliseconds: 200),
         transitionBuilder: (context, animation, secondaryAnimation, pageChild) {
           final barrierColor = context.tokens.colors.overlay.withValues(alpha: 0.5);
           final effectiveAnimation = LayrzModalRoute.resolveAnimation(context, animation);

           return Stack(
             children: [
               // Barrier. Mirrors LayrzBottomSheet's own barrier: an opaque
               // GestureDetector over a colored box, guarded by popIfCurrent
               // rather than a bare Navigator.pop so a fast second tap during
               // the dismiss transition (the barrier stays mounted and
               // hit-testable for the whole exit animation) cannot pop the
               // route underneath this one. See LayrzModalRoute.popIfCurrent.
               if (barrierDismissible)
                 GestureDetector(
                   behavior: HitTestBehavior.opaque,
                   onTap: () {
                     LayrzModalRoute.popIfCurrent(context);
                   },
                   child: Container(color: barrierColor),
                 )
               else
                 // Non-dismissible barrier: still painted (the page behind
                 // must read as non-interactive) but does not itself handle
                 // taps, so a stray click does not need a guard at all.
                 IgnorePointer(
                   child: Container(color: barrierColor),
                 ),
               Center(
                 child: FadeTransition(
                   opacity: effectiveAnimation,
                   child: ScaleTransition(
                     scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                       CurvedAnimation(parent: effectiveAnimation, curve: Curves.easeOut),
                     ),
                     child: pageChild,
                   ),
                 ),
               ),
             ],
           );
         },
         settings: const RouteSettings(name: '/dialog'),
       );
}

/// A tappable "X" icon that dismisses the enclosing [LayrzDialog].
///
/// Deliberately not a [LayrzButton] — the icon is a bare dismiss affordance, not
/// an action with a label, so it is built from [LayrzTappable] (the same hover/
/// press/focus-free building block [LayrzButton] itself is built on) directly
/// wrapping an [Icon]. Dismissal always goes through
/// [LayrzModalRoute.popIfCurrent], exactly like the barrier tap and Escape
/// handler, so a fast repeated tap during the exit transition cannot pop the
/// route underneath this one — see [LayrzModalRoute.popIfCurrent] for the
/// release-only bug that guard fixed.
class _DialogCloseButton extends StatelessWidget {
  /// Creates a dialog close button.
  const _DialogCloseButton();

  /// The hit target's side length, in logical pixels. Matches the icon's own
  /// visual size plus enough padding to keep the tap target comfortable
  /// without growing the title row's height noticeably.
  static const double _tapTargetSize = 28;

  /// The icon's size, in logical pixels.
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      label: context.l10n.dialogsCloseButtonLabel,
      excludeSemantics: true,
      child: LayrzTappable(
        onTap: () => LayrzModalRoute.popIfCurrent(context),
        borderRadius: tokens.radius.br1,
        child: SizedBox(
          width: _tapTargetSize,
          height: _tapTargetSize,
          child: Icon(
            MdiIcons.close,
            size: _iconSize,
            color: tokens.colors.fg3,
          ),
        ),
      ),
    );
  }
}

/// The actual content widget displayed inside the dialog route.
///
/// Manages focus (moving in on open, restoring to the invoker on close),
/// Escape-to-dismiss, and composes the [title]/[content]/[actions] slots or
/// the [child] escape hatch into a bounded, centered panel.
class _DialogContent extends StatefulWidget {
  /// Optional title slot content.
  final Widget? title;

  /// Optional body slot content.
  final Widget? content;

  /// Optional action row content.
  final List<Widget>? actions;

  /// Escape-hatch content replacing the entire body.
  final Widget? child;

  /// Optional semantic label for screen readers.
  final String? semanticLabel;

  /// Maximum panel width in logical pixels.
  final double maxWidth;

  /// Maximum panel height in logical pixels.
  final double maxHeight;

  /// Creates a dialog content widget.
  const _DialogContent({
    required this.title,
    required this.content,
    required this.actions,
    required this.child,
    required this.semanticLabel,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

/// State for [_DialogContent].
///
/// Owns focus restoration: [PopupRoute] (the base of [RawDialogRoute], which
/// [LayrzModalRoute] extends) traps focus inside the route while it is open,
/// but does not itself restore focus to whatever held it before the route was
/// pushed — a dialog that does not handle this leaves keyboard and
/// screen-reader users stranded with no focused element once it closes. This
/// State captures the previously-focused node in [initState] and explicitly
/// restores it in [dispose], which runs when the route is popped and its page
/// is removed from the tree.
class _DialogContentState extends State<_DialogContent> {
  late final FocusNode _focusNode;

  /// The node that held focus immediately before this dialog opened, captured
  /// in [initState] before this dialog's own [_focusNode] requests focus.
  /// Restored to it in [dispose]. `null` if nothing held focus (or the
  /// previously-focused node was disposed of independently in the meantime,
  /// in which case there is nothing safe to restore focus to).
  FocusNode? _previouslyFocused;

  /// The controller backing the [content] slot's scroll view.
  ///
  /// Owned here (rather than left implicit) so the exact same instance can be
  /// handed to both [LayrzScrollbar] and the [SingleChildScrollView] it
  /// decorates in [_buildSlots] -- [LayrzScrollbar] paints a thumb by reading
  /// a [ScrollPosition] off this controller, and a [Scrollbar]/[RawScrollbar]
  /// asserts if the controller it was given has no [ScrollPosition] attached,
  /// which is exactly what happened when neither widget was given an explicit
  /// controller and the scrollbar fell back to (an unattached)
  /// [PrimaryScrollController]. Mirrors [LayrzBottomSheet]'s own
  /// `DraggableScrollableSheet`-provided `scrollController`, wired the same
  /// way to its content's scroll view.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'LayrzDialog');
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _previouslyFocused = FocusManager.instance.primaryFocus;
      FocusScope.of(context).autofocus(_focusNode);
    });
  }

  @override
  void dispose() {
    // Restore focus to the invoker. Guarded because the previously-focused
    // node may have been disposed of independently while this dialog was
    // open (e.g. the widget that held it was removed from the tree by some
    // unrelated rebuild) -- FocusNode.canRequestFocus is false on a disposed
    // node rather than throwing, so this check is enough to make the
    // restoration a no-op in that case instead of crashing on teardown.
    final previouslyFocused = _previouslyFocused;
    if (previouslyFocused != null && previouslyFocused.canRequestFocus) {
      previouslyFocused.requestFocus();
    }
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final panel = Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Escape dismisses the dialog. isCurrent is checked at the call site
        // (not only inside popIfCurrent) so this handler can return `handled`
        // vs `ignored` BEFORE popping -- mirroring LayrzBottomSheet's own
        // Escape handler exactly (see bottom_sheet.dart), because the return
        // value decides whether Escape stops propagating here or keeps
        // bubbling to an ancestor that might otherwise also act on it.
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          LayrzModalRoute.popIfCurrent(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth, maxHeight: widget.maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colors.sf1,
            borderRadius: BorderRadius.circular(tokens.radius.r3),
            boxShadow: tokens.shadow.elevation3,
          ),
          child: widget.title != null
              // Title present: the close button is composed into the title
              // row itself (see _buildSlots), so no floating overlay is
              // needed here.
              ? Padding(
                  padding: EdgeInsets.all(tokens.spacing.sp3),
                  child: _buildSlots(context),
                )
              // No title -- either bare slots (content/actions only) or the
              // child escape hatch. Both cases still need a visible close
              // affordance (that is the whole point of always showing it),
              // so it floats over the panel's top-right corner via a Stack
              // rather than being composed into a title row that does not
              // exist. Painted AFTER (so visually above) the body, and inset
              // from the corner rather than flush with it, so it reads as an
              // overlay rather than colliding edge-to-edge with a `child`
              // that may paint its own content right up to the panel's
              // bounds -- callers using `child` should still leave a little
              // top-right clearance of their own, since this affordance
              // necessarily sits on top of whatever they placed there.
              : Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(tokens.spacing.sp3),
                      child: widget.child ?? _buildSlots(context),
                    ),
                    Positioned(
                      top: tokens.spacing.sp2,
                      right: tokens.spacing.sp2,
                      child: const _DialogCloseButton(),
                    ),
                  ],
                ),
        ),
      ),
    );

    // Route semantics, mirroring LayrzBottomSheet: only added when a label is
    // supplied, so a caller that omits semanticLabel does not get a focus
    // trap silently announced as an unnamed route.
    if (widget.semanticLabel != null) {
      return Semantics(
        label: widget.semanticLabel,
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        enabled: true,
        child: panel,
      );
    }

    return panel;
  }

  /// The [TextSelectionControls] used by the [content] slot's [SelectableRegion].
  ///
  /// DESIGN-147: touch selection handles and the selection action menu are
  /// Android/iOS only, on web or native (per [LayrzPlatform.isTouchOS]).
  /// [SelectableRegion.selectionControls] is required and non-nullable, so
  /// [emptyTextSelectionControls] is used as the "off" value instead: it does
  /// not mix in `TextSelectionHandleControls`, so [SelectableRegion] takes its
  /// `is! TextSelectionHandleControls` branch internally and shows a toolbar
  /// via the deprecated `buildToolbar()` path rather than force-unwrapping
  /// [_buildContextMenu] -- which is still passed unconditionally below and
  /// would otherwise null-check-crash on right-click. Mirrors
  /// `DetailPane._selectionControls` and `LayrzLayout`'s own gate exactly, so
  /// all [SelectableRegion] sites in the design system move together.
  TextSelectionControls get _selectionControls =>
      LayrzPlatform.isTouchOS ? LayrzTextSelectionControls.instance : emptyTextSelectionControls;

  /// Builds the copy toolbar for the [content] slot's [SelectableRegion].
  ///
  /// Mirrors `DetailPane._buildContextMenu` and `LayrzLayout`'s own -- a bare
  /// [SelectableRegion] with no `contextMenuBuilder` null-crashes on
  /// long-press in this repo, since there is no Material default to fall back
  /// on. On non-touch platforms this builder is never actually invoked -- see
  /// [_selectionControls] -- but it must remain unconditionally wired for the
  /// same reason.
  Widget _buildContextMenu(BuildContext context, SelectableRegionState state) {
    final tokens = context.tokens;
    final anchors = state.contextMenuAnchors;

    final toolbar = LayrzSelectionToolbar(
      actions: {LayrzSelectableAction.copy},
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor,
      tokens: tokens,
      onActionPressed: (actionType) {
        if (actionType == 'copy') {
          // ignore: deprecated_member_use
          state.copySelection(SelectionChangedCause.toolbar);
        }
      },
    );

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
      ),
      child: toolbar,
    );
  }

  /// Builds the [title]/[content]/[actions] slot layout used whenever
  /// [_DialogContent.child] is not supplied.
  ///
  /// The slot [Column] is sized directly against the [ConstrainedBox] the
  /// panel is already wrapped in (see `build`, which bounds it to
  /// [_DialogContent.maxWidth]/[_DialogContent.maxHeight]) rather than through
  /// an `IntrinsicWidth` shrink-to-fit. `IntrinsicWidth` must query the
  /// intrinsic width of its entire subtree, and `LayrzButton` builds its
  /// content through a `LayoutBuilder` (see button.dart), which by design
  /// throws rather than answer an intrinsic-dimension query — so any dialog
  /// with a `LayrzButton` anywhere in `title`/`content`/`actions` used to
  /// crash on open. Since the panel was already width-bounded by the
  /// `ConstrainedBox`, the `IntrinsicWidth` was shrink-to-fit polish, not a
  /// bounding requirement — dropping it means the panel now consistently
  /// takes [_DialogContent.maxWidth] instead of shrinking for small content,
  /// which matches the conventional dialog sizing that `maxWidth: 480`
  /// already implies.
  Widget _buildSlots(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: tokens.typography.title,
                  child: widget.title!,
                ),
              ),
              SizedBox(width: tokens.spacing.sp2),
              const _DialogCloseButton(),
            ],
          ),
          SizedBox(height: tokens.spacing.sp3),
        ],
        if (widget.content != null)
          Flexible(
            child: LayrzScrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableRegion(
                  selectionControls: _selectionControls,
                  contextMenuBuilder: _buildContextMenu,
                  child: DefaultTextStyle.merge(
                    style: tokens.typography.body,
                    child: widget.content!,
                  ),
                ),
              ),
            ),
          ),
        if (widget.actions != null && widget.actions!.isNotEmpty) ...[
          SizedBox(height: tokens.spacing.sp3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (int i = 0; i < widget.actions!.length; i++) ...[
                if (i > 0) SizedBox(width: tokens.spacing.sp2),
                widget.actions![i],
              ],
            ],
          ),
        ],
      ],
    );
  }
}
