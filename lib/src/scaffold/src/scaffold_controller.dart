import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Controller for managing the opened item state in [LayrzScaffoldShell].
///
/// This controller tracks selection by item key, not by item instance. This design
/// makes selection immune to instance replacement — when the list is rebuilt with
/// new instances (e.g., refetched from an API), the selection persists if the keys match.
///
/// It is a [ChangeNotifier], so listening widgets rebuild when the opened key changes.
///
/// In addition to the opened-item state, this controller exposes the list panel's item
/// counts — [totalCount] and [filteredCount] — as read-only [ValueListenable]s, mirroring
/// `LayrzTableController`'s `totalCount`/`visibleCount` pair. [LayrzScaffoldShell] has no
/// multiselect, so unlike the table controller there is no "selected count" here — only
/// total and post-search counts.
///
/// **Ownership:** The consuming app creates and disposes the controller; the shell
/// listens and rebuilds. The shell does NOT dispose the controller it receives.
class LayrzScaffoldController extends ChangeNotifier {
  /// The key of the currently opened item, or null when the detail pane is closed.
  Key? _openedKey;

  /// The builder for the currently opened detail content, or null when the detail
  /// pane is closed.
  ///
  /// Unlike [_openedKey] (which is looked up against `LayrzScaffoldShell.items` to
  /// highlight the matching row), this builder is the actual source of the detail
  /// pane's content — and the source of truth for [isOpen]. It need not correspond
  /// to any item in the list at all — this is what makes a "create new item" detail
  /// pane possible: the caller opens with a builder for a creation form and no key
  /// (or a synthetic one), and no row highlights because [_openedKey] stays null.
  WidgetBuilder? _openedBuilder;

  /// Backing notifier for [totalCount] — the number of items in the unfiltered item
  /// list. Driven by the [LayrzScaffoldShell]'s list panel.
  final ValueNotifier<int> _totalCount = ValueNotifier<int>(0);

  /// Backing notifier for [filteredCount] — the number of items currently shown after
  /// the active search filter. Driven by the [LayrzScaffoldShell]'s list panel.
  final ValueNotifier<int> _filteredCount = ValueNotifier<int>(0);

  /// Creates a new [LayrzScaffoldController] with an optional initial opened key.
  ///
  /// - [initialOpenedKey]: The key of the item to open on creation, or null to start closed.
  LayrzScaffoldController({
    Key? initialOpenedKey,
  }) : _openedKey = initialOpenedKey;

  /// The key of the currently opened item, or null when the detail pane is closed.
  Key? get openedKey => _openedKey;

  /// The builder for the currently opened detail content, or null when the detail
  /// pane is closed.
  ///
  /// [LayrzScaffoldShell] renders this directly in its detail pane (both the
  /// wide-layout side-by-side pane and the narrow-layout modal sheet) instead of
  /// resolving [openedKey] against its items list — see [open].
  WidgetBuilder? get openedBuilder => _openedBuilder;

  /// Whether the detail pane is currently open.
  ///
  /// Open state is defined by [openedBuilder], not [openedKey]: [key] is optional
  /// on [open], so a "create new item" flow can open a detail pane with a builder
  /// and no key at all (nothing to highlight in the list). That state is still
  /// open — [isOpen] must read `true` for it — so this checks [openedBuilder],
  /// never [openedKey].
  bool get isOpen => _openedBuilder != null;

  /// The number of items in the unfiltered item list, as a [ValueListenable].
  ///
  /// This is the length of the shell's full `items` list, independent of any search
  /// filter. It is `0` until the associated [LayrzScaffoldShell] has completed its
  /// first filter computation.
  ValueListenable<int> get totalCount => _totalCount;

  /// The number of items currently shown after the active search filter, as a
  /// [ValueListenable].
  ///
  /// With no search text this equals [totalCount]; with a search active it is the
  /// count of items that match. It is `0` until the associated [LayrzScaffoldShell]
  /// has completed its first filter computation. Wrap it in a `ValueListenableBuilder`
  /// to rebuild only when the count changes (e.g. an "X of Y" results label), without
  /// listening to the controller's other state.
  ValueListenable<int> get filteredCount => _filteredCount;

  /// Updates the [totalCount] and [filteredCount] notifiers.
  ///
  /// Called by [LayrzScaffoldShell]'s list panel each time it recomputes its filtered
  /// items. This is the write side of the read-only [totalCount]/[filteredCount]
  /// listenables; consumers observe the notifiers rather than calling this. Each
  /// notifier only notifies its listeners when its value actually changes.
  ///
  /// - [total]: The number of items in the unfiltered item list.
  /// - [filtered]: The number of items currently shown after the active search filter.
  void updateCounts({required int total, required int filtered}) {
    _totalCount.value = total;
    _filteredCount.value = filtered;
  }

  /// Opens the detail pane with the given detail content [builder], optionally
  /// highlighting the list row at [key].
  ///
  /// Sets [openedBuilder] to [builder] and [openedKey] to [key], then notifies
  /// listeners. [key] is optional and need not match any item in
  /// `LayrzScaffoldShell.items` — omitting it (or passing a synthetic key that
  /// matches no row) opens a detail pane with no corresponding row highlighted,
  /// which is exactly what a "create new item" flow needs: there is no domain
  /// object yet to key against, and none of the list rows should look selected.
  ///
  /// If the SAME [key] is already opened with an identical [builder], this is a
  /// no-op. Re-opening with a DIFFERENT [builder] (same key or not) still takes
  /// effect — the identity check covers both fields precisely so that re-opening
  /// to swap the detail content (e.g. the same synthetic "create" key redrawn
  /// with fresh form state) is never silently dropped.
  ///
  /// - [builder]: Builds the detail pane's content for this open call.
  /// - [key]: The key of the item (or a synthetic key) to open, or null to open
  ///   with no row highlighted. Defaults to null.
  void open({required WidgetBuilder builder, Key? key}) {
    if (identical(_openedBuilder, builder) && _openedKey == key) return;
    _openedKey = key;
    _openedBuilder = builder;
    notifyListeners();
  }

  /// Closes the detail pane.
  ///
  /// Sets [openedKey] and [openedBuilder] to null and notifies listeners.
  /// If already closed (per [isOpen], i.e. [openedBuilder] is already null), this
  /// is a no-op — checked on [openedBuilder], not [openedKey], since a keyless
  /// "create" open leaves [openedKey] null while still genuinely open.
  void close() {
    if (_openedBuilder == null) return;
    _openedKey = null;
    _openedBuilder = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _totalCount.dispose();
    _filteredCount.dispose();
    super.dispose();
  }
}
