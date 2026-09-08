import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'context_menu_item.dart';
import 'context_menu_layout_delegate.dart';
import 'context_menu_panel_items.dart';

/// A Material-free wrapper widget that shows a context menu anchored at the
/// pointer position, in the layrz_ui design system.
///
/// [LayrzContextMenu] wraps an arbitrary [child] and shows a floating [entries]
/// panel when the user:
/// - **right-clicks** (secondary tap) on desktop/web, or
/// - **long-presses** on touch devices.
///
/// The panel is anchored to the exact pointer position that triggered it —
/// not to [child]'s own rect — and is flipped/clamped by
/// [LayrzContextMenuLayoutDelegate] so it always stays fully inside the
/// viewport, however close to an edge the pointer was.
///
/// **Trigger gating:** both gestures are always wired, but which one a given
/// pointer device actually uses is a platform fact, not a caller choice —
/// mice and trackpads present a secondary button (right-click) that touch
/// hardware does not have, and touch surfaces have no secondary button to
/// press. `onSecondaryTapDown` and `onLongPressStart` are both always active,
/// because a touch-only device simply never emits `onSecondaryTapDown` and a
/// mouse-only device rarely triggers a long-press by accident. Suppressing
/// the browser's own native context menu on web (see
/// [_maybeSuppressBrowserContextMenu]) is the only platform-conditional
/// behavior this widget has, and it is handled by [BrowserContextMenu]
/// itself, which is a no-op on every non-web target.
///
/// **Self-contained:** this widget ships its own entry model
/// ([LayrzContextMenuEntry], [LayrzContextMenuLabel], [LayrzContextMenuDivider])
/// rather than reusing `LayrzDropdownEntry`/`LayrzDropdownItem` from
/// `lib/src/menus/` — the two menu families are intentionally independent so
/// a change to one can never silently ripple into the other.
///
/// **Child gestures:** [child] keeps its own tap/long-press gestures where
/// possible. This widget only listens for `onSecondaryTapDown` (which has no
/// primary-gesture equivalent to conflict with) and `onLongPressStart`. A
/// long-press recognizer competing with one already present on [child] is
/// resolved by Flutter's normal gesture arena — if [child] itself declares a
/// competing long-press recognizer, only one of the two ultimately wins the
/// gesture, which is an unavoidable consequence of two long-press
/// recognizers existing on the same pointer down.
///
/// **Graceful degradation:** if the widget tree has no [Overlay] ancestor,
/// [LayrzContextMenu] returns [child] unchanged (no menu is ever shown). This
/// keeps [child] renderable in minimal test harnesses.
///
/// **Panel styling:**
/// - Background: `tokens.colors.sf1`
/// - Border radius: `tokens.radius.br3`
/// - Shadow: `tokens.shadow.elevation3`
/// - Enter animation: fade using `tokens.motion.dHover`/`easingEnter`
class LayrzContextMenu extends StatefulWidget {
  /// The widget wrapped by this context menu.
  ///
  /// Keeps its own gestures where possible — see the class doc for how this
  /// widget's own gesture detection composes with [child]'s.
  final Widget child;

  /// The items shown in the context menu panel when it opens.
  ///
  /// Each element is one of [LayrzContextMenuEntry], [LayrzContextMenuLabel],
  /// or [LayrzContextMenuDivider] — the sealed [LayrzContextMenuItem]
  /// hierarchy makes any other widget type impossible by construction.
  final List<LayrzContextMenuItem> entries;

  /// Optional maximum height for the panel's content in logical pixels.
  ///
  /// When `null` (the default), the panel's height is constrained only by
  /// the overlay bounds minus padding. When set, content taller than this
  /// value scrolls inside the panel.
  final double? maxHeight;

  /// Whether to suppress the browser's native context menu on web when the
  /// user right-clicks [child].
  ///
  /// Defaults to `true`. Without suppression, a right-click on web would
  /// show both this widget's own menu and the browser's native one
  /// simultaneously. Has no effect on non-web targets.
  final bool suppressBrowserContextMenu;

