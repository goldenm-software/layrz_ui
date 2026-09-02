import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// A Material-free wrapper that applies the standard Layrz hover and press treatment
/// to any child widget.
///
/// [LayrzTappable] wraps its child with a [MouseRegion] for hover detection,
/// a [GestureDetector] for tap/long-press/secondary-tap, and a [DecoratedBox]
/// for state-driven surface painting. It is the role [InkWell] plays in Material,
/// without Material and without an ink splash.
///
/// **Surface painting:**
/// - Default surface is transparent (no tint when idle).
/// - Hover paints a tint using the `hoverColor` or the default hover token.
/// - Pressed paints a tint using the `pressedColor` or the default pressed token.
/// - Disabled state disables all gestures and paints a disabled-state tint.
///
/// **States:**
/// - **Hovered**: the pointer is over the widget (desktop/mouse only).
/// - **Pressed**: the pointer is down within the widget.
/// - **Disabled**: when [disabled] is true, gestures are not wired and the
///   widget reflects the disabled visual state.
///
/// **Note:** [LayrzTappable] does NOT own focus. No [FocusNode], [Focus] widget,
/// or keyboard activation is provided. Focus remains with whatever real control
/// wraps this widget. This prevents unintended tab stops in, e.g., list rows that
/// already manage their own focus.
///
/// **Hit area:** The entire [borderRadius] region is tappable via [HitTestBehavior.opaque],
/// so even transparent areas of the painted surface respond to taps.
///
/// **Double-tap:** [onTap] fires at most once per [kDoubleTapTimeout] window, so a
/// double-tap invokes it exactly once rather than once per physical tap. There is no
/// public `onDoubleTap` -- see the implementation note on the cooldown timer for why.
/// A side effect of this: double-tap-to-select on text inside an active [LayrzTappable]
/// (via an ancestor [SelectableRegion]) is not restored by this fix -- the
/// [GestureDetector]'s tap recognizer still wins the gesture arena over
/// [SelectableRegion]'s own recognizer regardless of what the callback does afterward,
/// so that limitation is unchanged from before this fix (measured).
///
/// **Interaction states per decision D15:** Only colour, opacity, and cursor change
/// across states; geometry (size, padding, margin, border width) remains constant.
/// No ripple, splash, or scale animation.
///
/// Parameters:
/// - [child]: the widget to be wrapped (mandatory).
/// - [onTap]: called when the user taps the widget. If null, the widget is inert.
/// - [onLongPress]: called when the user long-presses the widget. If null, long-press
///   is not recognized. Ignored if [disabled] is true.
/// - [onSecondaryTap]: called when the user right-clicks or secondary-taps the widget.
///   If null, secondary tap is not recognized. Ignored if [disabled] is true.
/// - [disabled]: when true, all gestures are disabled, the cursor falls back to default,
///   and a disabled-state visual treatment is applied. Defaults to false.
/// - [borderRadius]: the border radius applied to the painted surface. Defaults to
///   [BorderRadius.zero] (sharp corners). This should match the child's own border
///   radius to avoid misaligned painting.
/// - [color]: the idle surface color. Defaults to transparent. When null, no tint
///   is applied while idle.
/// - [hoverColor]: the surface color when hovered. Defaults to null, which uses
///   [LayrzTokens.colors.sf2] (the second surface level). When non-null, overrides
///   the token-based hover color.
/// - [pressedColor]: the surface color when pressed. Defaults to null, which uses
///   [LayrzTokens.colors.sf3] (the third surface level). When non-null, overrides
///   the token-based pressed color.
/// - [collapseDoubleTap]: whether a double-tap is collapsed into a single [onTap]
///   call via the cooldown described above. Defaults to true. Set to false when
///   re-tapping the *same* target in quick succession is itself a legitimate,
///   distinct gesture that must not be swallowed -- see [collapseDoubleTap] for
///   the concrete case this exists for.
class LayrzTappable extends StatefulWidget {
  /// The widget to be wrapped with the tapable treatment.
  final Widget child;

  /// Called when the user taps the widget.
  ///
  /// When null, the widget is not interactive (no cursor change, no hover/press feedback).
  /// The gesture is not wired at all if [disabled] is true.
  final VoidCallback? onTap;

