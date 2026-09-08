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
/// It is hand-rolled directly on top of [AnimationController] and
/// [CurvedAnimation] (`package:flutter/widgets.dart`); it does not use the SDK
/// [Expansible] primitive. That primitive's own height-interpolation and
/// state machine previously produced a janky body reveal, an inconsistent
/// border/seam between header and body, and a shadow that did not track the
/// reveal cleanly -- driving every one of those concerns off a single
/// controller and a single [CurvedAnimation] owned by this widget removes the
/// layer of indirection that caused them.
///
/// **This is a single panel, not a group.** Group behaviour -- multiple
/// accordions coordinating so only one stays open, nesting one accordion
/// inside another's body, or a free-form header slot replacing the fixed
/// leading-icon/title/chevron layout -- is explicit v1 non-goal. A caller who
/// needs several of these to behave like a group composes that coordination
/// themselves, driving each instance's [expanded] from shared state.
///
/// **Controlled, not stateful.** [LayrzAccordion] holds no expansion state of
/// its own beyond the animation position. [expanded] is the single source of
/// truth, and [onExpansionChanged] is the only way the widget asks its caller
/// to change it -- mirroring every other controlled input in this design
/// system. There is no internal toggle that can drift from what the caller
/// believes is showing.
///
/// **Whole-header hit target.** The entire header row -- leading icon, title,
/// and chevron alike -- is a single tap and keyboard target. This is a hard
/// requirement, not a convenience: a chevron-only hit target is the most
/// common real-world complaint about disclosure widgets, since users expect
/// to be able to tap or click anywhere on a visually cohesive row.
///
/// **Collapsed body is genuinely absent from the tree.** The body subtree is
/// only built while the reveal [AnimationController] is above `0.0`, or
/// mid-flight toward it. Once the collapse animation settles back to `0.0`,
/// the body is not merely hidden (as an [Offstage] or zero-height box would
/// do) -- it is not built at all. A screen reader walking the tree while
/// collapsed never encounters the body's content.
///
/// **Motion.** The reveal animation always drives a single
/// [CurvedAnimation] built from [LayrzMotionTokens.easingEmphasized]
/// (`Curves.easeInOutCirc` by default) over [LayrzMotionTokens.dTransition]
/// -- never a hardcoded curve or duration -- this is the token disclosure
/// components use for a height change large enough that the standard
/// [LayrzMotionTokens.easing] reads as too subtle.
///
/// **One continuous border around the whole panel.** The header and body do
/// not each paint their own border. A single outer shell -- built by
/// `_buildPanelShell` -- wraps both in one [DecoratedBox]/[ClipRRect] pair, so
/// the border traces one continuous rounded rectangle around header and body
/// in every frame, including mid-animation. All four corners stay uniformly
/// rounded to [LayrzTokens.radius.r2] in every expansion state -- collapsed,
/// expanded, and everywhere in between -- so the panel always reads as one
/// consistently rounded card and never squares off at the bottom once open.
/// A single hairline divider is drawn between header and body, sized to zero
/// height while collapsed; that divider height (not the corner radius) is
/// driven by the same reveal animation. It is deliberately *not* part of the
/// header's own [AnimatedContainer], which instead animates only
/// hover/press/focus color changes on the snappier
/// [LayrzMotionTokens.dHover]. Coupling both concerns to one
/// [AnimatedContainer] duration previously forced a choice between a
/// sluggish hover and geometry that snapped to its expanded state before the
/// body finished revealing -- visible as a "blink" on both expand and
/// collapse. Driving the divider from the reveal's own animation keeps the
/// two perfectly in lockstep instead.
///
/// **Body reveal.** The body is wrapped in a [ClipRect] +
/// `Align(alignment: Alignment.topCenter, heightFactor: progress)`, keyed to
/// the same [CurvedAnimation] driving the divider and shadow below, so the
/// body's visible height grows from the top edge in lockstep with everything
/// else -- no separately-timed geometry to "blink" against.
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

