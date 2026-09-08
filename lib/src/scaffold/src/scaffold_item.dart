import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';

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

  /// The row-level quick actions for this item (e.g. edit, delete).
  ///
  /// When empty (the default), the list row renders exactly as a plain tile with no
  /// trailing action affordance. When non-empty, the list panel reveals these buttons
  /// at the row's trailing edge — on hover for wide/desktop viewports
  /// (`context.isCompact == false`), or after a horizontal swipe for compact/mobile
  /// viewports (`context.isCompact == true`). The row body remains tappable to open
  /// the detail pane in both cases; the actions are an overlay/translation on top of
  /// it, never a resize of the row's own box.
  ///
  /// Prefer the icon-only Fab presentation (`isFab: true`) for these buttons, since the
  /// revealed strip is typically narrow relative to the row.
  final List<LayrzButton> actions;

  /// Creates a new [LayrzScaffoldItem].
  ///
  /// - [key]: The unique identity key for this item. Required. Determines selection persistence.
  /// - [item]: The underlying data item represented by this scaffold item. Required.
  /// - [tile]: The widget to display for this scaffold item in the list. Required.
  /// - [searchableStrings]: The set of strings that can be searched to find this item.
  ///   Defaults to the empty set.
  /// - [actions]: The row-level quick actions revealed at the trailing edge of the list
  ///   row (on hover for desktop, on horizontal swipe for mobile). Defaults to the empty
  ///   list, which renders the row with no action affordance at all.
  const LayrzScaffoldItem({
    required this.key,
    required this.item,
    required this.tile,
    this.searchableStrings = const {},
    this.actions = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayrzScaffoldItem && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
