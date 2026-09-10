import 'package:flutter/widgets.dart';

/// An immutable descriptor for a single tab within a [LayrzWorkspaceTabs]
/// workspace.
///
/// A [LayrzWorkspaceTab] carries identity and presentation data — [id],
/// [label], [icon], and [closable] — **and now also owns its content**
/// through [left] and [right]. This is a deliberate model change from the
/// original bar-only design: [LayrzWorkspaceTabs] no longer merely renders a
/// tab strip while the caller renders the body elsewhere — it renders the
/// strip *and* the connected content panel for the active tab, reading that
/// panel's content straight off this descriptor.
///
/// [left] is the tab's primary content pane and is always required. [right]
/// is optional: when non-null, the tab renders in **split view** — [left]
/// and [right] side-by-side behind a resizable divider — and when `null` the
/// panel shows [left] alone, filling the whole content area.
///
/// See also:
///   - [LayrzWorkspaceTabs], the controlled strip-and-panel widget that
///     renders this descriptor's [left]/[right] content when the tab is
///     active.
@immutable
class LayrzWorkspaceTab {
  /// Stable unique identity for this tab.
  ///
  /// Passed back through every [LayrzWorkspaceTabs] callback
  /// ([LayrzWorkspaceTabs.onTabSelected], [LayrzWorkspaceTabs.onTabClosed])
  /// and used internally to key persisted per-tab UI state (such as a
  /// resizable split ratio). Must never be derived from [label] — a rename
  /// must not change identity, and two tabs may legitimately share a label
  /// while never sharing an [id].
  final String id;

  /// The tab's visible label text.
  final String label;

  /// An optional leading icon rendered before [label], acting as a
  /// favicon-equivalent for the tab (e.g. a document-type or app icon).
  ///
  /// Null renders no leading icon.
  final IconData? icon;

  /// Whether this tab shows a close (×) affordance.
  ///
  /// Defaults to `true`. When `false`, this specific tab never renders a
  /// close button and never emits [LayrzWorkspaceTabs.onTabClosed], even
  /// when the strip as a whole has a non-null `onTabClosed` handler — this
  /// is how a pinned or "home" tab opts out of being closed while the rest
  /// of the strip remains closable.
  final bool closable;

  /// The tab's primary content pane, rendered in the connected panel
  /// whenever this tab is the active one.
  ///
  /// Required — every tab owns at least one pane of content. When [right]
  /// is `null`, [left] fills the entire panel content area; when [right] is
  /// non-null, [left] renders as the start (left-hand) pane of a resizable
  /// split view.
  final Widget left;

  /// An optional secondary content pane.
  ///
  /// When non-null, this tab renders in **split view**: [left] and [right]
  /// side-by-side, separated by a draggable divider the user can drag to
  /// resize the split ratio (see [LayrzWorkspaceTabs] for the resizing
  /// behaviour). When `null` (the default), the tab is a single pane and
  /// [left] fills the panel alone. Layrz workspace tabs support at most two
  /// panes — there is no third slot.
  final Widget? right;

  /// Creates a new [LayrzWorkspaceTab].
  ///
  /// [id], [label], and [left] are required. [icon] is optional and
  /// defaults to `null` (no leading icon). [closable] defaults to `true`.
  /// [right] is optional and defaults to `null` (single-pane tab); pass a
  /// non-null [right] to put this tab into split view.
  const LayrzWorkspaceTab({
    required this.id,
    required this.label,
    required this.left,
    this.icon,
    this.closable = true,
    this.right,
  });

  /// Whether this tab is currently in split view, i.e. [right] is non-null.
  bool get isSplit => right != null;

  /// Returns a copy of this tab with the given fields replaced.
  ///
  /// [right] cannot be cleared back to `null` through [copyWith] alone —
  /// pass a new [LayrzWorkspaceTab] directly if a tab must drop its split
  /// pane and return to single-pane view.
  LayrzWorkspaceTab copyWith({
    String? id,
    String? label,
    Widget? left,
    IconData? icon,
    bool? closable,
    Widget? right,
  }) {
    return LayrzWorkspaceTab(
      id: id ?? this.id,
      label: label ?? this.label,
      left: left ?? this.left,
      icon: icon ?? this.icon,
      closable: closable ?? this.closable,
      right: right ?? this.right,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzWorkspaceTab &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          icon == other.icon &&
          closable == other.closable &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(id, label, icon, closable, left, right);
}