/// A private wrapper around [LayrzAccordion.body], used only so tests (and,
/// incidentally, the widget inspector) can identify the actual body subtree
/// independently of the surface [DecoratedBox] and reveal machinery around
/// it.
///
/// Deliberately kept in this file rather than exported: it carries no public
/// contract of its own, it exists purely as a stable marker in the render
/// tree.
class _BodyMarker extends StatelessWidget {
  /// The accordion body content this marker wraps.
  final Widget child;

  /// Creates a new [_BodyMarker] wrapping [child].
  const _BodyMarker({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _LayrzAccordionState extends State<LayrzAccordion> with SingleTickerProviderStateMixin {
  /// Drives the expand/collapse reveal: `0.0` fully collapsed, `1.0` fully
  /// expanded.
  ///
  /// Owned entirely by this widget -- [LayrzAccordion] itself holds no
  /// expansion state, [expanded] is the source of truth, and this controller
  /// is just the concrete animation object that tracks progress toward it.
  /// Seeded to the correct starting value in [initState] so the first frame
  /// never animates from the wrong end.
  late final AnimationController _controller;

  /// The eased view of [_controller], built once dependencies (and therefore
  /// [LayrzTokens]) are available. Every visual that keys off expansion
  /// progress -- shadow fade, divider height, chevron rotation, body reveal --
  /// reads this, not [_controller] directly, so they all move on exactly the
  /// same eased timeline.
  late CurvedAnimation _curved;

  /// Whether [_curved] has been constructed yet.
  ///
  /// [didChangeDependencies] runs before the first [build], but also again on
  /// later dependency changes (e.g. an ancestor [LayrzTheme] rebuilding with
  /// new tokens) -- this flag distinguishes "first-time construction" from
  /// "tokens changed, refresh the curve and duration" so the former only ever
  /// happens once.
  bool _curvedInitialized = false;

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
    _controller = AnimationController(
      vsync: this,
      // Tokens need a BuildContext, which is not yet available here; the
      // real duration is set from LayrzTokens in didChangeDependencies below,
      // before this controller ever animates.
      duration: const Duration(milliseconds: 200),
      value: widget.expanded ? 1.0 : 0.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.tokens.motion;
    _controller.duration = motion.dTransition;
    if (!_curvedInitialized) {
      _curved = CurvedAnimation(parent: _controller, curve: motion.easingEmphasized);
      _curvedInitialized = true;
    }
  }

  @override
  void didUpdateWidget(LayrzAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    _curved.dispose();
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
    final header = _buildHeader(context, tokens, spec);

    return _buildPanelShell(tokens, spec, header);
  }

  /// Wraps the whole panel -- [header] and the reveal-driven body together --
  /// in a single outer border and rounded-rectangle clip, plus the internal
  /// divider line drawn between them while expanded.
  ///
  /// Owning the outer border in exactly one place -- here -- guarantees one
  /// continuous outline in every frame, collapsed or expanded or
  /// mid-animation, rather than the header and body each painting an
  /// independent border that could drift apart at the seam.
  ///
  /// The corner radius is a constant [LayrzTokens.radius.r2] on all four
  /// corners, in every expansion state -- collapsed, expanded, and every
  /// frame in between. The panel is meant to read as one consistently
  /// rounded card whether closed or open; it must never square off at the
  /// bottom once expanded. Expansion progress never drives any part of the
  /// corner geometry -- only the shadow fade (below), the internal divider's
  /// height, and the body reveal are still keyed to it.
  ///
  /// [_curved] is the single eased [Animation] this whole method (and the
  /// header's chevron, and the body reveal) reads from, so the divider,
  /// shadow, and body height all interpolate in lockstep on one timeline --
  /// never separately-timed geometry that could visibly "blink" apart on
  /// expand or collapse.
  ///
  /// The seam between header and body is a single hairline [Container] whose
  /// *height* (not merely its opacity) animates from `0` to [spec.borderWidth]
  /// with the same progress: while collapsed the body is absent from the tree
  /// and the divider must also occupy zero space, or a stray line would
  /// render with nothing below it.
  ///
  /// **Elevation on open.** An outer [DecoratedBox] -- carrying only
  /// [BoxDecoration.boxShadow] and the same constant [borderRadius], no
  /// border and no fill -- wraps the [ClipRRect]/border/[Column] stack
  /// instead of sitting inside it. This is load-bearing, not stylistic:
  /// [ClipRRect] clips its subtree to its rounded rect, so a shadow painted
  /// on the inner, clipped [DecoratedBox] is clipped away and never reaches
  /// the screen. Placing the shadow on a node that wraps the clip, rather
  /// than one the clip contains, is the only way for it to render at all.
  /// The border itself stays on the inner [DecoratedBox] exactly as before,
  /// so it keeps painting *over* the clipped fill and remains visible
  /// sitting on top of the shadow in both states.
  ///
  /// The shadow fades in and out on the same progress driving the divider
  /// above -- never a second timeline. [spec.shadow] is the constant,
  /// full-elevation [LayrzTokens.shadow.elevation2] list; [_fadeShadow]
  /// scales each [BoxShadow]'s alpha by progress so it is fully absent at 0
  /// (collapsed, flat, border-only) and at full strength at 1 (expanded,
  /// reads as a raised card), interpolating continuously in between. The
  /// corner radius itself never participates in this fade -- it is constant
  /// regardless of progress.
  Widget _buildPanelShell(
    LayrzTokens tokens,
    LayrzAccordionStyleSpec spec,
    Widget header,
  ) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final progress = _curved.value;
        final borderRadius = BorderRadius.circular(tokens.radius.r2);
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
                  _buildBodyReveal(spec, progress),
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
  /// value driving the outer shell's divider and body reveal, so the shadow
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

  /// Builds the reveal-driven body slot -- present in the tree and clipped to
  /// [progress] of its natural height while `progress > 0`, and genuinely
  /// absent (a zero-size [SizedBox.shrink]) once the controller has settled
  /// fully at `0.0`.
  ///
  /// The absence check is on [AnimationController.isDismissed] rather than a
  /// bare `progress == 0` comparison: `isDismissed` is `true` only once the
  /// controller is both at `0.0` *and* not mid-forward (i.e. it is not merely
  /// passing through `0.0` while animating), which is exactly the "fully
  /// collapsed and settled" condition the body's absence must track --
  /// matching the class docs' "collapsed body is genuinely absent" contract
  /// and the `_BodyMarker findsNothing` test assertion.
  ///
  /// While present, the body is wrapped in a [ClipRect] +
  /// `Align(heightFactor: progress)` anchored to the top, so its visible
  /// height grows from `0` to its natural height as [progress] goes from `0`
  /// to `1` -- a smooth, top-anchored reveal keyed to the very same
  /// [CurvedAnimation] driving the divider and shadow, rather than a
  /// separately-timed geometry change. [ExcludeSemantics] wraps the interior
  /// while the controller is at rest and collapsed is impossible here (the
  /// branch that would render collapsed content already builds
  /// [SizedBox.shrink] instead), so no extra semantics gating is needed on
  /// this branch beyond what [_BodyMarker] itself carries.
  Widget _buildBodyReveal(LayrzAccordionStyleSpec spec, double progress) {
    if (_controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: progress.clamp(0.0, 1.0),
        child: _BodyMarker(
          child: DecoratedBox(
            decoration: BoxDecoration(color: spec.headerBackgroundColor),
            child: SizedBox(
              width: double.infinity,
              child: widget.body,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header row: leading icon (optional), title, and a chevron
  /// that rotates in step with [_curved].
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
  /// border and corner radius are owned entirely by [_buildPanelShell], which
  /// encloses header and body in one continuous outline.
  Widget _buildHeader(
    BuildContext context,
    LayrzTokens tokens,
    LayrzAccordionStyleSpec spec,
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
                    turns: _curved.drive(Tween<double>(begin: 0.0, end: 0.5)),
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
