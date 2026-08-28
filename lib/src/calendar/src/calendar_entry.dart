import 'package:flutter/widgets.dart';

import 'calendar_zone.dart';

/// An immutable data class representing a single event rendered on a
/// [LayrzCalendar].
///
/// A [LayrzCalendarEntry] carries only the data a calendar surface needs to
/// place and paint an event; it has no notion of persistence or editing.
/// [start] and [end] together determine whether the entry spans a single day
/// or multiple days: an entry is multi-day when [start] and [end] fall on
/// different calendar dates, regardless of the actual time components. [end]
/// must never be strictly before [start].
///
/// **Extension point: consumers are expected to subclass this.** The
/// calendar's own data model is deliberately minimal — title, start, end,
/// color, preview flag, and a bare [onTap] — because a real app's event
/// almost always needs more (a database ID, a full domain object, whatever
/// its own "event" concept carries). Rather than growing this class to
/// anticipate every such need, the intended pattern is:
///
/// ```dart
/// class MyEvent extends LayrzCalendarEntry {
///   const MyEvent({required this.recordId, required super.title, required super.start, required super.end})
///     : super(onTap: null); // wire onTap per-instance in the constructor body or via a factory
/// }
/// ```
///
/// The caller builds `MyEvent` instances (each free to wire its own [onTap]
/// closure, which already has the surrounding scope's data available, so the
/// closure needs no parameter to "get back" to that data) and passes them to
/// [LayrzCalendar.entries]. `LayrzCalendar` never reconstructs or copies an
/// entry it did not create itself — every widget in this module holds the
/// exact instance it was given — so a consumer catching their own `MyEvent`
/// anywhere downstream of construction is never necessary in the first
/// place; the object in scope when [onTap] fires already **is** theirs.
///
/// **Equality contract a subclass must observe.** [operator ==] compares
/// [runtimeType] before any field, so a `MyEvent` instance never
/// accidentally compares equal to a plain [LayrzCalendarEntry], or to an
/// instance of a *different* subclass, no matter how their base fields line
/// up. What base equality does **not** protect against: two instances of
/// the **same** subclass that differ only in fields the subclass itself
/// added compare equal here, because this class's [operator ==] and
/// [hashCode] know nothing about them. **A subclass that adds fields
/// meaningful to equality must override both** to fold those fields in
/// (typically by calling `super == other` / hashing `Object.hash(super
/// .hashCode, ...extra fields)`) — this class does not and cannot do that
/// for it. [onTap] itself is deliberately excluded from both [operator ==]
/// and [hashCode] in this base class, and a subclass's override should keep
/// it excluded too: closures compare by identity, so two entries with
/// otherwise-identical data but separately-written closures (e.g. two
/// `MyEvent(recordId: 1, onTap: () {...})` built from the same data at
/// different times) would spuriously compare unequal if it were included,
/// which would break widget diffing and set/map membership for no benefit —
/// nothing meaningful is asserted by comparing two callbacks for identity.
///
/// **Equality and hashing caveat**: like [LayrzStep], equality depends on
/// [color], a [Color], which is compared by value, and is otherwise a plain
/// value comparison of every field except [onTap].
///
/// **All dates passed to one calendar — [start], [end], and the calendar's
/// own `focusedDate` — are expected to share a single timezone.**
@immutable
class LayrzCalendarEntry {
  /// Creates a [LayrzCalendarEntry].
  ///
  /// **Callers must ensure `end` is not before `start`.** This is not
  /// asserted at construction — doing so would require a non-const
  /// constructor, which would block callers from declaring `const` event
  /// lists — so a violation is a caller bug that [occupies] and [isMultiDay]
  /// do not defend against. Note that supplying a non-null [onTap] already
  /// makes a given call non-const (a closure is never a compile-time
  /// constant), so this only preserves `const` for entries that pass
  /// [onTap] as `null` or omit it.
  const LayrzCalendarEntry({
    required this.title,
    required this.start,
    required this.end,
    this.color,
    this.isPreview = false,
    this.onTap,
  });

  /// The event's display title, shown on the day cell or event chip.
  final String title;

  /// The event's start date and time.
  ///
  /// Only the calendar-date portion of [start] (year/month/day) is used to
  /// decide which day cell(s) the entry occupies; the time-of-day portion is
  /// reserved for the week/day views a later pass adds.
  final DateTime start;

