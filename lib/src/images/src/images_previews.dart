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
  return Center(
    child: LayrzAvatar.icon(
      icon: LayrzIcons.solarOutlineCheckCircle,
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

/// Preview of [LayrzAvatar] with image source.
@Preview(name: 'Avatar - Image', theme: LayrzPreviewTheme.light)
Widget previewLayrzAvatarImage() {
  return const Center(
    child: LayrzAvatar.image(
      source: 'https://cdn.layrz.com/resources/com.layrz.one/favicon/normal.png',
      size: 48,
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
