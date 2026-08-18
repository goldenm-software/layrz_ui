import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/preview.dart';

/// Preview of [LayrzAvatar] with initials display.
@Preview(name: 'Avatar - Initials', theme: LayrzPreviewTheme.light)
Widget previewLayrzAvatarInitials() {
  return const Center(
    child: LayrzAvatar(
      nameText: 'John Doe',
      size: 48,
    ),
  );
}

/// Preview of [LayrzAvatar] with icon display.
@Preview(name: 'Avatar - Icon', theme: LayrzPreviewTheme.light)
Widget previewLayrzAvatarIcon() {
  final icon = LayrzIcon(
    name: 'home',
    codePoint: 0xE88A,
    family: LayrzFamily.materialDesignIcons,
  );
  return Center(
    child: LayrzAvatar.icon(
      icon: icon,
      size: 48,
    ),
  );
}

/// Preview of [LayrzAvatar] with emoji display.
@Preview(name: 'Avatar - Emoji', theme: LayrzPreviewTheme.light)
Widget previewLayrzAvatarEmoji() {
  return const Center(
    child: LayrzAvatar.emoji(
      emoji: '🎉',
      size: 48,
    ),
  );
}

/// Preview of [LayrzAvatar] with circle shape.
@Preview(name: 'Avatar - Circle Shape', theme: LayrzPreviewTheme.light)
Widget previewLayrzAvatarCircle() {
  return const Center(
    child: LayrzAvatar(
      nameText: 'Jane Smith',
      size: 48,
      shape: LayrzAvatarShape.circle,
    ),
  );
}

/// Preview of [LayrzAvatar] with rounded shape.
@Preview(name: 'Avatar - Rounded Shape', theme: LayrzPreviewTheme.light)
Widget previewLayrzAvatarRounded() {
  return const Center(
    child: LayrzAvatar(
      nameText: 'Jane Smith',
      size: 48,
      shape: LayrzAvatarShape.rounded,
    ),
  );
}

/// Preview of [LayrzImage] with a data-URI image.
@Preview(name: 'Image - Data URI', theme: LayrzPreviewTheme.light)
Widget previewLayrzImageDataUri() {
  // A simple 1x1 PNG pixel (red)
  const dataUri =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

  return const Center(
    child: LayrzImage(
      source: dataUri,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
    ),
  );
}
