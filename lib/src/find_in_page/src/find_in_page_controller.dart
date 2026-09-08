import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/search/search.dart';

/// How long [LayrzFindInPageController.setQuery] waits after the last
/// keystroke before triggering a walk.
///
/// Matches the debounce proven in the DESIGN-109 spike
/// (`example/lib/src/sections/find_in_page/find_spike.dart`'s
/// `kFindSpikeQueryDebounce`), which itself mirrors `LayrzSearchInput`'s own
/// 300ms debounce (`inputs/src/search/search_input.dart`) so typing feel is
/// consistent across the design system.
const Duration kFindInPageQueryDebounce = Duration(milliseconds: 300);

/// Owns the search state and lifecycle behind [LayrzFindInPageHost] —
/// production home of the mechanism proven by the DESIGN-109 spike
/// (`example/lib/src/sections/find_in_page/find_spike.dart`).
///
/// A [ChangeNotifier] rather than a [State] directly, so [LayrzFindInPageHost]
/// can own one instance for the lifetime of the whole app while notifying
/// both the find bar and the highlight painter of state changes independently.
///
/// ### Idle cost
/// The single most important property for a find-in-page feature that is
/// **on by default** (see `LayrzApp.enableFindInPage`) is that it must cost
/// nothing when nobody is searching. This controller holds a
/// [SemanticsHandle] — the single most expensive resource involved, since
/// holding one forces Flutter to build and maintain a full semantics tree for
/// the entire app for as long as it is held (see
/// [SemanticsBinding.ensureSemantics]) — **only between [open] and [close]**,
/// never for the app's whole lifetime. An app that never opens find pays
/// exactly zero semantics-tree cost from this feature.
///
/// ### Two-layer search, lifted from the spike unchanged
/// Locating matches (via [walkSemantics], over the semantics tree) and
/// resolving word-level highlight geometry (via [findRenderTextSources] +
/// [resolveWordHighlights], over the render tree, restricted to
/// currently-visible matches) remain two separate mechanisms, for exactly the
/// reasons documented on the spike's own `_performWalk`/`_resolveHighlights` —
/// see those doc comments for the full reasoning this class's [_performWalk]
/// and [_resolveHighlights] implement identically.
///
/// ### Self-exclusion is release-safe, not debug-only
/// The spike excluded its own find bar's subtree from the walk by resolving
/// `RenderObject.debugSemantics` — an accessor that is `null` outside of
/// `kReleaseMode` (see the spike's `_findBarSubtreeId` doc). That is
/// explicitly documented there as a spike-only shortcut, unfit for
/// production. This controller instead excludes the find bar's own matches
/// **by rect containment** ([excludeRect]): after `walkSemantics` returns
/// every match anywhere in the tree (find bar included — nothing is pruned
/// from the walk itself), any match whose [FindMatch.globalRect] center falls
/// inside [excludeRect] is dropped before matches are ever exposed to a
/// caller. [LayrzFindInPageHost] measures the find bar's own on-screen rect
/// via a plain [RenderBox.localToGlobal] (always available in every build
/// mode, unlike `debugSemantics`) and keeps [excludeRect] in sync with it on
/// every layout the bar undergoes. Center-containment (rather than exact
/// overlap) mirrors `resolveRenderTextSource`'s own containment test in
/// `render_text_walker.dart` — a small, deliberate tolerance for the same
/// kind of sub-pixel rounding that test's doc explains.
class LayrzFindInPageController extends ChangeNotifier {
  /// Whether find is currently open. `false` initially and after [close].
  ///
  /// While `false`, this controller holds no [SemanticsHandle], subscribes to
  /// no [SemanticsOwner], and [matches]/[highlights] are always empty — see
  /// the class doc's "Idle cost" section.
  bool get isOpen => _isOpen;
  bool _isOpen = false;

  /// The current search query text.
  String get query => _query;
  String _query = '';

