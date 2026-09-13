import 'package:flutter/foundation.dart' show compute, kIsWeb;

/// How many merge runs execute between yields in the web (chunked) sort path.
///
/// After this many runs the sort yields with `Future.delayed(Duration.zero)` —
/// a MACROTASK, not a microtask. This distinction is load-bearing: `await null`
/// (or any already-completed future) resumes on the microtask queue, and Dart
/// drains the *entire* microtask queue before the browser ever paints, so it
/// does NOT let the UI render mid-sort. Only returning to the event loop via a
/// macrotask lets the browser service a frame — keeping the UI responsive (and
/// the table's "sorting" strip animating) during a large sort on web, where
/// `compute` cannot move the work off the single main thread.
const int _kYieldEveryRuns = 64;

/// Payload sent across the isolate boundary to [sortByKeys] for the default
/// (no `LayrzColumn.customSort`) sort path.
///
/// Deliberately carries no domain objects: only [sortKeys] (plain `String`s)
/// and [ascending] cross into the isolate, so the copy cost of a `compute()`
/// round trip no longer scales with the size or shape of the table's row
/// type `T` — only with the row *count*. The isolate returns the sorted
/// **index order**, not sorted items; the caller (`LayrzTable`, on the main
/// thread) uses those indices to reorder its own `List<T>` by reference,
/// which is cheap regardless of how large `T` is.
class SortKeysParams {
  /// Sort key strings, one per row, built on the main thread from the active
  /// sort column's `valueBuilder`.
  ///
  /// Computing these ahead of time keeps `valueBuilder` — which may close
  /// over `BuildContext` or localization objects — from ever crossing the
  /// isolate boundary.
  final List<String> sortKeys;

  /// Whether the sort should be ascending (`true`) or descending (`false`).
  final bool ascending;

  /// Creates a [SortKeysParams] payload.
  const SortKeysParams({required this.sortKeys, required this.ascending});
}

/// Payload sent across the isolate boundary to [sortTableItems] for the
/// `LayrzColumn.customSort` path.
///
/// Every field here must be isolate-safe: plain data, or a closure that does
/// not capture a `BuildContext`, a `State`, a `ChangeNotifier`/`ValueNotifier`,
/// or any other object tied to the widget tree. Unlike [SortKeysParams], this
/// path does send the full [items] list across the boundary, because
/// [customSort] must compare the actual `T` objects — there is no
/// precomputed-key shortcut available when the caller supplies its own
/// comparator. Per its own contract (see `LayrzColumn.customSort`),
/// [customSort] itself must be isolate-safe.
class SortParams<T> {
  /// The rows to sort, in their pre-sort (already search-filtered) order.
  final List<T> items;

  /// The per-column comparator to drive every comparison, invoked as
  /// `customSort(a, b, ascending)`.
  final int Function(T a, T b, bool ascending) customSort;

  /// Whether the sort should be ascending (`true`) or descending (`false`).
  final bool ascending;

  /// Creates a [SortParams] payload.
  SortParams({required this.items, required this.customSort, required this.ascending});
}

/// Isolate entrypoint that sorts [SortParams.items] using
/// [SortParams.customSort].
///
/// Intended to be run off the UI thread via `compute(sortTableItems, params)`
/// so that sorting large datasets does not block a frame. Left
/// library-visible (not prefixed with `_`) rather than fully private, so a
/// future component in this module can reuse the same off-thread sort
/// primitive.
///
/// Returns a new list; [SortParams.items] itself is not mutated in place.
List<T> sortTableItems<T>(SortParams<T> params) {
  final sorted = List<T>.of(params.items);
  sorted.sort((a, b) => params.customSort(a, b, params.ascending));
  return sorted;
}

/// Isolate entrypoint that sorts [SortKeysParams.sortKeys] using
/// [defaultSortCompare] and returns the resulting **index order** rather than
/// reordered items.
///
/// This is the default (no `LayrzColumn.customSort`) sort path: only string
/// keys and an index array cross the isolate boundary, never the row objects
/// themselves. The caller reorders its own `List<T>` by these indices back on
/// the main thread — cheap reference shuffling, independent of how large or
/// deeply-nested `T` is.
List<int> sortByKeys(SortKeysParams params) {
  final indices = List<int>.generate(params.sortKeys.length, (i) => i);
  indices.sort((a, b) => defaultSortCompare(params.sortKeys[a], params.sortKeys[b], ascending: params.ascending));
  return indices;
}

