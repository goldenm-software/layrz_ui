import 'package:flutter/widgets.dart';

/// Signature for a per-column cell tap callback in [LayrzColumn.onTap].
///
/// [item] is the row's underlying data object of type [T].
///
/// When a [LayrzColumn.onTap] is `null`, the table falls back to copying the
/// cell's displayed text to the clipboard instead of invoking a callback.
typedef CellTap<T> = void Function(T item);

/// Describes a single column of a `LayrzTable<T>`.
///
/// A [LayrzColumn] is a pure data/config object: it declares how to extract,
/// display, sort, and react to taps on one column's cells for a row of type
/// [T]. It carries no widget state and does not depend on `BuildContext`.
///
/// Column identity is carried by [key], which is **required** and must be
/// **unique across the column set** passed to a single table. The table uses
/// [key] directly as the header cell's key, and derives each row's cell key
/// by combining [key] with that row's index. `LayrzTableController` also
/// keys column order and visibility by [key]. There is no fallback identity
/// (no optional `id`, no index-derived key) — the caller is always
/// responsible for supplying a stable, unique [Key] per column.
///
/// Both [valueBuilder] and [customSort] must be **isolate-safe**: the table
/// may invoke them from a background isolate (via `compute`) to keep sorting
/// off the UI thread for large datasets. An isolate-safe function must not
/// capture a `BuildContext`, a `State`, a `ChangeNotifier`/`ValueNotifier`,
/// or any other object tied to the widget tree — doing so compiles cleanly
/// but crashes (or silently misbehaves) at runtime once the closure is sent
/// across the isolate boundary. Keep these closures pure: read only from
/// [T] and other isolate-safe values captured by value.
@immutable
class LayrzColumn<T> {
  /// The unique identity of this column.
  ///
  /// Required, and must be unique across the full set of columns passed to
  /// one `LayrzTable`. Used directly as the header cell's widget key; each
  /// row's cell key is derived by combining this [key] with the row's index.
  /// `LayrzTableController` also keys stored column order and visibility by
  /// this value. Equality and [hashCode] for [LayrzColumn] are based solely
  /// on [key], never on [headerText].
  final Key key;

  /// The text shown in this column's header cell.
  final String headerText;

  /// Extracts the display/sort/search string for this column from a row's
  /// data object.
  ///
  /// Called for every row to compute the cell's displayed text (unless
  /// [richTextBuilder] overrides the visual rendering), to build the
  /// case-insensitive search index, and as the input to the default sort
  /// comparator when [customSort] is not provided.
  ///
  /// **Must be isolate-safe** (see class doc): it may run inside a
  /// background isolate during sorting, so it must not capture
  /// `BuildContext`, i18n lookups, or any notifier/state object — only pure,
  /// value-based computation over [T].
  final String Function(T item) valueBuilder;

  /// Optionally overrides how this column's cell is visually rendered,
  /// producing rich text spans instead of the plain string from
  /// [valueBuilder].
  ///
  /// When provided, this controls only the cell's *display*: search and the
  /// default sort still operate on [valueBuilder]'s string (or on
  /// [customSort] when given). Because copy-to-clipboard on tap copies the
  /// cell's *displayed* text, a table falls back to reconstructing plain
  /// text from these spans for that purpose when [richTextBuilder] is set
  /// and [onTap] is `null`.
  final List<InlineSpan> Function(T item)? richTextBuilder;

  /// The horizontal alignment of this column's cell content.
  ///
  /// Defaults to [Alignment.centerLeft].
  final Alignment alignment;

  /// Whether tapping this column's header toggles sorting by this column.
  ///
  /// Defaults to `true`. When `false`, the header for this column does not
  /// respond to the sort-toggle tap gesture.
  final bool isSortable;

  /// The fixed width, in logical pixels, of this column.
  ///
  /// When `null` (the default), the column is a **flex** column: it shares
  /// the width remaining after fixed-width columns are subtracted, split
  /// evenly among all flex columns and floored at the table's configured
  /// minimum column width. When non-`null`, the column occupies exactly this
  /// many logical pixels regardless of available space.
  final double? width;

  /// Invoked when this column's cell is tapped, for the row whose data is
  /// [item].
  ///
  /// Defaults to `null`. When `null`, tapping the cell instead copies the
  /// cell's **displayed text** (see [richTextBuilder]) to the clipboard and
  /// shows a confirmation toast — the table's default tap behavior. When
  /// non-`null`, this callback runs **instead of** the clipboard copy.
  ///
  /// This is a per-cell tap affordance, distinct from tapping the column's
  /// header, which toggles sorting (see [isSortable]).
  final CellTap<T>? onTap;

  /// Overrides the default sort comparator for this column.
  ///
  /// Receives two row data objects, [T] `a` and `b`, plus the current sort
  /// direction as `ascending`, and must return a negative, zero, or positive
  /// `int` following the standard `Comparator` contract (already accounting
  /// for `ascending`). When `null`, the table falls back to its default
  /// comparator over [valueBuilder]'s string (numeric, then `H:M:S`
  /// duration, then `DateTime`, then case-insensitive string compare).
  ///
  /// **Must be isolate-safe** (see class doc): like [valueBuilder], this may
  /// run inside a background isolate during sorting and must not capture
  /// `BuildContext`, i18n lookups, or any notifier/state object.
  final int Function(T a, T b, bool ascending)? customSort;

  /// Creates a [LayrzColumn].
  ///
  /// [key] is required and must be unique across the column set. [headerText]
  /// and [valueBuilder] are required. All other parameters are optional and
  /// take the defaults documented on their respective fields.
  const LayrzColumn({
    required this.key,
    required this.headerText,
    required this.valueBuilder,
    this.richTextBuilder,
    this.alignment = Alignment.centerLeft,
    this.isSortable = true,
    this.width,
    this.onTap,
    this.customSort,
  });

  /// Returns a copy of this column with the given fields replaced.
  ///
  /// Each parameter, when provided, replaces the corresponding field on the
  /// returned [LayrzColumn]; omitted parameters keep this column's current
  /// value.
  LayrzColumn<T> copyWith({
    Key? key,
    String? headerText,
    String Function(T item)? valueBuilder,
    List<InlineSpan> Function(T item)? richTextBuilder,
    Alignment? alignment,
    bool? isSortable,
    double? width,
    CellTap<T>? onTap,
    int Function(T a, T b, bool ascending)? customSort,
  }) {
    return LayrzColumn<T>(
      key: key ?? this.key,
      headerText: headerText ?? this.headerText,
      valueBuilder: valueBuilder ?? this.valueBuilder,
      richTextBuilder: richTextBuilder ?? this.richTextBuilder,
      alignment: alignment ?? this.alignment,
      isSortable: isSortable ?? this.isSortable,
      width: width ?? this.width,
      onTap: onTap ?? this.onTap,
      customSort: customSort ?? this.customSort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LayrzColumn<T> && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => Object.hash(runtimeType, key);
}
