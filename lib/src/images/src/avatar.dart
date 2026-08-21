import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/src/avatar_source.dart';
import 'package:layrz_ui/src/images/src/image.dart';

/// Private: opaque light gray background for images and emojis.
const Color _kWhiteBackground = Color(0xFFFCFCFC);

/// A static avatar display widget for the layrz_ui design system.
///
/// [LayrzAvatar] renders a user avatar in one of five forms:
/// - **URL** ([LayrzAvatarUrl]): fetches and displays an image from a network URL
/// - **Base64** ([LayrzAvatarBase64]): displays an image from a base64-encoded string
/// - **Icon** ([LayrzAvatarIcon]): renders an icon from [IconData] at 70% of avatar size
/// - **Emoji** ([LayrzAvatarEmoji]): displays a Unicode emoji glyph centered
/// - **Null source** (no [source] provided): displays generated initials from [nameText]
///
/// The avatar is created using either the default constructor (which accepts a [LayrzAvatarSource])
/// or one of the semantic named constructors: `.image()`, `.icon()`, `.emoji()`, or `.initials()`.
///
/// **Container shape** defaults to a rounded box using the `r3` radius token from the theme.
/// The corner radius can be customized via the [borderRadius] parameter. When null (the default),
/// the shape defaults to `context.tokens.radius.r3` (16px). When provided, [borderRadius]
/// replaces (does not augment) the token value. Values at or above `size / 2` render a circle.
/// **Background color** defaults to the primary token color and is ignored behind images.
///
/// **Fixed drop shadow**: Every avatar carries `tokens.shadow.compact1` — the same ramp
/// used by small components like [LayrzButton]. This is intentionally not configurable.
/// The compact shadow ramp was chosen over the elevation ramp because a soft low-offset
/// shadow disappears at avatar sizes; compact shadows provide clear separation even at
/// 40px width. This fixed shadow is applied in all render modes: URL, base64, icon, emoji,
/// and initials.
///
/// **Static display only**: This widget has no interaction callbacks ([onTap], [onLongPress],
/// etc.). Callers who need interactivity should wrap the avatar in a [GestureDetector]
/// or similar widget themselves. This keeps the API minimal and separation of concerns clear.
///
/// **Initials algorithm** (when falling back to text):
/// - Strip all non-alphanumeric characters
/// - If empty, display `"NA"` (Not Available)
/// - If one character, display that character
/// - If two or more characters, display the first two characters in uppercase
///
/// Note: This algorithm is not Unicode-aware (combining characters, non-Latin scripts).
/// It is a known limitation, not a bug to solve. Most real-world use cases involve
/// Latin-script names anyway.
class LayrzAvatar extends StatelessWidget {
  /// Creates a new [LayrzAvatar].
  ///
  /// Renders the avatar described by the [LayrzAvatarSource] object.
  /// Falls back to initials from [nameText] when the source is null.
  /// At least one of [source] or [nameText] should be provided for useful output.
  const LayrzAvatar({
    super.key,
    this.source,
    this.nameText,
    this.size = 40,
    this.color,
    this.borderRadius,
  }) : _imageSource = null,
       _icon = null,
       _emoji = null;

  /// Creates an avatar that displays an image from a URL or base64 source.
  ///
  /// The [imageSource] can be:
  /// - An http(s) URL
  /// - A data-URI with base64 encoding
  /// - A bare base64 string
  ///
  /// See [LayrzImage] for detailed source handling.
  const LayrzAvatar.image({
    super.key,
    required String imageSource,
    this.size = 40,
    this.borderRadius,
  }) : source = null,
       nameText = null,
       color = null,
       // ignore: prefer_initializing_formals
       _imageSource = imageSource,
       _icon = null,
       _emoji = null;

  /// Creates an avatar that displays an icon from an [IconData].
  ///
  /// The icon is rendered at 70% of the avatar [size] to maintain visual balance.
  /// [color] defaults to the primary token color.
  const LayrzAvatar.icon({
    super.key,
    required IconData icon,
    this.size = 40,
    this.color,
    this.borderRadius,
    // ignore: prefer_initializing_formals
  }) : source = null,
       nameText = null,
       _imageSource = null,
       // ignore: prefer_initializing_formals
       _icon = icon,
       _emoji = null;

  /// Creates an avatar that displays a Unicode emoji glyph.
  ///
  /// The emoji is rendered centered and scaled to 60% of the avatar [size].
  /// The background color defaults to white for emoji avatars.
  const LayrzAvatar.emoji({
    super.key,
    required String emoji,
    this.size = 40,
    this.borderRadius,
    // ignore: prefer_initializing_formals
  }) : source = null,
       nameText = null,
       color = null,
       _imageSource = null,
       _icon = null,
       // ignore: prefer_initializing_formals
       _emoji = emoji;

  /// Creates an avatar that displays initials from a name.
  ///
  /// The initials are extracted from [nameText] using the algorithm described
  /// in [LayrzAvatar]'s documentation.
  const LayrzAvatar.initials({
    super.key,
    required this.nameText,
    this.size = 40,
    this.color,
    this.borderRadius,
  }) : source = null,
       _imageSource = null,
       _icon = null,
       _emoji = null;

