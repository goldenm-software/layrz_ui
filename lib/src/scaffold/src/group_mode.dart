/// How the [LayrzScaffoldShell] list panel arranges its items.
enum LayrzScaffoldGroupMode {
  /// Items are grouped by their [LayrzScaffoldItem.group] value.
  ///
  /// Items with the same [group] appear under a sticky header with that group name.
  /// Items with null [group] appear in an ungrouped trailing run with no header.
  /// This mode is the default.
  grouped,

  /// Items are displayed in a flat list with no grouping.
  ///
  /// [LayrzScaffoldItem.group] values are ignored. All items are displayed
  /// in the order they appear in the [items] list.
  flat,
}