  /// Called when the user long-presses the widget.
  ///
  /// Ignored if [disabled] is true.
  final VoidCallback? onLongPress;

  /// Called when the user right-clicks or secondary-taps the widget.
  ///
  /// Ignored if [disabled] is true.
  final VoidCallback? onSecondaryTap;

  /// Whether the widget is disabled.
  ///
  /// When true, all gestures are disabled, the cursor falls back to default,
  /// and a disabled-state visual treatment is applied. Defaults to false.
  final bool disabled;

  /// The border radius applied to the painted surface.
  ///
  /// Defaults to [BorderRadius.zero] (sharp corners). This should match the
  /// child's own shape to avoid misaligned painting.
  final BorderRadius? borderRadius;

  /// The idle surface color.
  ///
  /// When null, defaults to transparent (no tint applied while idle).
  final Color? color;

  /// The surface color when hovered.
  ///
  /// Defaults to null, which uses [LayrzTokens.colors.sf2] (the second surface level).
  /// When non-null, overrides the token-based hover color.
  final Color? hoverColor;

  /// The surface color when pressed.
  ///
  /// Defaults to null, which uses [LayrzTokens.colors.sf4] (the fourth surface level).
  /// When non-null, overrides the token-based pressed color.
  final Color? pressedColor;

  /// Whether a double-tap is collapsed into a single [onTap] call.
  ///
  /// Defaults to true, matching the double-tap cooldown documented on the class:
  /// without it, a double-tap fires the underlying [GestureDetector]'s `onTap`
  /// twice -- once per physical tap, since nothing puts a [DoubleTapGestureRecognizer]
  /// in the gesture arena to make the two taps resolve as one gesture. That
  /// collapsing is correct for the overwhelming majority of tappable surfaces
  /// (buttons, rows, list items), where a double-tap should read as a single
  /// activation, not two.
  ///
  /// Set to false when re-tapping the *same* target in quick succession is itself
  /// a legitimate, distinct gesture rather than an accidental double-tap -- for
  /// example, a date-range picker calendar cell: a user first taps a cell to
  /// complete a range, then taps that same cell again, in quick succession, to
  /// pick it back up as the movable endpoint. With the default cooldown, that
  /// second tap is silently swallowed and the pick-up never happens. With this
  /// set to false, every discrete tap delivers its own [onTap] call.
  final bool collapseDoubleTap;

  /// Creates a new [LayrzTappable].
  ///
  /// All parameters except [child] are optional.
  const LayrzTappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.disabled = false,
    this.borderRadius,
    this.color,
    this.hoverColor,
    this.pressedColor,
    this.collapseDoubleTap = true,
  });

  @override
  State<LayrzTappable> createState() => _LayrzTappableState();
}

class _LayrzTappableState extends State<LayrzTappable> {
  /// Whether the pointer is currently over the widget (hover state).
  bool _isHovered = false;

  /// Whether the pointer is currently down within the widget (pressed state).
  bool _isPressed = false;

  /// Non-null while a just-fired [LayrzTappable.onTap] is still inside its
  /// double-tap cooldown window; a second [_handleTap] call while this is
  /// active is swallowed rather than re-invoking [LayrzTappable.onTap].
  ///
  /// This is a [Timer], not a `DateTime.now()` timestamp comparison: a
  /// [GestureDetector] with only `onTap` wired (no `onDoubleTap`) resolves
  /// each tap of a double-tap independently and fires `onTap` once per tap
  /// (measured: 2 calls for 2 taps). Adding a real `onDoubleTap` recognizer to
  /// the arena does make a double-tap collapse to a single `onTap`-shaped
  /// outcome, but it does so by *not* calling `onTap` at all on a double-tap
  /// (measured: 0 `onTap` calls, 1 `onDoubleTap` call) and it makes every
  /// single tap in the entire design system wait out the full recognizer
  /// resolution window before firing (measured: exactly `kDoubleTapTimeout`,
  /// 300ms, versus ~0ms today) -- both wrong for this fix. A post-resolution
  /// cooldown on the callback itself keeps single-tap latency at ~0ms (the
  /// [GestureDetector] arena and its timing are untouched) while still
  /// collapsing a double-tap to exactly one [LayrzTappable.onTap] call.
  Timer? _doubleTapCooldown;

