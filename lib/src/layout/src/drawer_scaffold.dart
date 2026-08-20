import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// A module-private scaffold that owns the animated drawer presentation.
///
/// This widget manages the entire drawer animation: the page scales down and
/// translates right, revealing the drawer behind it. The animation is driven by
/// a single [AnimationController] with full gesture support (edge drag to open,
/// swipe to close, fling settle).
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutDrawerScaffold extends StatefulWidget {
  /// Creates a drawer scaffold.
  const LayrzLayoutDrawerScaffold({
    /// Callback to build the top bar with access to open drawer.
    required this.topBarBuilder,

    /// The main content widget (body).
    required this.body,

    /// Callback to build the drawer with access to close drawer.
    required this.drawerBuilder,

    /// The background color of the page layer.
    required this.backgroundColor,

    super.key,
  });

  /// Callback to build the top bar, receives openDrawer callback.
  final Widget Function(VoidCallback openDrawer) topBarBuilder;

  /// The main content widget (body).
  final Widget body;

  /// Callback to build the drawer, receives closeDrawer callback.
  final Widget Function(VoidCallback closeDrawer) drawerBuilder;

  /// The background color of the page layer.
  final Color backgroundColor;

  @override
  State<LayrzLayoutDrawerScaffold> createState() => _LayrzLayoutDrawerScaffoldState();
}

class _LayrzLayoutDrawerScaffoldState extends State<LayrzLayoutDrawerScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  bool _themedInitialized = false;
  bool _isDragging = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
      reverseCurve: Curves.linear,
    );
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final newIsOpen = _controller.value > 0;
    if (newIsOpen != _isOpen) {
      setState(() {
        _isOpen = newIsOpen;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update animation durations and curves based on tokens once.
    if (!_themedInitialized) {
      final tokens = context.tokens;
      _controller.duration = tokens.motion.dPageTransition;
      _controller.reverseDuration = tokens.motion.dPageTransition;
      // Dispose old animation and create new one with correct curves
      _curvedAnimation.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: tokens.motion.easingEnter,
        reverseCurve: tokens.motion.easingExit,
      );
      _themedInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Open the drawer with animation or jump.
  void openDrawer() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  /// Close the drawer with animation or jump.
  void closeDrawer() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.0;
    } else {
      _controller.reverse();
    }
  }

  /// Settle the drawer based on fling velocity and position.
  void _settleDrawer(double velocity) {
    // Settle direction: velocity threshold is 365 px/s.
    // Positive velocity (rightward) opens, negative closes.
    const settleVelocity = kLayrzLayoutDrawerDragSettleVelocity;
    final currentValue = _controller.value;

    bool shouldOpen = false;
    if (velocity.abs() > settleVelocity) {
      // Velocity is strong; positive opens, negative closes.
      shouldOpen = velocity > 0;
    } else {
      // Velocity is weak; settle on position.
      shouldOpen = currentValue > 0.5;
    }

    if (shouldOpen) {
      openDrawer();
    } else {
      closeDrawer();
    }
  }

  /// Handle horizontal drag start.
  void _onHorizontalDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  /// Handle horizontal drag update.
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Update controller value based on drag distance (linear, no easing).
    _controller.value += details.delta.dx / kLayrzLayoutDrawerWidth;
  }

  /// Handle horizontal drag end.
  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    // Settle based on fling velocity (px/s).
    final pixelsPerSecond = details.velocity.pixelsPerSecond.dx;
    _settleDrawer(pixelsPerSecond);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Build the page (top bar + body) once, outside the AnimatedBuilder.
    final page = Column(
      children: [
        widget.topBarBuilder(openDrawer),
        Expanded(child: widget.body),
      ],
    );

    // Build the drawer once, outside the AnimatedBuilder, and reuse it.
    // This prevents ~1000 rebuilds per second and eliminates GC pressure.
    final drawerWidget = RepaintBoundary(
      child: widget.drawerBuilder(closeDrawer),
    );

    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          closeDrawer();
        }
      },
      child: ColoredBox(
        color: widget.backgroundColor,
        child: AnimatedBuilder(
          animation: _isDragging ? _controller : _curvedAnimation,
          child: drawerWidget,
          builder: (context, drawerChild) {
            // Use curved value for animations, raw value for drags.
            final t = _isDragging ? _controller.value : _curvedAnimation.value;

            // Build page layer: bare when closed (t == 0), transformed/clipped when open (t > 0).
            // ColoredBox appears in both branches; Transform/Clip/shadow only when t > 0.
            Widget pageLayer = ColoredBox(
              color: widget.backgroundColor,
              child: page,
            );

            if (t > 0) {
              // Geometry: scale and translate.
              final scale = lerpDouble(1.0, kLayrzLayoutDrawerOpenScale, t) ?? 1.0;
              final dx = kLayrzLayoutDrawerWidth * t;
              final borderRadius = lerpDouble(0.0, tokens.radius.r16, t) ?? 0.0;

              pageLayer = IgnorePointer(
                ignoring: true,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.scale(
                    key: const ValueKey('drawer_scaffold_page_layer_transformed'),
                    scale: scale,
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        boxShadow: tokens.shadow.elevation4,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: RepaintBoundary(
                          child: ColoredBox(
                            color: widget.backgroundColor,
                            child: page,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Stack(
              children: [
                // (1) Drawer panel, positioned at left edge, width 260. Mounted only while t > 0.
                if (t > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: kLayrzLayoutDrawerWidth,
                    child: drawerChild!,
                  ),

                // (2) Page layer: bare when closed, transformed/clipped when open.
                Positioned.fill(child: pageLayer),

                // (3) Tap-to-close and open-state drag detector (merged into one).
                // Uses fixed Positioned.fill + Transform for paint-only, no layout.
                if (t > 0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(kLayrzLayoutDrawerWidth * t, 0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: closeDrawer,
                        onHorizontalDragStart: _onHorizontalDragStart,
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),

                // (4) Closed-state edge drag detector (20px strip on left).
                // Uses HitTestBehavior.opaque for hit-testability.
                if (t == 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: kLayrzLayoutDrawerEdgeDragWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: _onHorizontalDragStart,
                      onHorizontalDragUpdate: _onHorizontalDragUpdate,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
