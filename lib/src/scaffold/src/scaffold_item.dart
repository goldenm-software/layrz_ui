import 'package:flutter/widgets.dart';

/// A class representing an item in the Layrz scaffold.
///
/// Each item carries its own identity key, the data it represents, a pre-built tile widget,
/// and a set of searchable strings for filtering.
@immutable
class LayrzScaffoldItem<T> {
  /// The unique identity key for this item.
  ///
  /// This key is used to track selection state independently of the item's data instance.
  /// When you rebuild the list with new item instances (e.g., refetched from an API),
  /// the selection state persists if the key remains the same — making selection immune
  /// to instance inequality.
  final Key key;

  /// The underlying data item represented by this scaffold item.
  final T item;

  /// The widget to display for this scaffold item in the list.
  final Widget tile;

  /// The set of strings that can be searched to find this item.
  ///
  /// Search queries are matched case-insensitively as substrings against any of these strings.
  /// An empty set makes the item unsearchable.
  final Set<String> searchableStrings;

  /// Creates a new [LayrzScaffoldItem].
  ///
  /// - [key]: The unique identity key for this item. Required. Determines selection persistence.
  /// - [item]: The underlying data item represented by this scaffold item. Required.
  /// - [tile]: The widget to display for this scaffold item in the list. Required.
  /// - [searchableStrings]: The set of strings that can be searched to find this item.
  ///   Defaults to the empty set.
  const LayrzScaffoldItem({
    required this.key,
    required this.item,
    required this.tile,
    this.searchableStrings = const {},
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayrzScaffoldItem && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
