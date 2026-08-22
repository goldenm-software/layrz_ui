import 'package:flutter/widgets.dart';

/// A stable registry entry for one input component in the showroom.
///
/// Each demo is identified by a unique [id], has a human-readable [name],
/// belongs to a [category], and provides a [detailsBuilder] that renders
/// all variants of that component.
@immutable
final class InputDemo {
  /// A stable, unique identifier for this input component.
  /// Used to track selection and preserve state across rebuilds.
  final String id;

  /// The human-readable name of this input component.
  /// E.g., "Text Input", "Number Input", "Radio Input".
  final String name;

  /// The category this component belongs to.
  /// Categories: "Text", "Numeric", "Boolean", "Choice", "Search", "Flow".
  final String category;

  /// Builder for the detail pane content.
  /// Receives the context and is responsible for rendering all meaningful
  /// variants of this input component.
  final Widget Function(BuildContext) detailsBuilder;

  /// Creates a new [InputDemo].
  const InputDemo({
    required this.id,
    required this.name,
    required this.category,
    required this.detailsBuilder,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputDemo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category;

  @override
  int get hashCode => Object.hash(id, name, category);
}
