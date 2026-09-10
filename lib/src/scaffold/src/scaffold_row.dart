import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'scaffold_item.dart';

/// The velocity threshold, in logical pixels per second, above which a horizontal
/// drag release is treated as a deliberate swipe rather than an incidental drag.
///
/// Mirrors the swipe-dismiss threshold used elsewhere in the design system
/// (`LayrzSnackbarMessenger`), keeping swipe-to-reveal gestures consistent in feel.
const double _kSwipeVelocityThreshold = 200;

/// The minimum horizontal reveal distance, in logical pixels, used as a fallback
/// when [LayrzScaffoldItem.actions] contains a non-Fab action.
///
/// Row actions are a Fab-only (square, icon-only) design — [_revealExtentFor]
/// computes the exact reveal distance from `kLayrzButtonHeight` for that
/// contract. A non-Fab [LayrzButton] has a content-dependent width that cannot
/// be known without laying it out, so rather than clip it (the pre-fix bug this
/// change addresses) or add a full measurement pass for a caller shape the
/// design doesn't support, the reveal falls back to this constant — the same
/// distance the row used unconditionally before this fix. It is a safety net,
/// not a supported sizing path.
const double _kFallbackRevealExtent = 96;

/// A single row in [ListPanel]'s list, rendering [LayrzScaffoldItem.tile] and, when
/// [LayrzScaffoldItem.actions] is non-empty, a trailing-edge action reveal.
///
/// The row body stays tappable to open the detail pane at all times — including while
/// the actions are revealed.
///
/// **Desktop** (`context.isCompact == false`): the actions reveal on hover as an
/// OVERLAY painted on top of the row body — the row body never translates, resizes,
/// or otherwise moves (decision D15: hover may only vary colour/opacity/shadow/
/// cursor). The overlay fades in/out purely via opacity, backed by a semi-transparent
/// scrim so the row's own content stays partially visible behind the action buttons.
///
/// **Mobile** (`context.isCompact == true`): the actions reveal after a leftward
/// horizontal drag (tracked live, and snapped to fully revealed or fully hidden on
/// release based on distance and velocity) and hide on a swipe back to the right, or
/// on a tap of the row body while revealed. This is a drag gesture, not a hover
/// interaction state, so it keeps translating the row body over the actions strip
/// exactly as before — decision D15 governs interaction *states* (hover/press/focus/
/// disabled), not a user-driven swipe gesture.
///
/// When [LayrzScaffoldItem.actions] is empty, or when the row is the currently
/// [ScaffoldRow.isSelected] item, this widget renders identically to a plain
/// [LayrzTappable]-wrapped tile with no additional overlay, gesture wiring, or
/// state — a strict no-regression path for existing callers. A selected row never
/// reveals its actions: they are already present in the detail pane open for that
/// same item, so exposing them again on the list row would be redundant.
class ScaffoldRow<T> extends StatefulWidget {
  /// The item this row represents.
  final LayrzScaffoldItem<T> item;

  /// Whether this row is the currently opened/selected item.
  final bool isSelected;

  /// Whether this row sits at an even position within the on-screen (filtered)
  /// list, used to alternate the idle background between `tokens.colors.sf1`
  /// (even) and `tokens.colors.sf2` (odd) — the same zebra-striping convention
  /// `LayrzTable` uses (see `table_row.dart`'s `rowIndex.isEven` check).
  ///
  /// Ignored when [isSelected] is true: a selected row always paints `sf4`
  /// regardless of parity.
  final bool isEvenRow;

  /// Called when the row body is tapped, to open the detail pane for [item].
  ///
  /// `null` when the list panel has no tap handler configured, in which case the
  /// row is rendered disabled/inert exactly as [LayrzTappable] would.
  final VoidCallback? onTap;

