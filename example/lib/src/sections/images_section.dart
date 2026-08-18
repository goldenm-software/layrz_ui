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
          LayrzText('Avatar Variants', style: tokens.typography.headline.copyWith(fontSize: 16)),
          SizedBox(height: tokens.spacing.sp16),
          _buildAvatarRow(tokens),

          SizedBox(height: tokens.spacing.sp24),

          // Avatar shapes
          LayrzText('Avatar Shapes', style: tokens.typography.headline.copyWith(fontSize: 16)),
          SizedBox(height: tokens.spacing.sp16),
          _buildShapesRow(tokens),

          SizedBox(height: tokens.spacing.sp24),

          // Image component
          LayrzText('Image Component', style: tokens.typography.headline.copyWith(fontSize: 16)),
          SizedBox(height: tokens.spacing.sp16),
          _buildImageDemo(tokens),
        ],
      ),
    );
  }

  /// Displays different avatar types.
  Widget _buildAvatarRow(LayrzTokens tokens) {
    final icon = LayrzIcon(
      name: 'home',
      codePoint: 0xE88A,
      family: LayrzFamily.materialDesignIcons,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Column(
            children: [
              const LayrzAvatar(nameText: 'John Doe', size: 48),
              SizedBox(height: tokens.spacing.sp8),
              LayrzText('Initials', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              LayrzAvatar.icon(icon: icon, size: 48),
              SizedBox(height: tokens.spacing.sp8),
              LayrzText('Icon', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              const LayrzAvatar.emoji(emoji: '🎉', size: 48),
              SizedBox(height: tokens.spacing.sp8),
              LayrzText('Emoji', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              const LayrzAvatar.image(
                source: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
                size: 48,
              ),
              SizedBox(height: tokens.spacing.sp8),
              LayrzText('Base64', style: tokens.typography.label),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays avatar with different shapes.
  Widget _buildShapesRow(LayrzTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Column(
            children: [
              const LayrzAvatar(
                nameText: 'Circle',
                size: 48,
                shape: LayrzAvatarShape.circle,
              ),
              SizedBox(height: tokens.spacing.sp8),
              LayrzText('Circle', style: tokens.typography.label),
            ],
          ),
          SizedBox(width: tokens.spacing.sp24),
          Column(
            children: [
              const LayrzAvatar(
                nameText: 'Rounded',
                size: 48,
                shape: LayrzAvatarShape.rounded,
              ),
              SizedBox(height: tokens.spacing.sp8),
              LayrzText('Rounded', style: tokens.typography.label),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays the image component with a data-URI.
  Widget _buildImageDemo(LayrzTokens tokens) {
    // A simple 1x1 PNG pixel image in a data-URI
    const dataUri =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

    return Center(
      child: Column(
        children: [
          const LayrzImage(
            source: dataUri,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
          SizedBox(height: tokens.spacing.sp8),
          LayrzText('Data-URI Image', style: tokens.typography.label),
        ],
      ),
    );
  }
}
