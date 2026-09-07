import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [Layo], the "MrLayo" brand mascot, across every implemented
/// [LayoEmotion].
///
/// Demonstrates the widget's size-automatic layout contract: an explicit
/// [Layo.width] pinned inside a fixed-size box, and the default (null width)
/// behaviour filling a bounded parent so it stretches to the available width
/// while its height still derives from the fixed 500:833 aspect ratio. Every
/// multi-[Layo] display in this section uses [LayrzRow]/[LayrzCol] (the
/// responsive 12-column grid) rather than [Wrap] or a plain [Row], so each
/// [Layo] always sits in a bounded-width column and reflows cleanly at any
/// viewport size instead of overflowing on narrow ones.
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
          'emotions via LayoEmotion.',
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
