import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Internal cache for decoded base64 bytes, keyed by source hash.
///
/// This avoids re-decoding identical base64 payloads across multiple renders
/// (e.g., when an avatar appears in a list). The cache is bounded to prevent
/// unbounded memory growth.
final Map<int, Uint8List> _imageSourceCache = {};

/// Maximum number of entries to keep in the decoded-bytes cache.
///
/// When the cache exceeds this size, the oldest entry (by insertion order)
/// is evicted. A cap of 50 provides a reasonable balance: most UIs won't
/// have more than 50 unique avatar images loaded at once.
const int _maxCacheSize = 50;

/// Clears all entries from the decoded-bytes cache.
///
/// This is a no-op on an empty cache. Intended for testing to ensure
/// test isolation when repeated cache hits matter.
@visibleForTesting
void clearImageSourceCache() {
  _imageSourceCache.clear();
}

/// Determines if a source string is an SVG (vector graphic).
///
/// SVG is detected in two ways:
/// 1. The path ends with `.svg` (asset or network URL paths).
/// 2. The MIME type in a data-URI is `image/svg+xml` (e.g., `data:image/svg+xml;base64,...`).
///
/// Returns false if the source cannot be meaningfully classified (e.g., null or empty).
bool isSvgSource(String? source) {
  if (source == null || source.isEmpty) return false;

  // Check extension (works for paths and URLs)
  if (source.endsWith('.svg')) return true;

  // Check data-URI MIME type
  if (source.startsWith('data:image/svg+xml')) return true;

  return false;
}

/// Determines if a source string is a network URL.
///
/// Network URLs start with `http://` or `https://`.
bool isNetworkSource(String? source) {
  if (source == null || source.isEmpty) return false;
  return source.startsWith('http://') || source.startsWith('https://');
}

/// Determines if a source string is a data-URI.
///
/// Data-URIs start with `data:`. This includes:
/// - Base64: `data:image/png;base64,...`
/// - SVG: `data:image/svg+xml;base64,...` or `data:image/svg+xml,...`
bool isDataUriSource(String? source) {
  if (source == null || source.isEmpty) return false;
  return source.startsWith('data:');
}

/// Determines if a source string appears to be bare base64 (no `data:` prefix).
///
/// **Rule**: A string is considered bare base64 if:
/// - It does NOT start with `http://`, `https://`, or `data:`
/// - It does NOT end with `.svg`
/// - It contains only base64-safe characters: `[A-Za-z0-9+/=]`
///
/// This heuristic is intentionally conservative: it does not attempt to
/// distinguish bare base64 from asset paths with absolute certainty
/// (both are alphanumeric). However, asset paths in Flutter typically:
/// - Contain forward slashes (`assets/images/avatar.png`)
/// - Rarely contain only base64-safe chars without slashes
///
/// If a source matches this heuristic, it is treated as bare base64.
/// If decoding fails, the error is caught and the source is treated as an asset.
bool isLikelyBase64(String? source) {
  if (source == null || source.isEmpty) return false;

  // Exclude obvious non-base64 sources
  if (source.startsWith('http://') || source.startsWith('https://') || source.startsWith('data:')) {
    return false;
  }
  if (source.endsWith('.svg')) {
    return false;
  }

  // Asset paths contain slashes; bare base64 typically does not
  if (source.contains('/')) {
    return false;
  }

  // Check if the source contains only base64-safe characters
  return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(source);
}

/// Decodes a base64 string (with or without the `data:` prefix).
///
/// Handles both:
/// - Full data-URI: `data:image/png;base64,<base64>`
/// - Bare base64: `<base64>`
///
/// The decoded bytes are cached by source hash to avoid re-decoding identical
/// payloads. The cache is bounded; when full, the oldest entry is evicted.
///
/// Throws [FormatException] if the base64 payload is malformed.
Uint8List decodeBase64Source(String source) {
  final hash = source.hashCode;

  // Return cached bytes if available
  if (_imageSourceCache.containsKey(hash)) {
    return _imageSourceCache[hash]!;
  }

  // Extract the actual base64 string
  String base64String = source;
  if (source.startsWith('data:')) {
    // Split on the last comma to handle MIME types with semicolons
    final parts = source.split(',');
    if (parts.length != 2) {
      throw FormatException('Invalid data-URI: expected format data:mime;base64,<base64>');
    }
    base64String = parts[1];
  }

  // Decode the base64 string
  final bytes = base64Decode(base64String);

  // Store in cache with eviction if necessary
  if (_imageSourceCache.length >= _maxCacheSize) {
    // Evict the first (oldest) entry
    _imageSourceCache.remove(_imageSourceCache.keys.first);
  }
  _imageSourceCache[hash] = bytes;

  return bytes;
}

/// Extracts the MIME type from a data-URI.
///
/// For example, `data:image/png;base64,...` returns `image/png`.
/// If the format is invalid or no MIME type is found, returns an empty string.
String getMimeTypeFromDataUri(String source) {
  if (!source.startsWith('data:')) return '';

  try {
    // Remove 'data:' prefix
    final afterData = source.substring(5);
    // Split on comma to get the metadata part
    final metaPart = afterData.split(',')[0];
    // Extract MIME type (before semicolon, if any)
    final mimeType = metaPart.split(';')[0];
    return mimeType;
  } catch (e) {
    return '';
  }
}
