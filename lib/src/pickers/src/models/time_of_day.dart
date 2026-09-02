import 'package:flutter/widgets.dart';

/// An immutable time-of-day value with hour, minute, and second precision.
///
/// Distinct from Flutter's Material `TimeOfDay` (which this library cannot
/// depend on — see the Material/Cupertino-free constraint) and from
/// [Duration] (which is an elapsed span, not a wall-clock reading).
/// [LayrzTimeOfDay] is the value type [LayrzTimeInput] and
/// [LayrzTimeRangeInput] operate on.
///
/// Comparable via [compareTo] and the `<`/`<=`/`>`/`>=` operators, which order
/// times chronologically within a single day (hour first, then minute, then
/// second).
@immutable
class LayrzTimeOfDay implements Comparable<LayrzTimeOfDay> {
  /// The hour, in 24-hour form, `0` through `23`.
  final int hour;

  /// The minute, `0` through `59`.
  final int minute;

  /// The second, `0` through `59`.
  ///
  /// Defaults to `0`. Whether this is surfaced to the user depends on the
  /// consuming widget's `showSeconds` parameter — this value type always
  /// carries a second, regardless of whether it is displayed.
  final int second;

  /// Creates a new [LayrzTimeOfDay].
  ///
  /// [hour] must be between 0 and 23, [minute] and [second] between 0 and 59
  /// inclusive; asserted in debug builds. No interval snapping is applied —
  /// any minute/second combination is representable.
  const LayrzTimeOfDay({required this.hour, required this.minute, this.second = 0})
    : assert(hour >= 0 && hour <= 23, 'hour must be between 0 and 23, got $hour.'),
      assert(minute >= 0 && minute <= 59, 'minute must be between 0 and 59, got $minute.'),
      assert(second >= 0 && second <= 59, 'second must be between 0 and 59, got $second.');

  /// Creates a [LayrzTimeOfDay] from [dateTime]'s hour, minute, and second,
  /// discarding the date and timezone components.
  factory LayrzTimeOfDay.fromDateTime(DateTime dateTime) =>
      LayrzTimeOfDay(hour: dateTime.hour, minute: dateTime.minute, second: dateTime.second);

  /// The hour expressed on a 12-hour clock, `1` through `12`.
  ///
  /// Midnight (`hour == 0`) and noon (`hour == 12`) both map to `12`, matching
  /// conventional 12-hour clock display.
  int get hour12 {
    final h = hour % 12;
    return h == 0 ? 12 : h;
  }

  /// Whether this time falls in the post-meridiem (PM) half of the day, i.e.
  /// [hour] is 12 or greater.
  bool get isPm => hour >= 12;

  /// Returns a copy of this time with the given fields replaced.
  LayrzTimeOfDay copyWith({int? hour, int? minute, int? second}) => LayrzTimeOfDay(
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    second: second ?? this.second,
  );

  @override
  int compareTo(LayrzTimeOfDay other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    if (minute != other.minute) return minute.compareTo(other.minute);
    return second.compareTo(other.second);
  }

  /// Whether this time is chronologically before [other].
  bool operator <(LayrzTimeOfDay other) => compareTo(other) < 0;

  /// Whether this time is chronologically before or equal to [other].
  bool operator <=(LayrzTimeOfDay other) => compareTo(other) <= 0;

  /// Whether this time is chronologically after [other].
  bool operator >(LayrzTimeOfDay other) => compareTo(other) > 0;

  /// Whether this time is chronologically after or equal to [other].
  bool operator >=(LayrzTimeOfDay other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayrzTimeOfDay && other.hour == hour && other.minute == minute && other.second == second);

  @override
  int get hashCode => Object.hash(hour, minute, second);

  @override
  String toString() => 'LayrzTimeOfDay(hour: $hour, minute: $minute, second: $second)';
}