  /// Whether a search is currently in flight — pending in its debounce
  /// window, or walked but not yet resolved to painted highlights.
  ///
  /// Drives [LayrzFindBar]'s thin indeterminate progress line: `true` from
  /// the moment a non-empty query (re)starts the debounce timer in
  /// [setQuery], or [searchNow] is invoked for a non-empty query, until the
  /// highlight resolution for that **settled** query commits at the end of
  /// [_resolveHighlights]. `false` while idle (no query, or the last search's
  /// results are already painted) and immediately after the query is cleared
  /// — there is nothing to search, so nothing is "in flight".
  ///
  /// Deliberately hooks into the existing debounce/generation-guard/
  /// post-frame-resolve lifecycle rather than adding a second timer: the
  /// generation guard in [_staleGenerationGuard] is what lets this flip to
  /// `false` only when the resolution that commits belongs to the latest
  /// [_matchesGeneration], the same guard that already protects
  /// [_highlights] from a stale commit.
  bool get isSearching => _isSearching;
  bool _isSearching = false;

  /// Sets [_isSearching] and notifies listeners only when the value actually
  /// changes — keeps [LayrzFindBar] from rebuilding on every walk/resolve
  /// tick when the flag was already in the state being set.
  void _setSearching(bool value) {
    if (_isSearching == value) return;
    _isSearching = value;
    notifyListeners();
  }

  /// The most recent walk's results, in reading order, with the find bar's
  /// own matches already excluded via [excludeRect] — see the class doc's
  /// "Self-exclusion" section. Empty before the first walk, when the last
  /// walk found nothing, or whenever [isOpen] is `false`.
  List<FindMatch> get matches => _matches;
  List<FindMatch> _matches = const [];

  /// The index into [matches] treated as "current". `-1` when there is no
  /// current match.
  int get currentIndex => _currentIndex;
  int _currentIndex = -1;

  /// The most recently resolved highlight geometry for the currently-visible
  /// matches, in the same order [visibleMatches] would produce.
  List<MatchHighlight> get highlights => _highlights;
  List<MatchHighlight> _highlights = const [];

  /// The subset of [matches] currently on screen (`!isHidden`), in the same
  /// order [matches] already holds them (reading order). See [FindMatch.isHidden]'s
  /// doc for why a hidden match still counts and cycles, but is never painted.
  List<FindMatch> get visibleMatches => _matches.where((match) => !match.isHidden).toList(growable: false);

  /// The find bar's own on-screen rect, used to exclude its matches from the
  /// walk — see the class doc's "Self-exclusion" section.
  ///
  /// Kept in sync by [LayrzFindInPageHost] via [updateExcludeRect] on every
  /// layout the bar undergoes. `null` before the bar has ever been measured
  /// (e.g. the first frame find is open), in which case no exclusion is
  /// applied for that walk — the very next post-frame walk, once the bar's
  /// rect is known, corrects this.
  Rect? get excludeRect => _excludeRect;
  Rect? _excludeRect;

  /// The pending debounced walk, if any — see [setQuery]. `null` when there
  /// is no pending debounce.
  Timer? _debounceTimer;

  /// Bumped every time [_performWalk] actually changes [_matches] — the
  /// generation [_resolveHighlights] guards against committing a stale
  /// result for, exactly mirroring the spike's `_staleGenerationGuard`.
  int _matchesGeneration = 0;

  /// Guards against scheduling more than one pending post-frame walk at once.
  bool _walkScheduled = false;

  /// Guards against scheduling more than one pending post-frame highlight
  /// resolution at once.
  bool _highlightResolveScheduled = false;

  /// Holds the semantics tree open while [isOpen] is `true`. `null` while
  /// closed — see the class doc's "Idle cost" section.
  SemanticsHandle? _semanticsHandle;

  /// Whether this controller has been [dispose]d — guards every callback and
  /// scheduled post-frame closure below against running after teardown.
  bool _disposed = false;

