import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Showcases [Layo], the static "MrLayo" brand mascot.
///
/// Demonstrates the widget's size-automatic layout contract: an explicit
/// [Layo.width] pinned inside a fixed-size box, and the default (null width)
/// behaviour filling an [Expanded] cell so it stretches to the available
/// width while its height still derives from the fixed 500:833 aspect ratio.
class LayoSection extends StatelessWidget {
  /// Creates a new [LayoSection].
  const LayoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Layo',
      description:
          'The static "MrLayo" brand mascot, drawn entirely with CustomPainter — no bundled '
          'image or SVG. Size-automatic: fills the width its parent provides and derives '
          'height from the fixed 500:833 aspect ratio, or pass an explicit width.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explicit width — Layo(width: 120)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const Layo(width: 120),

          SizedBox(height: tokens.spacing.sp4),

          Text('Explicit width — Layo(width: 240)', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp3),
          const Layo(width: 240),

          SizedBox(height: tokens.spacing.sp4),

          Text(
            'Default (no width) — fills a bounded parent, here an Expanded row cell',
            style: tokens.typography.title,
          ),
          SizedBox(height: tokens.spacing.sp3),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Expanded(child: Layo()),
                SizedBox(width: 24),
                Expanded(child: Layo()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
