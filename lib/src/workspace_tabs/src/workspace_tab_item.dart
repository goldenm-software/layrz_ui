import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

import 'workspace_tab.dart';
import 'workspace_tab_chrome_painter.dart';

/// The minimum width a single tab item shrinks to before the strip starts
/// scrolling instead of shrinking further.
const double kLayrzWorkspaceTabMinWidth = 96.0;

/// The preferred (unconstrained) width a single tab item takes when there is
/// enough room for every open tab to render at full size.
const double kLayrzWorkspaceTabPreferredWidth = 200.0;

/// One tab within a [LayrzWorkspaceTabs] strip: the connected-chrome
/// background, optional leading [LayrzWorkspaceTab.icon], label, and a
/// close (×) affordance.
///
/// This widget owns only its own hover/focus visuals — selection,
/// activation, and close all report back to the parent strip via callbacks.
/// It renders no drag behavior itself; the parent strip wraps it with the
/// pointer listeners that drive reordering.
class LayrzWorkspaceTabItem extends StatefulWidget {
  /// The tab descriptor this item renders.
  final LayrzWorkspaceTab tab;

  /// Whether this tab is the currently active one.
  final bool isActive;

  /// Whether this item currently holds keyboard focus, for the arrow-key
  /// traversal the parent strip manages.
  final bool isFocused;

  /// Called when the user activates this tab (tap, or Enter/Space while
  /// focused).
  final VoidCallback onSelected;

  /// Called when the user presses this tab's close (×) affordance.
  ///
  /// Null when [LayrzWorkspaceTab.closable] is `false`, or when the parent
  /// strip's `onTabClosed` handler is `null` — in both cases no close
  /// affordance is rendered at all.
  final VoidCallback? onClosed;

  /// Whether this item is currently the tab being dragged for reordering.
  ///
  /// Rendered with reduced opacity, per D15 (interaction states vary
  /// colour/opacity only, never geometry).
  final bool isDragging;

  /// Creates a new [LayrzWorkspaceTabItem].
  const LayrzWorkspaceTabItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.isFocused,
    required this.onSelected,
    this.onClosed,
    this.isDragging = false,
  });

  @override
  State<LayrzWorkspaceTabItem> createState() => _LayrzWorkspaceTabItemState();
}

class _LayrzWorkspaceTabItemState extends State<LayrzWorkspaceTabItem> {
  /// Whether the pointer is currently hovering this tab item, used only to
  /// vary this item's fill colour (D15: interaction states are colour/opacity
  /// only). The close (×) affordance's visibility is independent of hover —
  /// see [showClose] at the top of [build].
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // `widget.onClosed` is already null when this tab isn't closable, or
    // when the parent strip has no `onTabClosed` handler (see
    // `LayrzWorkspaceTabs`'s wiring), so a non-null value alone means the ×
    // should render. It is intentionally NOT gated on hover or `isActive`:
    // the close affordance is always visible on every closable tab, active
    // or not, and — because it's spread into the `Row` only when true — its
    // presence in the layout is fixed, so it never shifts on hover.
    final showClose = widget.onClosed != null;

    final fillColor = widget.isActive ? tokens.colors.sf1 : (_isHovered ? tokens.colors.sf3 : tokens.colors.sf2);
    final labelColor = widget.isActive ? tokens.colors.fg1 : tokens.colors.fg2;
    final topRadius = tokens.radius.r2;
    // The outward-flaring bottom shoulder is smaller than the inward top
    // radius on every tab (active or not) — it's a subtle S-curve accent,
    // not a mirrored corner, and it's token-driven rather than a hardcoded
    // magic number.
    final shoulderRadius = tokens.radius.r1;

    return Semantics(
      container: true,
      button: true,
      selected: widget.isActive,
      label: widget.tab.label,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: Opacity(
          opacity: widget.isDragging ? 0.5 : 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: kLayrzWorkspaceTabMinWidth),
            child: CustomPaint(
              painter: LayrzWorkspaceTabChromePainter(
                fillColor: fillColor,
                topRadius: topRadius,
                shoulderRadius: shoulderRadius,
                // The active tab's open (merged-bottom) border is stroked in
                // the same colour+width as the content panel's border below
                // it (`tokens.colors.divider` / `tokens.border.stroke1`), so
                // the tab's top+sides+shoulders and the panel's outline read
                // as one continuous line rather than two separately-styled
                // shapes. Keyboard focus overrides this with the usual
                // primary focus ring, on any tab (active or not).
                borderColor: widget.isFocused
                    ? tokens.colors.primary.shade500
                    : (widget.isActive ? tokens.colors.divider : null),
                borderWidth: widget.isFocused ? 2.0 : tokens.border.stroke1,
                mergeBottom: widget.isActive,
              ),
              // A tab is a control, not selectable body text — disabled here
              // per the same convention `LayrzTabView`'s pills use (see
              // `_LayrzTabPill.build` in `lib/src/tabs/src/tab_view.dart`),
              // so the label can't be drag-selected like a paragraph while
              // tap/close/drag gestures underneath are unaffected.
              child: SelectionContainer.disabled(
                child: LayrzTappable(
                  onTap: widget.onSelected,
                  color: const Color(0x00000000),
                  hoverColor: const Color(0x00000000),
                  pressedColor: const Color(0x00000000),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.tab.icon != null) ...[
                          Icon(widget.tab.icon, size: 16.0, color: labelColor),
                          SizedBox(width: tokens.spacing.sp1),
                        ],
                        Flexible(
                          // Excluded from the semantics tree so its own
                          // auto-generated text label doesn't duplicate the
                          // label already carried by this item's outer
                          // Semantics node (which would otherwise read as
                          // "Alpha\nAlpha" to assistive technology).
                          child: ExcludeSemantics(
                            child: Text(
                              widget.tab.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tokens.typography.body.copyWith(
                                color: labelColor,
                                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        if (showClose) ...[
                          SizedBox(width: tokens.spacing.sp1),
                          _LayrzWorkspaceTabCloseButton(
                            label: widget.tab.label,
                            color: labelColor,
                            onTap: widget.onClosed!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The close (×) affordance rendered inside a [LayrzWorkspaceTabItem].
///
/// A small, independently focusable/tappable hit target so the close action
/// never accidentally activates the tab it belongs to (its own
/// [GestureDetector] consumes the tap before it reaches the tab's own
/// [LayrzTappable]).
class _LayrzWorkspaceTabCloseButton extends StatefulWidget {
  /// The owning tab's label, used to build this button's semantic label.
  final String label;

  /// The icon's colour, matching the owning tab's current label colour.
  final Color color;

  /// Called when the user taps this close affordance.
  final VoidCallback onTap;

  /// Creates a new [_LayrzWorkspaceTabCloseButton].
  const _LayrzWorkspaceTabCloseButton({required this.label, required this.color, required this.onTap});

  @override
  State<_LayrzWorkspaceTabCloseButton> createState() => _LayrzWorkspaceTabCloseButtonState();
}

class _LayrzWorkspaceTabCloseButtonState extends State<_LayrzWorkspaceTabCloseButton> {
  /// Whether the pointer is currently hovering this close affordance.
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      container: true,
      button: true,
      label: 'Close ${widget.label}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _isHovered ? tokens.colors.sf4 : const Color(0x00000000),
              borderRadius: tokens.radius.br1,
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp1 / 2),
              child: Icon(MdiIcons.close, size: 14.0, color: widget.color),
            ),
          ),
        ),
      ),
    );
  }
}