  /// Creates a new [LayrzContextMenu].
  ///
  /// [child] and [entries] are required. [maxHeight] and
  /// [suppressBrowserContextMenu] are optional.
  const LayrzContextMenu({
    required this.child,
    required this.entries,
    this.maxHeight,
    this.suppressBrowserContextMenu = true,
    super.key,
  });

  @override
  State<LayrzContextMenu> createState() => _LayrzContextMenuState();
}

class _LayrzContextMenuState extends State<LayrzContextMenu> with SingleTickerProviderStateMixin {
  late final MenuController _controller;
  late final AnimationController _animationController;
  late final CurvedAnimation _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MenuController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _maybeSuppressBrowserContextMenu();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guarded: this widget must degrade gracefully to a bare `child` when
    // there is no ancestor `Overlay` (see `build`), which in practice also
    // means there may be no ancestor `LayrzTheme` in a minimal test harness.
    // `context.tokens` asserts on a missing `LayrzTheme`, so reading it here
    // unconditionally would crash before `build` ever gets a chance to
    // degrade.
    try {
      _animationController.duration = context.tokens.motion.dHover;
    } catch (_) {
      // Theme not available; the animation keeps its placeholder duration
      // and the widget still degrades correctly in `build`.
    }
  }

  /// Suppresses the browser's native context menu on web.
  ///
  /// [BrowserContextMenu] (from `package:flutter/services.dart`, itself
  /// re-exported by `package:flutter/widgets.dart` — no Material/Cupertino
  /// import needed) documents itself as a no-op on non-web targets, but its
  /// own `disableContextMenu`/`enableContextMenu` methods carry a hard
  /// `assert(kIsWeb, ...)` rather than silently returning — calling either
  /// one on a native target trips that assertion in debug/test builds. The
  /// explicit [kIsWeb] guard here is therefore load-bearing, not defensive
  /// styling: without it every widget test for this widget would fail with
  /// that assertion the moment [initState] ran. Without suppression, a
  /// right-click on web shows both the browser's own native menu and this
  /// widget's panel at once.
  void _maybeSuppressBrowserContextMenu() {
    if (!widget.suppressBrowserContextMenu || !kIsWeb) return;
    BrowserContextMenu.disableContextMenu();
  }

  @override
  void dispose() {
    if (widget.suppressBrowserContextMenu && kIsWeb) {
      // Restore the browser's native context menu so other widgets on the
      // page (or a future page) are not left with it permanently disabled.
      BrowserContextMenu.enableContextMenu();
    }
    _animationController.dispose();
    _curvedAnimation.dispose();
    super.dispose();
  }

  void _handleOpenRequested(Offset? position, VoidCallback showOverlay) {
    showOverlay();
    _animationController.reset();
    _animationController.forward();
  }

  void _handleCloseRequested(VoidCallback hideOverlay) {
    _animationController.reset();
    hideOverlay();
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    _controller.open(position: details.localPosition);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _controller.open(position: details.localPosition);
  }

  Widget _buildPanelOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final tokens = context.tokens;

    return TapRegion(
      groupId: info.tapRegionGroupId,
      onTapOutside: (PointerDownEvent event) {
        MenuController.maybeOf(context)?.close();
      },
      child: CustomSingleChildLayout(
        delegate: LayrzContextMenuLayoutDelegate(
          anchorRect: info.anchorRect,
          position: info.position,
          overlaySize: info.overlaySize,
          tokens: tokens,
          maxHeight: widget.maxHeight,
        ),
        child: FadeTransition(
          opacity: _curvedAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: tokens.colors.sf1,
              borderRadius: tokens.radius.br3,
              boxShadow: tokens.shadow.elevation3,
            ),
            child: ClipRRect(
              borderRadius: tokens.radius.br3,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.entries
                      .map((item) => LayrzContextMenuItemWidget(item: item))
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Overlay.maybeOf(context) == null) {
      return widget.child;
    }

    return RawMenuAnchor(
      controller: _controller,
      onOpenRequested: _handleOpenRequested,
      onCloseRequested: _handleCloseRequested,
      useRootOverlay: true,
      consumeOutsideTaps: false,
      overlayBuilder: _buildPanelOverlay,
      builder: (context, controller, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTapDown: _handleSecondaryTapDown,
          onLongPressStart: _handleLongPressStart,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