  /// Creates a new [ScaffoldRow].
  ///
  /// - [item]: The item this row represents. Required.
  /// - [isSelected]: Whether this row is the currently opened/selected item. Required.
  /// - [isEvenRow]: Whether this row sits at an even position in the on-screen list,
  ///   used for zebra striping. Defaults to true (matching the previous single-tone
  ///   `sf1` idle color for a row built without this parameter).
  /// - [onTap]: Called when the row body is tapped. Defaults to null (inert row).
  const ScaffoldRow({
    super.key,
    required this.item,
    required this.isSelected,
    this.isEvenRow = true,
    this.onTap,
  });

  @override
  State<ScaffoldRow<T>> createState() => _ScaffoldRowState<T>();
}

class _ScaffoldRowState<T> extends State<ScaffoldRow<T>> {
  /// Whether the pointer is currently hovering this row (desktop reveal trigger).
  bool _isHovered = false;

  /// Whether the trailing actions are currently revealed at rest (mobile swipe state).
  bool _isRevealed = false;

  /// The live horizontal drag offset while a swipe gesture is in progress, in
  /// logical pixels. Always `<= 0` — the row body only ever slides toward the
  /// leading edge to expose the trailing actions.
  double _dragExtent = 0;

  /// Whether a horizontal drag gesture is currently in progress.
  bool _isDragging = false;

  /// The horizontal distance, in logical pixels, that the row body translates to
  /// fully reveal the trailing actions strip.
  ///
  /// Recomputed in [build] via [_revealExtentFor] and cached here so the drag
  /// gesture handlers — which run outside the widget tree's build phase, in
  /// response to raw pointer callbacks — clamp and snap against the exact same
  /// value the current frame was laid out with, rather than a stale one from a
  /// previous build or a re-derived one that could disagree with it.
  double _revealExtent = _kFallbackRevealExtent;

