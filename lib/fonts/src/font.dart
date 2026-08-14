import 'package:flutter/foundation.dart';

/// Where the bytes of a [LayrzFont] come from.
enum LayrzFontSource {
  /// Fetched from Google Fonts at runtime by family name.
  google,

  /// Already registered with the engine via the app's pubspec `fonts:` section.
  local,

  /// Downloaded from an arbitrary URL as a raw font file.
  uri,
}

/// An immutable representation of a font resource with its source and identity.
///
/// A font is identified by its [name] (the family name) and [source] (where the bytes come from).
/// Only fonts with [LayrzFontSource.uri] may have a [uri] set.
@immutable
class LayrzFont {
  /// Creates a new [LayrzFont].
  ///
  /// The [uri] parameter is only meaningful when [source] is [LayrzFontSource.uri];
  /// an assertion will fail if [uri] is null when [source] is [LayrzFontSource.uri].
  const LayrzFont({required this.source, required this.name, this.uri})
    : assert(
        source != LayrzFontSource.uri || uri != null,
        'uri must be non-null when source is LayrzFontSource.uri',
      );

  /// Where the bytes of this font come from.
  final LayrzFontSource source;

  /// The font family name.
  final String name;

  /// The URL to fetch the raw font file from, only set when [source] is [LayrzFontSource.uri].
  final String? uri;

  /// Creates a copy of this [LayrzFont] with the given fields replaced.
  LayrzFont copyWith({LayrzFontSource? source, String? name, String? uri}) {
    return LayrzFont(
      source: source ?? this.source,
      name: name ?? this.name,
      uri: uri ?? this.uri,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzFont &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          name == other.name &&
          uri == other.uri;

  @override
  int get hashCode => Object.hash(source, name, uri);

  @override
  String toString() => 'LayrzFont(source: $source, name: $name, uri: $uri)';
}

/// The default font name for the Layrz design system.
const String kLayrzFontName = 'Open Sans';

/// The Layrz brand default font.
const LayrzFont kLayrzFont = LayrzFont(
  source: LayrzFontSource.google,
  name: kLayrzFontName,
);

/// Font families tried in order when the requested family fails to resolve.
const List<String> kLayrzFontFallbacks = <String>['Ubuntu', 'Roboto'];