/// A bottom-up (iterative) merge sort of the index array `0..n`, ordered by
/// [defaultSortCompare] over [SortKeysParams.sortKeys], that `await`s a
/// microtask every [_kYieldEveryRuns] merge runs so the event loop can service
/// frames.
///
/// Merge sort (not `List.sort`) is used because the work must be broken into
/// resumable chunks: Dart's built-in `List.sort` is a single synchronous call
/// with no yield point, so on web — where there is no isolate to move it to —
/// it blocks the only thread for the whole sort. This yields cooperatively
/// instead, trading a little raw speed for a responsive UI. It is stable and
/// returns the sorted **index order**, matching [sortByKeys].
Future<List<int>> sortByKeysYielding(SortKeysParams params) async {
  final keys = params.sortKeys;
  final n = keys.length;
  var current = List<int>.generate(n, (i) => i);
  var buffer = List<int>.filled(n, 0);
  var runsSinceYield = 0;

  for (var width = 1; width < n; width *= 2) {
    for (var lo = 0; lo < n; lo += 2 * width) {
      final mid = (lo + width < n) ? lo + width : n;
      final hi = (lo + 2 * width < n) ? lo + 2 * width : n;
      var i = lo;
      var j = mid;
      var k = lo;
      while (i < mid && j < hi) {
        // `<= 0` keeps equal keys in their original relative order (stable).
        if (defaultSortCompare(keys[current[i]], keys[current[j]], ascending: params.ascending) <= 0) {
          buffer[k++] = current[i++];
        } else {
          buffer[k++] = current[j++];
        }
      }
      while (i < mid) {
        buffer[k++] = current[i++];
      }
      while (j < hi) {
        buffer[k++] = current[j++];
      }
      if (++runsSinceYield >= _kYieldEveryRuns) {
        runsSinceYield = 0;
        // Macrotask yield: returns to the event loop so the browser can paint a
        // frame. A microtask (`await null`) would not — Dart drains all
        // microtasks before rendering. See [_kYieldEveryRuns].
        await Future<void>.delayed(Duration.zero);
      }
    }
    final tmp = current;
    current = buffer;
    buffer = tmp;
  }
  return current;
}

/// Runs [sortTableItems] off the UI thread via `compute` on native. On web,
/// where `compute` has no isolate and would run synchronously on the single
/// main thread (freezing the UI), falls back to [sortTableItems] but still
/// returns a `Future`, so callers await the same shape on both platforms.
///
/// The web path here does not chunk the custom-comparator sort (the caller
/// supplies an arbitrary `customSort`, so there is no stable key array to
/// merge on); it accepts one synchronous sort but keeps the async signature.
/// The common default path ([sortIndexesOffThread]) IS chunked on web.
Future<List<T>> sortTableItemsOffThread<T>(SortParams<T> params) async {
  if (kIsWeb) {
    // Macrotask yield so the "sorting" indicator actually paints before the
    // (synchronous) custom-comparator sort runs; a microtask would not let the
    // browser render first. See [_kYieldEveryRuns].
    await Future<void>.delayed(Duration.zero);
    return sortTableItems(params);
  }
  return compute(sortTableItems, params);
}

/// Runs [sortByKeys] off the UI thread via `compute` on native. On web, uses
/// the cooperative chunked [sortByKeysYielding] so a large sort does not
/// freeze the single main thread.
///
/// Returns the sorted index order into the original (pre-sort) list; the
/// caller reorders its own items by these indices rather than sending them
/// across the isolate boundary — see [SortKeysParams].
Future<List<int>> sortIndexesOffThread(SortKeysParams params) {
  if (kIsWeb) {
    return sortByKeysYielding(params);
  }
  return compute(sortByKeys, params);
}

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
