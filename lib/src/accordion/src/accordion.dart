import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'accordion_style_spec.dart';

/// A single, Material-free disclosure panel that expands and collapses to
/// reveal its body content.
///
/// [LayrzAccordion] renders a fixed header -- an optional leading icon, a
/// title, and a trailing chevron that rotates with the expansion progress --
/// followed by a body that is only present in the widget tree while expanded.
/// It is built on the SDK [Expansible] primitive (`package:flutter/widgets.dart`),
/// which supplies the expand/collapse animation and height interpolation; this
/// widget is a styling and interaction wrap around it, not a ground-up
/// implementation.
///
/// **This is a single panel, not a group.** Group behaviour -- multiple
/// accordions coordinating so only one stays open, nesting one accordion
/// inside another's body, or a free-form header slot replacing the fixed
/// leading-icon/title/chevron layout -- is explicit v1 non-goal. A caller who
/// needs several of these to behave like a group composes that coordination
/// themselves, driving each instance's [expanded] from shared state.
///
/// **Controlled, not stateful.** [LayrzAccordion] holds no expansion state of
/// its own. [expanded] is the single source of truth, and [onExpansionChanged]
/// is the only way the widget asks its caller to change it -- mirroring every
/// other controlled input in this design system. There is no internal toggle
/// that can drift from what the caller believes is showing.
///
/// **Whole-header hit target.** The entire header row -- leading icon, title,
/// and chevron alike -- is a single tap and keyboard target. This is a hard
/// requirement, not a convenience: a chevron-only hit target is the most
/// common real-world complaint about disclosure widgets, since users expect
/// to be able to tap or click anywhere on a visually cohesive row.
///
/// **Collapsed body is genuinely absent from the tree.** [Expansible] is
/// configured with `maintainState: false`, so once the collapse animation
/// finishes, the body subtree is not merely hidden (as an [Offstage] or
/// zero-height box would do) -- it is not built at all. A screen reader
/// walking the tree while collapsed never encounters the body's content.
///
/// **Motion.** The reveal animation always uses
/// [LayrzMotionTokens.easingEmphasized] (`Curves.easeInOutCirc` by default),
/// never a hardcoded curve -- this is the token disclosure components use for
/// a height change large enough that the standard [LayrzMotionTokens.easing]
/// reads as too subtle.
///
/// **Interaction states.** Per decision D15, hovering, focusing, or pressing
/// the header only ever changes colour -- never its size, padding, or border
/// width. The header's own height change on expand/collapse is the widget's
/// *function*, not an interaction state, and is not subject to that rule.
class LayrzAccordion extends StatefulWidget {
  /// The title text displayed in the header.
  final String titleText;

  /// An optional icon displayed before the title in the header.
  ///
  /// When null, the header lays out with just the title and the trailing
  /// chevron -- no placeholder space is reserved for a leading icon.
  final IconData? leadingIcon;

  /// The content revealed below the header while the panel is expanded.
  ///
  /// Only present in the widget tree while [expanded] is true or the reveal
  /// animation is still in flight; see the class documentation for why the
  /// body is fully removed, not merely hidden, once collapsed.
  final Widget body;

  /// Whether the panel is currently expanded.
  ///
  /// [LayrzAccordion] is fully controlled: this is the single source of truth
  /// for the panel's expansion state. Toggling the header calls
  /// [onExpansionChanged] with the new desired value; it never mutates this
  /// value itself.
  final bool expanded;

  /// Called with the new desired expansion state when the header is tapped
  /// or activated via keyboard (Space or Enter).
  ///
  /// When null, the header is disabled: it does not respond to tap, keyboard
  /// activation, or hover/press visuals, and is excluded from the a11y tree's
  /// interactive actions (though its label and expanded state are still
  /// announced).
  final ValueChanged<bool>? onExpansionChanged;

  /// Creates a new [LayrzAccordion].
  const LayrzAccordion({
    super.key,
    required this.titleText,
    required this.body,
    required this.expanded,
    this.onExpansionChanged,
    this.leadingIcon,
  });

  @override
  State<LayrzAccordion> createState() => _LayrzAccordionState();
}

class _LayrzAccordionState extends State<LayrzAccordion> {
  /// Drives [Expansible]'s expand/collapse animation and state machine.
  ///
  /// Kept in sync with [LayrzAccordion.expanded] in [didUpdateWidget] and on
  /// first build via [initState], since [LayrzAccordion] itself holds no
  /// expansion state -- [Expansible] still needs a concrete controller object
  /// to drive its internal animation.
  late final ExpansibleController _controller;

  /// The interactive states currently active on the header (hover, focus,
  /// press, disabled), resolved into a [LayrzAccordionStyleSpec] on every build.
  final Set<WidgetState> _states = {};

  /// The focus node backing keyboard activation of the header.
  ///
  /// Owned and disposed by this widget -- [LayrzAccordion] does not expose a
  /// caller-supplied focus node, since a single disclosure panel has no
  /// scenario (unlike a form field) where a caller needs to drive its focus
  /// externally.
  final FocusNode _focusNode = FocusNode();