  @override
  void didUpdateWidget(covariant ScaffoldRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.key != widget.item.key) {
      // A different item was recycled into this row's slot (e.g. after filtering) —
      // reset transient interaction state rather than carrying over a stale reveal.
      _isHovered = false;
      _isRevealed = false;
      _isDragging = false;
      _dragExtent = 0;
    } else if (!oldWidget.isSelected && widget.isSelected) {
      // The row just became selected, which takes the plain no-reveal path
      // regardless of these fields — but reset them anyway so a subsequent
      // deselection doesn't resume mid-reveal from stale state.
      _isHovered = false;
      _isRevealed = false;
      _isDragging = false;
      _dragExtent = 0;
    }
  }

  /// Computes the horizontal distance the row body must translate to fully
  /// reveal [LayrzScaffoldItem.actions], from the strip's actual content.
  ///
  /// Row actions are Fab (square, icon-only) [LayrzButton]s by design, so each
  /// action's width is exactly `kLayrzButtonHeight`, separated by `sp1` gaps
  /// (the actions [Row]'s own `spacing`), inside `sp2` horizontal padding on
  /// each side of the strip (see `actionsStrip` in [build]):
  /// `n * kLayrzButtonHeight + (n - 1) * sp1 + 2 * sp2`.
  ///
  /// If any action is not a Fab button, its true width is content-dependent and
  /// cannot be derived without laying it out, so this falls back to
  /// [_kFallbackRevealExtent] instead — see that constant's doc for why a full
  /// measurement pass is not worth adding for a caller shape outside the
  /// supported row-action contract.
  ///
  /// - [tokens]: The active [LayrzTokens], supplying the `sp1`/`sp2` spacing
  ///   used by the actions strip's own layout. Required.
  double _revealExtentFor(LayrzTokens tokens) {
    final actions = widget.item.actions;
    final n = actions.length;
    if (n == 0) return 0;
    if (actions.any((action) => !action.style.isFab)) {
      return _kFallbackRevealExtent;
    }
    final actionsWidth = n * kLayrzButtonHeight + (n - 1) * tokens.spacing.sp1;
    return actionsWidth + 2 * tokens.spacing.sp2;
  }

  /// Handles the start of a horizontal drag gesture, seeding the live drag extent
  /// from the current rest position so the translation continues smoothly.
  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragExtent = _isRevealed ? -_revealExtent : 0;
    });
  }

  /// Handles horizontal drag updates, translating the row body toward the trailing
  /// edge as the user drags left, and back toward rest as they drag right.
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx).clamp(-_revealExtent, 0.0);
    });
  }

  /// Handles the end of a horizontal drag gesture, snapping to fully revealed or
  /// fully hidden based on the release velocity, falling back to the final drag
  /// distance when the release is too slow to read as a deliberate swipe.
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    final bool reveal;
    if (velocity < -_kSwipeVelocityThreshold) {
      reveal = true;
    } else if (velocity > _kSwipeVelocityThreshold) {
      reveal = false;
    } else {
      reveal = _dragExtent.abs() > (_revealExtent / 2);
    }

    setState(() {
      _isDragging = false;
      _isRevealed = reveal;
      _dragExtent = 0;
    });
  }

  /// Handles a tap on the row body.
  ///
  /// While actions are revealed on a compact viewport, the first tap only hides
  /// the reveal (matching the common "swipe list" convention of not accidentally
  /// opening a row you swiped to inspect); a subsequent tap opens it normally.
  void _onRowTap(bool isCompact) {
    if (isCompact && _isRevealed) {
      setState(() => _isRevealed = false);
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final item = widget.item;

    if (item.actions.isEmpty || widget.isSelected) {
      return _buildTappable(tokens: tokens, onTap: widget.onTap);
    }

    // Cached rather than recomputed inline so the drag gesture handlers — which
    // run outside build, in response to raw pointer callbacks — clamp and snap
    // against the same value this frame was laid out with.
    _revealExtent = _revealExtentFor(tokens);

    final isCompact = context.isCompact;
    final rowBody = _buildTappable(tokens: tokens, onTap: () => _onRowTap(isCompact));

    if (!isCompact) {
      return _buildDesktopOverlay(tokens: tokens, item: item, rowBody: rowBody);
    }

    return _buildMobileSwipe(tokens: tokens, item: item, rowBody: rowBody);
  }

  /// Builds the desktop presentation: the row body is laid out once, never
  /// translated or resized, and the actions strip is a same-place [Stack] layer
  /// painted ON TOP of it, faded in/out purely via opacity on hover
  /// (decision D15 — hover may vary colour/opacity/shadow/cursor only).
  ///
  /// A gradient scrim sits directly behind the action buttons so the row's own
  /// content stays partially visible through the overlay rather than being
  /// fully hidden by it.
  ///
  /// - [tokens]: The active [LayrzTokens]. Required.
  /// - [item]: The item whose [LayrzScaffoldItem.actions] populate the overlay. Required.
  /// - [rowBody]: The already-built, never-translated row body. Required.
  Widget _buildDesktopOverlay({
    required LayrzTokens tokens,
    required LayrzScaffoldItem<T> item,
    required Widget rowBody,
  }) {
    final overlay = Positioned.fill(
      child: IgnorePointer(
        // The overlay must not eat hover/pointer events while invisible, and while
        // visible its own children (the action buttons) still resolve their own
        // hit testing — the row body beneath it remains tappable at every opacity.
        ignoring: !_isHovered,
        child: AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.0,
          duration: tokens.motion.dHover,
          curve: tokens.motion.easing,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A right-aligned scrim behind the action buttons — a gradient from
              // transparent to a translucent tint of the row's own idle surface
              // color — so the row's text/content is still legible behind the
              // buttons rather than fully occluded ("with a transparency to still
              // see the content behind" per the reviewer's request).
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _rowIdleColor(tokens).withValues(alpha: 0),
                          _rowIdleColor(tokens).withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  // `ListPanel` already reserves `kLayrzScrollbarThickness` of trailing
                  // gutter for the ListView's own scrollbar (see the padding around
                  // ListView.builder in list_panel.dart), so this row never shares pixels
                  // with the scrollbar to begin with. This sp2 is purely the row's own
                  // breathing room from its rounded edge, symmetric on both sides.
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: tokens.spacing.sp1,
                    children: item.actions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ClipRRect(
        // Matches the row body's own LayrzTappable(borderRadius: tokens.radius.br2)
        // corners exactly, so the overlay never paints past the row's rounded surface.
        borderRadius: tokens.radius.br2,
        child: Stack(
          // The row body paints first (underneath, stationary at all times, and it
          // is the Stack's only non-positioned child so it alone determines the
          // Stack's size); the actions overlay is Positioned.fill on top of it,
          // visible only via opacity.
          children: [rowBody, overlay],
        ),
      ),
    );
  }

  /// Builds the mobile presentation: unchanged swipe-to-translate behavior. The
  /// row body slides left over an actions strip painted beneath it, driven by
  /// [_onHorizontalDragStart]/[_onHorizontalDragUpdate]/[_onHorizontalDragEnd].
  ///
  /// - [tokens]: The active [LayrzTokens]. Required.
  /// - [item]: The item whose [LayrzScaffoldItem.actions] populate the strip. Required.
  /// - [rowBody]: The row body to translate. Required.
  Widget _buildMobileSwipe({
    required LayrzTokens tokens,
    required LayrzScaffoldItem<T> item,
    required Widget rowBody,
  }) {
    final revealPixels = _isDragging ? -_dragExtent : (_isRevealed ? _revealExtent : 0.0);

    final actionsStrip = Positioned.fill(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spacing.sp1,
            children: item.actions,
          ),
        ),
      ),
    );

    final translatedBody = AnimatedContainer(
      duration: _isDragging ? Duration.zero : tokens.motion.dHover,
      curve: tokens.motion.easing,
      transform: Matrix4.translationValues(-revealPixels, 0, 0),
      child: rowBody,
    );

    final stack = ClipRRect(
      // Matches the row body's own LayrzTappable(borderRadius: tokens.radius.br2)
      // corners exactly, so the actions strip beneath never paints past the row's
      // rounded surface the way the previous rectangular ClipRect allowed.
      borderRadius: tokens.radius.br2,
      child: Stack(
        // The actions strip paints first (underneath), the translating body paints
        // on top of it so it fully covers the strip at rest (revealPixels == 0).
        children: [actionsStrip, translatedBody],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: stack,
    );
  }

  /// The row's own idle surface color — the same value [_buildTappable] passes
  /// as `LayrzTappable.color` — used to tint the desktop overlay's scrim so it
  /// reads as a translucent veil over this exact row rather than an arbitrary color.
  Color _rowIdleColor(LayrzTokens tokens) {
    if (widget.isSelected) return tokens.colors.sf4;
    return widget.isEvenRow ? tokens.colors.sf1 : tokens.colors.sf2;
  }

  /// Builds the shared tappable shell (selection tint, border radius, disabled-when-
  /// selected behaviour, and the item content) common to both the plain and
  /// action-reveal row paths.
  Widget _buildTappable({
    required LayrzTokens tokens,
    required VoidCallback? onTap,
  }) {
    return LayrzTappable(
      disabled: widget.isSelected,
      onTap: onTap,
      borderRadius: tokens.radius.br2,
      // Precedence: selected (sf4) wins outright; otherwise the idle color
      // alternates sf1/sf2 by row parity (matching LayrzTable's zebra striping —
      // see table_row.dart's `rowIndex.isEven` check) and LayrzTappable itself
      // still overrides this with sf3 on hover / sf4 on press.
      color: _rowIdleColor(tokens),
      child: _buildRowContent(tokens),
    );
  }

  /// Builds the row's own content: the item tile plus the selection indicator bar.
  Widget _buildRowContent(LayrzTokens tokens) {
    return Padding(
      padding: tokens.spacing.pd2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tappable tile
          Expanded(child: widget.item.tile),
          if (widget.isSelected) ...[
            // Indicator bar — reserved space always (same width whether selected or not)
            Container(
              width: 3,
              height: double.infinity,
              decoration: BoxDecoration(
                color: tokens.colors.primary,
                borderRadius: tokens.radius.br3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
