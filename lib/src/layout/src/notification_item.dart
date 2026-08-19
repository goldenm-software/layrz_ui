import 'package:flutter/widgets.dart';

/// A single notification displayed in the [LayrzLayout] notifications panel.
///
/// [LayrzNotificationItem] represents a notification entry with a title, body
/// content, and optional icon and tap handler. Notifications are displayed in
/// a dropdown menu accessed via the bell icon in the rail footer (expanded
/// presentation) or top bar (drawer presentation).
@immutable
class LayrzNotificationItem {
  /// Creates a notification item.
  ///
  /// The [id], [title], and [content] parameters are required. All other
  /// parameters are optional.
  const LayrzNotificationItem({
    required this.id,
    required this.title,
    required this.content,
    this.icon,
    this.onTap,
  });

  /// A stable identifier for this notification.
  ///
  /// The [id] is used to uniquely identify this notification in the list.
  /// When deduplicating or updating notifications, this [id] is compared
  /// to determine uniqueness.
  final String id;

  /// The title text of the notification.
  ///
  /// This is displayed as the primary heading in the notification panel entry.
  final String title;

  /// The body content of the notification.
  ///
  /// This is displayed below the [title] as the notification's detailed message.
  final String content;

  /// An optional icon displayed alongside the title and content.
  ///
  /// If null, only the text is shown. The icon is rendered at a small size
  /// in the notification entry.
  final IconData? icon;

  /// An optional callback fired when the user taps this notification.
  ///
  /// If provided, this callback is invoked when the notification is tapped.
  /// The notification panel remains open after the tap unless the callback
  /// explicitly dismisses it.
  final VoidCallback? onTap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzNotificationItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          icon == other.icon &&
          onTap == other.onTap;

  @override
  int get hashCode => Object.hash(runtimeType, id, title, content, icon, onTap);

  /// Returns a copy of this notification with the given fields replaced.
  LayrzNotificationItem copyWith({
    String? id,
    String? title,
    String? content,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return LayrzNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
    );
  }
}
