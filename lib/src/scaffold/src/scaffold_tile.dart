import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/menus/src/dropdown_items.dart';

/// An abstract specification for a row in the [LayrzScaffoldShell] list.
///
/// This base class describes a single list row but does not render it.
/// The shell owns rendering; the tile only holds the data and is created
/// fresh on each build by the consumer's [onBuild] callback.
///
/// **Subclassing contract:**
/// - Subclasses **should** override `==` and `hashCode`, typically over a stable id
///   plus a version/updatedAt field, so the shell can detect real changes cheaply.
/// - Without that override, the tile compares by identity. Since a fresh instance is
///   produced each build, change detection degrades to "always changed" — correct,
///   just not optimal.
/// - [LayrzScaffoldValueTile] exists for the simple case where value equality
///   over the three fields is desired.
abstract base class LayrzScaffoldTile {
  /// Allows subclasses to be const.
  const LayrzScaffoldTile();

  /// The row's primary line.
  InlineSpan get titleRichText;

  /// The row's optional secondary line, ellipsised to one line.
  InlineSpan? get subtitleRichText;

  /// The row's overflow-menu actions. Empty means no menu is rendered.
  List<LayrzDropdownItem> get actions;
}
