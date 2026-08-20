import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// A Material-free card widget in the layrz_ui design system.
///
/// [LayrzCard] is a simple, elevated surface container that holds child content.
/// It supports five discrete elevation levels (1–5), an optional background color,
/// and optional interactive behavior via [onTap].
///
/// The card deliberately has no outer margin — inter-child spacing is owned by
/// [LayrzRow] and [LayrzConstrainedView] through their `spacing` parameter, so a card
/// margin would double-count. Place the card inside a spacing container if needed.
///
/// **Padding** is fixed at 16 logical pixels on all sides, matching the design system's
/// standard spacing. This is not exposed as a parameter.
///
/// **Interaction behavior:**
/// - When [onTap] is **null**, the card is inert: no hover response, no press response,
///   default cursor, not focusable, and it does NOT appear as a button to assistive technology.
/// - When [onTap] is **non-null**, the card is interactive:
///   - Cursor becomes [SystemMouseCursors.click].
///   - **Hovered**: shadow steps UP one level (clamped at elevation 5).
///   - **Pressed**: shadow steps DOWN one level (clamped at elevation 1).
///   - **Focused**: shadow steps UP one level (clamped at elevation 5), and focus is visible.
///   - Geometry (size, padding, radius) remains constant across states per decision D15.
///   - Focusable by Tab navigation; activatable by Enter or Space keys.
///   - Announced to assistive technology as an interactive button.
///
/// **Elevation** is an integer from 1 to 5, selecting the named ramp. Values outside
/// this range will trigger an assertion at construction time. The card uses the discrete
/// elevation ramp exclusively (e.g., [elevation1], [elevation2], …, [elevation5]),
/// not the continuous [elevation(double)] helper.
class LayrzCard extends StatefulWidget {
  /// Creates a new [LayrzCard].
  ///
  /// The [elevation] must be between 1 and 5 inclusive. [child] is required.
  /// When [backgroundColor] is null, the card defaults to the surface token color.
  /// When [onTap] is null, the card is not interactive.
  const LayrzCard({
    super.key,
    required this.child,
    this.elevation = 1,
    this.backgroundColor,
    this.onTap,
  }) : assert(
         elevation >= 1 && elevation <= 5,
         'elevation must be between 1 and 5, got $elevation',
       );

  /// The widget displayed inside the card.
  final Widget child;

  /// The elevation level of the card (1–5).
  ///
  /// Selects a discrete shadow level from the elevation ramp. Higher values
  /// produce a larger drop shadow. Defaults to 1.
  final int elevation;

  /// The background fill color of the card.
  ///
  /// When null, defaults to the surface token color (white in light mode).
  /// When provided, overrides the token color entirely.
  final Color? backgroundColor;

  /// Called when the user taps the card.
  ///
  /// When null, the card is not interactive (no cursor change, no hover/press feedback).
  final VoidCallback? onTap;

  @override
  State<LayrzCard> createState() => _LayrzCardState();
}

class _LayrzCardState extends State<LayrzCard> {
  /// Controller to manage interactive states (hovered, pressed, focused).
  late WidgetStatesController _statesController;

  /// Current elevation during interaction (may differ from widget.elevation).
  late int _currentElevation;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
    _currentElevation = widget.elevation;
  }

  @override
  void didUpdateWidget(LayrzCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elevation != widget.elevation) {
      _currentElevation = widget.elevation;
    }
  }

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  /// Resolves the shadow list for the current elevation level.
  List<BoxShadow> _resolveShadow(LayrzTokens tokens) {
    return switch (_currentElevation) {
      1 => tokens.shadow.elevation1,
      2 => tokens.shadow.elevation2,
      3 => tokens.shadow.elevation3,
      4 => tokens.shadow.elevation4,
      5 => tokens.shadow.elevation5,
      _ => tokens.shadow.elevation1,
    };
  }

  /// Handles pointer down to set the pressed state.
  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap == null) return;
    _statesController.update(WidgetState.pressed, true);
    _updateElevation();
  }

  /// Handles pointer up or cancel to release the pressed state.
  void _onPointerUp(PointerEvent event) {
    if (widget.onTap == null) return;
    _statesController.update(WidgetState.pressed, false);
    _updateElevation();
  }

  /// Updates the current elevation based on hover, press, and focus states.
  void _updateElevation() {
    if (!mounted) return;

    int newElevation = widget.elevation;
    final states = _statesController.value;

    // Hover or Focus: raise shadow one level, clamped at 5.
    if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      newElevation = (widget.elevation + 1).clamp(1, 5);
    }

    // Press takes precedence: lower shadow one level, clamped at 1.
    if (states.contains(WidgetState.pressed)) {
      newElevation = (widget.elevation - 1).clamp(1, 5);
    }

    if (newElevation != _currentElevation) {
      setState(() {
        _currentElevation = newElevation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final backgroundColor = widget.backgroundColor ?? tokens.colors.surface;

    final content = Container(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: tokens.radius.br3,
        boxShadow: _resolveShadow(tokens),
      ),
      child: widget.child,
    );

    // If not interactive, return the card as-is (no semantics, no focus).
    if (widget.onTap == null) {
      return content;
    }

    // If interactive, wrap with focus, keyboard, and semantic support.
    final interactiveCard = FocusableActionDetector(
      onShowHoverHighlight: (show) {
        _statesController.update(WidgetState.hovered, show);
        _updateElevation();
      },
      onShowFocusHighlight: (show) {
        _statesController.update(WidgetState.focused, show);
        _updateElevation();
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap!();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapCancel: () {
              _statesController.update(WidgetState.pressed, false);
              _updateElevation();
            },
            child: AnimatedContainer(
              duration: tokens.motion.dHover,
              curve: tokens.motion.easing,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: tokens.radius.br3,
                boxShadow: _resolveShadow(tokens),
              ),
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    // Wrap in Semantics to expose button properties to assistive technology.
    return Semantics(
      button: true,
      enabled: true,
      child: interactiveCard,
    );
  }
}