  bool get _isDisabled => widget.onExpansionChanged == null;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    if (widget.expanded) {
      _controller.expand();
    }
  }

  @override
  void didUpdateWidget(LayrzAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.expand();
      } else {
        _controller.collapse();
      }
    }
    if (_isDisabled) {
      _states.remove(WidgetState.hovered);
      _states.remove(WidgetState.pressed);
      _states.remove(WidgetState.focused);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setState(WidgetState state, bool value) {
    if (value ? _states.contains(state) : !_states.contains(state)) return;
    setState(() {
      if (value) {
        _states.add(state);
      } else {
        _states.remove(state);
      }
    });
  }

  void _toggle() {
    if (_isDisabled) return;
    widget.onExpansionChanged!(!widget.expanded);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (_isDisabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    final spec = LayrzAccordionStyleSpec.resolve(states: _states, tokens: tokens);

    return ClipRRect(
      borderRadius: tokens.radius.br2,
      child: Expansible(
        controller: _controller,
        maintainState: false,
        animationStyle: AnimationStyle(
          duration: tokens.motion.dTransition,
          curve: tokens.motion.easingEmphasized,
        ),
        headerBuilder: (context, animation) => _buildHeader(context, tokens, spec, animation),
        bodyBuilder: (context, animation) => _buildBody(spec, tokens),
      ),
    );
  }

  /// Wraps [LayrzAccordion.body] in a surface that shares [spec]'s header
  /// background color.
  ///
  /// Without this, the body paints on whatever is behind the accordion --
  /// transparent by default -- so an expanded panel reads as a filled header
  /// floating above a detached body. Filling the body with the same color as
  /// the header makes the two read as one continuous panel surface with no
  /// seam, which is only ever visible while expanded since the collapsed body
  /// is absent from the tree (`maintainState: false`).
  Widget _buildBody(LayrzAccordionStyleSpec spec, LayrzTokens tokens) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.headerBackgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(tokens.radius.r2),
          bottomRight: Radius.circular(tokens.radius.r2),
        ),
        border: Border(
          left: BorderSide(color: spec.borderColor, width: spec.borderWidth),
          right: BorderSide(color: spec.borderColor, width: spec.borderWidth),
          bottom: BorderSide(color: spec.borderColor, width: spec.borderWidth),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: widget.body,
      ),
    );
  }

  /// Builds the header row: leading icon (optional), title, and a chevron
  /// that rotates in step with [animation].
  ///
  /// The whole row shares a single [GestureDetector] and [Focus] node, so
  /// tapping or activating anywhere on the row -- not just the chevron --
  /// toggles the panel. Structure mirrors `LayrzCheckboxInput`'s header/label
  /// pattern: [GestureDetector] > [Focus] > [MouseRegion] > [Semantics], with
  /// the innermost [Semantics] carrying the merged toggle/label/expanded
  /// contract and the title [Text] excluded from semantics beneath it so its
  /// string is not announced twice.
  Widget _buildHeader(
    BuildContext context,
    LayrzTokens tokens,
    LayrzAccordionStyleSpec spec,
    Animation<double> animation,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isDisabled ? null : _toggle,
      onTapDown: _isDisabled ? null : (_) => _setState(WidgetState.pressed, true),
      onTapUp: _isDisabled ? null : (_) => _setState(WidgetState.pressed, false),
      onTapCancel: _isDisabled ? null : () => _setState(WidgetState.pressed, false),
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: !_isDisabled,
        skipTraversal: _isDisabled,
        onFocusChange: (hasFocus) => _setState(WidgetState.focused, hasFocus),
        onKeyEvent: (node, event) {
          if (_isDisabled) return KeyEventResult.ignored;
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter)) {
            _toggle();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: _isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => _setState(WidgetState.hovered, true),
          onExit: (_) => _setState(WidgetState.hovered, false),
          child: Semantics(
            button: true,
            label: widget.titleText,
            enabled: !_isDisabled,
            expanded: widget.expanded,
            onTap: _isDisabled ? null : _toggle,
            child: AnimatedContainer(
              duration: tokens.motion.dHover,
              curve: tokens.motion.easing,
              padding: tokens.spacing.pd3,
              decoration: BoxDecoration(
                color: spec.headerBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(tokens.radius.r2),
                  topRight: Radius.circular(tokens.radius.r2),
                  bottomLeft: widget.expanded ? Radius.zero : Radius.circular(tokens.radius.r2),
                  bottomRight: widget.expanded ? Radius.zero : Radius.circular(tokens.radius.r2),
                ),
                border: Border(
                  top: BorderSide(color: spec.borderColor, width: spec.borderWidth),
                  left: BorderSide(color: spec.borderColor, width: spec.borderWidth),
                  right: BorderSide(color: spec.borderColor, width: spec.borderWidth),
                  bottom: widget.expanded
                      ? BorderSide.none
                      : BorderSide(
                          color: spec.borderColor,
                          width: spec.borderWidth,
                        ),
                ),
              ),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(widget.leadingIcon, color: spec.headerContentColor, size: 20),
                    SizedBox(width: tokens.spacing.sp2),
                  ],
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        widget.titleText,
                        style: tokens.typography.body.copyWith(color: spec.headerContentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.sp2),
                  RotationTransition(
                    turns: animation.drive(Tween<double>(begin: 0.0, end: 0.5)),
                    child: Icon(MdiIcons.chevronDown, color: spec.headerContentColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
