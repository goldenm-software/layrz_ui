import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'image_source.dart';

/// A Material-free image widget that displays raster and vector images.
///
/// [LayrzImage] resolves multiple source formats and routes rendering to the
/// appropriate widget:
/// - **Network URLs** (`http://`, `https://`) → `Image.network` or `SvgPicture.network`
/// - **Data-URIs** (`data:...`) → decoded bytes → `Image.memory` or `SvgPicture.memory`
/// - **Base64 without prefix** (bare base64) → decoded bytes → `Image.memory`
/// - **Asset paths** (anything else) → `Image.asset` or `SvgPicture.asset`
///
/// **SVG detection**: A source is treated as SVG if the path ends with `.svg`
/// or the data-URI MIME type is `image/svg+xml`.
///
/// **Placeholders and fallbacks**:
/// - [placeholder] is shown while a network image is loading.
/// - [fallback] is shown if the source cannot be fetched or decoded (malformed
///   base64, missing asset, network error, etc.).
///
/// **Base64 handling**: Both full data-URIs (`data:image/png;base64,...`) and
/// bare base64 strings are accepted. Malformed base64 raises no exception in
/// `build()`; instead, [fallback] is displayed.
///
/// **Decoded-bytes cache**: Base64 payloads are cached by source hash to avoid
/// redundant decoding in lists or repeated renders. The cache is bounded (50 entries)
/// and uses LRU-like eviction.
class LayrzImage extends StatelessWidget {
  /// Creates a new [LayrzImage].
  ///
  /// The [source] must be one of: an http(s) URL, a data-URI, a bare base64 string,
  /// or an asset path. At least one of [width] or [height] should be specified,
  /// or the image will expand to fill available space.
  const LayrzImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.placeholder,
    this.fallback,
  });

  /// Image location: an http(s) URL, a `data:` URI, a bare base64 payload, or an asset path.
  ///
  /// Examples:
  /// - `https://example.com/image.png`
  /// - `data:image/png;base64,iVBORw0KGgo...`
  /// - `iVBORw0KGgo...` (bare base64, without `data:` prefix)
  /// - `assets/images/avatar.png`
  final String source;

  /// The width of the displayed image in logical pixels.
  ///
  /// When null, the image width is unconstrained. At least one of [width]
  /// or [height] should be specified to avoid unexpected sizing.
  final double? width;

  /// The height of the displayed image in logical pixels.
  ///
  /// When null, the image height is unconstrained. At least one of [width]
  /// or [height] should be specified to avoid unexpected sizing.
  final double? height;

  /// How the image should be fitted within its bounds.
  ///
  /// Defaults to [BoxFit.cover], which crops the image to fill the space while
  /// maintaining aspect ratio. See [BoxFit] for other options.
  final BoxFit fit;

  /// The alignment of the image within its bounding box.
  ///
  /// Defaults to [Alignment.center]. Affects how the image is positioned when
  /// the fit does not fill the entire bounds.
  final Alignment alignment;

  /// The quality used when resampling the image.
  ///
  /// Defaults to [FilterQuality.medium]. Use [FilterQuality.high] for better
  /// quality at the cost of slight performance overhead, or [FilterQuality.low]
  /// for faster rendering on low-end devices.
  final FilterQuality filterQuality;

  /// Widget shown while a network image is loading.
  ///
  /// Only applies to network sources (URLs starting with `http://` or `https://`).
  /// Ignored for asset and data-URI sources, which load synchronously or nearly so.
  /// When null, a blank area is shown during loading.
  final Widget? placeholder;

  /// Widget shown when the source cannot be fetched or decoded.
  ///
  /// This includes:
  /// - Network errors (404, timeout, connection failure, etc.)
  /// - Malformed base64 strings
  /// - Missing asset files
  /// - Unsupported image formats
  ///
  /// When null, a blank area is shown on error.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    // Determine source type and route to appropriate rendering logic
    if (isSvgSource(source)) {
      return _buildSvg();
    }
    return _buildRaster();
  }

  /// Builds an SVG image using [SvgPicture].
  Widget _buildSvg() {
    if (isNetworkSource(source)) {
      return SvgPicture.network(
        source,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        placeholderBuilder: placeholder != null ? (_) => placeholder! : null,
      );
    }

    if (isDataUriSource(source)) {
      return _buildSvgFromDataUri();
    }

    // Asset path
    return SvgPicture.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
    );
  }

  /// Builds an SVG image from a data-URI by decoding base64 bytes.
  Widget _buildSvgFromDataUri() {
    try {
      final bytes = decodeBase64Source(source);
      return SvgPicture.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      );
    } catch (e) {
      return fallback ?? const SizedBox.shrink();
    }
  }

  /// Builds a raster image using [Image] and related providers.
  Widget _buildRaster() {
    if (isNetworkSource(source)) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        loadingBuilder: placeholder != null
            ? (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder!;
              }
            : null,
        errorBuilder: (context, error, stackTrace) => fallback ?? const SizedBox.shrink(),
      );
    }

    if (isDataUriSource(source) || isLikelyBase64(source)) {
      return _buildRasterFromDataOrBase64();
    }

    // Asset path
    return Image.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stackTrace) => fallback ?? const SizedBox.shrink(),
    );
  }

  /// Builds a raster image from a data-URI or bare base64 by decoding bytes.
  Widget _buildRasterFromDataOrBase64() {
    try {
      final bytes = decodeBase64Source(source);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        errorBuilder: (context, error, stackTrace) => fallback ?? const SizedBox.shrink(),
      );
    } catch (e) {
      return fallback ?? const SizedBox.shrink();
    }
  }
}
