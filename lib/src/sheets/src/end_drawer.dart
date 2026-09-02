import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';

/// A right-edge, fixed-width modal drawer for presenting content that needs
/// more room than an anchored panel, with an optional pinned action row.
///
/// [LayrzEndDrawer] is the public promotion of what was previously the
/// picker-only, library-private `LayrzPickerDrawer` (DESIGN-49). The
/// maintainer's own words, reported against the picker drawer's
/// Cancel/Clear/Save footer: *"Be like the BottomSheet and Dialog, place
/// actions slot, this way we can set sticked to end."* His screenshot showed
/// the calendar and its footer both crammed into the top ~35% of the drawer
/// with a large empty gap below — the footer was composed as an ordinary
/// trailing child of the scrolling body, so it only ever sat directly under
/// short content instead of at the drawer's own bottom edge. [actions] fixes
/// that structurally: it is a sibling of the scrollable body, not nested
/// inside it, so it always renders flush with the drawer's bottom edge
/// regardless of how short [builder]'s content is, exactly like
/// [LayrzDialog]'s and [LayrzBottomSheet]'s own action rows.
///
/// **Now a general-purpose overlay, not a picker-only implementation
/// detail.** The previous `LayrzPickerDrawer` doc argued against promotion:
/// *"nothing outside the picker family needs an end-drawer yet, and shipping
/// a public component nobody has reviewed for the general case is a bigger
/// commitment than this fix calls for."* The maintainer's DESIGN-98 request
/// reverses that call explicitly, and asks that every date-related input
/// (`LayrzDateInput`, `LayrzDateRangeInput`, `LayrzTimeInput`,
/// `LayrzTimeRangeInput`, `LayrzDateTimeInput`, `LayrzDateTimeRangeInput`,
/// `LayrzMonthInput`, `LayrzMonthRangeInput`) move onto it with an actions
/// row — including the three that previously committed on tap through
/// [LayrzAnchoredPanel] and had no footer at all. See each of those widgets'
/// own file for what changed.
///
/// **Built from [LayrzModalRoute]**, exactly as [LayrzBottomSheet] and
/// `LayrzDialog` are — this gets barrier handling, reduce-motion support, and
/// the double-pop guard for free, and keeps this drawer's own code limited to
/// what genuinely differs (slide-from-right transition, fixed width, no drag
/// handle, no snap sizes).
///
/// **`<960px` still uses [LayrzBottomSheet]** — this drawer is the desktop
/// container only; every caller keeps its own `context.isCompact` branch that
/// opens a bottom sheet unchanged. That branching lives in each input widget,
/// not here.
///
/// **Escape reverts a pending Save.** Pressing Escape dismisses the drawer
/// exactly like the barrier tap or [Navigator.pop] does — the surface never
/// treats Escape as "confirm", only as "cancel", mirroring [LayrzBottomSheet]'s
/// and [LayrzAnchoredPanel]'s identical contract.
///
/// **Involuntary close discards the draft.** [Navigator.push] always builds a
/// fresh [_EndDrawerContent] (and therefore a fresh `builder` subtree) on
/// every call to [show] — unlike [LayrzAnchoredPanel]'s `RawMenuAnchor`, which
/// keeps a single overlay entry alive and merely toggles its visibility, a
/// route push tears the whole subtree down on pop and builds an entirely new
/// one on the next push. So the surfaces this drawer hosts need no
/// `ValueKey`/generation-counter trick to force reconstruction — every open
/// already starts a fresh `State`, the same guarantee [LayrzBottomSheet]
/// already relies on for its own callers.
///
/// **Example usage** (a Save/Cancel picker):
/// ```dart
/// await LayrzEndDrawer.show<void>(
///   context,
///   semanticLabel: 'Choose a date',
///   builder: (context) => MyPickerSurface(),
///   actions: [
///     LayrzButton.cancel(labelText: 'Cancel', onTap: () => Navigator.pop(context)),
///     LayrzButton.save(labelText: 'Save', onTap: () => Navigator.pop(context)),
///   ],
/// );
/// ```
class LayrzEndDrawer {
  LayrzEndDrawer._();

  /// The drawer's fixed width in logical pixels.
  ///
  /// Chosen to comfortably fit a calendar grid alongside two time-field
  /// clusters without either needing to shrink — the same requirement that
  /// drove `LayrzPickerDrawer`'s original DESIGN-49 sizing, carried over
  /// unchanged by this promotion.
  static const double width = 420.0;

