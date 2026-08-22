import 'package:flutter/widgets.dart';

/// A class representing an item in the Layrz scaffold.
class LayrzScaffoldItem<T> {
  /// The underlying data item represented by this scaffold item.
  final T item;

  /// The widget to display for this scaffold item.
  final Widget tile;

  /// The set of strings that can be searched to find this item.
  final Set<String> searchableStrings;

  /// Creates a new [LayrzScaffoldItem].
  ///
  /// This constructor requires the [item], [tile], and [searchableStrings] parameters to be provided.
  LayrzScaffoldItem({
    required this.item,
    required this.tile,
    this.searchableStrings = const {},
  });
}