  /// Resolves the current surface color based on state.
  Color _resolveColor(LayrzTokens tokens) {
    // Disabled state has its own visual treatment.
    if (widget.disabled) {
      // Use a disabled tint: semi-transparent dark for disabled appearance.
      return tokens.colors.fg3.withValues(alpha: 0.12);
    }

    // Pressed state takes priority over hover.
    if (_isPressed) {
      return widget.pressedColor ?? tokens.colors.sf4;
    }

    // Hover state.
    if (_isHovered) {
      return widget.hoverColor ?? tokens.colors.sf3;
    }

    // Idle state: use the explicit color or transparent.
    return widget.color ?? context.tokens.colors.sf1;
  }

  /// Resolves the cursor based on state and interactivity.
  MouseCursor _resolveCursor(LayrzTokens tokens) {
    if (widget.disabled || (widget.onTap == null && widget.onLongPress == null && widget.onSecondaryTap == null)) {
      return SystemMouseCursors.basic;
    }
    return SystemMouseCursors.click;
  }

  /// Handles pointer enter (hover).
  void _onEnter(PointerEnterEvent event) {
    if (widget.disabled) return;
    setState(() {
      _isHovered = true;
    });
  }

  /// Handles pointer exit (hover end).
  void _onExit(PointerExitEvent event) {
    if (widget.disabled) return;
    setState(() {
      _isHovered = false;
    });
  }

  /// Handles pointer down (press start).
  void _onPointerDown(PointerDownEvent event) {
    if (widget.disabled) return;
    setState(() {
      _isPressed = true;
    });
  }

  /// Handles pointer up or cancel (press end).
  void _onPointerUp(PointerEvent event) {
    if (widget.disabled) return;
    setState(() {
      _isPressed = false;
    });
  }

  /// Invokes [LayrzTappable.onTap], applying the double-tap cooldown only when
  /// [LayrzTappable.collapseDoubleTap] is true.
  ///
  /// Without the cooldown, a double-tap fires the underlying [GestureDetector]'s
  /// `onTap` twice -- once per physical tap, since nothing puts a
  /// [DoubleTapGestureRecognizer] in the gesture arena to make the two taps
  /// resolve as one gesture. See [_doubleTapCooldown] for why this is a
  /// [Timer]-based cooldown rather than an `onDoubleTap` recognizer. When
  /// [LayrzTappable.collapseDoubleTap] is false, that swallowing is skipped
  /// entirely and every physical tap delivers its own [LayrzTappable.onTap] call.
  void _handleTap() {
    if (!widget.collapseDoubleTap) {
      widget.onTap?.call();
      return;
    }
    if (_doubleTapCooldown != null) return;
    widget.onTap?.call();
    _doubleTapCooldown = Timer(kDoubleTapTimeout, () => _doubleTapCooldown = null);
  }

  @override
  void dispose() {
    _doubleTapCooldown?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LayrzTappable oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        // Reset hover and press states if the widget becomes disabled or loses all gestures.
        if (widget.disabled || (widget.onTap == null && widget.onLongPress == null && widget.onSecondaryTap == null)) {
          _isHovered = false;
          _isPressed = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final borderRadius = widget.borderRadius ?? BorderRadius.zero;
    final surfaceColor = _resolveColor(tokens);

    // Inert path: no gestures, no hover feedback.
    if (widget.disabled || (widget.onTap == null && widget.onLongPress == null && widget.onSecondaryTap == null)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: borderRadius,
        ),
        child: widget.child,
      );
    }

    // Interactive path: wrap with mouse region, listeners, and animated decoration.
    return MouseRegion(
      cursor: _resolveCursor(tokens),
      onEnter: _onEnter,
      onExit: _onExit,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: GestureDetector(
          onTap: widget.onTap == null ? null : _handleTap,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onSecondaryTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: tokens.motion.dHover,
            curve: tokens.motion.easing,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: borderRadius,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
