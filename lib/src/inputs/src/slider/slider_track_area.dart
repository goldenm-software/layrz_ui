import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

import 'slider_bubble_layout_delegate.dart';
import 'slider_painter.dart';
import 'slider_value_bubble.dart';

/// The painted track/thumb region of a `LayrzSlider`, plus its drag-only
/// value bubble.
///
/// Split out of `LayrzSlider`'s `build` method purely to keep that file under
/// the repository's per-file size guidance — this widget owns no state of its
/// own; every value it needs (current fraction, colours, whether a drag is
/// active) is resolved by `_LayrzSliderState` and passed in, so the widget
/// stays a plain, stateless rendering layer.
///
/// See `LayrzSlider`'s class doc ("Drag value bubble" section) for why the
/// bubble is a [Positioned] child of a [Stack] with `clipBehavior: Clip.none`
/// rather than a normally laid-out sibling: that is what keeps its
/// appearance and disappearance during a drag from ever changing this
/// widget's own height.
class LayrzSliderTrackArea extends StatelessWidget {
  /// The full width of the track, from the enclosing `LayoutBuilder`.
  final double trackWidth;

  /// The fixed height of this widget's invisible hit-slop region.
  ///
  /// Must stay constant across every rebuild regardless of interaction state
  /// (including whether the bubble is showing) — see decision D15.
  final double hitSlopHeight;

  /// The painted height of the track plus the thumb's full edge length,
  /// forwarded to the inner [CustomPaint]'s `size`.
  final double paintHeight;

  /// The thumb's current position as a fraction of the track, `0.0`–`1.0`.
  final double fraction;

  /// The painter that draws the track and thumb for the current frame.
  final LayrzSliderPainter painter;

  /// Half of the thumb's edge length, used by [LayrzSliderBubbleLayoutDelegate]
  /// to keep the bubble aligned with the same thumb-centre x-coordinate the
  /// painter itself uses.
  final double thumbHalfSize;

  /// The vertical gap between the top of the thumb and the bottom of the
  /// bubble, applied as the bubble's negative `top` offset.
  final double bubbleClearance;

  /// Whether a drag gesture is currently in progress.
  ///
  /// The bubble is only built while this is `true` — it is never present at
  /// rest, per the slider's decided drag-only bubble behaviour.
  final bool isDragging;

  /// Whether the caller has suppressed the value display entirely.
  ///
  /// When `false`, the bubble is suppressed along with the static label it
  /// supplements — the bubble is decidedly not shown on its own.
  final bool showValueLabel;

  /// The already-formatted current value, shown inside the bubble.
  final String formattedValue;

  /// Whether the slider is disabled, used to pick the bubble's fill colour.
  final bool isDisabled;

  /// The design tokens used to resolve the bubble's colours, radius, and
  /// typography.
  final LayrzTokens tokens;

  /// Creates the track/thumb/bubble rendering region of a `LayrzSlider`.
  const LayrzSliderTrackArea({
    super.key,
    required this.trackWidth,
    required this.hitSlopHeight,
    required this.paintHeight,
    required this.fraction,
    required this.painter,
    required this.thumbHalfSize,
    required this.bubbleClearance,
    required this.isDragging,
    required this.showValueLabel,
    required this.formattedValue,
    required this.isDisabled,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hitSlopHeight,
      width: double.infinity,
      child: Stack(
        // Clip.none lets the drag bubble paint above this SizedBox's bounds
        // without being cropped. A Stack sizes itself from its non-positioned
        // children only (here, the Center/CustomPaint pair below) -- a
        // Positioned child never contributes to that size, so the bubble
        // appearing/disappearing on drag start/end never changes this
        // SizedBox's fixed height, which is what keeps surrounding form
        // content from reflowing (the exact flicker D15 exists to prevent).
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ExcludeSemantics(
              child: CustomPaint(
                size: Size(trackWidth, paintHeight),
                painter: painter,
              ),
            ),
          ),
          if (isDragging && showValueLabel)
            Positioned(
              // left/right: 0 gives this Positioned's child bounded (loose)
              // constraints from the Stack -- without both set, Stack hands
              // the child unbounded width, which crashes the
              // CustomSingleChildLayout below. The bubble itself does not
              // stretch to fill that width: CustomSingleChildLayout sizes it
              // to its own unconstrained intrinsic size and then positions
              // it, so it still hugs its text while its centre tracks the
              // thumb's fraction.
              left: 0,
              right: 0,
              top: -bubbleClearance,
              child: CustomSingleChildLayout(
                delegate: LayrzSliderBubbleLayoutDelegate(
                  trackWidth: trackWidth,
                  thumbHalfSize: thumbHalfSize,
                  fraction: fraction,
                ),
                child: ExcludeSemantics(
                  child: LayrzSliderValueBubble(
                    text: formattedValue,
                    color: isDisabled ? tokens.colors.fg4 : tokens.colors.fg1,
                    textColor: tokens.colors.sf1,
                    tokens: tokens,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
