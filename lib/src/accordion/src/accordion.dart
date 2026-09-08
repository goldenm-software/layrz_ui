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
/// **One continuous border around the whole panel.** The header and body do
/// not each paint their own border. A single outer shell -- built by
/// `_buildPanelShell` from [Expansible.expansibleBuilder], which receives the
/// built header, the built body, and the raw reveal [Animation] together --
/// wraps both in one [DecoratedBox]/[ClipRRect] pair, so the border traces one
/// continuous rounded rectangle around header and body in every frame,
/// including mid-animation. Its bottom corners collapse to [Radius.zero] as
/// the body attaches (fully rounded when collapsed, matching a standalone
/// header; square-bottomed once expanded, reading as one block with the
/// body), and a single hairline divider is drawn between header and body,
/// sized to zero height while collapsed. This geometry is driven by that same
/// [LayrzMotionTokens.dTransition] / [LayrzMotionTokens.easingEmphasized]
/// timeline, via the `animation` value [Expansible.expansibleBuilder]
/// supplies -- the very same object [Expansible.headerBuilder] and
/// [Expansible.bodyBuilder] receive. It is deliberately *not* part of the
/// header's own [AnimatedContainer], which instead animates only
/// hover/press/focus color changes on the snappier [LayrzMotionTokens.dHover].
/// Coupling both concerns to one [AnimatedContainer] duration previously
/// forced a choice between a sluggish hover and geometry that snapped to its
/// expanded state before the body finished revealing -- visible as a "blink"
/// on both expand and collapse. Driving geometry from the reveal's own
/// animation keeps the two perfectly in lockstep instead.
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

    return Expansible(
      controller: _controller,
      maintainState: false,
      animationStyle: AnimationStyle(
        duration: tokens.motion.dTransition,
        curve: tokens.motion.easingEmphasized,
      ),
      headerBuilder: (context, animation) => _buildHeader(context, tokens, spec, animation),
      bodyBuilder: (context, animation) => _buildBody(spec, tokens),
      expansibleBuilder: (context, header, body, animation) => _buildPanelShell(tokens, spec, animation, header, body),
    );
  }

  /// Wraps the whole panel -- [header] and [body] together -- in a single
  /// outer border and rounded-rectangle clip, plus the internal divider line
  /// drawn between them while expanded.
  ///
  /// This is the fix for the "border does not propagate to the body" defect:
  /// previously the header and body each painted their own independent
  /// border via two separate [DecoratedBox]/[ClipRRect] pairs, so at full
  /// expansion (header bottom border faded to [BorderSide.none], body with no
  /// top border) there was no single render node whose edges traced a
  /// continuous rectangle around both -- the body read as a detached, inset
  /// box. Owning the outer border in exactly one place -- here -- guarantees
  /// one continuous outline in every frame, collapsed or expanded or
  /// mid-animation.
  ///
  /// The bottom corners interpolate from [LayrzTokens.radius.r2] (fully
  /// rounded, matching a standalone collapsed header) down to [Radius.zero]
  /// (square, so the panel reads as one rounded-top block while the body is
  /// visible) using the same [progress] the header's own geometry and the
  /// body reveal are driven by -- see [animation] below. The top corners stay
  /// fixed at [LayrzTokens.radius.r2] regardless of expansion state.
  ///
  /// [animation] is [Expansible]'s raw, linear controller -- the same object
  /// passed to [Expansible.headerBuilder] and [Expansible.bodyBuilder] -- so
  /// this shell's corner radius interpolates in lockstep with the body's own
  /// height-factor reveal, not on a separately-timed animation. See the
  /// [LayrzAccordion] class docs for the "blink" bug that separate timelines
  /// previously caused.
  ///
  /// The seam between header and body is a single hairline [Container] whose
  /// *height* (not merely its opacity) animates from `0` to [spec.borderWidth]
  /// with the same progress: while collapsed the body is absent from the tree
  /// (`maintainState: false`) and the divider must also occupy zero space, or
  /// a stray line would render with nothing below it.
  ///
  /// **Elevation on open (DESIGN-92 follow-up).** An outer [DecoratedBox] --
  /// carrying only [BoxDecoration.boxShadow] and the same animated
  /// [borderRadius], no border and no fill -- wraps the existing
  /// [ClipRRect]/border/[Column] stack instead of sitting inside it. This is
  /// load-bearing, not stylistic: [ClipRRect] clips its subtree to its rounded
  /// rect, so a shadow painted on the inner, clipped [DecoratedBox] is clipped
  /// away and never reaches the screen. Placing the shadow on a node that
  /// wraps the clip, rather than one the clip contains, is the only way for it
  /// to render at all. The border itself stays on the inner [DecoratedBox]
  /// exactly as before, so it keeps painting *over* the clipped fill and
  /// remains visible sitting on top of the shadow in both states.
  ///
  /// The shadow fades in and out on the same [progress] driving the corner
  /// radius and divider above -- never a second timeline, for the same
  /// "blink" reason documented on the class. [spec.shadow] is the constant,
  /// full-elevation [LayrzTokens.shadow.elevation2] list; [_fadeShadow] scales
  /// each [BoxShadow]'s alpha by [progress] so it is fully absent at 0
  /// (collapsed, flat) and at full strength at 1 (expanded, reads as a raised
  /// card), interpolating continuously in between.
  Widget _buildPanelShell(
    LayrzTokens tokens,
    LayrzAccordionStyleSpec spec,
    Animation<double> animation,
    Widget header,
    Widget body,
  ) {
    final expandProgress = CurvedAnimation(parent: animation, curve: tokens.motion.easingEmphasized);
    return AnimatedBuilder(
      animation: expandProgress,
      builder: (context, child) {
        final progress = expandProgress.value;
        final bottomRadius = Radius.circular(tokens.radius.r2 * (1 - progress));
        final borderRadius = BorderRadius.only(
          topLeft: Radius.circular(tokens.radius.r2),
          topRight: Radius.circular(tokens.radius.r2),
          bottomLeft: bottomRadius,
          bottomRight: bottomRadius,
        );
        final dividerHeight = spec.borderWidth * progress;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: _fadeShadow(spec.shadow, progress),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: spec.borderColor, width: spec.borderWidth),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  if (dividerHeight > 0) Container(height: dividerHeight, color: spec.borderColor),
                  body,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Scales the alpha of every [BoxShadow] in [shadow] by [progress].
  ///
  /// [shadow] is the panel's constant, full-elevation shadow list --
  /// [LayrzAccordionStyleSpec.shadow], resolved from
  /// [LayrzTokens.shadow.elevation2]. [progress] is the same 0-to-1 expansion
  /// value driving the outer shell's corner radius and divider, so the shadow
  /// fades in lockstep with the reveal instead of snapping in once fully
  /// expanded. At `progress == 0` every returned [BoxShadow] has alpha `0`
  /// (invisible, so the collapsed panel reads as flat); at `progress == 1` the
  /// original, unmodified alphas are returned (full [LayrzTokens.shadow.elevation2]
  /// strength).
  List<BoxShadow> _fadeShadow(List<BoxShadow> shadow, double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    return [
      for (final boxShadow in shadow)
        boxShadow.copyWith(color: boxShadow.color.withValues(alpha: boxShadow.color.a * clamped)),
    ];
  }

  /// Wraps [LayrzAccordion.body] in a surface that shares [spec]'s header
  /// background color.
  ///
  /// Without this, the body paints on whatever is behind the accordion --
  /// transparent by default -- so an expanded panel reads as a filled header
  /// floating above a detached body. Filling the body with the same color as
  /// the header makes the two read as one continuous panel surface with no
  /// seam. The body itself no longer draws any border or corner radius of its
  /// own -- see [_buildPanelShell], which owns the single outer border and
  /// clip that encloses header and body together.
  Widget _buildBody(LayrzAccordionStyleSpec spec, LayrzTokens tokens) {
    return DecoratedBox(
      decoration: BoxDecoration(color: spec.headerBackgroundColor),
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
  ///
  /// The header paints only its background color and content here -- the
  /// border and corner radius that used to be drawn around the header alone
  /// are now owned entirely by [_buildPanelShell], which encloses header and
  /// body in one continuous outline. See the [LayrzAccordion] class docs and
  /// [_buildPanelShell] for why a single outer shell replaced the header's own
  /// independently-clipped border.
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
              color: spec.headerBackgroundColor,
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
