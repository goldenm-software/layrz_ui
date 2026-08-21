import 'package:flutter/widgets.dart';

/// Immutable spacing tokens defining a consistent five-level grid for margins, padding, and sized-box gaps.
///
/// Spacing values use five semantic levels (1–5) with the following pixel values:
/// - Level 1: 4 pixels
/// - Level 2: 8 pixels
/// - Level 3: 16 pixels
/// - Level 4: 24 pixels
/// - Level 5: 32 pixels
///
/// Three accessor families derive from the base [spN] fields:
/// - [pdN] — [EdgeInsets.all] for padding; returned as explicit padding intent.
/// - [mgN] — [EdgeInsets.all] for margins; returned as explicit margin intent.
/// - [sbN] — [SizedBox] spacers in three variants:
///   - [sbN] — square spacer, constrained to [sp N]×[spN].
///   - [sbNh] — horizontal gap, constrained to width [spN], unconstrained height.
///   - [sbNv] — vertical gap, constrained to height [spN], unconstrained width.
///
/// The [pdN] and [mgN] accessors are intentionally identical in value; they exist
/// so call sites read as explicit padding vs margin intent.
@immutable
class LayrzSpacingTokens {
  /// Spacing level 1 — 4 pixels.
  final double sp1;

  /// Spacing level 2 — 8 pixels.
  final double sp2;

  /// Spacing level 3 — 16 pixels.
  final double sp3;

  /// Spacing level 4 — 24 pixels.
  final double sp4;

  /// Spacing level 5 — 32 pixels.
  final double sp5;

  /// Creates a new [LayrzSpacingTokens] with all spacing levels.
  const LayrzSpacingTokens({
    this.sp1 = 6.0,
    this.sp2 = 10.0,
    this.sp3 = 14.0,
    this.sp4 = 20.0,
    this.sp5 = 32.0,
  });

  /// Padding level 1 — [EdgeInsets.all] with 4 pixels on all sides.
  EdgeInsets get pd1 => EdgeInsets.all(sp1);

  /// Padding level 2 — [EdgeInsets.all] with 8 pixels on all sides.
  EdgeInsets get pd2 => EdgeInsets.all(sp2);

  /// Padding level 3 — [EdgeInsets.all] with 16 pixels on all sides.
  EdgeInsets get pd3 => EdgeInsets.all(sp3);

  /// Padding level 4 — [EdgeInsets.all] with 24 pixels on all sides.
  EdgeInsets get pd4 => EdgeInsets.all(sp4);

  /// Padding level 5 — [EdgeInsets.all] with 32 pixels on all sides.
  EdgeInsets get pd5 => EdgeInsets.all(sp5);

  /// Margin level 1 — [EdgeInsets.all] with 4 pixels on all sides.
  EdgeInsets get mg1 => EdgeInsets.all(sp1);

  /// Margin level 2 — [EdgeInsets.all] with 8 pixels on all sides.
  EdgeInsets get mg2 => EdgeInsets.all(sp2);

  /// Margin level 3 — [EdgeInsets.all] with 16 pixels on all sides.
  EdgeInsets get mg3 => EdgeInsets.all(sp3);

  /// Margin level 4 — [EdgeInsets.all] with 24 pixels on all sides.
  EdgeInsets get mg4 => EdgeInsets.all(sp4);

  /// Margin level 5 — [EdgeInsets.all] with 32 pixels on all sides.
  EdgeInsets get mg5 => EdgeInsets.all(sp5);

  /// Sized-box spacer level 1 — [SizedBox.square] with 4-pixel dimensions.
  Widget get sb1 => SizedBox.square(dimension: sp1);

  /// Sized-box spacer level 2 — [SizedBox.square] with 8-pixel dimensions.
  Widget get sb2 => SizedBox.square(dimension: sp2);

  /// Sized-box spacer level 3 — [SizedBox.square] with 16-pixel dimensions.
  Widget get sb3 => SizedBox.square(dimension: sp3);

  /// Sized-box spacer level 4 — [SizedBox.square] with 24-pixel dimensions.
  Widget get sb4 => SizedBox.square(dimension: sp4);

  /// Sized-box spacer level 5 — [SizedBox.square] with 32-pixel dimensions.
  Widget get sb5 => SizedBox.square(dimension: sp5);

  /// Horizontal spacer level 1 — [SizedBox] with 4-pixel width, unconstrained height.
  Widget get sb1h => SizedBox(width: sp1);

  /// Horizontal spacer level 2 — [SizedBox] with 8-pixel width, unconstrained height.
  Widget get sb2h => SizedBox(width: sp2);

  /// Horizontal spacer level 3 — [SizedBox] with 16-pixel width, unconstrained height.
  Widget get sb3h => SizedBox(width: sp3);

  /// Horizontal spacer level 4 — [SizedBox] with 24-pixel width, unconstrained height.
  Widget get sb4h => SizedBox(width: sp4);

  /// Horizontal spacer level 5 — [SizedBox] with 32-pixel width, unconstrained height.
  Widget get sb5h => SizedBox(width: sp5);

  /// Vertical spacer level 1 — [SizedBox] with 4-pixel height, unconstrained width.
  Widget get sb1v => SizedBox(height: sp1);

  /// Vertical spacer level 2 — [SizedBox] with 8-pixel height, unconstrained width.
  Widget get sb2v => SizedBox(height: sp2);

  /// Vertical spacer level 3 — [SizedBox] with 16-pixel height, unconstrained width.
  Widget get sb3v => SizedBox(height: sp3);

  /// Vertical spacer level 4 — [SizedBox] with 24-pixel height, unconstrained width.
  Widget get sb4v => SizedBox(height: sp4);

  /// Vertical spacer level 5 — [SizedBox] with 32-pixel height, unconstrained width.
  Widget get sb5v => SizedBox(height: sp5);

  /// Returns a copy of this spacing tokens object with the given fields replaced.
  LayrzSpacingTokens copyWith({
    double? sp1,
    double? sp2,
    double? sp3,
    double? sp4,
    double? sp5,
  }) {
    return LayrzSpacingTokens(
      sp1: sp1 ?? this.sp1,
      sp2: sp2 ?? this.sp2,
      sp3: sp3 ?? this.sp3,
      sp4: sp4 ?? this.sp4,
      sp5: sp5 ?? this.sp5,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSpacingTokens &&
          runtimeType == other.runtimeType &&
          sp1 == other.sp1 &&
          sp2 == other.sp2 &&
          sp3 == other.sp3 &&
          sp4 == other.sp4 &&
          sp5 == other.sp5;

  @override
  int get hashCode => Object.hash(sp1, sp2, sp3, sp4, sp5);
}
