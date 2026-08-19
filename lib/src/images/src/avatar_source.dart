import 'package:flutter/widgets.dart';

/// Sealed hierarchy representing the source and type of an avatar.
///
/// [LayrzAvatarSource] represents what a [LayrzAvatar] should render. It uses
/// a sealed class hierarchy to guarantee exhaustiveness when switching over
/// avatar sources — adding a new source type later will be a compile error at
/// every unhandled `switch` statement, not a silent fallthrough.
///
/// A `null` source (no [LayrzAvatarSource] provided to [LayrzAvatar]) falls back
/// to displaying initials from the name text; there is no `none` variant because
/// null already expresses that state and provides the fallback.
sealed class LayrzAvatarSource {
  /// Creates a new avatar source.
  const LayrzAvatarSource();
}

/// Avatar source: display an image from a network URL or base64 string.
///
/// The [url] can be:
/// - An `http(s)` URL
/// - A data-URI with base64 encoding
/// - A bare base64 string
///
/// When the URL is null or empty, [LayrzAvatar] falls back to initials.
final class LayrzAvatarUrl extends LayrzAvatarSource {
  /// Creates a URL-based avatar source.
  ///
  /// The [url] parameter specifies the image source as a URL, data-URI, or
  /// base64 string. The avatar displays this image on a white background
  /// to ensure visibility for images with transparency.
  const LayrzAvatarUrl(this.url);

  /// The image URL, data-URI, or base64 string.
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAvatarUrl &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => Object.hash(runtimeType, url);

  /// Returns a copy of this source with the given field replaced.
  LayrzAvatarUrl copyWith({String? url}) {
    return LayrzAvatarUrl(url ?? this.url);
  }
}

/// Avatar source: display an image from a base64-encoded string.
///
/// When the base64 string is null or empty, [LayrzAvatar] falls back to initials.
final class LayrzAvatarBase64 extends LayrzAvatarSource {
  /// Creates a base64-based avatar source.
  ///
  /// The [base64] parameter specifies a raw base64-encoded image string.
  /// The avatar displays this image on a white background to ensure visibility
  /// for images with transparency.
  const LayrzAvatarBase64(this.base64);

  /// The base64-encoded image string.
  final String base64;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAvatarBase64 &&
          runtimeType == other.runtimeType &&
          base64 == other.base64;

  @override
  int get hashCode => Object.hash(runtimeType, base64);

  /// Returns a copy of this source with the given field replaced.
  LayrzAvatarBase64 copyWith({String? base64}) {
    return LayrzAvatarBase64(base64 ?? this.base64);
  }
}

/// Avatar source: display an icon from an [IconData].
///
/// The icon is rendered at 70% of the avatar size to maintain visual balance.
/// When the [icon] is null, [LayrzAvatar] falls back to initials.
final class LayrzAvatarIcon extends LayrzAvatarSource {
  /// Creates an icon-based avatar source.
  ///
  /// The [icon] parameter specifies the Flutter [IconData] to render.
  /// It is displayed at 70% of the avatar size on a colored background
  /// (defaulting to the primary token color).
  const LayrzAvatarIcon(this.icon);

  /// The icon to display as an avatar.
  final IconData icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAvatarIcon &&
          runtimeType == other.runtimeType &&
          icon == other.icon;

  @override
  int get hashCode => Object.hash(runtimeType, icon);

  /// Returns a copy of this source with the given field replaced.
  LayrzAvatarIcon copyWith({IconData? icon}) {
    return LayrzAvatarIcon(icon ?? this.icon);
  }
}

/// Avatar source: display a Unicode emoji glyph.
///
/// The emoji is rendered centered and scaled to 60% of the avatar size
/// on a white background. When the [emoji] is null or empty, [LayrzAvatar]
/// falls back to initials.
final class LayrzAvatarEmoji extends LayrzAvatarSource {
  /// Creates an emoji-based avatar source.
  ///
  /// The [emoji] parameter specifies a Unicode emoji string (typically a single
  /// character, but may be a multi-character sequence like `👨‍👩‍👧‍👦`).
  /// It is displayed centered at 60% of the avatar size on a white background.
  const LayrzAvatarEmoji(this.emoji);

  /// The emoji string to display.
  final String emoji;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAvatarEmoji &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji;

  @override
  int get hashCode => Object.hash(runtimeType, emoji);

  /// Returns a copy of this source with the given field replaced.
  LayrzAvatarEmoji copyWith({String? emoji}) {
    return LayrzAvatarEmoji(emoji ?? this.emoji);
  }
}
