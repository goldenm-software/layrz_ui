import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays [LayrzAvatar] and [LayrzImage] components with various configurations.
///
/// Demonstrates avatar types (initials, icon, emoji, image), shapes, and sizes,
/// as well as image source handling (asset, data-URI, bare base64).
Widget buildImagesSection() {
  return Builder(
    builder: (context) {
      return const _ImagesSectionContent();
    },
  );
}

/// Content for the images section of the showroom.
class _ImagesSectionContent extends StatelessWidget {
  /// Creates a new [_ImagesSectionContent].
  const _ImagesSectionContent();

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
          SizedBox(height: tokens.spacing.sp16),
          _buildAvatarRow(tokens),

          SizedBox(height: tokens.spacing.sp24),

          // Image component
          Text('Image Component', style: tokens.typography.headline.copyWith(fontSize: 16)),
          SizedBox(height: tokens.spacing.sp16),
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
              SizedBox(height: tokens.spacing.sp8),
              Text('Initials', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              LayrzAvatar.icon(icon: LayrzIcons.solarOutlineCheckCircle, size: 48),
              SizedBox(height: tokens.spacing.sp8),
              Text('Icon', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              const LayrzAvatar.emoji(emoji: '🎉', size: 48),
              SizedBox(height: tokens.spacing.sp8),
              Text('Emoji', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              const LayrzAvatar.image(
                imageSource: 'https://cdn.layrz.com/resources/com.layrz.one/favicon/normal.png',
                size: 48,
              ),
              SizedBox(height: tokens.spacing.sp8),
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
          SizedBox(height: tokens.spacing.sp8),
          Text('Network Image', style: tokens.typography.label),
        ],
      ),
    );
  }
}
