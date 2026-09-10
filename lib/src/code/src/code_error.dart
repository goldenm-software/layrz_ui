import 'package:flutter/widgets.dart';

/// A single diagnostic reported against a position in a code snippet.
///
/// This is a transport-shaped model for backend/compiler diagnostics — a
/// linter, a syntax checker, or a language runtime — surfaced by a code
/// widget as a gutter marker, an underline, or an inline annotation. It
/// carries only where the error is and what it says; how it is drawn is
/// entirely up to the consuming widget/theme.
@immutable
class LayrzCodeError {
  /// The 1-based line number the error is reported against.
  ///
  /// Follows the backend convention of counting lines from `1`, not `0` —
  /// matching how compilers, linters, and most editors report positions.
  final int line;

  /// The 1-based column number the error is reported against.
  ///
  /// Follows the backend convention of counting columns from `1`, not `0`.
  final int column;

  /// The human-readable diagnostic message describing the error.
  final String message;

  /// Creates a new [LayrzCodeError].
  ///
  /// All fields are required: [line] and [column] are 1-based positions,
  /// and [message] is the human-readable text to display for it.
  const LayrzCodeError({
    required this.line,
    required this.column,
    required this.message,
  });

  /// Returns a copy of this error with the given fields replaced.
  ///
  /// Any field omitted (or passed as `null`) keeps its current value.
  LayrzCodeError copyWith({
    int? line,
    int? column,
    String? message,
  }) {
    return LayrzCodeError(
      line: line ?? this.line,
      column: column ?? this.column,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzCodeError &&
          runtimeType == other.runtimeType &&
          line == other.line &&
          column == other.column &&
          message == other.message;

  @override
  int get hashCode => Object.hash(line, column, message);

  @override
  String toString() => 'LayrzCodeError(line: $line, column: $column, message: $message)';
}
