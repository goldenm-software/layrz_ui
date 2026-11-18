import 'badge_visual.dart';

/// A [LayrzBadgeVisual] that shows how many items are hidden as `+N`
/// (e.g. `+3` next to the first of four destinations).
///
/// Same size, colors and centering as [LayrzBadgeVisual]; only the label
/// changes. Counts above [kLayrzBadgeMaxCount] render as `+99`.
class LayrzOverflowBadgeVisual extends LayrzBadgeVisual {
  /// Creates a `+N` badge for [count] hidden items.
  const LayrzOverflowBadgeVisual({
    required int super.count,
    super.type,
    super.color,
    super.key,
  });

  /// Formats [count] as `+N`, capped at `+99`; negative counts render as `+0`.
  static String formatOverflow(int count) {
    if (count < 0) return '+0';
    if (count > kLayrzBadgeMaxCount) return '+$kLayrzBadgeMaxCount';
    return '+$count';
  }

  @override
  String formatLabel(int count) => formatOverflow(count);
}
