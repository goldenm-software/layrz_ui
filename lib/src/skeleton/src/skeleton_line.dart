import 'package:flutter/widgets.dart';

import 'skeleton_shimmer_box.dart';

/// A single text-line skeleton shape primitive — the loading placeholder
/// for one line of real text.
///
/// [LayrzSkeletonLine] is used as a child of `LayrzSkeleton`'s `child` tree,
/// alongside other primitives (`LayrzSkeletonBox`, `LayrzSkeletonCircle`),
/// composed by the caller into the shape of the real widget being loaded:
///
/// ```dart
/// LayrzSkeleton(
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       LayrzSkeletonLine(width: 160, matchTextStyle: context.titleStyle),
///       const SizedBox(height: 6),
///       const LayrzSkeletonLine(width: 220),
///     ],
///   ),
/// )
/// ```
///
/// **No-reflow**: [width] is honored exactly, and the line's height is
/// either the explicit [height] or derived from [matchTextStyle] (see
/// below) — never an arbitrary hardcoded value — so a caller can make this
/// primitive occupy exactly the box the real text will occupy once it
/// loads, avoiding a layout jump.
///
/// **[matchTextStyle]**: when the real content this line stands in for is
/// text rendered with a known [TextStyle] (e.g. `context.titleStyle` or
/// `context.bodyStyle`), pass it here instead of guessing a [height]. The
/// line's height is derived from that style's line-box metrics
/// (`fontSize * height`, falling back to a `1.2` line-height multiplier when
/// the style does not specify one — the same default `package:flutter`
/// itself uses for [TextStyle.height]), so the placeholder's vertical
/// footprint matches the real text's rendered line height. [height] takes
/// precedence when both are supplied.
///
/// Used standalone (outside any `LayrzSkeleton` ancestor), it still shimmers
/// via a self-owned fallback ticker, so it renders sensibly in isolation
/// (e.g. a widget catalog page or a unit test) — see
/// `LayrzSkeletonShimmerBox` for that fallback mechanism.
class LayrzSkeletonLine extends StatelessWidget {
  /// The width of the line, in logical pixels.
  final double width;

  /// The explicit height of the line, in logical pixels.
  ///
  /// When null, the height is derived from [matchTextStyle] if provided, or
  /// falls back to [kDefaultLayrzSkeletonLineHeight] (`12.0`) otherwise.
  /// Takes precedence over [matchTextStyle] when both are supplied.
  final double? height;

  /// A [TextStyle] to derive this line's height from, so it matches the
  /// line-box height of the real text it stands in for.
  ///
  /// Ignored when [height] is explicitly supplied. See the class-level doc
  /// for the exact derivation.
  final TextStyle? matchTextStyle;

  /// The corner radius applied to the line, in logical pixels.
  ///
  /// Defaults to `kDefaultLayrzSkeletonLineRadius` (`4.0`) — text-line
  /// placeholders read best with a soft, pill-leaning rounding rather than
  /// sharp corners, unlike the general-purpose [LayrzSkeletonBox].
  final double borderRadius;

  /// Creates a new [LayrzSkeletonLine].
  const LayrzSkeletonLine({
    super.key,
    required this.width,
    this.height,
    this.matchTextStyle,
    this.borderRadius = kDefaultLayrzSkeletonLineRadius,
  });

  /// Resolves this line's effective height, per the precedence documented on
  /// [height] and [matchTextStyle].
  double get _resolvedHeight {
    final explicit = height;
    if (explicit != null) return explicit;

    final style = matchTextStyle;
    if (style?.fontSize != null) {
      final lineHeightMultiplier = style!.height ?? 1.2;
      return style.fontSize! * lineHeightMultiplier + .5;
    }

    return kDefaultLayrzSkeletonLineHeight;
  }

  @override
  Widget build(BuildContext context) {
    return LayrzSkeletonShimmerBox(
      shape: SizedBox(
        width: width,
        height: _resolvedHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

/// The default height, in logical pixels, of a [LayrzSkeletonLine] when
/// neither an explicit `height` nor a `matchTextStyle` is supplied.
const double kDefaultLayrzSkeletonLineHeight = 12.0;

/// The default corner radius, in logical pixels, applied to a
/// [LayrzSkeletonLine].
const double kDefaultLayrzSkeletonLineRadius = 4.0;
