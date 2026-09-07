import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [Layo], the "MrLayo" brand mascot, across every implemented
/// [LayoEmotion], plus [AvatarLayo], the cropped head/shoulders framing of
/// the same mascot.
///
/// Demonstrates the widget's size-automatic layout contract: an explicit
/// [Layo.width] pinned inside a fixed-size box, and the default (null width)
/// behaviour filling a bounded parent so it stretches to the available width
/// while its height still derives from the fixed 500:833 aspect ratio. Every
/// multi-[Layo] display in this section uses [LayrzRow]/[LayrzCol] (the
/// responsive 12-column grid) rather than [Wrap] or a plain [Row], so each
/// [Layo] always sits in a bounded-width column and reflows cleanly at any
/// viewport size instead of overflowing on narrow ones.
///
/// The [AvatarLayo] demos further down follow the same grid discipline and
/// cover both [LayoAvatarShape] values and every [LayoEmotion] rendered as an
/// avatar, each showing its own fixed per-emotion background color.
class LayoSection extends StatelessWidget {
  /// Creates a new [LayoSection].
  const LayoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Layo',
      description:
          'The "MrLayo" brand mascot, drawn entirely with CustomPainter — no bundled image or '
          'SVG. Size-automatic: fills the width its parent provides and derives height from '
          'the fixed 500:833 aspect ratio, or pass an explicit width. Renders one of ten '
          'emotions via LayoEmotion. AvatarLayo crops the same mascot into a square '
          'head/shoulders portrait, in either a circle or rounded-box frame.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All emotions — Layo(emotion: ...)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            spacing: tokens.spacing.sp4,
            children: LayoEmotion.values.map((emotion) {
              return LayrzCol(
                xs: 12,
                sm: 6,
                md: 3,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 180),
                    child: _EmotionTile(label: emotion.name, emotion: emotion),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('Explicit width — Layo(width: 120)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const Layo(width: 120),

          SizedBox(height: tokens.spacing.sp4),

          Text('Explicit width — Layo(width: 240)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const Layo(width: 240),

          SizedBox(height: tokens.spacing.sp4),

          Text('AvatarLayo — shapes', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            spacing: tokens.spacing.sp4,
            children: [
              LayrzCol(
                xs: 6,
                sm: 4,
                md: 2,
                child: Center(
                  child: _AvatarTile(label: 'circle', shape: LayoAvatarShape.circle),
                ),
              ),
              LayrzCol(
                xs: 6,
                sm: 4,
                md: 2,
                child: Center(
                  child: _AvatarTile(label: 'roundedBox', shape: LayoAvatarShape.roundedBox),
                ),
              ),
            ],
          ),

          SizedBox(height: tokens.spacing.sp4),

          Text('AvatarLayo — all emotions', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          LayrzRow(
            spacing: tokens.spacing.sp4,
            children: LayoEmotion.values.map((emotion) {
              return LayrzCol(
                xs: 6,
                sm: 4,
                md: 2,
                child: Center(
                  child: _AvatarTile(label: emotion.name, emotion: emotion),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A single labeled [Layo] tile, used by [LayoSection] to lay out every
/// emotion side by side for visual comparison inside a [LayrzRow]/[LayrzCol]
/// grid.
///
/// Renders its [Layo] with no explicit width, since the enclosing
/// [LayrzCol] already gives this tile a bounded width to fill — [Layo]'s own
/// [AspectRatio] derives its height from that automatically.
class _EmotionTile extends StatelessWidget {
  /// Creates a new [_EmotionTile].
  const _EmotionTile({required this.label, required this.emotion});

  /// The plain-text caption shown above the mascot, naming the
  /// [LayoEmotion] value being demonstrated.
  final String label;

  /// Which [LayoEmotion] this tile's [Layo] renders.
  final LayoEmotion emotion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.typography.body),
        SizedBox(height: tokens.spacing.sp2),
        Layo(emotion: emotion),
      ],
    );
  }
}

/// A single labeled [AvatarLayo] tile, used by [LayoSection] to lay out
/// several avatars side by side for visual comparison inside a
/// [LayrzRow]/[LayrzCol] grid.
///
/// Gives its [AvatarLayo] an explicit [width] of 120 logical pixels so the
/// square frame renders at a consistent, legible size regardless of how wide
/// the enclosing [LayrzCol] happens to be.
class _AvatarTile extends StatelessWidget {
  /// Creates a new [_AvatarTile].
  const _AvatarTile({
    required this.label,
    this.shape = LayoAvatarShape.circle,
    this.emotion = LayoEmotion.mrLayo,
  });

  /// The plain-text caption shown above the avatar, naming the property
  /// being demonstrated (a shape or an emotion).
  final String label;

  /// Which [LayoAvatarShape] this tile's [AvatarLayo] clips itself to.
  final LayoAvatarShape shape;

  /// Which [LayoEmotion] this tile's [AvatarLayo] renders.
  final LayoEmotion emotion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.typography.body),
        SizedBox(height: tokens.spacing.sp2),
        AvatarLayo(shape: shape, emotion: emotion, width: 120),
      ],
    );
  }
}
