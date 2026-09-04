import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Lookup table from a lowercase file extension (without the leading dot) to
/// its MIME type.
///
/// `file_picker`'s [PlatformFile][] carries no MIME type of its own -- only a
/// [name] and an [extension] getter derived from it -- so [LayrzFileInputResult]
/// infers the MIME type from the extension using this table. Extensions not
/// present here fall back to `application/octet-stream` (see
/// [mimeTypeForExtension]).
///
/// This intentionally covers only the common web/image/document formats a
/// file drop-zone is likely to see; it is not an exhaustive MIME registry.
///
/// [PlatformFile]: https://pub.dev/documentation/file_picker/latest/file_picker/PlatformFile-class.html
const Map<String, String> kFileExtensionMimeTypes = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'bmp': 'image/bmp',
  'svg': 'image/svg+xml',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'csv': 'text/csv',
  'json': 'application/json',
  'xml': 'application/xml',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'zip': 'application/zip',
  'mp4': 'video/mp4',
  'mp3': 'audio/mpeg',
};

/// Resolves the MIME type for a lowercase file [extension] (without the
/// leading dot), falling back to `application/octet-stream` when the
/// extension is unrecognized or null.
///
/// See [kFileExtensionMimeTypes] for the covered extensions.
String mimeTypeForExtension(String? extension) {
  if (extension == null) return 'application/octet-stream';
  return kFileExtensionMimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
}

/// Returns whether [mimeType] identifies an image format (`image/*`).
///
/// Used by [LayrzFileInputPreview] to decide between an image thumbnail and
/// a generic name+icon chip.
bool isImageMimeType(String mimeType) => mimeType.startsWith('image/');

/// An immutable, picked-or-dropped file, as produced by [LayrzFileInput].
///
/// Mirrors the shape of `lib/src/images/src/image_source.dart`'s base64
/// handling: [dataUri] carries the same `data:<mime>;base64,<payload>` format
/// consumed there and by [LayrzImage], so a result's [dataUri] can be passed
/// directly as a [LayrzImage.source]. [bytes] is kept alongside it so callers
/// that need raw bytes (e.g. for direct upload) are not forced to re-decode
/// [dataUri] themselves.
///
/// Two results are equal when their [name], [mimeType], and [bytes] content
/// are all equal -- [dataUri] is derived from those and never compared
/// directly, since it is always redundant with them.
@immutable
class LayrzFileInputResult {
  /// The original file name, including its extension (e.g. `photo.png`).
  final String name;

  /// The resolved MIME type (e.g. `image/png`), inferred from the file's
  /// extension via [mimeTypeForExtension] when the source does not supply
  /// one directly.
  final String mimeType;

  /// The raw, decoded file bytes.
  final Uint8List bytes;

  /// The file size in bytes, equal to `bytes.length`.
  int get size => bytes.length;

  /// Whether this file is an image, per [isImageMimeType] on [mimeType].
  ///
  /// [LayrzFileInputPreview] uses this to choose between an image thumbnail
  /// and a generic name+icon chip.
  bool get isImage => isImageMimeType(mimeType);

  /// The file encoded as a `data:<mimeType>;base64,<payload>` URI.
  ///
  /// Computed once at construction time (see the constructor), since this
  /// class is immutable -- there is no later point at which [bytes] or
  /// [mimeType] could change to invalidate a cached value.
  final String dataUri;

  /// Creates a new [LayrzFileInputResult].
  ///
  /// [name] is the original file name including extension. [mimeType] is the
  /// resolved MIME type -- callers reading from `file_picker`'s
  /// `PlatformFile` should resolve it via [mimeTypeForExtension] on
  /// `PlatformFile.extension` before constructing this. [bytes] are the raw
  /// decoded file contents. [dataUri] is derived eagerly from [mimeType] and
  /// [bytes] -- base64-encoding happens once here rather than being deferred
  /// and repeated on every access.
  LayrzFileInputResult({
    required this.name,
    required this.mimeType,
    required this.bytes,
  }) : dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';

  /// Returns this file's raw, decoded content as a [Uint8List].
  ///
  /// A typed accessor equivalent to reading [bytes] directly -- provided so
  /// callers converting a [LayrzFileInputResult] (e.g. for a direct upload)
  /// have an explicit, discoverable conversion method alongside [toDataUri]
  /// rather than reaching for the field by name.
  Uint8List toBytes() => bytes;

  /// Returns this file encoded as a `data:<mimeType>;base64,<payload>` URI.
  ///
  /// Equivalent to reading [dataUri] directly -- provided as an explicit
  /// conversion method alongside [toBytes]. The value is already computed
  /// eagerly at construction time (see [dataUri]'s own doc), so this performs
  /// no extra encoding work.
  String toDataUri() => dataUri;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzFileInputResult &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          mimeType == other.mimeType &&
          listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hash(name, mimeType, Object.hashAll(bytes));

  @override
  String toString() => 'LayrzFileInputResult(name: $name, mimeType: $mimeType, size: $size bytes)';
}
