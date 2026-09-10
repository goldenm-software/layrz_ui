import 'package:flutter/widgets.dart';

/// Owns and persists interactive state for a [LayrzLayout] that would
/// otherwise be lost whenever the layout (or its ancestor route) rebuilds
/// or remounts — most commonly on navigation, when a new page is pushed
/// with a fresh [LayrzLayout] wrapping it.
///
/// A [LayrzLayoutController] follows the same `ChangeNotifier` shape as the
/// repo's other stateful controllers (e.g. `LayrzTableController`): every
/// mutator updates the controller's fields and calls [notifyListeners], so
/// widgets that listen to the controller rebuild automatically.
///
/// Three pieces of state are persisted:
/// - The navigation rail's scroll offset, via [railScrollController] and
///   [railScrollOffset] — so scrolling down a long list of navigation items
///   is not reset every time the page body changes. On the expanded (rail)
///   presentation this is automatic: the same [ScrollController] instance
///   stays attached to the same long-lived scrollable. On the drawer
///   presentation the scrollable is recreated on every rebuild of the
///   drawer branch, so [railScrollOffset] is kept as the durable source of
///   truth and [restoreRailScroll] must be called after each such rebuild
///   to jump the freshly-attached scrollable back to it.
/// - Whether the notifications panel is open, via [notificationsOpen].
/// - The current search query typed into the layout's search affordance,
///   via [searchQuery].
///
/// **Lifecycle**: like every controller in this design system, disposal is
/// caller-owned. If [LayrzLayout] is given an external controller, the
/// layout never disposes it; the caller must call [dispose] itself (e.g.
/// from a `State.dispose()`). If [LayrzLayout] creates its own internal
/// controller because none was supplied, the layout disposes that internal
/// instance when it unmounts.
class LayrzLayoutController extends ChangeNotifier {
  /// Creates a [LayrzLayoutController].
  ///
  /// [notificationsOpen] seeds the initial open state of the notifications
  /// panel; defaults to `false` (closed).
  ///
  /// [searchQuery] seeds the initial search query text; defaults to an
  /// empty string (no filter applied).
  LayrzLayoutController({
    bool notificationsOpen = false,
    String searchQuery = '',
    // ignore: prefer_initializing_formals
  }) : _notificationsOpen = notificationsOpen,
       // ignore: prefer_initializing_formals
       _searchQuery = searchQuery,
       _railScrollController = ScrollController() {
    _railScrollController.addListener(_onRailScrolled);
  }

  /// The [ScrollController] attached to the navigation rail's scrollable
  /// list of items.
  ///
  /// Because this controller (and the [ScrollController] it owns) outlives
  /// any single [LayrzLayout] widget instance, the rail's scroll offset
  /// survives a route rebuild that replaces the layout's `body` — the rail
  /// itself does not reset to the top every time the page changes.
  ///
  /// Owned by this [LayrzLayoutController]: it is created in the
  /// constructor and disposed in [dispose]. Do not dispose it separately.
  ScrollController get railScrollController => _railScrollController;
  final ScrollController _railScrollController;

  /// The last known scroll offset of [railScrollController], persisted
  /// independently of whichever scrollable widget the controller happens to
  /// be attached to right now.
  ///
  /// This is updated automatically whenever [railScrollController] has an
  /// attached client and scrolls (see [_onRailScrolled]), so it always
  /// reflects the most recent position the user scrolled the nav rail or
  /// drawer to — even across a rebuild that detaches and reattaches
  /// [railScrollController] to a brand-new scrollable, which is exactly what
  /// happens to the drawer presentation's nav panel on every rebuild of the
  /// drawer branch. Defaults to `0.0`.
  ///
  /// Use [restoreRailScroll] after such a rebuild to jump the newly-attached
  /// scrollable back to this offset.
  double get railScrollOffset => _railScrollOffset;
  double _railScrollOffset = 0.0;

  /// Listener attached to [railScrollController] in the constructor.
  ///
  /// Mirrors [railScrollController]'s current pixel offset into
  /// [railScrollOffset] whenever the controller has an attached client and
  /// that client reports a scroll position. Guarded with [ScrollController.hasClients]
  /// because a [ScrollController] can fire spurious notifications (or be
  /// queried) while briefly detached — e.g. mid-rebuild, between the old
  /// scrollable disposing and a new one attaching.
  void _onRailScrolled() {
    if (!_railScrollController.hasClients) return;
    _railScrollOffset = _railScrollController.offset;
  }

  /// Restores [railScrollController] to [railScrollOffset], if needed.
  ///
  /// Call this after a rebuild that may have replaced the scrollable widget
  /// [railScrollController] is attached to with a brand-new one — most
  /// notably, every rebuild of the drawer presentation's nav panel, whose
  /// `SingleChildScrollView` is recreated from scratch each time. A freshly
  /// attached scrollable always starts at `0.0` regardless of what
  /// [railScrollController] previously pointed at, so without this call the
  /// drawer's nav rail would silently reset to the top on every such
  /// rebuild.
  ///
  /// This is a no-op — safe to call unconditionally, including from a
  /// post-frame callback on every build — when:
  /// - [railScrollController] has no attached client yet (nothing to jump), or
  /// - the attached client's current offset already matches [railScrollOffset]
  ///   (the expanded/rail presentation's long-lived scrollable, where the
  ///   offset was never lost in the first place).
  ///
  /// The target offset is clamped to the attached position's
  /// `maxScrollExtent` so a saved offset that no longer fits (e.g. the nav
  /// item list shrank) does not throw or overscroll.
  void restoreRailScroll() {
    if (!_railScrollController.hasClients) return;
    final position = _railScrollController.position;
    if (position.pixels == _railScrollOffset) return;
    final target = _railScrollOffset.clamp(0.0, position.maxScrollExtent);
    _railScrollController.jumpTo(target);
  }

  /// Whether the notifications panel is currently open.
  bool get notificationsOpen => _notificationsOpen;
  bool _notificationsOpen;

  /// Sets whether the notifications panel is open.
  ///
  /// [open] replaces [notificationsOpen]. If [open] equals the current
  /// value, this is a no-op — [notifyListeners] is not called. Otherwise
  /// [notifyListeners] is called so listening widgets can react (e.g. to
  /// show or hide the panel).
  void setNotificationsOpen(bool open) {
    if (_notificationsOpen == open) return;
    _notificationsOpen = open;
    notifyListeners();
  }

  /// Toggles [notificationsOpen] between open and closed.
  ///
  /// Equivalent to calling [setNotificationsOpen] with the opposite of the
  /// current value.
  void toggleNotifications() => setNotificationsOpen(!_notificationsOpen);

  /// The current search query text.
  ///
  /// An empty string (the default) means no search filter is applied.
  String get searchQuery => _searchQuery;
  String _searchQuery;

  /// Sets the current search query text.
  ///
  /// [query] replaces [searchQuery] verbatim (no trimming or
  /// normalization). If [query] equals the current value, this is a
  /// no-op — [notifyListeners] is not called. Otherwise [notifyListeners]
  /// is called.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _railScrollController.removeListener(_onRailScrolled);
    _railScrollController.dispose();
    super.dispose();
  }
}
