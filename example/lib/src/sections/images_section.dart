import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Content for the images section of the showroom.
class ImagesSection extends StatelessWidget {
  /// Creates a new [ImagesSection].
  const ImagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Images & Avatars',
      description: 'Material-free avatar component supporting URLs, base64, icons, emoji, and fallback initials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar variants
          Text('Avatar Variants', style: tokens.typography.headline.copyWith(fontSize: 16)),
          SizedBox(height: tokens.spacing.sp3),
          _buildAvatarRow(tokens),

          SizedBox(height: tokens.spacing.sp4),

          // Image component
          Text('Image Component', style: tokens.typography.headline.copyWith(fontSize: 16)),
          SizedBox(height: tokens.spacing.sp3),
          _buildImageDemo(tokens),
        ],
      ),
    );
  }

  /// Displays different avatar types.
  Widget _buildAvatarRow(LayrzTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Column(
            children: [
              const LayrzAvatar(nameText: 'John Doe', size: 48),
              SizedBox(height: tokens.spacing.sp2),
              Text('Initials', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp4),
          Column(
            children: [
              LayrzAvatar.icon(icon: MdiIcons.checkCircleOutline, size: 48),
              SizedBox(height: tokens.spacing.sp2),
              Text('Icon', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp4),
          Column(
            children: [
              const LayrzAvatar.emoji(emoji: '🎉', size: 48),
              SizedBox(height: tokens.spacing.sp2),
              Text('Emoji', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp4),
          Column(
            children: [
              const LayrzAvatar.image(
                imageSource: 'https://cdn.layrz.com/resources/com.layrz.one/favicon/normal.png',
                size: 48,
              ),
              SizedBox(height: tokens.spacing.sp2),
              Text('Network Image', style: tokens.typography.label),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays the image component with a network URL.
  Widget _buildImageDemo(LayrzTokens tokens) {
    const networkUrl = 'https://cdn.layrz.com/resources/com.layrz.one/favicon/normal.png';

    return Center(
      child: Column(
        children: [
          const LayrzImage(
            source: networkUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
          SizedBox(height: tokens.spacing.sp2),
          Text('Network Image', style: tokens.typography.label),
        ],
      ),
    );
  }
}