  /// Shows the drawer and returns the result.
  ///
  /// Returns `Future<T?>` that completes with the value passed to
  /// [Navigator.pop] in the drawer, or `null` if the drawer is dismissed
  /// without a value (barrier tap, Escape, or the system/Android back
  /// gesture).
  ///
  /// **Parameters:**
  /// - [context]: the build context from which to show the drawer. Must
  ///   contain a [Navigator].
  /// - [builder]: builds the drawer's scrolling content. The builder receives
  ///   the drawer's own [BuildContext].
  /// - [actions]: optional list of widgets (typically `LayrzButton`s),
  ///   rendered in a row **pinned to the drawer's bottom edge**, right-aligned
  ///   with spacing between them — matching [LayrzDialog]'s and
  ///   [LayrzBottomSheet]'s own `actions` slot's spacing, alignment, and
  ///   position, so all three components' action rows read as siblings rather
  ///   than cousins. `null` (the default) renders nothing and changes no
  ///   layout: the drawer's `Column` simply has no second child, identical to
  ///   every caller before DESIGN-98.
  ///
  ///   **Pinned to the bottom edge, never inside the scrolling content.**
  ///   [actions] is a sibling of the `Expanded` scroll view wrapping
  ///   [builder], not composed into [builder]'s own returned widget tree —
  ///   this is the structural fix for the maintainer's report: a short
  ///   [builder] no longer leaves an empty gap below the action row, because
  ///   the row is anchored to the drawer's own bottom edge rather than to the
  ///   bottom of whatever content happens to render above it. A tall
  ///   [builder] scrolls independently above the row without ever pushing it
  ///   off-screen.
  /// - [canDismiss]: whether the drawer can be dismissed by any route other
  ///   than one of its own [actions] — the barrier tap, the Escape key, and
  ///   the system/Android back gesture all read this single value. `null`
  ///   (the default) infers from [actions], mirroring [LayrzDialog.show]'s
  ///   identical inference exactly: dismissable (`true`) when [actions] is
  ///   `null` or empty (nothing to lose), not dismissable (`false`) when
  ///   [actions] is a non-empty list (a decision-bearing surface should be
  ///   answered through its actions, not escaped around them). Passing `true`
  ///   explicitly with [actions] present reopens every non-action route at
  ///   once, for a caller that wants both actions and free dismissal.
  /// - [semanticLabel]: names the drawer's route for screen readers. Required
  ///   in practice — without it no dialog/route semantics are added at all,
  ///   mirroring [LayrzBottomSheet.show]'s identical `semanticLabel` contract
  ///   (see its own doc for why this is not defaulted to a generic string).
  ///   Must be localized by the caller.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    List<Widget>? actions,
    bool? canDismiss,
    String? semanticLabel,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);

    // Single source of truth for every non-action dismissal route (barrier,
    // Escape, and the system/Android back gesture) -- mirrors
    // LayrzDialog.show's identical inference exactly (dialog.dart), computed
    // once here rather than re-derived at each dismissal site so they cannot
    // drift apart. Deliberately NOT composed by passing `actions: null` down
    // while rendering them inside `builder` -- see LayrzBottomSheet's own doc
    // for the corrected bug that pattern caused: actions must stay a real,
    // separate parameter the route itself reads.
    final effectiveCanDismiss = canDismiss ?? (actions == null || actions.isEmpty);

    return navigator.push<T>(
      _EndDrawerRoute<T>(
        builder: builder,
        actions: actions,
        canDismiss: effectiveCanDismiss,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Internal route class for managing the drawer's presentation. Mirrors
/// `_BottomSheetRoute`'s structure closely — see that class's own doc for the
/// shared machinery both build on via [LayrzModalRoute].
class _EndDrawerRoute<T> extends LayrzModalRoute<T> {
  /// Semantic label for screen readers (caller-supplied, optional).
  final String? semanticLabel;

  /// Creates a new drawer route.
  _EndDrawerRoute({
    required WidgetBuilder builder,
    required List<Widget>? actions,
    required bool canDismiss,
    required this.semanticLabel,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) {
           return _EndDrawerContent(
             builder: builder,
             actions: actions,
             canDismiss: canDismiss,
             semanticLabel: semanticLabel,
           );
         },
         barrierDismissible: canDismiss,
         barrierColor: const Color(0x00000000),
         transitionBuilder: (context, animation, secondaryAnimation, child) {
           final barrierColor = context.tokens.colors.overlay.withValues(alpha: 0.5);
           final effectiveAnimation = LayrzModalRoute.resolveAnimation(context, animation);

           return Stack(
             children: [
               if (canDismiss)
                 GestureDetector(
                   behavior: HitTestBehavior.opaque,
                   onTap: () => LayrzModalRoute.popIfCurrent(context),
                   child: Container(color: barrierColor),
                 )
               else
                 // Non-dismissible barrier, mirroring LayrzDialog's and
                 // LayrzBottomSheet's own: still painted (the page behind must
                 // read as non-interactive) but does not itself handle taps,
                 // so a stray click needs no guard at all.
                 IgnorePointer(
                   child: Container(color: barrierColor),
                 ),
               Align(
                 alignment: AlignmentDirectional.centerEnd,
                 child: SlideTransition(
                   position: Tween<Offset>(
                     begin: const Offset(1, 0),
                     end: Offset.zero,
                   ).animate(CurvedAnimation(parent: effectiveAnimation, curve: Curves.easeOut)),
                   child: child,
                 ),
               ),
             ],
           );
         },
         transitionDuration: const Duration(milliseconds: 300),
         settings: const RouteSettings(name: '/end_drawer'),
       );
}

/// The actual content widget displayed inside the drawer route.
///
/// Manages focus entry on open (mirroring [LayrzBottomSheet]'s own
/// `_BottomSheetContentState`), Escape-to-dismiss, and the system/Android
/// back gesture. Composes the scrolling [builder] body above a bottom-pinned
/// [actions] row — see [LayrzEndDrawer.show]'s `actions` doc for why the row
/// is a sibling of the scroll view rather than nested inside it. Unlike the
/// bottom sheet, this surface is never persistent and never drag-resizable —
/// every drawer this hosts is modal and fixed-width.
class _EndDrawerContent extends StatefulWidget {
  /// The builder function that constructs the drawer's scrolling content.
  final WidgetBuilder builder;

  /// Optional action row content, pinned to the drawer's bottom edge. See
  /// [LayrzEndDrawer.show]'s `actions` doc for the full contract.
  final List<Widget>? actions;

  /// Whether the drawer can be dismissed by any route other than one of its
  /// own [actions] -- gates Escape and the system/Android back gesture here.
  /// See [LayrzEndDrawer.show]'s `canDismiss` doc for the full contract; this
  /// is the same resolved value the enclosing [_EndDrawerRoute] also used for
  /// the barrier.
  final bool canDismiss;

  /// Semantic label for screen readers (caller-supplied, optional).
  final String? semanticLabel;

  /// Creates a new drawer content widget.
  const _EndDrawerContent({
    required this.builder,
    required this.actions,
    required this.canDismiss,
    required this.semanticLabel,
  });

  @override
  State<_EndDrawerContent> createState() => _EndDrawerContentState();
}

class _EndDrawerContentState extends State<_EndDrawerContent> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).autofocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;

    final focusChild = Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Escape dismisses the drawer, but only when it is dismissible --
        // gated on widget.canDismiss the same way the barrier and the
        // PopScope below are, mirroring LayrzDialog's and LayrzBottomSheet's
        // identical Escape handlers. When not dismissible, this returns
        // `ignored` unconditionally so Escape keeps propagating exactly as if
        // this drawer were not listening at all.
        if (widget.canDismiss &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          LayrzModalRoute.popIfCurrent(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: LayrzEndDrawer.width,
        height: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colors.sf1,
            boxShadow: tokens.shadow.elevation3,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: widget.builder(context),
                  ),
                ),
                // Actions -- a SECOND, non-expanded Column child, sibling to
                // the Expanded scroll view above rather than nested inside
                // it. This is the structural fix for the maintainer's report:
                // pinning the row here means it always sits flush with the
                // drawer's own bottom edge, regardless of how short the
                // scrolling content above it is -- mirroring
                // LayrzBottomSheet's own actions placement (bottom_sheet.dart)
                // exactly.
                if (hasActions)
                  Padding(
                    padding: EdgeInsets.all(tokens.spacing.sp3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < widget.actions!.length; i++) ...[
                          if (i > 0) SizedBox(width: tokens.spacing.sp2),
                          // Flexible (not left to size itself): a Row's
                          // non-flex children are handed UNBOUNDED width, so
                          // a caller passing a single wide action entry (the
                          // common case -- see LayrzPickerDrawerActions,
                          // which wraps a whole Cancel/Clear/Save row as one
                          // list entry) would size to that entry's own
                          // natural width regardless of the drawer's actual
                          // 420px-minus-padding budget, overflowing this Row
                          // instead of shrinking within it.
                          Flexible(child: widget.actions![i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // System/Android back gesture. canPop mirrors every other dismissal route
    // on widget.canDismiss: `true` lets the framework pop normally (identical
    // to there being no PopScope at all), `false` intercepts the pop attempt
    // and does nothing -- no partial dismissal, no popped route, no swallowed
    // gesture reaching past this drawer to an ancestor. Mirrors LayrzDialog's
    // and LayrzBottomSheet's own PopScope exactly.
    final popScoped = PopScope(
      canPop: widget.canDismiss,
      child: focusChild,
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        label: widget.semanticLabel,
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        enabled: true,
        child: popScoped,
      );
    }

    return popScoped;
  }
}