  /// Locates the live [SemanticsOwner] for the app's [View].
  ///
  /// Mirrors the spike's own `_findSemanticsOwner` exactly: walks
  /// [RendererBinding.rootPipelineOwner]'s children (one [PipelineOwner] per
  /// [View]; the single-implicit-view case this targets has exactly one) and
  /// returns the first exposing a non-null [PipelineOwner.semanticsOwner].
  /// `null` before the first frame has attached a render tree.
  SemanticsOwner? _findSemanticsOwner() {
    SemanticsOwner? found;
    RendererBinding.instance.rootPipelineOwner.visitChildren((child) {
      found ??= child.semanticsOwner;
    });
    return found;
  }

  /// Locates the live render tree's root [RenderObject], the render-tree
  /// counterpart to [_findSemanticsOwner] — mirrors the spike's
  /// `_findRenderTreeRoot` exactly.
  RenderObject? _findRenderTreeRoot() {
    RenderObject? found;
    RendererBinding.instance.rootPipelineOwner.visitChildren((child) {
      found ??= child.rootNode;
    });
    return found;
  }

  /// Opens find: acquires the [SemanticsHandle], subscribes to the live
  /// [SemanticsOwner], and schedules an initial walk if [query] is already
  /// non-empty (e.g. re-opening after a previous session left text behind).
  ///
  /// A no-op if already [isOpen] — opening twice does not acquire a second
  /// handle or a second subscription.
  void open() {
    if (_isOpen) return;
    _isOpen = true;
    _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
    _findSemanticsOwner()?.addListener(_handleSemanticsChanged);
    if (_query.trim().isNotEmpty) {
      _scheduleWalk();
    }
    notifyListeners();
  }

  /// Closes find: cancels any pending debounce, unsubscribes from the
  /// [SemanticsOwner], disposes the [SemanticsHandle], and clears every piece
  /// of search state instantly (matches, highlights, current index) — a
  /// closed find bar shows nothing and holds nothing.
  ///
  /// **Does not clear [query]** — matching a real browser's Ctrl+F, reopening
  /// preserves the last search text (see [open]'s doc). A no-op if already
  /// closed.
  void close() {
    if (!_isOpen) return;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _findSemanticsOwner()?.removeListener(_handleSemanticsChanged);
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
    _isOpen = false;
    _matches = const [];
    _highlights = const [];
    _currentIndex = -1;
    _matchesGeneration++;
    _isSearching = false;
    notifyListeners();
  }

  /// Toggles find open/closed — the direct target of the Ctrl/Cmd+F shortcut
  /// [LayrzFindInPageHost] registers.
  void toggle() {
    if (_isOpen) {
      close();
    } else {
      open();
    }
  }

  /// Updates [excludeRect] — called by [LayrzFindInPageHost] whenever the
  /// find bar's measured rect changes (its first layout, or any later resize
  /// / reposition). See the class doc's "Self-exclusion" section.
  ///
  /// Does not itself trigger a re-walk: the bar's own layout settling is not,
  /// by itself, a content change worth re-walking for — the next genuine
  /// semantics change (typing, scrolling) picks up the corrected exclusion
  /// automatically. Passing the same [Rect] as already held is a no-op.
  void updateExcludeRect(Rect rect) {
    if (_excludeRect == rect) return;
    _excludeRect = rect;
  }

