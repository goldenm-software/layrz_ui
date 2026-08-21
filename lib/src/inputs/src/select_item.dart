import 'package:flutter/widgets.dart';

/// Immutable shared value+label item type consumed by select-like input components.
///
/// `LayrzSelectItem<T>` is the standard item type used by [LayrzSelectInput], [LayrzRadioInput],
/// [LayrzComboBoxInput], [LayrzMultiSelectInput], and [LayrzDualListInput]. It combines a
/// human-readable label, a typed value, optional custom rendering, and search metadata into
/// a single immutable structure.
///
/// The `labelText` serves dual roles: it is the primary search key and the default display
/// text when the item is selected in a field. The `value` is what gets passed back to the
/// consumer on selection. The `child` allows consumers to customize item rendering in
/// selection surfaces (dropdowns, dialogs) without affecting the field's display of the
/// selected item (which always uses `labelText`).
@immutable
class LayrzSelectItem<T> {
  /// The human-readable label displayed to the user.
  ///
  /// This is a required field that serves two purposes:
  /// 1. **Display**: It is the default text shown for this item in selection surfaces.
  ///    When a consumer does not provide a [child], surfaces render a default row
  ///    using this text.
  /// 2. **Search**: This is the primary search key. When a user types into a searchable
  ///    input (e.g., `LayrzSelectInput` with search enabled), the query is matched
  ///    against this text (case-insensitive substring match).
  ///
  /// Even if [child] is supplied to customize rendering, `labelText` is still required
  /// because it is used for field display and search matching.
  final String labelText;

  /// The typed value associated with this item.
  ///
  /// This is the value handed back to the consumer when this item is selected.
  /// It is nullable to support "none" / "clear" entries that represent the absence
  /// of a selection (null value).
  ///
  /// When used in [LayrzSelectInput], selecting an item with a null value clears
  /// the field's selection.
  final T? value;

  /// Optional custom widget for rendering this item in selection surfaces.
  ///
  /// When non-null, this widget is rendered instead of the default label-based row
  /// in dropdowns, dialogs, and other selection surfaces. The consumer retains full
  /// control over the appearance of items in the selection list.
  ///
  /// The field's display of the selected item always uses [labelText], never this widget.
  /// So the field still shows the label even if a custom rendering is provided.
  ///
  /// Common use cases: custom icons, colored badges, complex item layouts.
  final Widget? child;

  /// Additional strings used for searching beyond [labelText].
  ///
  /// This set holds extra search terms that are folded into matching when the user
  /// searches. Examples include:
  /// - Alternative spellings or abbreviations (`{"Jan", "January"}` for a month)
  /// - Category or group names (`{"Sensor", "Hardware"}` for a device item)
  /// - Codes or IDs (`{"SKU-123", "Inventory ID"}`)
  ///
  /// All entries in this set participate in the same case-insensitive substring matching
  /// as [labelText]. An empty set is valid and means no additional search terms.
  ///
  /// Set equality is order-independent, so two items with the same attributes in
  /// different orders are equal.
  final Set<String> searchableAttributes;

  /// Creates a new [LayrzSelectItem].
  const LayrzSelectItem({
    required this.labelText,
    required this.value,
    this.child,
    this.searchableAttributes = const {},
  });

  /// Returns a copy of this item with the given fields replaced.
  ///
  /// Fields not passed retain their original values. To explicitly set a field to null
  /// (for [value] or [child], which are nullable), pass `null` directly:
  ///
  /// ```dart
  /// final item = LayrzSelectItem(labelText: 'Alice', value: 123, child: someWidget);
  ///
  /// // Clear the custom child, keep value:
  /// final clearedChild = item.copyWith(child: null);
  /// assert(clearedChild.child == null);
  /// assert(clearedChild.value == 123);
  ///
  /// // Clear the value, keep custom child:
  /// final clearedValue = item.copyWith(value: null);
  /// assert(clearedValue.value == null);
  /// assert(clearedValue.child == someWidget);
  /// ```
  ///
  /// The implementation uses a private sentinel (`_unset`) to distinguish "field not passed"
  /// (retain current value) from "field explicitly set to null" (set to null). This allows
  /// both nullable fields to be cleared independently.
  LayrzSelectItem<T> copyWith({
    String? labelText,
    Object? value = _unset,
    Object? child = _unset,
    Set<String>? searchableAttributes,
  }) {
    return LayrzSelectItem<T>(
      labelText: labelText ?? this.labelText,
      value: identical(value, _unset) ? this.value : value as T?,
      child: identical(child, _unset) ? this.child : child as Widget?,
      searchableAttributes: searchableAttributes ?? this.searchableAttributes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzSelectItem<T> &&
          runtimeType == other.runtimeType &&
          labelText == other.labelText &&
          value == other.value &&
          child == other.child &&
          _setEquals(searchableAttributes, other.searchableAttributes);

  @override
  int get hashCode => Object.hash(
    labelText,
    value,
    child,
    Object.hashAll(searchableAttributes.toList()..sort()),
  );

  /// Checks whether this item matches a search query.
  ///
  /// Returns `true` if the query matches the [labelText] or any entry in
  /// [searchableAttributes] using case-insensitive substring matching.
  /// An empty or whitespace-only query returns `true` (matches everything).
  ///
  /// Examples:
  /// ```dart
  /// final item = LayrzSelectItem(
  ///   labelText: 'Production Server',
  ///   searchableAttributes: {'prod', 'backend'},
  /// );
  ///
  /// item.matches('prod')       // → true (matches 'Production' in labelText)
  /// item.matches('Prod')       // → true (case-insensitive)
  /// item.matches('backend')    // → true (matches searchableAttributes)
  /// item.matches('database')   // → false (no match)
  /// item.matches('')           // → true (empty query matches all)
  /// item.matches('   ')        // → true (whitespace-only matches all)
  /// ```
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();

    // Empty or whitespace-only query matches everything.
    if (normalized.isEmpty) return true;

    // Check labelText.
    if (labelText.toLowerCase().contains(normalized)) return true;

    // Check searchableAttributes.
    for (final attr in searchableAttributes) {
      if (attr.toLowerCase().contains(normalized)) return true;
    }

    return false;
  }

  @override
  String toString() =>
      'LayrzSelectItem<$T>('
      'labelText: $labelText, '
      'value: $value, '
      'child: $child, '
      'searchableAttributes: $searchableAttributes'
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
