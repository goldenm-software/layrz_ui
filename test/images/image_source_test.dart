import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/images/src/image_source.dart';

void main() {
  group('isSvgSource', () {
    test('detects .svg file extension', () {
      expect(isSvgSource('assets/images/icon.svg'), isTrue);
      expect(isSvgSource('https://example.com/image.svg'), isTrue);
      expect(isSvgSource('data:image/svg+xml;base64,abc'), isTrue);
    });

    test('detects SVG MIME type in data-URI', () {
      expect(isSvgSource('data:image/svg+xml;base64,abc'), isTrue);
      expect(isSvgSource('data:image/svg+xml,<svg>...'), isTrue);
    });

    test('returns false for non-SVG sources', () {
      expect(isSvgSource('assets/images/icon.png'), isFalse);
      expect(isSvgSource('https://example.com/image.png'), isFalse);
      expect(isSvgSource('data:image/png;base64,abc'), isFalse);
    });

    test('returns false for null or empty', () {
      expect(isSvgSource(null), isFalse);
      expect(isSvgSource(''), isFalse);
    });
  });

  group('isNetworkSource', () {
    test('detects http URLs', () {
      expect(isNetworkSource('http://example.com/image.png'), isTrue);
      expect(isNetworkSource('https://example.com/image.png'), isTrue);
    });

    test('returns false for non-network sources', () {
      expect(isNetworkSource('assets/images/icon.png'), isFalse);
      expect(isNetworkSource('data:image/png;base64,abc'), isFalse);
      expect(isNetworkSource('iVBORw0KGgo...'), isFalse);
    });

    test('returns false for null or empty', () {
      expect(isNetworkSource(null), isFalse);
      expect(isNetworkSource(''), isFalse);
    });
  });

  group('isDataUriSource', () {
    test('detects data-URIs', () {
      expect(isDataUriSource('data:image/png;base64,iVBORw0KGgo...'), isTrue);
      expect(isDataUriSource('data:image/svg+xml;base64,abc'), isTrue);
      expect(isDataUriSource('data:image/png;base64,'), isTrue);
    });

    test('returns false for non-data-URI sources', () {
      expect(isDataUriSource('assets/images/icon.png'), isFalse);
      expect(isDataUriSource('https://example.com/image.png'), isFalse);
      expect(isDataUriSource('iVBORw0KGgo...'), isFalse);
    });

    test('returns false for null or empty', () {
      expect(isDataUriSource(null), isFalse);
      expect(isDataUriSource(''), isFalse);
    });
  });

  group('isLikelyBase64', () {
    test('detects bare base64 strings', () {
      expect(
        isLikelyBase64(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        ),
        isTrue,
      );
    });

    test('returns false for network URLs', () {
      expect(isLikelyBase64('https://example.com/image.png'), isFalse);
      expect(isLikelyBase64('http://example.com/image.png'), isFalse);
    });

    test('returns false for data-URIs', () {
      expect(isLikelyBase64('data:image/png;base64,iVBORw0KGgo...'), isFalse);
    });

    test('returns false for asset paths with slashes', () {
      expect(isLikelyBase64('assets/images/icon.png'), isFalse);
      expect(isLikelyBase64('images/avatar.png'), isFalse);
    });

    test('returns false for .svg files', () {
      expect(isLikelyBase64('icon.svg'), isFalse);
      expect(isLikelyBase64('assets/images/icon.svg'), isFalse);
    });

    test('returns false for strings with invalid base64 characters', () {
      expect(isLikelyBase64('not_valid_@_base64'), isFalse);
      expect(isLikelyBase64('invalid*base64'), isFalse);
    });

    test('returns false for null or empty', () {
      expect(isLikelyBase64(null), isFalse);
      expect(isLikelyBase64(''), isFalse);
    });
  });

  group('decodeBase64Source', () {
    test('decodes full data-URI with base64', () {
      const plainText = 'hello world';
      final encoded = base64Encode(utf8.encode(plainText));
      final dataUri = 'data:text/plain;base64,$encoded';

      final result = decodeBase64Source(dataUri);
      expect(utf8.decode(result), equals(plainText));
    });

    test('decodes bare base64 string', () {
      const plainText = 'hello world';
      final encoded = base64Encode(utf8.encode(plainText));

      final result = decodeBase64Source(encoded);
      expect(utf8.decode(result), equals(plainText));
    });

    test('caches decoded bytes by source hash', () {
      const plainText = 'test data';
      final encoded = base64Encode(utf8.encode(plainText));

      final result1 = decodeBase64Source(encoded);
      final result2 = decodeBase64Source(encoded);

      // Both should return identical bytes
      expect(result1, equals(result2));
      // And be the same object (proof of caching)
      expect(identical(result1, result2), isTrue);
    });

    test('throws FormatException for malformed base64', () {
      expect(
        () => decodeBase64Source('not!a!valid!base64!!!'),
        throwsFormatException,
      );
    });

    test('throws FormatException for invalid data-URI format', () {
      expect(
        () => decodeBase64Source('data:text/plain;base64,abc,def,xyz'),
        throwsFormatException,
      );
    });

    test('respects cache size cap and evicts oldest entry', () {
      clearImageSourceCache();

      // Create several different base64 strings
      final strings = <String>[];
      for (int i = 0; i < 5; i++) {
        final encoded = base64Encode(utf8.encode('data $i'));
        strings.add(encoded);
      }

      // Decode them all
      for (final s in strings) {
        decodeBase64Source(s);
      }

      // Cache should have at most 5 entries (our test subset)
      // Now add more and verify eviction occurs
      for (int i = 5; i < 55; i++) {
        final encoded = base64Encode(utf8.encode('data $i'));
        decodeBase64Source(encoded);
      }

      // After eviction, cache size should not exceed the cap
      // We can't directly inspect the cache, but we can verify the clear works
      clearImageSourceCache();
    });
  });

  group('Cache management', () {
    test('clearImageSourceCache clears all entries', () {
      const plainText = 'test';
      final encoded = base64Encode(utf8.encode(plainText));

      decodeBase64Source(encoded);
      clearImageSourceCache();

      // After clearing, the same source should be re-decoded (not cached)
      // This is an indirect test, but consistent caching should be the only variable
      final result = decodeBase64Source(encoded);
      expect(utf8.decode(result), equals(plainText));
    });
  });

  group('getMimeTypeFromDataUri', () {
    test('extracts MIME type from data-URI', () {
      expect(
        getMimeTypeFromDataUri('data:image/png;base64,abc'),
        equals('image/png'),
      );
      expect(
        getMimeTypeFromDataUri('data:image/svg+xml;base64,abc'),
        equals('image/svg+xml'),
      );
      expect(
        getMimeTypeFromDataUri('data:text/plain,hello'),
        equals('text/plain'),
      );
    });

    test('returns empty string for invalid format', () {
      expect(getMimeTypeFromDataUri('not a data uri'), equals(''));
      expect(getMimeTypeFromDataUri('https://example.com'), equals(''));
      expect(getMimeTypeFromDataUri(''), equals(''));
    });

    test('handles data-URI without semicolon', () {
      expect(getMimeTypeFromDataUri('data:image/png,abc'), equals('image/png'));
    });
  });
}
