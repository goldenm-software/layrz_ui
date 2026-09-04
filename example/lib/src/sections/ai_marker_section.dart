import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the AI marker section for the showroom.
///
/// Demonstrates the bare [LayrzAiMarker] at a couple of sizes, plus
/// [LayrzAiMarker.wrap] overlaid on sample content at all four
/// [LayrzAiMarkerPosition] corners. Neither form exposes a `tooltip` or
/// `semanticsLabel` parameter -- both the announced label and the tooltip
/// text are sourced from [LayrzUiL10n] and are not configurable per call
/// site, so this demo only ever passes `position`, `size`, `child`, and
/// `isVisible`.
class AiMarkerSection extends StatelessWidget {
  /// Creates a new [AiMarkerSection].
  const AiMarkerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'AI Marker',
      description:
          'An icon-only marker disclosing AI-generated or AI-assisted content. The '
          'disclosure text is fixed and localized -- there is no tooltip/label override.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inline marker', style: tokens.typography.title),
          const LayrzAiMarker(),
          SizedBox(height: tokens.spacing.sp4),
          Text('Overlaid via LayrzAiMarker.wrap -- all four corners', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'The marker is painted on top of the child without affecting its layout '
            'footprint. Hover or long-press the sparkle to see the localized disclosure '
            'tooltip; the burst and shine animations respect the platform\'s reduce-motion '
            'setting and render as a static, settled pose when it is enabled.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Wrap(
            spacing: tokens.spacing.sp4,
            runSpacing: tokens.spacing.sp4,
            children: [
              for (final position in LayrzAiMarkerPosition.values)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    LayrzAiMarker.wrap(
                      position: position,
                      child: _SampleCard(tokens: tokens),
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    Text(position.name, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                  ],
                ),
            ],
          ),
          SizedBox(height: tokens.spacing.sp4),
          Text('isVisible: false', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp2),
          Text(
            'When isVisible is false, only the child renders -- no marker, no overlay, no '
            'disclosure semantics.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzAiMarker.wrap(isVisible: false, child: _SampleCard(tokens: tokens)),
        ],
      ),
    );
  }
}

/// A small placeholder card used as the overlay target in every demo above --
/// stands in for a chat bubble or content card, the realistic use case for
/// [LayrzAiMarker.wrap].
class _SampleCard extends StatelessWidget {
  /// Creates a new [_SampleCard].
  const _SampleCard({required this.tokens});

  /// The design tokens used to style this card, threaded from the parent build.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 90,
      padding: EdgeInsets.all(tokens.spacing.sp3),
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        borderRadius: tokens.radius.br2,
        border: Border.all(color: tokens.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(MdiIcons.messageTextOutline, size: 20, color: tokens.colors.fg3),
          SizedBox(height: tokens.spacing.sp2),
          Text('Sample content', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
        ],
      ),
    );
  }
}
