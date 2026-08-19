import 'package:flutter/widgets.dart';

/// An immutable item model for [LayrzScaffoldShell].
///
/// [LayrzScaffoldItem] represents a single row in the scaffold's list panel.
/// Each item has a stable identity ([id]), display properties ([title], [subtitle], [icon]),
/// optional visual styling ([tint]), and optional grouping ([group]).
@immutable
class LayrzScaffoldItem {
  /// Creates a new [LayrzScaffoldItem].
  ///
  /// The [id] and [title] are required. All other fields are optional.
  const LayrzScaffoldItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.tint,
    this.group,
  });

  /// The stable identifier for this item.
  ///
  /// This value is used to track which item is selected. Identity is based
  /// on [id], not object reference.
  final String id;

  /// The primary display text for this item.
  final String title;

  /// Optional secondary text displayed below the title.
  ///
  /// When non-null, this text is rendered on a single line below [title]
  /// with `TextOverflow.ellipsis` applied. Defaults to null.
  final String? subtitle;

  /// Optional icon to display in the item's icon tile.
  ///
  /// When non-null, this icon is rendered in a 20×20 tile. When null,
  /// the tile shows empty. Defaults to null.
  final IconData? icon;

  /// Optional tint color for the icon tile background.
  ///
  /// When non-null, the icon tile background is filled with this color.
  /// When null, defaults to the `colors.surface3` token. Defaults to null.
  final Color? tint;

  /// Optional grouping key for the list panel.
  ///
  /// When non-null, this item is grouped under a sticky header with this key.
  /// Items with the same [group] value are displayed together under a shared header.
  /// When null, the item is placed in an ungrouped trailing run with no header.
  /// Defaults to null.
  final String? group;

  /// Creates a copy of this [LayrzScaffoldItem] with the given fields replaced.
  LayrzScaffoldItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? tint,
    String? group,
  }) {
    return LayrzScaffoldItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      tint: tint ?? this.tint,
      group: group ?? this.group,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzScaffoldItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          subtitle == other.subtitle &&
          icon == other.icon &&
          tint == other.tint &&
          group == other.group;

  @override
  int get hashCode => Object.hash(id, title, subtitle, icon, tint, group);

  @override
  String toString() =>
      'LayrzScaffoldItem(id: $id, title: $title, subtitle: $subtitle, icon: $icon, tint: $tint, group: $group)';
}
