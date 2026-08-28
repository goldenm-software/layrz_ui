import 'package:flutter/widgets.dart';

import 'timeline_side.dart';

/// An immutable, dated event rendered by a [LayrzTimeline].
///
/// [LayrzTimelineEntry] deliberately carries no state vocabulary — there is
/// no `completed`/`active`/`pending` field, unlike a stepper's step. A
/// timeline entry represents an event that already happened (or is scheduled
/// to happen); it does not model progress through a sequence, so imposing
/// that vocabulary here would be the wrong direction of coupling with
/// `LayrzStepper` (see `engineering/decisions.md` and the batch's
/// implementation plan §5.3).
///
/// This is a display-only data class: [LayrzTimeline] has no built-in editing
/// of entries. A caller that needs to add, remove, or reorder entries does so
/// by rebuilding the list it passes in.
@immutable
class LayrzTimelineEntry {
  /// Creates a [LayrzTimelineEntry].
  const LayrzTimelineEntry({
    required this.labelText,
    this.descriptionText,
    this.timestampText,
    this.icon,
    this.accentColor,
    this.side,
    this.content,
  });

  /// The primary, short text identifying this event (e.g. "Order shipped").
  ///
  /// Always rendered, and always included in the entry's semantics label.
  final String labelText;

  /// Optional longer supporting text rendered below [labelText].
  ///
  /// When null, no description line is rendered.
  final String? descriptionText;

  /// Optional caller-formatted date/time text rendered alongside the entry
  /// (e.g. "Aug 28, 2026" or "2 hours ago").
  ///
  /// [LayrzTimelineEntry] does not parse, format, or sort by this value — it
  /// is opaque display text. Ordering the entry list chronologically is the
  /// caller's responsibility; see [LayrzTimeline.entries].
  final String? timestampText;

  /// Optional icon rendered inside this entry's marker.
  ///
  /// When null, the marker renders as a plain dot. The marker is always
  /// excluded from semantics (it is decorative), so this icon carries no
  /// meaning that is not already present in [labelText] or [descriptionText].
  final IconData? icon;

  /// Optional accent color applied to this entry's marker and connector
  /// segment.
  ///
  /// When null, the marker and connector use the theme's default (neutral)
  /// colors. Per WCAG 1.4.1, [LayrzTimeline] never uses [accentColor] alone to
  /// convey meaning — if an entry's distinguishing feature is its accent,
  /// [icon] or [labelText] must also carry that distinction.
  final Color? accentColor;

  /// Which side of the spine this entry's content card renders on, in the
  /// two-sided layout.
  ///
  /// When null, [LayrzTimeline] alternates sides automatically based on the
  /// entry's position in [LayrzTimeline.entries]. Has no effect in the
  /// one-sided layout (see [LayrzTimelineSide]).
  final LayrzTimelineSide? side;

  /// Optional extra widget rendered below the description line, inside this
  /// entry's content card (e.g. an attachment chip or an action button).
  ///
  /// When null, the card renders only [labelText], [descriptionText], and
  /// [timestampText].
  final Widget? content;

  /// Returns a copy of this entry with the given fields replaced.
  LayrzTimelineEntry copyWith({
    String? labelText,
    String? descriptionText,
    String? timestampText,
    IconData? icon,
    Color? accentColor,
    LayrzTimelineSide? side,
    Widget? content,
  }) {
    return LayrzTimelineEntry(
      labelText: labelText ?? this.labelText,
      descriptionText: descriptionText ?? this.descriptionText,
      timestampText: timestampText ?? this.timestampText,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      side: side ?? this.side,
      content: content ?? this.content,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzTimelineEntry &&
          runtimeType == other.runtimeType &&
          labelText == other.labelText &&
          descriptionText == other.descriptionText &&
          timestampText == other.timestampText &&
          icon == other.icon &&
          accentColor == other.accentColor &&
          side == other.side &&
          content == other.content;

  @override
  int get hashCode => Object.hash(
    labelText,
    descriptionText,
    timestampText,
    icon,
    accentColor,
    side,
    content,
  );
}
