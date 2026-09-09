import 'package:flutter/widgets.dart';

/// An immutable descriptor for a single tab within a [LayrzWorkspaceTabs] strip.
///
/// A [LayrzWorkspaceTab] carries only identity and presentation data — [id],
/// [label], [icon], and [closable]. It never carries content: the developer
/// keeps the tab list and the currently active id in their own state, and
/// maps [id] to whatever body widget belongs to that tab. This mirrors a
/// browser's own tab-strip model, where the strip renders and reorders tabs
/// but the page content behind each one lives outside the strip entirely.
///
/// See also:
///   - [LayrzWorkspaceTabs], the controlled, bar-only strip widget this
///     descriptor is rendered by.
@immutable
class LayrzWorkspaceTab {
  /// Stable unique identity for this tab.
  ///
  /// Passed back through every [LayrzWorkspaceTabs] callback
  /// ([LayrzWorkspaceTabs.onTabSelected], [LayrzWorkspaceTabs.onTabClosed])
  /// and used by the developer to key their own content for this tab. Must
  /// never be derived from [label] — a rename must not change identity, and
  /// two tabs may legitimately share a label while never sharing an [id].
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

  /// Creates a new [LayrzWorkspaceTab].
  ///
  /// [id] and [label] are required. [icon] is optional and defaults to
  /// `null` (no leading icon). [closable] defaults to `true`.
  const LayrzWorkspaceTab({
    required this.id,
    required this.label,
    this.icon,
    this.closable = true,
  });

  /// Returns a copy of this tab with the given fields replaced.
  LayrzWorkspaceTab copyWith({
    String? id,
    String? label,
    IconData? icon,
    bool? closable,
  }) {
    return LayrzWorkspaceTab(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      closable: closable ?? this.closable,
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
          closable == other.closable;

  @override
  int get hashCode => Object.hash(id, label, icon, closable);
}
