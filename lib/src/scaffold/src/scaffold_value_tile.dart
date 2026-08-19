import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/menus/src/dropdown_items.dart';

import 'scaffold_tile.dart';

/// A [LayrzScaffoldTile] with value equality over its three fields.
///
/// This concrete implementation is for simple lists that do not need custom
/// change detection. It implements `==` and `hashCode` over all three fields,
/// allowing the shell to detect real changes cheaply.
final class LayrzScaffoldValueTile extends LayrzScaffoldTile {
  /// The row's primary line.
  @override
  final InlineSpan titleRichText;

  /// The row's optional secondary line, ellipsised to one line.
  @override
  final InlineSpan? subtitleRichText;

  /// The row's overflow-menu actions. Empty means no menu is rendered.
  @override
  final List<LayrzDropdownItem> actions;

  /// Creates a new [LayrzScaffoldValueTile].
  ///
  /// - [titleRichText]: The title to display in the row. Required.
  /// - [subtitleRichText]: The subtitle to display, or null. Defaults to null.
  /// - [actions]: Action menu items, or an empty list. Defaults to an empty list.
  const LayrzScaffoldValueTile({
    required this.titleRichText,
    this.subtitleRichText,
    this.actions = const [],
  });

  /// Creates a copy of this tile with the given fields replaced.
  LayrzScaffoldValueTile copyWith({
    InlineSpan? titleRichText,
    InlineSpan? subtitleRichText,
    List<LayrzDropdownItem>? actions,
  }) {
    return LayrzScaffoldValueTile(
      titleRichText: titleRichText ?? this.titleRichText,
      subtitleRichText: subtitleRichText ?? this.subtitleRichText,
      actions: actions ?? this.actions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayrzScaffoldValueTile &&
        other.titleRichText == titleRichText &&
        other.subtitleRichText == subtitleRichText &&
        listEquals(other.actions, actions);
  }

  @override
  int get hashCode => Object.hash(titleRichText, subtitleRichText, Object.hashAll(actions));
}
