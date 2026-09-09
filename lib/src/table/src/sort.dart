import 'package:flutter/foundation.dart' show compute;

/// Payload sent across the isolate boundary to [sortTableItems].
///
/// Every field here must be isolate-safe: plain data, or a closure that does
/// not capture a `BuildContext`, a `State`, a `ChangeNotifier`/`ValueNotifier`,
/// or any other object tied to the widget tree. `LayrzTable` builds this on
/// the main thread by precomputing [sortKeys] from `LayrzColumn.valueBuilder`
/// *before* crossing into the isolate, so that closure never itself needs to
/// travel — only its already-computed string results do. When the caller
/// supplies `LayrzColumn.customSort`, that comparator function does cross the
/// boundary; per its own contract (see `LayrzColumn.customSort`) it must be
/// isolate-safe on its own.
class SortParams<T> {
  /// The rows to sort, in their pre-sort (already search-filtered) order.
  final List<T> items;

  /// Precomputed sort key strings, one per entry in [items] at the same
  /// index, built on the main thread from the active sort column's
  /// `valueBuilder`.
  ///
  /// Computing these ahead of time keeps `valueBuilder` — which may close
  /// over `BuildContext` or localization objects — from ever crossing the
  /// isolate boundary. Only used when [customSort] is `null`.
  final List<String> sortKeys;

  /// Whether the sort should be ascending (`true`) or descending (`false`).
  final bool ascending;

  /// Optional per-column comparator overriding the default key-based
  /// comparison.
  ///
  /// When non-`null`, this is invoked as `customSort(a, b, ascending)` for
  /// every comparison and [sortKeys] is ignored. Must be isolate-safe: it
  /// must not capture a `BuildContext`, i18n lookups, or any notifier/state
  /// object — see `LayrzColumn.customSort`.
  final int Function(T a, T b, bool ascending)? customSort;

  /// Creates a [SortParams] payload.
  ///
  /// [items] and [sortKeys] must have the same length when [customSort] is
  /// `null`, since [sortKeys] is indexed in parallel with [items].
  SortParams({required this.items, required this.sortKeys, required this.ascending, this.customSort});
}

/// Isolate entrypoint that sorts [SortParams.items] according to the rest of
/// [params].
///
/// Intended to be run off the UI thread via `compute(sortTableItems, params)`
/// so that sorting large datasets does not block a frame. Left
/// library-visible (not prefixed with `_`) rather than fully private, so a
/// future component in this module can reuse the same off-thread sort
/// primitive.
///
/// When [SortParams.customSort] is provided, it drives the comparison
/// directly and [SortParams.sortKeys] is unused. Otherwise, a parallel index
/// array is sorted using [defaultSortCompare] over the precomputed
/// [SortParams.sortKeys], then [SortParams.items] is reordered to match —
/// this avoids re-sorting the (potentially large) item objects themselves.
///
/// Returns a new list; [SortParams.items] itself may or may not be mutated in
/// place depending on the code path, so callers must use the returned list.
List<T> sortTableItems<T>(SortParams<T> params) {
  final customSort = params.customSort;
  if (customSort != null) {
    final sorted = List<T>.of(params.items);
    sorted.sort((a, b) => customSort(a, b, params.ascending));
    return sorted;
  }

  final indices = List<int>.generate(params.items.length, (i) => i);
  indices.sort((a, b) => defaultSortCompare(params.sortKeys[a], params.sortKeys[b], ascending: params.ascending));

  return [for (final i in indices) params.items[i]];
}

/// Runs [sortTableItems] off the UI thread via `compute`.
///
/// This is the entrypoint callers should invoke from the main isolate; it
/// wraps `compute()` so the sort work (index sort + reordering, or the
/// caller's [SortParams.customSort]) happens in a background isolate.
Future<List<T>> sortTableItemsOffThread<T>(SortParams<T> params) => compute(sortTableItems, params);

/// Compares two precomputed sort key strings, [a] and [b], for the default
/// (no `LayrzColumn.customSort`) comparator.
///
/// Tries, in order: numeric comparison (`num.tryParse`), `H:M:S`/`M:S`
/// duration comparison, `DateTime` comparison (`DateTime.tryParse`), and
/// finally case-insensitive lexicographic string comparison. The first
/// interpretation both [a] and [b] parse as consistently is used; if they
/// disagree (e.g. one parses as numeric and the other does not), comparison
/// falls through to the next interpretation, ending at the string fallback,
/// which always succeeds.
///
/// When [ascending] is `false`, the result is the descending-order
/// comparison (equivalent to comparing [b] to [a] under the ascending rule).
int defaultSortCompare(String a, String b, {required bool ascending}) {
  final numA = num.tryParse(a);
  final numB = num.tryParse(b);
  if (numA != null && numB != null) {
    if (numA == numB) return 0;
    final greater = numA > numB;
    return ascending == greater ? 1 : -1;
  }

  final durationA = _tryParseDuration(a);
  final durationB = _tryParseDuration(b);
  if (durationA != null && durationB != null) {
    return ascending ? durationA.compareTo(durationB) : durationB.compareTo(durationA);
  }

  final dateA = DateTime.tryParse(a);
  final dateB = DateTime.tryParse(b);
  if (dateA != null && dateB != null) {
    return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
  }

  return ascending ? a.toLowerCase().compareTo(b.toLowerCase()) : b.toLowerCase().compareTo(a.toLowerCase());
}

/// Parses [value] as an `H:M:S` or `M:S` duration string, returning `null`
/// when it does not match that shape.
///
/// Requires at least two colon-separated numeric parts (minutes and
/// seconds); a lone number is left to the numeric or string comparators
/// instead of being misread as a duration.
Duration? _tryParseDuration(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;

  final numericParts = parts.map(int.tryParse).toList();
  if (numericParts.any((part) => part == null)) return null;

  final hours = numericParts.length > 2 ? numericParts[numericParts.length - 3]! : 0;
  final minutes = numericParts[numericParts.length - 2]!;
  final seconds = numericParts[numericParts.length - 1]!;
  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}
