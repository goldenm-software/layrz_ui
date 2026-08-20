import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzAvatar] with initials display.
@Preview(name: 'Avatar - Initials', size: Size(200, 120), theme: layrzPreviewLightTheme)
Widget previewLayrzAvatarInitials() {
  return const Center(
    child: LayrzAvatar(
      nameText: 'John Doe',
      size: 48,
    ),
  );
}

/// Preview of [LayrzAvatar] with icon display.
@Preview(name: 'Avatar - Icon', size: Size(200, 120), theme: layrzPreviewLightTheme)
Widget previewLayrzAvatarIcon() {
  return Center(
    child: LayrzAvatar.icon(
      icon: LayrzIcons.solarOutlineCheckCircle,
      size: 48,
    ),
  );
}

/// Preview of [LayrzAvatar] with emoji display.
@Preview(name: 'Avatar - Emoji', size: Size(200, 120), theme: layrzPreviewLightTheme)
Widget previewLayrzAvatarEmoji() {
  return const Center(
    child: LayrzAvatar.emoji(
      emoji: '🎉',
      size: 48,
    ),
  );
}

/// Preview of [LayrzAvatar] with image source.
@Preview(name: 'Avatar - Image', size: Size(200, 120), theme: layrzPreviewLightTheme)
Widget previewLayrzAvatarImage() {
  return const Center(
    child: LayrzAvatar.image(
      imageSource: 'https://cdn.layrz.com/resources/com.layrz.one/favicon/normal.png',
      size: 48,
    ),
  );
}

/// Preview of [LayrzImage] with a data-URI image.
@Preview(name: 'Image - Data URI', size: Size(200, 200), theme: layrzPreviewLightTheme)
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
