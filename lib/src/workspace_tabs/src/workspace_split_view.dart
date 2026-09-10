import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

/// The minimum extent, in logical pixels, either pane of a
/// [LayrzWorkspaceSplitView] may shrink to.
///
/// Dragging the divider clamps against this constant on both sides so
/// neither pane can be squeezed out of usability entirely.
const double kLayrzWorkspaceSplitMinPaneExtent = 160.0;

/// A resizable two-pane split view: [left] and [right] rendered
/// side-by-side, separated by a draggable vertical divider the user can drag
/// to change the split ratio.
///
/// The ratio is a controlled value: [ratio] (0.0–1.0, the fraction of the
/// available width given to [left]) is supplied by the caller and
/// [onRatioChanged] is invoked live as the divider is dragged. This widget
/// owns no persistent state of its own — [LayrzWorkspaceTabs] is the one
/// that remembers the ratio across rebuilds, so it can key that memory
/// per-tab.
///
/// Neither pane is ever allowed to shrink below
/// [kLayrzWorkspaceSplitMinPaneExtent]: every drag delta is clamped against
/// that floor on both sides before [onRatioChanged] is called, so a fast or
/// large pointer movement cannot collapse a pane past its minimum in one
/// jump.
class LayrzWorkspaceSplitView extends StatefulWidget {
  /// The start (left-hand) pane's content.
  final Widget left;

  /// The end (right-hand) pane's content.
  final Widget right;

  /// The current split ratio, as the fraction of the available width given
  /// to [left]; the remainder (minus the divider's own width) goes to
  /// [right].
  ///
  /// Must be between `0.0` and `1.0` inclusive. The caller is responsible
  /// for persisting this value and feeding it back in on rebuild —
  /// [LayrzWorkspaceSplitView] does not remember it itself.
  final double ratio;

  /// Called with the new ratio whenever the user drags the divider.
  ///
  /// Fired continuously during the drag (not only on release), already
  /// clamped so neither pane crosses [kLayrzWorkspaceSplitMinPaneExtent].
  final ValueChanged<double> onRatioChanged;

  /// Creates a new [LayrzWorkspaceSplitView].
  ///
  /// [left], [right], [ratio], and [onRatioChanged] are all required.
  const LayrzWorkspaceSplitView({
    super.key,
    required this.left,
    required this.right,
    required this.ratio,
    required this.onRatioChanged,
  });

  @override
  State<LayrzWorkspaceSplitView> createState() => _LayrzWorkspaceSplitViewState();
}

class _LayrzWorkspaceSplitViewState extends State<LayrzWorkspaceSplitView> {
  /// Whether the pointer currently hovers the divider handle, used only to
  /// vary its fill colour (D15: colour/opacity only, never geometry).
  bool _isHovered = false;

  /// Whether the divider is currently being dragged, used alongside
  /// [_isHovered] to decide the handle's fill colour.
  bool _isDragging = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  /// Converts a horizontal drag delta in logical pixels, measured against
  /// [totalWidth] and the fixed [dividerWidth], into a new clamped ratio.
  double _ratioAfterDelta({
    required double deltaX,
    required double totalWidth,
    required double dividerWidth,
  }) {
    final usableWidth = (totalWidth - dividerWidth).clamp(0.0, totalWidth);
    if (usableWidth <= 0) return widget.ratio;

    final currentLeftWidth = widget.ratio * usableWidth;
    final nextLeftWidth = (currentLeftWidth + deltaX).clamp(
      kLayrzWorkspaceSplitMinPaneExtent,
      (usableWidth - kLayrzWorkspaceSplitMinPaneExtent).clamp(0.0, usableWidth),
    );
    return nextLeftWidth / usableWidth;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final dividerWidth = tokens.spacing.sp2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final usableWidth = (totalWidth - dividerWidth).clamp(0.0, totalWidth);
        final leftWidth = (widget.ratio * usableWidth).clamp(
          0.0,
          (usableWidth - kLayrzWorkspaceSplitMinPaneExtent).clamp(0.0, usableWidth),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: leftWidth, child: widget.left),
            Semantics(
              container: true,
              label: 'Resize split',
              // A `slider`-shaped adjustable control: assistive tech reads
              // this as a draggable separator between the two panes rather
              // than an inert divider line.
              slider: true,
              value: '${(widget.ratio * 100).round()}%',
              increasedValue: '${((widget.ratio * 100) + 5).clamp(0, 100).round()}%',
              decreasedValue: '${((widget.ratio * 100) - 5).clamp(0, 100).round()}%',
              onIncrease: () => widget.onRatioChanged(
                _ratioAfterDelta(deltaX: usableWidth * 0.05, totalWidth: totalWidth, dividerWidth: dividerWidth),
              ),
              onDecrease: () => widget.onRatioChanged(
                _ratioAfterDelta(deltaX: -usableWidth * 0.05, totalWidth: totalWidth, dividerWidth: dividerWidth),
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => _setHovered(true),
                onExit: (_) => _setHovered(false),
                child: Listener(
                  onPointerDown: (_) => setState(() => _isDragging = true),
                  onPointerUp: (_) => setState(() => _isDragging = false),
                  onPointerCancel: (_) => setState(() => _isDragging = false),
                  onPointerMove: (event) => widget.onRatioChanged(
                    _ratioAfterDelta(deltaX: event.delta.dx, totalWidth: totalWidth, dividerWidth: dividerWidth),
                  ),
                  child: SizedBox(
                    width: dividerWidth,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: (_isDragging || _isHovered) ? tokens.colors.primary : tokens.colors.divider,
                          borderRadius: tokens.radius.br1,
                        ),
                        child: SizedBox(width: tokens.border.stroke2, height: double.infinity),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: widget.right),
          ],
        );
      },
    );
  }
}