  /// Handles every keystroke from the find bar's query field — see the
  /// spike's `_handleQueryChanged` doc for the full "why debounce, why
  /// clearing bypasses it" reasoning this lifts unchanged.
  ///
  /// [newValue] becoming empty or whitespace-only clears
  /// matches/highlights/currentIndex **immediately**, with no debounce delay
  /// — a browser-standard instant response to clearing the field. A
  /// non-empty [newValue] instead (re)starts [kFindInPageQueryDebounce],
  /// cancelling whatever debounce was already pending.
  void setQuery(String newValue) {
    _query = newValue;
    _debounceTimer?.cancel();

    if (newValue.trim().isEmpty) {
      _debounceTimer = null;
      _isSearching = false;
      if (_matches.isEmpty && _highlights.isEmpty) {
        notifyListeners();
        return;
      }
      _matches = const [];
      _highlights = const [];
      _currentIndex = -1;
      _matchesGeneration++;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _debounceTimer = Timer(kFindInPageQueryDebounce, () {
      _debounceTimer = null;
      if (_disposed || !_isOpen) return;
      _performWalk();
    });
    notifyListeners();
  }

  /// Runs an immediate walk against [query], bypassing any pending debounce
  /// — used by the find bar's submit action (Enter in the query field when
  /// there is not yet a settled match set).
  void searchNow() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_query.trim().isNotEmpty) {
      _isSearching = true;
    }
    _performWalk();
  }

  /// Advances [currentIndex] to the next match (wrapping to `0` past the
  /// last one) and asks the framework to scroll it into view via
  /// [SemanticsAction.showOnScreen] — mirrors the spike's `_handleNextPressed`
  /// exactly, including the fire-and-forget scroll request (see that
  /// method's doc for why nothing further needs to be awaited here).
  void next() {
    if (_matches.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _matches.length;
    _currentIndex = nextIndex;
    notifyListeners();

    final owner = _findSemanticsOwner();
    owner?.performAction(_matches[nextIndex].nodeId, SemanticsAction.showOnScreen);
  }

  /// Cycles [currentIndex] backward (wrapping to the last match before the
  /// first one) and requests the same scroll-into-view as [next] — the
  /// reverse-direction counterpart the spike did not need (it only ever
  /// exercised "Next"), needed here for the find bar's up/previous control
  /// and Shift+Enter.
  void previous() {
    if (_matches.isEmpty) return;
    final previousIndex = (_currentIndex - 1) % _matches.length;
    final wrapped = previousIndex < 0 ? _matches.length - 1 : previousIndex;
    _currentIndex = wrapped;
    notifyListeners();

    final owner = _findSemanticsOwner();
    owner?.performAction(_matches[wrapped].nodeId, SemanticsAction.showOnScreen);
  }

  /// Listener attached to the live [SemanticsOwner] while [isOpen] — see the
  /// spike's `_handleSemanticsChanged` doc for the full "why a pending
  /// debounce suppresses this" reasoning this lifts unchanged: every
  /// keystroke changes the query field's own semantics value, which would
  /// otherwise re-walk against still-being-typed intermediate text on the
  /// very next frame, bypassing [setQuery]'s debounce entirely.
  void _handleSemanticsChanged() {
    if (_query.trim().isEmpty) return;
    if (_debounceTimer != null) return;
    _scheduleWalk();
  }

  /// Defers a semantics walk to the next frame, coalescing any number of
  /// triggers within the current frame into a single walk — mirrors the
  /// spike's `_scheduleWalk` exactly.
  void _scheduleWalk() {
    if (_walkScheduled) return;
    _walkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walkScheduled = false;
      if (_disposed || !_isOpen) return;
      _performWalk();
    });
  }

  /// Runs [walkSemantics] against the live tree's root, applies the
  /// rect-based self-exclusion (see the class doc's "Self-exclusion"
  /// section), and updates [_matches]/[_currentIndex] — mirrors the spike's
  /// `_performWalk`, including its no-op guard (skip notifying when the
  /// freshly walked list is unchanged by value) that is what stops a
  /// walk-triggered rebuild from re-triggering another walk forever. See that
  /// method's doc for the full loop this guard closes.
  void _performWalk() {
    final root = _findSemanticsOwner()?.rootSemanticsNode;
    if (root == null) return;

    final rawMatches = walkSemantics(root, _query);
    final rect = _excludeRect;
    final matches = rect == null
        ? rawMatches
        : rawMatches.where((match) => !rect.contains(match.globalRect.center)).toList(growable: false);

    if (_matchListsEqual(matches, _matches)) {
      // The walk found nothing new to resolve highlights for — no post-frame
      // resolution will be scheduled, so this is the "settled" point for
      // this query and isSearching must clear here rather than being left
      // waiting on a resolution that will never run.
      _setSearching(false);
      return;
    }

    _matches = matches;
    _currentIndex = matches.isEmpty ? -1 : _currentIndex.clamp(0, matches.length - 1);
    _matchesGeneration++;
    notifyListeners();
    _scheduleHighlightResolution();
  }

  /// Compares two [FindMatch] lists for equality by value — mirrors the
  /// spike's `_matchListsEqual` exactly.
  static bool _matchListsEqual(List<FindMatch> a, List<FindMatch> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Defers a highlight-geometry resolution to the next frame, coalescing
  /// any number of triggers within the current frame — mirrors the spike's
  /// `_scheduleHighlightResolution` exactly, including why this may never run
  /// synchronously (`getBoxesForSelection` asserts `!debugNeedsLayout`, valid
  /// only once layout has settled for the frame in question — see that
  /// method's doc for the crash this deferral fixes).
  void _scheduleHighlightResolution() {
    if (_highlightResolveScheduled) return;
    _highlightResolveScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _highlightResolveScheduled = false;
      if (_disposed || !_isOpen) return;
      _resolveHighlights();
    });
  }

  /// Resolves word-level (or whole-node fallback) highlight geometry for
  /// [visibleMatches] — mirrors the spike's `_resolveHighlights` exactly,
  /// including the stale-generation guard ([_staleGenerationGuard]) that
  /// closes the sync race documented on that method: a later walk can bump
  /// [_matchesGeneration] again while an earlier resolution for a previous
  /// generation is still in flight, and simply discarding the stale result
  /// is not enough — see that guard's doc for why it must also reschedule.
  void _resolveHighlights() {
    final startGeneration = _matchesGeneration;

    final visible = visibleMatches;
    if (visible.isEmpty) {
      if (_staleGenerationGuard(startGeneration)) return;
      // This resolution commits for the latest generation — the settled
      // query has nothing visible to highlight, but the search is over.
      _setSearching(false);
      if (_highlights.isNotEmpty) {
        _highlights = const [];
        notifyListeners();
      }
      return;
    }

    final renderRoot = _findRenderTreeRoot();
    final sources = renderRoot == null ? const <RenderTextSource>[] : findRenderTextSources(renderRoot);

    final highlights = [
      for (final match in visible) resolveWordHighlights(match: match, query: _query, sources: sources),
    ];

    if (_staleGenerationGuard(startGeneration)) return;

    // This resolution commits for the latest generation — the settled
    // query's highlights are resolved, whether or not they actually changed
    // the previously-painted set.
    _setSearching(false);

    if (_highlightsEqual(highlights, _highlights)) return;
    _highlights = highlights;
    notifyListeners();
  }

  /// Returns whether [_resolveHighlights] is holding a result computed for a
  /// stale [_matchesGeneration] — mirrors the spike's
  /// `_staleGenerationGuard` exactly; see that method's doc for the on-device
  /// bug ("1 of 24" counter with 53-match boxes still painted) this guard
  /// exists to prevent from recurring.
  bool _staleGenerationGuard(int startGeneration) {
    if (_matchesGeneration == startGeneration) return false;
    _scheduleHighlightResolution();
    return true;
  }

  /// Compares two [MatchHighlight] lists for equality by value — mirrors the
  /// spike's `_highlightsEqual` exactly.
  static bool _highlightsEqual(List<MatchHighlight> a, List<MatchHighlight> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _findSemanticsOwner()?.removeListener(_handleSemanticsChanged);
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
    super.dispose();
  }
}
