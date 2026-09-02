import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';

/// A right-edge drawer used as the desktop container for the five
/// Save-carrying picker widgets (`LayrzDateRangeInput`, `LayrzTimeRangeInput`,
/// `LayrzDateTimeInput`, `LayrzDateTimeRangeInput`, `LayrzMonthRangeInput`).
///
/// **Why this exists**: DESIGN-49 replaced [LayrzAnchoredPanel] for these five
/// widgets. The maintainer's own words: *"I think we should remove the tab
/// format, and use an EndDrawer on desktop and Bottom sheet on mobile, using
/// the overlay like the other inputs well, technically works, but it's kinda
/// weird. and uses a lot of space, with an EndDrawer we have more space to
/// use."* An anchored panel's width tracks the anchor field, which is too
/// cramped for a calendar plus two time-field clusters; a fixed-width drawer
/// gives these widgets room the anchored panel cannot.
///
/// **Library-private to the pickers module, not a new public overlay
/// primitive.** [LayrzPickerDrawer] is deliberately narrow in scope: it only
/// knows how to host one picker surface with a fixed width and full height,
/// with no snap sizes, no drag handle, and no generic "arbitrary side"
/// configuration the way [LayrzAnchoredPanel] offers. Promoting this to
/// `lib/src/overlays/` as a public `LayrzDrawer` was considered and rejected
/// for this unit: nothing outside the picker family needs an end-drawer yet,
/// and shipping a public component nobody has reviewed for the general case
/// is a bigger commitment than this fix calls for. If a second, unrelated
/// caller needs a drawer, promoting this file (or building a more general
/// sibling) is a decision for the maintainer, not an incidental side effect
/// of this fix.
///
/// **Built from [LayrzModalRoute]**, exactly as [LayrzBottomSheet] is — this
/// gets barrier handling, reduce-motion support, and the double-pop guard for
/// free, and keeps this drawer's own code limited to what genuinely differs
/// (slide-from-right transition, fixed width, no drag handle).
///
/// **`<960px` still uses [LayrzBottomSheet]** — this drawer is the desktop
/// container only; every caller in this batch keeps its existing
/// `context.isCompact` branch that opens a bottom sheet unchanged.
///
/// **Escape reverts a pending Save.** Pressing Escape dismisses the drawer
/// exactly like the barrier tap or [Navigator.pop] does — the surface never
/// treats Escape as "confirm", only as "cancel", mirroring
/// [LayrzBottomSheet]'s and [LayrzAnchoredPanel]'s identical contract.
///
/// **Involuntary close discards the draft.** [Navigator.push] always builds
/// a fresh [_PickerDrawerContent] (and therefore a fresh `builder` subtree)
/// on every call to [show] — unlike [LayrzAnchoredPanel]'s `RawMenuAnchor`,
/// which keeps a single overlay entry alive and merely toggles its
/// visibility, a route push tears the whole subtree down on pop and builds
/// an entirely new one on the next push. So the picker surfaces this drawer
/// hosts need no `ValueKey`/generation-counter trick to force
/// reconstruction — every open already starts a fresh `State`, the same
/// guarantee [LayrzBottomSheet] already relies on for its own callers.
class LayrzPickerDrawer {
  LayrzPickerDrawer._();

  /// The drawer's fixed width in logical pixels.
  ///
  /// Chosen to comfortably fit a calendar grid alongside two time-field
  /// clusters without either needing to shrink — the whole reason DESIGN-49
  /// asked for a drawer instead of the anchored panel.
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
  /// - [builder]: builds the drawer's content. The builder receives the
  ///   drawer's own [BuildContext].
  /// - [semanticLabel]: names the drawer's route for screen readers. Required
  ///   in practice — without it no dialog/route semantics are added at all,
  ///   mirroring [LayrzBottomSheet.show]'s identical `semanticLabel` contract
  ///   (see its own doc for why this is not defaulted to a generic string).
  ///   Must be localized by the caller.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? semanticLabel,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);

    return navigator.push<T>(
      _PickerDrawerRoute<T>(
        builder: builder,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Internal route class for managing the drawer's presentation. Mirrors
/// `_BottomSheetRoute`'s structure closely — see that class's own doc for the
/// shared machinery both build on via [LayrzModalRoute].
class _PickerDrawerRoute<T> extends LayrzModalRoute<T> {
  /// Semantic label for screen readers (caller-supplied, optional).
  final String? semanticLabel;

  /// Creates a new drawer route.
  _PickerDrawerRoute({
    required WidgetBuilder builder,
    required this.semanticLabel,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) {
           return _PickerDrawerContent(builder: builder, semanticLabel: semanticLabel);
         },
         barrierDismissible: true,
         barrierColor: const Color(0x00000000),
         transitionBuilder: (context, animation, secondaryAnimation, child) {
           final barrierColor = context.tokens.colors.overlay.withValues(alpha: 0.5);
           final effectiveAnimation = LayrzModalRoute.resolveAnimation(context, animation);

           return Stack(
             children: [
               GestureDetector(
                 behavior: HitTestBehavior.opaque,
                 onTap: () => LayrzModalRoute.popIfCurrent(context),
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
         settings: const RouteSettings(name: '/picker_drawer'),
       );
}

/// The actual content widget displayed inside the drawer route.
///
/// Manages focus entry on open (mirroring [LayrzBottomSheet]'s own
/// `_BottomSheetContentState`), Escape-to-dismiss, and the system/Android
/// back gesture. Unlike the bottom sheet, this surface is never persistent
/// and never drag-resizable — every drawer this batch opens is modal and
/// fixed-width.
class _PickerDrawerContent extends StatefulWidget {
  /// The builder function that constructs the drawer's content.
  final WidgetBuilder builder;

  /// Semantic label for screen readers (caller-supplied, optional).
  final String? semanticLabel;

  /// Creates a new drawer content widget.
  const _PickerDrawerContent({required this.builder, required this.semanticLabel});

  @override
  State<_PickerDrawerContent> createState() => _PickerDrawerContentState();
}

class _PickerDrawerContentState extends State<_PickerDrawerContent> {
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

    final focusChild = Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Mirrors _BottomSheetContentState's identical Escape handling
        // (bottom_sheet.dart) -- guarded on isCurrent for the same
        // double-pop reason documented there.
        if (event.logicalKey == LogicalKeyboardKey.escape && (ModalRoute.of(context)?.isCurrent ?? false)) {
          LayrzModalRoute.popIfCurrent(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: LayrzPickerDrawer.width,
        height: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colors.sf1,
            boxShadow: tokens.shadow.elevation3,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: widget.builder(context),
            ),
          ),
        ),
      ),
    );

    final popScoped = PopScope(
      canPop: true,
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
