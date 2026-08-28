/// Zone-preserving `DateTime` construction helpers shared across the
/// calendar module.
///
/// **The defect this file exists to fix.** Every internal date computation in
/// this module used to read `.year`/`.month`/`.day` (and occasionally
/// `.hour`/`.minute`) off a caller-supplied [DateTime] and feed those fields
/// straight into the plain [DateTime] constructor. That constructor always
/// builds a value in the *host's* local zone, silently discarding whatever
/// zone the original value actually carried. A consumer passing
/// `package:timezone`'s `TZDateTime` — which `extends DateTime` and so is
/// accepted anywhere a `DateTime` parameter is declared — got a calendar
/// whose every internal grid/stepping/occupancy computation was silently
/// re-anchored to the host's own zone instead of the value's own.
///
/// **The fix is narrow: preserve the subtype of whatever was passed in**,
/// not add a `Location`/timezone parameter anywhere. `LayrzCalendar` and
/// every surface underneath it stay entirely ignorant of `package:timezone` —
/// this file is the only place in `lib/` that imports it, and only to check
/// `reference is TZDateTime` and read back its own `location` (see
/// [sameZoneDate]'s implementation). A [DateTime] parameter on any public
/// widget or function in this module still only ever needs a [DateTime] —
/// the zone information already lives inside the value itself.
///
/// **Every call site that used to do
/// `DateTime(reference.year, reference.month, reference.day, ...)` should
/// instead call [sameZoneDate]/[sameZoneDateTime]**, threading through
/// whichever original value (`reference`) the extracted fields came from.
library;

import 'package:timezone/timezone.dart' as tz;

/// Builds a date-only [DateTime] for [year]/[month]/[day], in the same zone
/// [reference] itself is expressed in.
///
/// When [reference] is a `TZDateTime` (from `package:timezone`), the result
/// is a `TZDateTime` constructed in [reference]'s own `location` — so
/// calendar-field stepping (`day: n + 7`, month overflow, etc.) normalizes
/// according to that zone's own DST rules, not the host's. When [reference]
/// is a plain [DateTime], the result is a plain [DateTime] built the same way
/// calendar code always has — **no behavior change for existing callers that
/// never used `package:timezone`.**
///
/// **Always step calendar fields through this helper (or the plain
/// [DateTime] constructor when no [reference] is available), never
/// [Duration].** `Duration` arithmetic is absolute elapsed time; stepping a
/// `TZDateTime` by `Duration(days: n)` across that zone's own DST transition
/// lands on the wrong local day exactly the way it does for a plain
/// [DateTime] in the host's zone — the `Location` carried along changes
/// nothing about that hazard. [year]/[month]/[day] here already carry
/// whatever field-overflow arithmetic the caller wants (e.g. `day + 7`); this
/// helper only decides which constructor family evaluates it.
///
/// **No `package:timezone` initialization is required by this call.**
/// [reference]'s `location` is already a fully self-contained `Location`
/// object — the caller who originally constructed [reference] is the one who
/// ran `initializeTimeZones()` (or otherwise obtained a `Location`), and that
/// work is carried on the value itself. Reusing it here needs no global state
/// and no setup burden falls on a consumer of this module.
DateTime sameZoneDate(DateTime reference, int year, int month, [int day = 1]) {
  if (reference is tz.TZDateTime) {
    return tz.TZDateTime(reference.location, year, month, day);
  }
  return DateTime(year, month, day);
}

/// Builds a full date+time [DateTime] for the given fields, in the same zone
/// [reference] itself is expressed in — see [sameZoneDate] for the subtype
/// preservation rule, the `Duration`-vs-calendar-field-stepping rule, and why
/// no `package:timezone` initialization is needed.
///
/// All time-of-day fields default to zero, matching the plain [DateTime]
/// constructor's own defaults.
DateTime sameZoneDateTime(
  DateTime reference,
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
  int second = 0,
  int millisecond = 0,
  int microsecond = 0,
]) {
  if (reference is tz.TZDateTime) {
    return tz.TZDateTime(reference.location, year, month, day, hour, minute, second, millisecond, microsecond);
  }
  return DateTime(year, month, day, hour, minute, second, millisecond, microsecond);
}