  /// Avatar source describing what to render.
  ///
  /// When null, falls back to initials from [nameText].
  final LayrzAvatarSource? source;

  /// Name text from which initials are generated when [source] is null.
  ///
  /// If null and no usable source is available, displays `"NA"` as a placeholder.
  final String? nameText;

  /// Width and height of the avatar in logical pixels.
  ///
  /// Defaults to 40. The avatar is always square with rounded corners, so this
  /// single value defines both dimensions.
  final double size;

  /// Background fill color of the avatar.
  ///
  /// Defaults to the primary token color when null. Ignored when rendering an
  /// image (images render on a white background to ensure visibility when the
  /// source has transparency).
  final Color? color;

  /// Corner radius of the avatar in logical pixels.
  ///
  /// When null (the default), the avatar uses the `r3` radius token from the theme.
  /// When provided, this value replaces (rather than augments) the token value.
  /// Values at or above `size / 2` render a circle.
  final double? borderRadius;

  /// For named constructors: the image source (used by `.image()` constructor).
  final String? _imageSource;

  /// For named constructors: the icon to render (used by `.icon()` constructor).
  final IconData? _icon;

  /// For named constructors: the emoji to render (used by `.emoji()` constructor).
  final String? _emoji;

  @override
  Widget build(BuildContext context) {
    // If a named constructor provides a specific rendering, use it
    if (_imageSource case final source?) {
      return _buildContainer(
        context: context,
        backgroundColor: _kWhiteBackground,
        child: LayrzImage(
          source: source,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_icon case final icon?) {
      final defaultColor = color ?? context.tokens.colors.primary;
      return _buildContainer(
        context: context,
        backgroundColor: defaultColor,
        child: Icon(
          icon,
          color: _pickTextColor(defaultColor),
          size: size * 0.7,
        ),
      );
    }

    if (_emoji case final emoji?) {
      return _buildContainer(
        context: context,
        backgroundColor: _kWhiteBackground,
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size * 0.6,
            height: 1.0,
          ),
        ),
      );
    }

    // Resolve from the avatar source
    if (source != null) {
      return _buildFromSource(context);
    }

    // Fall back to initials
    final initials = _generateInitials(nameText);
    final defaultColor = color ?? context.tokens.colors.primary;
    return _buildContainer(
      context: context,
      backgroundColor: defaultColor,
      child: Text(
        initials,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: _pickTextColor(defaultColor),
        ),
      ),
    );
  }

  /// Builds the avatar from the [source] descriptor.
  Widget _buildFromSource(BuildContext context) {
    final src = source!;

    return switch (src) {
      LayrzAvatarUrl(:final url) => _buildContainer(
        context: context,
        backgroundColor: _kWhiteBackground,
        child: LayrzImage(
          source: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
      LayrzAvatarBase64(:final base64) => _buildContainer(
        context: context,
        backgroundColor: _kWhiteBackground,
        child: LayrzImage(
          source: base64,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
      LayrzAvatarIcon(:final icon) => _buildIconContent(context, icon),
      LayrzAvatarEmoji(:final emoji) => _buildContainer(
        context: context,
        backgroundColor: _kWhiteBackground,
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size * 0.6,
            height: 1.0,
          ),
        ),
      ),
    };
  }

  /// Builds the container (surface, clipping, shape).
  ///
  /// The outer container applies the fixed compact-level-1 shadow, ensuring it is
  /// not clipped by the inner [ClipRRect]. The inner container clips to the resolved
  /// radius and applies the background color.
  Widget _buildContainer({
    required BuildContext context,
    required Color backgroundColor,
    required Widget child,
  }) {
    final radius = BorderRadius.circular(borderRadius ?? context.tokens.radius.r3);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: context.tokens.shadow.compact1,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  /// Builds an icon avatar using an [IconData].
  Widget _buildIconContent(BuildContext context, IconData icon) {
    final defaultColor = color ?? context.tokens.colors.primary;
    return _buildContainer(
      context: context,
      backgroundColor: defaultColor,
      child: Icon(
        icon,
        color: _pickTextColor(defaultColor),
        size: size * 0.7,
      ),
    );
  }

  /// Generates initials from a name string.
  ///
  /// Algorithm:
  /// - Strip all non-alphanumeric characters
  /// - Empty result → "NA"
  /// - Single character → that character
  /// - Two or more → first two characters, uppercased
  static String _generateInitials(String? raw) {
    if (raw == null || raw.isEmpty) return 'NA';
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleaned.isEmpty) return 'NA';
    if (cleaned.length == 1) return cleaned;
    return cleaned.substring(0, 2).toUpperCase();
  }

  /// Picks a contrasting text color (black or white) based on background brightness.
  ///
  /// Uses a simple luminance heuristic: if the background is bright, use black;
  /// otherwise, use white. This ensures readability without requiring an explicit
  /// textColor parameter.
  static Color _pickTextColor(Color background) {
    // Extract RGB components using the new Color API
    final r = background.r;
    final g = background.g;
    final b = background.b;

    // Standard relative luminance calculation
    final lum = (0.299 * r + 0.587 * g + 0.114 * b);
    return lum > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }
}
