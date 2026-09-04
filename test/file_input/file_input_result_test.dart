import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('mimeTypeForExtension', () {
    test('resolves known extensions case-insensitively', () {
      expect(mimeTypeForExtension('png'), 'image/png');
      expect(mimeTypeForExtension('PNG'), 'image/png');
      expect(mimeTypeForExtension('jpg'), 'image/jpeg');
      expect(mimeTypeForExtension('jpeg'), 'image/jpeg');
      expect(mimeTypeForExtension('pdf'), 'application/pdf');
    });

    test('falls back to application/octet-stream for unknown extensions', () {
      expect(mimeTypeForExtension('xyz'), 'application/octet-stream');
    });

    test('falls back to application/octet-stream for null extension', () {
      expect(mimeTypeForExtension(null), 'application/octet-stream');
    });
  });

  group('isImageMimeType', () {
    test('returns true for image/* types', () {
      expect(isImageMimeType('image/png'), isTrue);
      expect(isImageMimeType('image/svg+xml'), isTrue);
    });

    test('returns false for non-image types', () {
      expect(isImageMimeType('application/pdf'), isFalse);
      expect(isImageMimeType('text/plain'), isFalse);
    });
  });

  group('LayrzFileInputResult', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    test('computes size from bytes length', () {
      final result = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      expect(result.size, 4);
    });

    test('isImage reflects the mime type', () {
      final image = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      final doc = LayrzFileInputResult(name: 'a.pdf', mimeType: 'application/pdf', bytes: bytes);
      expect(image.isImage, isTrue);
      expect(doc.isImage, isFalse);
    });

    test('dataUri encodes mimeType and base64 bytes correctly', () {
      final result = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      expect(result.dataUri, 'data:image/png;base64,${base64Encode(bytes)}');
    });

    test('equal when name, mimeType, and bytes content match', () {
      final a = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      final b = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: Uint8List.fromList([1, 2, 3, 4]));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when bytes content differs', () {
      final a = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      final b = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: Uint8List.fromList([9, 9, 9, 9]));
      expect(a, isNot(equals(b)));
    });

    test('not equal when name differs', () {
      final a = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      final b = LayrzFileInputResult(name: 'b.png', mimeType: 'image/png', bytes: bytes);
      expect(a, isNot(equals(b)));
    });

    test('toString includes name, mimeType, and size', () {
      final result = LayrzFileInputResult(name: 'a.png', mimeType: 'image/png', bytes: bytes);
      final str = result.toString();
      expect(str, contains('a.png'));
      expect(str, contains('image/png'));
      expect(str, contains('4 bytes'));
    });
  });
}
