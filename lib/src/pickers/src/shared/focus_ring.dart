import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// A visible keyboard-focus indicator for grid cells, satisfying WCAG 2.1
/// 2.4.7 Focus Visible — see `engineering/accessibility.md`.
///
/// Wraps [child] with a border that appears only while [focusNode] holds
/// primary focus, listening to [focusNode] directly rather than depending
/// on any focus-visual support inside [child] itself — this is what lets
/// [LayrzPickersDayGrid] and [LayrzPickersMonthGrid] gain a focus ring
/// without any change to `day_grid_cell.dart`/`month_grid_cell.dart`
/// (neither file is `U10`'s to edit).
///
/// **D15 compliance is the entire point of this widget's shape.** The ring
/// is painted by a [Stack] + [Positioned.fill] [IgnorePointer] sibling laid
/// *over* [child], never by wrapping [child] in a bordered [Container] or
/// [Padding] — either of those would add to [child]'s own footprint and
/// change its rendered size the instant focus arrives, which is exactly the
/// reflow-on-focus failure D15 forbids for a grid where an arrow key moves
/// focus dozens of times in a row. The overlay border sits flush with
/// [child]'s own edge (`Positioned.fill`, no inset) and paints only colour,
/// border colour and opacity — see [build] — so [child]'s box is bit-for-bit
/// identical focused or not; `focus_ring_test.dart` asserts this directly by
/// comparing [RenderBox.size] before and after focus.
///
/// Colour comes from `context.tokens.colors.primary`, matching the "today"
/// ring [LayrzPickersDayGridCell]/[LayrzPickersMonthGridCell] already paint
/// with `Border.all(color: tokens.colors.primary, ...)` — a focus ring in
/// the same hue as the "today" ring is visually distinguished from it by
/// [borderWidth] alone (wider) plus the fact the two are never both partway
/// through their own state at once from a user's perspective (today's ring
/// is static; the focus ring only appears while that exact cell holds
/// keyboard focus), not by using a different colour that would need its own
/// token.
class LayrzFocusRing extends StatefulWidget {
  /// The [FocusNode] this ring listens to. Must be the same node the
  /// wrapped cell's own interactive [Focus] widget uses to take focus —
  /// [LayrzPickersDayGrid] and [LayrzPickersMonthGrid] both already own one
  /// such node per cell (`_focusNodeFor`), so this widget is composed
  /// around the cell using that same node rather than creating its own.
  final FocusNode focusNode;

  /// The cell content this ring is painted around. Never resized, padded,
  /// or otherwise altered by this widget — see the class doc's D15 note.
  final Widget child;

  /// The ring's border width in logical pixels, applied only while
  /// [focusNode] holds primary focus. Defaults to `2.0`, thick enough to
  /// read clearly against the grid's small (32×32 day cell / rounded-rect
  /// month cell) targets without visually merging with the 1.5px `today`
  /// ring [tokens.border.base] already paints on some cells.
  final double borderWidth;

  /// Creates a new [LayrzFocusRing].
  const LayrzFocusRing({super.key, required this.focusNode, required this.child, this.borderWidth = 2.0});

  @override
  State<LayrzFocusRing> createState() => _LayrzFocusRingState();
}

class _LayrzFocusRingState extends State<LayrzFocusRing> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _hasFocus = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(LayrzFocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _hasFocus = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  /// Mirrors [FocusNode.hasFocus] into [_hasFocus] on every focus change.
  ///
  /// Reads [FocusNode.hasFocus] rather than [FocusNode.hasPrimaryFocus] so a
  /// focused ancestor scope still shows the ring on this exact node when it
  /// is the one actually holding focus — for these leaf-cell nodes the two
  /// are equivalent in practice, but `hasFocus` is the correct one to read
  /// generally and costs nothing extra here.
  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      // No `alignment`/`fit` override needed beyond the default: `Stack`
      // sizes itself to `child` (its only non-positioned entry) and the
      // `Positioned.fill` ring overlay never contributes to that sizing —
      // see the class doc's D15 note.
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: _hasFocus ? Border.all(color: tokens.colors.primary.shade500, width: widget.borderWidth) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
