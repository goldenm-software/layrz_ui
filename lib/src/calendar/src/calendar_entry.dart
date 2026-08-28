import 'package:flutter/widgets.dart';

/// An immutable data class representing a single event rendered on a
/// [LayrzCalendar].
///
/// A [LayrzCalendarEntry] carries only the data a calendar surface needs to
/// place and paint an event; it has no notion of persistence, editing, or a
/// return value — this pass is display-only (see the class doc on
/// `LayrzCalendar`). [start] and [end] together determine whether the entry
/// spans a single day or multiple days: an entry is multi-day when [start]
/// and [end] fall on different calendar dates, regardless of the actual time
/// components. [end] must never be strictly before [start].
///
/// **Equality and hashing caveat**: like [LayrzStep], equality depends on
/// [color], a [Color], which is compared by value, and is otherwise a plain
/// value comparison of every field.
@immutable
class LayrzCalendarEntry {
  /// Creates a [LayrzCalendarEntry].
  ///
  /// **Callers must ensure `end` is not before `start`.** This is not
  /// asserted at construction — doing so would require a non-const
  /// constructor, which would block callers from declaring `const` event
  /// lists — so a violation is a caller bug that [occupies] and [isMultiDay]
  /// do not defend against.
  const LayrzCalendarEntry({
    required this.title,
    required this.start,
    required this.end,
    this.color,
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

  /// Whether this entry spans more than one calendar date.
  ///
  /// Compares only the year/month/day components of [start] and [end] — an
  /// entry from 23:00 to 01:00 the next calendar day is multi-day even though
  /// it lasts two hours, while an entry from 00:00 to 23:59 the same day is
  /// not, even though it spans nearly 24 hours.
  bool get isMultiDay {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.isAfter(startDate);
  }

  /// Whether this entry occupies the given calendar [date].
  ///
  /// Compares only year/month/day components of [date] against the inclusive
  /// range `[start, end]`, so a multi-day entry correctly occupies every date
  /// it spans, not just [start]'s date.
  bool occupies(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }

  /// Creates a copy of this entry with the given fields replaced.
  ///
  /// All parameters are optional; omitted fields retain their original
  /// values. There is no way to clear [color] back to null via [copyWith] —
  /// construct a new [LayrzCalendarEntry] for that.
  LayrzCalendarEntry copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    Color? color,
  }) {
    return LayrzCalendarEntry(
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
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
          color == other.color;

  @override
  int get hashCode => Object.hash(title, start, end, color);
}
