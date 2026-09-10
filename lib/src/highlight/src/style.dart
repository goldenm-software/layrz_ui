import 'package:flutter/widgets.dart';

/// A font-agnostic visual style for a [LayrzHighlightScope].
///
/// This intentionally does not wrap or expose a [TextStyle] — the engine
/// module stays free of any assumption about which font, size, or theme is
/// in use. A consumer (a widget, a theme extension) is responsible for
/// turning this into a [TextStyle] via `TextStyle(...).merge(...)` or
/// equivalent.
@immutable
class LayrzHighlightStyle {
  /// The color applied to text carrying this style.
  final Color color;

  /// Whether text carrying this style is rendered in bold weight.
  final bool bold;

  /// Whether text carrying this style is rendered in italic slant.
  final bool italic;

  /// Creates a new [LayrzHighlightStyle].
  ///
  /// [color] is required; [bold] and [italic] both default to `false`.
  const LayrzHighlightStyle({
    required this.color,
    this.bold = false,
    this.italic = false,
  });

  /// Returns a copy of this style with the given fields replaced.
  LayrzHighlightStyle copyWith({
    Color? color,
    bool? bold,
    bool? italic,
  }) {
    return LayrzHighlightStyle(
      color: color ?? this.color,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzHighlightStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          bold == other.bold &&
          italic == other.italic;

  @override
  int get hashCode => Object.hash(color, bold, italic);

  @override
  String toString() => 'LayrzHighlightStyle(color: $color, bold: $bold, italic: $italic)';
}
