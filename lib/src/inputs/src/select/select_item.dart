import 'package:flutter/widgets.dart';

/// Immutable shared value+presentation item type consumed by select-like input components.
///
/// `LayrzSelectItem<T>` is the standard item type used by [LayrzSelectInput] and
/// [LayrzRadioInput]. It is intentionally reduced to exactly three fields: a typed
/// [value], a set of [searchableStrings] used purely for filtering, and a [child]
/// widget that is the item's **only** presentation.
///
/// **BREAKING:** earlier versions also carried a `labelText` string that served double
/// duty as both the default display text and the primary search key. That field is
/// gone. The item now defines its own presentation entirely through [child] -- in
/// selection surfaces (dropdowns, bottom sheets) and, where the consuming widget
/// supports it, in the field itself while idle. A caller that put a flag icon next to
/// a country name in [child] sees that same flag in the field, not a degraded
/// plain-text fallback. Search is a fully separate concern, driven only by
/// [searchableStrings] -- so an item can be found by text that never appears on screen
/// at all (an ID, an alternate spelling, a category tag).
@immutable
class LayrzSelectItem<T> {
  /// The typed value associated with this item.
  ///
  /// This is the value handed back to the consumer when this item is selected.
  /// It is nullable to support "none" / "clear" entries that represent the absence
  /// of a selection (null value).
  ///
  /// When used in [LayrzSelectInput], selecting an item with a null value clears
  /// the field's selection.
  final T? value;

  /// The widget that renders this item -- its only presentation.
  ///
  /// Rendered in selection surfaces (dropdowns, dialogs, bottom sheets) in place of
  /// this item's row content, and, in widgets that support it (e.g. [LayrzSelectInput]),
  /// in the field itself while idle with this item selected. There is no separate label
  /// string anywhere in this type: whatever [child] renders is what the user sees,
  /// everywhere this item appears. Required -- an item with nothing to render is not a
  /// valid item.
  final Widget child;

  /// Strings used for searching, entirely independent of what [child] renders on screen.
  ///
  /// This set holds every term that participates in matching when the user searches --
  /// there is no other search key. Examples include:
  /// - The text visible in [child] itself, when it should also be searchable
  /// - Alternative spellings or abbreviations (`{"Jan", "January"}` for a month)
  /// - Category or group names (`{"Sensor", "Hardware"}` for a device item)
  /// - Codes or IDs (`{"SKU-123", "Inventory ID"}`), which may never appear in [child] at all
  ///
  /// All entries in this set participate in the same case-insensitive substring matching.
  /// An empty set means this item can never be found by search (it still renders normally;
  /// it is simply excluded whenever a non-empty query is typed).
  ///
  /// Set equality is order-independent, so two items with the same strings in
  /// different orders are equal.
  final Set<String> searchableStrings;

  /// Creates a new [LayrzSelectItem].
  const LayrzSelectItem({
    required this.value,
    required this.child,
    this.searchableStrings = const {},
  });

  /// Returns a copy of this item with the given fields replaced.
  ///
  /// Fields not passed retain their original values. To explicitly set [value] to null
  /// (clearing it while keeping the item otherwise intact), pass `null` directly:
  ///
  /// ```dart
  /// final item = LayrzSelectItem(value: 123, child: someWidget);
  ///
  /// // Clear the value, keep the child:
  /// final cleared = item.copyWith(value: null);
  /// assert(cleared.value == null);
  /// assert(cleared.child == someWidget);
  /// ```
  ///
  /// The implementation uses a private sentinel (`_unset`) to distinguish "field not passed"
  /// (retain current value) from "field explicitly set to null" for the nullable [value] field.
  LayrzSelectItem<T> copyWith({
    Object? value = _unset,
    Widget? child,
    Set<String>? searchableStrings,
  }) {
    return LayrzSelectItem<T>(
      value: identical(value, _unset) ? this.value : value as T?,
      child: child ?? this.child,
      searchableStrings: searchableStrings ?? this.searchableStrings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSelectItem<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          child == other.child &&
          _setEquals(searchableStrings, other.searchableStrings);

  @override
  int get hashCode => Object.hash(
    value,
    child,
    Object.hashAll(searchableStrings.toList()..sort()),
  );

  /// Checks whether this item matches a search query.
  ///
  /// Returns `true` if the query matches any entry in [searchableStrings], using
  /// case-insensitive substring matching. An empty or whitespace-only query returns
  /// `true` (matches everything). Note this is driven **entirely** by [searchableStrings] --
  /// [child] never participates in matching, since it may not even contain text.
  ///
  /// Examples:
  /// ```dart
  /// final item = LayrzSelectItem(
  ///   value: 'srv-1',
  ///   child: const Text('Production Server'),
  ///   searchableStrings: {'Production Server', 'prod', 'backend'},
  /// );
  ///
  /// item.matches('prod')       // → true
  /// item.matches('Prod')       // → true (case-insensitive)
  /// item.matches('backend')    // → true
  /// item.matches('database')   // → false (no match)
  /// item.matches('')           // → true (empty query matches all)
  /// item.matches('   ')        // → true (whitespace-only matches all)
  /// ```
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();

    // Empty or whitespace-only query matches everything.
    if (normalized.isEmpty) return true;

    for (final term in searchableStrings) {
      if (term.toLowerCase().contains(normalized)) return true;
    }

    return false;
  }

  @override
  String toString() =>
      'LayrzSelectItem<$T>('
      'value: $value, '
      'child: $child, '
      'searchableStrings: $searchableStrings'
      ')';

  /// Private sentinel used in [copyWith] to distinguish "field not passed" from null.
  static const Object _unset = Object();

  /// Helper to compare sets for equality in an order-independent way.
  static bool _setEquals<E>(Set<E> a, Set<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }
}