  /// The event's end date and time.
  ///
  /// Must not be before [start]. An entry whose [end] falls on a later
  /// calendar date than [start] is a multi-day entry — see the class doc for
  /// how that is detected.
  final DateTime end;

  /// The optional accent color used to paint this entry.
  ///
  /// When null, the surface falls back to a default event color resolved
  /// from [LayrzTokens] rather than a hardcoded value.
  final Color? color;

  /// Whether this entry is a provisional/ghost event rather than a real one.
  ///
  /// Set this to `true` to render a placeholder for an event a caller's own
  /// creation flow has not yet committed — for example, while a "new event"
  /// dialog is open, the caller can add a preview entry so the user sees
  /// where it will land on the calendar before saving it. A preview entry
  /// still participates in layout exactly like a normal one — it takes a
  /// lane, is included in overlap resolution, and occupies a normal slot —
  /// only its paint treatment differs. Defaults to `false`.
  final bool isPreview;

  /// Called when this entry is tapped — a chip in a month cell, a multi-day
  /// bar, an all-day band bar, or a timed block in the week/day hour grid.
  ///
  /// A plain notification with no parameter: the caller decides what happens
  /// next (open a dialog, an inline form, navigate elsewhere, anything else)
  /// — this entry has no opinion. Deliberately parameterless rather than
  /// `void Function(LayrzCalendarEntry)`, because the closure a caller
  /// assigns here is written in the same scope that already has this
  /// entry's (or its subclass's) own data available; there is nothing to
  /// hand back that the closure does not already have. See the class doc's
  /// "extension point" section for how this composes with subclassing.
  ///
  /// This entry's own tap target sits above the calendar surface's, so
  /// tapping an entry fires only this callback, never also
  /// [LayrzCalendar.onTap]. Null renders this entry non-interactive: no
  /// hover state, no pointer cursor, no interactive semantics node.
  /// Deliberately excluded from [operator ==] and [hashCode] — see the class
  /// doc's equality contract section for why.
  final VoidCallback? onTap;

  /// Whether this entry spans more than one calendar date.
  ///
  /// Compares only the year/month/day components of [start] and [end] — an
  /// entry from 23:00 to 01:00 the next calendar day is multi-day even though
  /// it lasts two hours, while an entry from 00:00 to 23:59 the same day is
  /// not, even though it spans nearly 24 hours. Each is read via
  /// [sameZoneDate] in its own zone, preserving a `TZDateTime`'s `Location`.
  bool get isMultiDay {
    final startDate = sameZoneDate(start, start.year, start.month, start.day);
    final endDate = sameZoneDate(end, end.year, end.month, end.day);
    return endDate.isAfter(startDate);
  }

  /// Whether this entry occupies the given calendar [date].
  ///
  /// Compares only year/month/day components of [date] against the inclusive
  /// range `[start, end]`, so a multi-day entry correctly occupies every date
  /// it spans, not just [start]'s date.
  bool occupies(DateTime date) {
    final day = sameZoneDate(date, date.year, date.month, date.day);
    final startDate = sameZoneDate(start, start.year, start.month, start.day);
    final endDate = sameZoneDate(end, end.year, end.month, end.day);
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }

  /// Creates a copy of this entry with the given fields replaced.
  ///
  /// All parameters are optional; omitted fields retain their original
  /// values. There is no way to clear [color] or [onTap] back to null via
  /// [copyWith] — construct a new [LayrzCalendarEntry] for that. [isPreview]
  /// is a plain `bool?`, not a sentinel-defaulted parameter, so omitting it
  /// preserves the receiver's existing value — including `true` — rather
  /// than resetting it to `false`.
  ///
  /// **A subclass overriding this should return its own runtime type**,
  /// carrying its extra fields forward unchanged (or accepting its own
  /// additional optional parameters for them) — this base implementation
  /// only knows about the fields declared here and always returns a plain
  /// [LayrzCalendarEntry].
  LayrzCalendarEntry copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    Color? color,
    bool? isPreview,
    VoidCallback? onTap,
  }) {
    return LayrzCalendarEntry(
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      isPreview: isPreview ?? this.isPreview,
      onTap: onTap ?? this.onTap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzCalendarEntry &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          start == other.start &&
          end == other.end &&
          color == other.color &&
          isPreview == other.isPreview;

  @override
  int get hashCode => Object.hash(title, start, end, color, isPreview);
}
