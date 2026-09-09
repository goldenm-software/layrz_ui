import 'package:flutter/widgets.dart';

/// The semantic category assigned to a lexed span of source code.
///
/// This is deliberately UI- and language-agnostic: it names *what kind of
/// thing* a token is, not how it should look. A [LayrzHighlightStyle] (or a
/// resolver callback) maps each scope to a color/weight/slant elsewhere.
enum LayrzHighlightScope {
  /// Plain, unclassified source text — whitespace, punctuation, or any
  /// character that did not match a grammar rule.
  text,

  /// A reserved word of the language's grammar (e.g. `if`, `def`, `return`).
  keyword,

  /// A name provided by the language's standard environment rather than
  /// user code (e.g. Python's `print`, `len`).
  builtin,

  /// A callable name recognized by the grammar (e.g. an LCL/LML function
  /// such as `GET_SENSOR`).
  function,

  /// A string literal, single-line or multi-line.
  string,

  /// A numeric literal, integer or floating point.
  number,

  /// A comment, from its opening marker to the end of its extent.
  comment,

  /// A named constant literal (e.g. `True`, `False`, `None`).
  constant,

  /// A decorator annotation (e.g. Python's `@staticmethod`).
  decorator,

  /// A template/interpolation variable, e.g. LML mustache `{{...}}`.
  variable,
}

/// A single classified span of source text.
///
/// [start] and [end] are character offsets into the original source string,
/// with [start] inclusive and [end] exclusive — the same convention as
/// [String.substring]. Tokens produced by `LayrzSyntaxHighlighter.tokenize`
/// are non-overlapping and cover the entire input in source order.
@immutable
class LayrzHighlightToken {
  /// The semantic category this span was classified as.
  final LayrzHighlightScope scope;

  /// The inclusive start offset of this token within the source string.
  final int start;

  /// The exclusive end offset of this token within the source string.
  final int end;

  /// Creates a new [LayrzHighlightToken] spanning `[start, end)` of the
  /// source string and classified as [scope].
  const LayrzHighlightToken({
    required this.scope,
    required this.start,
    required this.end,
  });

  /// The number of characters this token spans (`end - start`).
  int get length => end - start;

  /// Returns a copy of this token with the given fields replaced.
  LayrzHighlightToken copyWith({
    LayrzHighlightScope? scope,
    int? start,
    int? end,
  }) {
    return LayrzHighlightToken(
      scope: scope ?? this.scope,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzHighlightToken &&
          runtimeType == other.runtimeType &&
          scope == other.scope &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(scope, start, end);

  @override
  String toString() => 'LayrzHighlightToken(scope: $scope, start: $start, end: $end)';
}
