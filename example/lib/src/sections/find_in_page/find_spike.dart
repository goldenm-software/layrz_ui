import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';

import 'find_spike_button.dart';
import 'find_spike_editable_field.dart';
import 'find_spike_label_painter.dart';

/// How long the query field waits after the last keystroke before triggering
/// a walk, in [LayrzFindSpike] — see its class doc's "Debounced typing"
/// section for why this exists. Matches `LayrzSearchInput`'s own default
/// debounce (`inputs/src/search/search_input.dart`) so this spike's typing
/// feel is consistent with the rest of the design system, though the two are
/// otherwise unrelated implementations.
const Duration kFindSpikeQueryDebounce = Duration(milliseconds: 300);

/// A self-contained manual-verification harness for the DESIGN-109
/// browser-style Ctrl+F find-in-page spike.
///
/// **This is a SPIKE widget, not a production component.** Its purpose is to
/// prove — on a real device/browser, by eye — that the mechanism behind
/// `walkSemantics` (see `semantics_walker.dart`) actually works against a
/// realistic mix of content: plain [Text], [RichText] with multiple spans, an
/// editable field, content deliberately hidden from semantics via
/// [ExcludeSemantics] (correctly absent from a walk — nothing to do, since it
/// never gets a node at all), a virtualized [ListView.builder] (proving rows
/// the builder never instantiated are, correctly, simply absent — out of
/// scope for "find" the same way they are for an actual browser's DOM), and a
/// [CustomPaint]-drawn label wrapped in an explicit [Semantics] node (the
/// escape hatch a future `LayrzSearchable` would formalize for custom-painted
/// content). The outer [ListView]'s own rows — built but scrolled out of the
/// *outer* list's viewport — are the case this spike's "hidden matches still
/// count" correction targets: they keep a semantics node (flagged
/// [SemanticsFlags.isHidden]) and are still findable and jumpable via
/// "Next", the same way a real browser's Ctrl+F finds text you have to
/// scroll to see. It is not documented in the wiki, not exported from any
/// barrel, and not wired into any route — a caller drops it into a route
/// manually to exercise it.
///
/// ### Layout
/// A [Stack] with two layers:
/// 1. The scrollable content under test (built by [_buildContent]).
/// 2. A fixed top bar: a query field, a "Walk & Highlight" button, a "Next"
///    button, and a live "current+1 of N" counter.
///
/// A third, visually-overlaying layer — a [CustomPaint] driven by
/// [FindHighlightPainter], painting the word-level (or, failing that,
/// whole-node) highlight geometry for the currently-*visible* matches only
/// (see [_resolveHighlights]) — sits **outside** this [Stack] entirely, in an
/// [OverlayEntry] inserted into the application's root [Overlay]. See
/// [_highlightOverlayEntry]'s doc for why: this page's own [Stack] does not
/// necessarily sit at the screen origin (chrome like a sidebar or app bar can
/// offset it), while the highlight rects are global (screen) coordinates —
/// only the root overlay is guaranteed to share that origin.
///
/// ### Mechanism under test
/// Walking the semantics tree requires an active [SemanticsHandle] — see
/// [SemanticsBinding.ensureSemantics] — since Flutter does not build the
/// semantics tree at all unless something is holding one open (normally, an
/// attached accessibility service). This widget acquires that handle in
/// [initState] and holds it for its entire lifetime, releasing it in
/// [dispose]. After every walk-triggering event (a manual "Walk & Highlight"
/// tap, or the [SemanticsOwner] itself announcing a tree change — see
/// [_scheduleWalk]), the walk is deferred to the *next* frame via
/// [WidgetsBinding.addPostFrameCallback], since a [SemanticsOwner] change
/// notification can fire mid-build, before the frame's layout (and therefore
/// the geometry [walkSemantics] depends on) has settled.
///
/// "Next" both advances [_currentIndex] (wrapping back to `0` past the last
/// match) and asks the framework to scroll the newly-current match into view
/// via `SemanticsOwner.performAction(id, SemanticsAction.showOnScreen)` — this
/// only does anything for a node whose [RenderObject] registered a
/// `showOnScreen` handler (which [Scrollable]-backed content, including
/// [ListView], does automatically); a plain [Text] outside any scrollable
/// still highlights correctly, it simply has nothing to scroll.
///
/// ### Two-layer search: locate everything, highlight only what's visible
/// **Locating** matches ([_performWalk], via `walkSemantics`) and
/// **highlighting** them ([_resolveHighlights], via `findRenderTextSources` +
/// `resolveWordHighlights`, scheduled post-frame by
/// [_scheduleHighlightResolution]) are deliberately two separate mechanisms
/// over two separate trees:
///
/// * The semantics tree is the source of truth for *what matches exist and
///   where* — [_matches] holds every match anywhere in the document,
///   including scrolled-out-of-view ([FindMatch.isHidden]) ones, which is
///   exactly what the "N of M" counter and "Next" need (a real browser's
///   Ctrl+F can jump to a match you still have to scroll to see).
/// * The render tree is the source of truth for *word-level highlight
///   geometry*, and is only ever consulted for the small subset of matches
///   that are currently visible. A [SemanticsNode] has no public path back to
///   the [RenderObject] that produced it, so rather than resolving "this
///   match's exact render object", `findRenderTextSources` walks the render
///   tree independently, collecting every [RenderParagraph]/[RenderEditable]
///   it finds; `resolveWordHighlights` then correlates one of those against a
///   given match by geometry (see `render_text_walker.dart`'s
///   `resolveRenderTextSource` doc) and asks it for per-occurrence boxes via
///   [RenderParagraph.getBoxesForSelection]/[RenderEditable.getBoxesForSelection].
///
/// Restricting the render-tree resolution to visible matches only is a
/// deliberate performance choice, not an incidental one: per-glyph box
/// computation is real text-layout work, and this spike's content alone can
/// have dozens of hidden matches (20 "Sample paragraph" rows plus 40
/// virtualized list items) that would otherwise be resolved on every frame
/// for boxes nobody could see. See [_resolveHighlights]'s doc for the full
/// reasoning — and [_scheduleHighlightResolution]'s doc for why that
/// resolution additionally may only ever run from a post-frame callback,
/// never synchronously inside [build].
///
/// ### Debounced typing
/// The query field's [EditableText.onChanged] is debounced by
/// [kFindSpikeQueryDebounce] (mirroring `LayrzSearchInput`'s own 300ms
/// debounce in `inputs/src/search/search_input.dart`) before it triggers a
/// walk — typing "mango" letter by letter no longer walks against "m", "ma",
/// "man", and "mang" along the way, only against the final settled "mango"
/// once typing pauses. This is the actual root fix for a stale-highlight
/// sync bug caught during this widget's own development: resolving
/// word-level highlight geometry is deferred to a post-frame callback (see
/// [_scheduleHighlightResolution]), so an intermediate query's walk could in
/// principle still be mid-resolution when a later keystroke's walk
/// completed, painting a highlight set that belonged to an already-stale
/// query. Debouncing removes the intermediate queries entirely rather than
/// only reacting to the race after the fact (see [_staleGenerationGuard] for
/// the belt-and-suspenders fix that remains for whatever race the debounce
/// doesn't eliminate — a scroll-triggered re-walk of the *same*, already
/// debounce-settled query, for instance). The "Walk & Highlight" button
/// bypasses the debounce entirely (see [_handleWalkPressed]) — a deliberate
/// user tap should never wait. Clearing the field (query becomes empty or
/// whitespace-only) also bypasses the debounce, in the other direction: see
/// [_handleQueryChanged]'s doc for why clearing must feel instant rather
/// than waiting out the same delay a new search does.
class LayrzFindSpike extends StatefulWidget {
  /// Creates a [LayrzFindSpike].
  const LayrzFindSpike({super.key});

  @override
  State<LayrzFindSpike> createState() => _LayrzFindSpikeState();
}

class _LayrzFindSpikeState extends State<LayrzFindSpike> {
  /// Holds the semantics tree open for the lifetime of this widget. Without
  /// this handle, Flutter never builds a semantics tree at all outside of a
  /// real accessibility service being attached, and [walkSemantics] would
  /// have nothing to walk.
  late final SemanticsHandle _semanticsHandle;

  /// Controls the query text field.
  final TextEditingController _queryController = TextEditingController();

  /// Focus node for the query field, given focus when a Ctrl/Cmd+F chord is
  /// intercepted (see [_handleFindKeyPressed]).
  final FocusNode _queryFocusNode = FocusNode();

  /// The pending debounced walk, if any — see [_handleQueryChanged] and the
  /// class doc's "Debounced typing" section. `null` when there is no pending
  /// debounce (either nothing has been typed since the last walk, or the
  /// debounce already fired/was bypassed). Cancelled in [dispose] so a timer
  /// never fires after this widget is gone.
  Timer? _debounceTimer;

  /// The web-only browser-level Ctrl/Cmd+F interceptor (a no-op handle on
  /// native targets). Installed in [initState], disposed in [dispose].
  late final FindKeyCapture _findKeyCapture;

  /// The most recent walk's results, in reading order. Empty before the first
  /// walk, or when the last walk found nothing.
  List<FindMatch> _matches = const [];

  /// Bumped by [_performWalk] every time it actually changes [_matches] (a
  /// new query, or the same query against a changed tree). This is the
  /// "which search do these highlights belong to" identity [_resolveHighlights]
  /// checks against — see its doc for why a highlight resolution must never
  /// commit results computed for a [_matches] generation that is no longer
  /// current by the time that (post-frame-deferred) resolution actually
  /// finishes running.
  int _matchesGeneration = 0;

  /// The index into [_matches] treated as "current" — highlighted distinctly
  /// and the target of "Next"'s scroll-into-view. `-1` when there is no
  /// current match (no walk yet, or the last walk found nothing).
  int _currentIndex = -1;

  /// The most recently resolved highlight geometry for the currently-visible
  /// matches, in the same order [_visibleMatches] would produce.
  ///
  /// This is the **only** highlight state [build] ever reads — see
  /// [_resolveHighlights] for why resolving it is never allowed to happen
  /// during [build] itself, only in a post-frame callback scheduled by
  /// [_scheduleHighlightResolution].
  List<MatchHighlight> _highlights = const [];

  /// Guards against scheduling more than one pending post-frame walk at once
  /// — [SemanticsOwner] can notify its listeners many times within a single
  /// frame's worth of work, and only the walk scheduled for the *next* frame
  /// after the *last* of those notifications needs to actually run.
  bool _walkScheduled = false;

  /// Guards against scheduling more than one pending post-frame highlight
  /// resolution at once — the same coalescing [_walkScheduled] does for
  /// [_scheduleWalk], applied to [_scheduleHighlightResolution] instead. A
  /// walk and a scroll can each independently ask for highlights to be
  /// re-resolved within the same frame; only the resolution scheduled for the
  /// *next* frame after the *last* of those requests needs to actually run.
  bool _highlightResolveScheduled = false;

  /// The [OverlayEntry] painting the highlight layer, inserted into the app's
  /// ROOT [Overlay] (`Overlay.of(context, rootOverlay: true)`) rather than
  /// this widget's own [Stack].
  ///
  /// ### Why the root overlay, not the page [Stack]
  /// This spike can be pushed as a page nested below chrome that itself
  /// offsets the content area — e.g. a sidebar on desktop, an app bar on
  /// mobile — so this widget's own [Stack] does not sit at the screen
  /// origin: its local `(0, 0)` can be dozens to hundreds of logical pixels
  /// away from the true screen origin. [_matches] and [_highlights] carry
  /// **global** (screen) rects (see `FindMatch.globalRect` /
  /// `MatchHighlight.rects`), so painting them inside that offset local
  /// [Stack] silently shifts every box by exactly that offset — this was
  /// caught as highlight boxes landing on the wrong word on desktop (shifted
  /// right by the sidebar's width) and at the wrong row on mobile (shifted
  /// down by the app bar's height). The root overlay is anchored at the
  /// screen origin regardless of what chrome the current page sits behind,
  /// so painting there lets the already-global rects be used as-is, with no
  /// manual offset math.
  ///
  /// `null` until first inserted (see [_ensureHighlightOverlayInserted]),
  /// and reset to `null` in [dispose] after being removed.
  OverlayEntry? _highlightOverlayEntry;

  /// A key on the entire top bar [Row] (query field, buttons, counter),
  /// resolved to a [SemanticsNode.id] and fed to [walkSemantics] as
  /// [excludeSubtreeRootIds] — see [_findBarSubtreeId] for how, and its doc
  /// for the caveat on the API this relies on.
  final GlobalKey _topBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
    _findSemanticsOwner()?.addListener(_handleSemanticsChanged);
    _findKeyCapture = installFindKeyCapture(onFindPressed: _handleFindKeyPressed);
    // Overlay.of requires a BuildContext already under an Overlay ancestor,
    // and inserting into one is not allowed mid-build — deferred to the
    // first post-frame callback, by which point this State's context is
    // mounted under LayrzApp/WidgetsApp's Navigator-provided root Overlay.
    // See _ensureHighlightOverlayInserted's doc.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureHighlightOverlayInserted();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _findSemanticsOwner()?.removeListener(_handleSemanticsChanged);
    _findKeyCapture.dispose();
    _queryController.dispose();
    _queryFocusNode.dispose();
    _semanticsHandle.dispose();
    _highlightOverlayEntry?.remove();
    _highlightOverlayEntry = null;
    super.dispose();
  }

  /// Inserts [_highlightOverlayEntry] into the app's ROOT [Overlay] if it
  /// isn't already inserted — see that field's doc for why the root overlay
  /// specifically, rather than this widget's own [Stack], is where the
  /// highlight layer must paint.
  ///
  /// `rootOverlay: true` is load-bearing, not defensive: a *nested* overlay
  /// (e.g. one a dialog or a route transition installs) can itself sit at an
  /// offset from the screen origin, which would silently reintroduce the
  /// exact coordinate bug this fix removes. The root overlay is the one
  /// [Overlay] guaranteed to span the whole screen at the true screen
  /// origin, matching the global rects [_matches]/[_highlights] already
  /// carry.
  ///
  /// Idempotent — safe to call from [initState]'s post-frame callback and
  /// from anywhere else that wants to guarantee the entry exists before
  /// asking it to rebuild.
  void _ensureHighlightOverlayInserted() {
    if (_highlightOverlayEntry != null) return;
    final entry = OverlayEntry(builder: _buildHighlightOverlay);
    _highlightOverlayEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// Locates the live [SemanticsOwner] for this widget's [View], without
  /// using the deprecated flat `WidgetsBinding.pipelineOwner`/`RendererBinding.pipelineOwner`
  /// accessors.
  ///
  /// `RendererBinding.instance.rootPipelineOwner` is the root of a tree of
  /// [PipelineOwner]s — one per [View] — rather than a single flat owner; for
  /// the single-implicit-view case this spike (and `runApp` in general) runs
  /// under, the one actual per-view [PipelineOwner] is its sole direct child.
  /// This walks that (normally one-element) child list and returns the first
  /// child exposing a non-null [PipelineOwner.semanticsOwner], which is
  /// exactly the owner [walkSemantics] needs a root [SemanticsNode] from.
  ///
  /// Returns `null` if no child pipeline owns semantics yet — e.g. the very
  /// first frame, before the [View] has attached its render tree.
  SemanticsOwner? _findSemanticsOwner() {
    SemanticsOwner? found;
    RendererBinding.instance.rootPipelineOwner.visitChildren((child) {
      found ??= child.semanticsOwner;
    });
    return found;
  }

  /// Locates the live render tree's root [RenderObject] for this widget's
  /// [View], the render-tree counterpart to [_findSemanticsOwner].
  ///
  /// Mirrors [_findSemanticsOwner]'s exact traversal (`rootPipelineOwner` has
  /// one child [PipelineOwner] per [View]; the single-implicit-view case this
  /// spike runs under has exactly one), reading [PipelineOwner.rootNode]
  /// instead of [PipelineOwner.semanticsOwner]. This is what
  /// `findRenderTextSources` (see `render_text_walker.dart`) needs to start
  /// its independent render-tree walk for word-level highlight geometry —
  /// see [_resolveHighlights] for why that walk is kept entirely separate
  /// from the semantics walk in [_performWalk], and
  /// [_scheduleHighlightResolution] for why it may only run post-frame.
  ///
  /// Returns `null` under the same first-frame condition
  /// [_findSemanticsOwner] can return `null` for.
  RenderObject? _findRenderTreeRoot() {
    RenderObject? found;
    RendererBinding.instance.rootPipelineOwner.visitChildren((child) {
      found ??= child.rootNode;
    });
    return found;
  }

  /// Called when the web-level Ctrl/Cmd+F interceptor fires (see
  /// `find_key_capture_web.dart`) — moves focus to the query field so the
  /// user can start typing immediately, the same way a browser's native find
  /// bar auto-focuses on open. A no-op-triggering path on native targets,
  /// since [installFindKeyCapture] never invokes this callback there.
  void _handleFindKeyPressed() {
    _queryFocusNode.requestFocus();
  }

  /// Listener attached to the live [SemanticsOwner] — it is itself a
  /// [ChangeNotifier] and notifies whenever the semantics tree is rebuilt
  /// (e.g. a scroll reveals new content, *or the query field's own semantics
  /// value updating on every keystroke*). Coalesces into a single
  /// [_scheduleWalk] rather than walking synchronously, since this can fire
  /// mid-build.
  ///
  /// ### Why a pending debounce suppresses this
  /// Every keystroke changes the query field's own semantics value, which
  /// notifies this listener exactly like a genuine content-tree change (a
  /// scroll) would — with no debounce guard here, this path would re-walk
  /// against the query's intermediate, still-being-typed text on the very
  /// next frame after every keystroke, completely bypassing
  /// [_handleQueryChanged]'s [kFindSpikeQueryDebounce] (see the class doc's
  /// "Debounced typing" section for why that debounce is the actual fix for
  /// the stale-highlight sync bug this spike was built to chase down — a
  /// second, undebounced re-walk trigger racing it would silently reopen the
  /// same bug). [_debounceTimer] being non-null means the user is actively
  /// mid-keystroke and a debounced walk is already pending for whatever text
  /// eventually settles, so this notification is skipped entirely in that
  /// case — the pending debounce is the only re-walk that is allowed to run.
  /// Once the debounce fires (or is bypassed by the button/submit), this
  /// listener resumes reacting normally to scroll-driven tree changes for
  /// that now-settled query.
  void _handleSemanticsChanged() {
    if (_queryController.text.trim().isEmpty) return;
    if (_debounceTimer != null) return;
    _scheduleWalk();
  }

  /// Defers a semantics walk to the next frame, coalescing any number of
  /// triggers within the current frame into a single walk — see
  /// [_walkScheduled].
  void _scheduleWalk() {
    if (_walkScheduled) return;
    _walkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walkScheduled = false;
      if (!mounted) return;
      _performWalk();
    });
  }

  /// Resolves the top bar's own [SemanticsNode.id] via [_topBarKey], so it can
  /// be passed to [walkSemantics] as [excludeSubtreeRootIds] — otherwise the
  /// query field would match its own current text (typing "mango" would make
  /// the field showing "mango" a match against itself), which no real
  /// find-in-page bar should do.
  ///
  /// **SPIKE-only caveat:** this reads [RenderObject.debugSemantics], which —
  /// as its name signals — is only populated outside `kReleaseMode` (it
  /// returns `null` in a release build; see its doc in
  /// `rendering/object.dart`). That is an accepted limitation *for this
  /// spike's manual verification*, which never runs in release mode. The
  /// production `LayrzFindInPage` widget must not depend on this accessor —
  /// it needs a release-safe way to learn its own root node's id (for
  /// instance, walking `PipelineOwner.semanticsOwner!.rootSemanticsNode` once
  /// and matching by [GlobalKey.currentContext]'s [RenderObject] identity
  /// rather than through a debug-only cache, or restructuring so the find bar
  /// itself is excluded structurally rather than by id lookup). Returns
  /// `null` if the key isn't attached yet (first frame) or its render object
  /// has no computed semantics node yet.
  int? _findBarSubtreeId() {
    final renderObject = _topBarKey.currentContext?.findRenderObject();
    return renderObject?.debugSemantics?.id;
  }

  /// Runs [walkSemantics] against the live tree's root and updates
  /// [_matches]/[_currentIndex].
  ///
  /// Reads `pipelineOwner.semanticsOwner?.rootSemanticsNode` directly rather
  /// than caching it, since the root node identity itself does not change
  /// across the widget's lifetime once semantics is enabled, but reading it
  /// fresh avoids relying on that assumption. If there is no root yet (the
  /// very first frame, before semantics has been computed even once), the
  /// walk is skipped for this trigger — a later semantics-changed
  /// notification will retry.
  ///
  /// Excludes the top bar's own subtree (see [_findBarSubtreeId]) so the
  /// query field, buttons, and counter never match themselves. Matches
  /// include hidden (scrolled-out-of-view) nodes — see `walkSemantics`'s doc
  /// on `includeHidden` — since a real Ctrl+F finds text anywhere in the
  /// document, not just what is currently on screen.
  ///
  /// ### Why this compares before calling [setState]
  /// A rebuild triggered by this method's own `setState` changes the top
  /// bar's "N of M" counter text (`_buildTopBar` reads [_matches] and
  /// [_currentIndex] directly), which is itself semantics content — even
  /// though the top bar's own subtree is excluded from the *match search*
  /// (see [_findBarSubtreeId]), it is not excluded from the semantics tree
  /// *changing*, so that counter update fires [_handleSemanticsChanged]
  /// again. Left unguarded, that closes a loop: walk → `setState` → counter
  /// text changes → semantics-changed notification → another scheduled walk
  /// → `setState` → ... on every single frame, forever, even when nothing
  /// about the actual matches changed — this was caught as exactly that: a
  /// [debugPrint] meant to log once per search instead flooding on every
  /// frame. Comparing the freshly walked [matches] against the current
  /// [_matches] by value (`FindMatch` has value `==`) and skipping
  /// `setState` entirely when they're unchanged breaks the loop at its
  /// source — a `setState` that would not actually change what `build`
  /// produces never happens, so no further semantics-changed notification is
  /// generated by this walk.
  ///
  /// Only calls [_scheduleHighlightResolution] when the match set actually
  /// changed, for the same reason: an unchanged [_matches] means
  /// [_visibleMatches] is unchanged too, so there is nothing new for
  /// highlight resolution to compute.
  void _performWalk() {
    final root = _findSemanticsOwner()?.rootSemanticsNode;
    if (root == null) return;

    final query = _queryController.text;
    final excludeIds = <int>{};
    final topBarId = _findBarSubtreeId();
    if (topBarId != null) excludeIds.add(topBarId);

    final matches = walkSemantics(root, query, excludeSubtreeRootIds: excludeIds);
    if (_matchListsEqual(matches, _matches)) return;

    setState(() {
      _matches = matches;
      _currentIndex = matches.isEmpty ? -1 : _currentIndex.clamp(0, matches.length - 1);
      _matchesGeneration++;
    });
    _highlightOverlayEntry?.markNeedsBuild();
    _scheduleHighlightResolution();
  }

  /// Compares two [FindMatch] lists for equality by value — used by
  /// [_performWalk] to detect a no-op walk. `FindMatch` already implements
  /// value `==`; this just extends that comparison to a `List`, the same
  /// pattern `FindHighlightPainter._highlightsEqual` uses for
  /// `MatchHighlight`.
  static bool _matchListsEqual(List<FindMatch> a, List<FindMatch> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Handles the "Walk & Highlight" button and the query field's submit
  /// action — runs an immediate walk rather than waiting for the next
  /// semantics-changed notification, so a query typed while nothing else in
  /// the tree is changing still produces a result.
  ///
  /// Cancels any pending debounced walk from [_handleQueryChanged] first — a
  /// deliberate tap or submit means "search for what's in the field right
  /// now", so it must never be followed a moment later by a redundant
  /// debounced walk against whatever text happened to be in the field when
  /// the last keystroke landed (normally the same text, but a caller could in
  /// principle mutate [_queryController] between the two).
  void _handleWalkPressed() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _performWalk();
  }

  /// Handles every keystroke in the query field ([EditableText.onChanged]) —
  /// see the class doc's "Debounced typing" section for the sync bug this
  /// exists to fix at the root, rather than only reacting to after the fact.
  ///
  /// ### Clearing bypasses the debounce; typing goes through it
  /// [newValue] becoming empty or whitespace-only is handled **immediately**,
  /// with no debounce delay: any pending debounced walk is cancelled, and
  /// [_matches]/[_highlights]/[_currentIndex] are all cleared and committed
  /// via [setState] right here — not by falling through to [_performWalk] (a
  /// walk against an empty query only ever needs to reach the "clear
  /// everything" outcome, so reaching it directly, synchronously, is both
  /// simpler and faster than scheduling a walk to arrive at the same place).
  /// Clearing the field is the browser-standard way to dismiss a find-in-page
  /// search's highlights, and a 300ms lag before the boxes disappear would
  /// read as broken, not merely slow — unlike a new search's first result,
  /// which the debounce delaying by 300ms is unremarkable for.
  ///
  /// A non-empty [newValue] instead (re)starts [kFindSpikeQueryDebounce],
  /// cancelling whatever debounce was already pending — only the *last*
  /// keystroke within that window ever triggers a walk, exactly mirroring
  /// `LayrzSearchInput._handleSearchChanged`'s own debounce reset.
  void _handleQueryChanged(String newValue) {
    _debounceTimer?.cancel();

    if (newValue.trim().isEmpty) {
      _debounceTimer = null;
      if (_matches.isEmpty && _highlights.isEmpty) return;
      setState(() {
        _matches = const [];
        _highlights = const [];
        _currentIndex = -1;
        _matchesGeneration++;
      });
      _highlightOverlayEntry?.markNeedsBuild();
      return;
    }

    _debounceTimer = Timer(kFindSpikeQueryDebounce, () {
      _debounceTimer = null;
      if (!mounted) return;
      _performWalk();
    });
  }

  /// Advances [_currentIndex] to the next match (wrapping to `0` past the
  /// last one) and asks the framework to scroll it into view via
  /// [SemanticsOwner.performAction] with [SemanticsAction.showOnScreen].
  ///
  /// [_matches] is sorted by global `top` (see `walkSemantics`), so a hidden
  /// match below the fold naturally sorts after the currently-visible ones —
  /// "Next" reaches it in the same reading order it would if it were already
  /// on screen, and `showOnScreen` is exactly what scrolls it into view once
  /// it becomes current. This works whether the newly-current match is
  /// visible or hidden; requesting `showOnScreen` on an already-visible node
  /// is a harmless no-op.
  ///
  /// The scroll-into-view request is fire-and-forget: if it actually moves a
  /// [Scrollable], that scroll change will itself trigger
  /// [_handleSemanticsChanged] (the tree's geometry changed), which
  /// re-walks and refreshes every match's [FindMatch.globalRect] — including
  /// the one just scrolled to — on the following frame. There is nothing
  /// further to await here.
  void _handleNextPressed() {
    if (_matches.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _matches.length;
    setState(() => _currentIndex = nextIndex);
    _highlightOverlayEntry?.markNeedsBuild();

    final owner = _findSemanticsOwner();
    owner?.performAction(_matches[nextIndex].nodeId, SemanticsAction.showOnScreen);
  }

  /// The subset of [_matches] currently on screen, in the order [_matches]
  /// already holds them (which is reading order — see `walkSemantics`'s
  /// doc).
  ///
  /// A hidden (scrolled-out-of-view) match's [FindMatch.globalRect] reflects
  /// wherever the offscreen content currently sits, which can be far outside
  /// the viewport — neither painting nor resolving word-level geometry for
  /// one would draw anything meaningful, so both [build] and
  /// [_resolveHighlights] filter down to this list first. Kept as a single
  /// getter (rather than each of those two recomputing its own filter) so
  /// they can never disagree about which matches count as visible.
  List<FindMatch> get _visibleMatches => _matches.where((match) => !match.isHidden).toList(growable: false);

  /// Defers a highlight-geometry resolution to the next frame, coalescing
  /// any number of triggers within the current frame into a single
  /// resolution — the render-tree counterpart of [_scheduleWalk], guarded by
  /// [_highlightResolveScheduled] the same way [_scheduleWalk] is guarded by
  /// [_walkScheduled].
  ///
  /// ### Why this must never run synchronously
  /// [_resolveHighlights] calls `RenderParagraph.getBoxesForSelection` /
  /// `RenderEditable.getBoxesForSelection` (via `findRenderTextSources` +
  /// `resolveWordHighlights`), and both assert `!debugNeedsLayout` — reading
  /// per-glyph box geometry is only valid once layout has actually settled
  /// for the render objects in question. Calling this (or the geometry reads
  /// inside it) from [build] hits that assertion directly, because [build]
  /// can run *before* layout for the frame it is building — this was caught
  /// as a real crash (`Failed assertion: '!debugNeedsLayout'` inside
  /// [RenderParagraph.getBoxesForSelection], with [build] on the stack) when
  /// highlight resolution used to run inline from [build] instead of being
  /// scheduled here. A stale-or-invalid read that happens not to crash is the
  /// same illegal call one frame less unlucky — which is also the likely
  /// explanation for early word-level highlights landing on the wrong word
  /// even where nothing crashed outright.
  ///
  /// Mirrors [_scheduleWalk]'s post-frame deferral exactly, for exactly the
  /// same reason: whatever triggers a resolution (a completed walk, in
  /// [_performWalk]; a scroll settling, via [_handleSemanticsChanged] →
  /// [_scheduleWalk] → [_performWalk] again) can itself fire mid-build, so
  /// the actual geometry read always waits for the *next* frame's
  /// [WidgetsBinding.addPostFrameCallback] — by which point that frame's
  /// layout has completed and every visible match's [RenderTextSource] is
  /// safe to query.
  void _scheduleHighlightResolution() {
    if (_highlightResolveScheduled) return;
    _highlightResolveScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _highlightResolveScheduled = false;
      if (!mounted) return;
      _resolveHighlights();
    });
  }

  /// Resolves word-level (or, failing that, whole-node) highlight geometry
  /// for [_visibleMatches] and stores it in [_highlights] via [setState] —
  /// but only when the newly resolved geometry actually differs from what
  /// [_highlights] already holds (see [_highlightsEqual]). Skipping the
  /// `setState` on a no-op resolution is not just an optimization here: it is
  /// what stops a resolve → rebuild → semantics-changed → re-walk →
  /// re-resolve loop from spinning forever once a search has settled — see
  /// the equality check's own inline doc, and [_performWalk]'s matching guard
  /// on the walk side of the same loop.
  ///
  /// **Never call this directly from [build] or from any other point that
  /// cannot guarantee layout has already settled for this frame** — see
  /// [_scheduleHighlightResolution]'s doc for why, and always go through that
  /// method instead, which defers the actual call here to a post-frame
  /// callback.
  ///
  /// ### Why this only ever runs against the visible list
  /// [_matches] can hold every match `walkSemantics` found anywhere in the
  /// document, hidden ones included — that full list is exactly what the "N
  /// of M" counter and "Next" need, since a real Ctrl+F lets you jump to a
  /// match you still have to scroll to see. But
  /// `RenderTextSource.boxesForSelection` (see `render_text_walker.dart`) is
  /// real per-glyph text-layout work, and running it for every hidden match
  /// on every frame — most builds of this spike have dozens of "Sample
  /// paragraph" rows plus 40 virtualized list items — would be pure waste for
  /// boxes nobody could see anyway. Restricting resolution to
  /// [_visibleMatches] keeps this to a small, bounded number of render
  /// objects: whatever is actually on screen, typically single digits.
  ///
  /// As a match scrolls into or out of the viewport, the resulting semantics
  /// change re-triggers [_performWalk] (see [_handleSemanticsChanged]),
  /// which recomputes [_matches] and calls [_scheduleHighlightResolution]
  /// again — so a match picks up its word-level highlight the moment it
  /// becomes visible, and loses it the moment it scrolls away, without ever
  /// having paid the per-glyph cost while off screen.
  ///
  /// The render tree is walked (via `findRenderTextSources`) fresh on every
  /// call rather than cached, since the set of [RenderParagraph]/
  /// [RenderEditable] objects and their geometry can change on every layout
  /// (a resize, a scroll, a rebuild) — but the walk only ever happens when
  /// there is at least one visible match to resolve, and the render tree for
  /// this spike's content is small enough that repeating it per resolution is
  /// not a concern for a manual-verification harness. A production
  /// `LayrzFindInPage` would likely want to cache and invalidate this more
  /// carefully.
  void _resolveHighlights() {
    // Captured at the START of this resolution — see _staleGenerationGuard's
    // doc for why this, and the re-checks against it below, exist at all.
    final startGeneration = _matchesGeneration;

    final visibleMatches = _visibleMatches;
    if (visibleMatches.isEmpty) {
      if (_staleGenerationGuard(startGeneration)) return;
      if (_highlights.isNotEmpty) {
        setState(() => _highlights = const []);
        _highlightOverlayEntry?.markNeedsBuild();
      }
      return;
    }

    final renderRoot = _findRenderTreeRoot();
    final sources = renderRoot == null ? const <RenderTextSource>[] : findRenderTextSources(renderRoot);
    final query = _queryController.text;

    final highlights = [
      for (final match in visibleMatches) resolveWordHighlights(match: match, query: query, sources: sources),
    ];

    if (_staleGenerationGuard(startGeneration)) return;

    // Skip the setState entirely when the newly resolved geometry is
    // identical to what is already painted — this is what actually stops
    // the highlight-resolution loop from also re-triggering a rebuild (and
    // therefore another semantics-changed notification): a setState that
    // would not change what build produces still schedules a rebuild, and
    // this widget's own rebuild is what was re-triggering semantics-changed
    // notifications frame after frame (see _performWalk's doc for the
    // matching guard on the walk side). A resolution that produces the same
    // boxes as last time is exactly the steady-state case once a search has
    // settled and nothing is scrolling.
    if (_highlightsEqual(highlights, _highlights)) return;
    setState(() => _highlights = highlights);
    _highlightOverlayEntry?.markNeedsBuild();
  }

  /// Returns whether [_resolveHighlights] is holding a result computed for a
  /// [_matches] generation that is no longer current — [startGeneration] is
  /// whatever [_matchesGeneration] was when that resolution began.
  ///
  /// ### The sync bug this exists to close
  /// [findRenderTextSources] + [resolveWordHighlights] are real, non-trivial
  /// work — nothing prevents another [_performWalk] from completing and
  /// bumping [_matchesGeneration] again *while a resolution for an earlier
  /// generation is still running*. Simply discarding that stale result (as
  /// an earlier version of this guard did) is not enough on its own: the
  /// newer walk's own call to [_scheduleHighlightResolution] can itself be a
  /// no-op if [_highlightResolveScheduled] was still `true` at that moment
  /// (i.e. exactly the in-flight resolution now discovering it is stale) —
  /// so unless *something* schedules a fresh resolution here, the query and
  /// counter can settle on their final state while [_highlights] is left
  /// holding a previous query's boxes forever, with nothing left to correct
  /// it. This was caught on-device as exactly that: the counter read "1 of
  /// 24" (a settled "mango" search) while the painted boxes still matched an
  /// earlier, superseded "m" search's 53 matches.
  ///
  /// Calling [_scheduleHighlightResolution] here — rather than only relying
  /// on [_performWalk] having already called it — is what guarantees "last
  /// state wins": whichever resolution is the last to notice it was
  /// superseded is also the one that schedules the resolution that will
  /// finally succeed (once nothing supersedes it again in turn).
  bool _staleGenerationGuard(int startGeneration) {
    if (_matchesGeneration == startGeneration) return false;
    _scheduleHighlightResolution();
    return true;
  }

  /// Compares two [MatchHighlight] lists for equality by value — used by
  /// [_resolveHighlights] to detect a no-op resolution. `MatchHighlight`
  /// already implements value `==`; this just extends that comparison to a
  /// `List`, the same pattern [_matchListsEqual] applies to `FindMatch`.
  static bool _highlightsEqual(List<MatchHighlight> a, List<MatchHighlight> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Returns whether [node] is [ancestor] itself or one of its descendants in
  /// the render tree.
  ///
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          top: 64,
          child: _buildContent(context),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 64,
          child: _buildTopBar(context),
        ),
      ],
    );
  }

  /// Builds the highlight layer's content for [_highlightOverlayEntry] — a
  /// full-screen, pointer-ignoring [CustomPaint] driven by
  /// [FindHighlightPainter], reading [_highlights]/[_currentIndex] live from
  /// this [State] at build time (this builder runs in the root [Overlay]'s
  /// own context, not this widget's [build], so it must close over `this`
  /// rather than receive these as parameters).
  ///
  /// `size: Size.infinite` together with the entry sitting directly in the
  /// root [Overlay] (see [_ensureHighlightOverlayInserted]) is what gives
  /// this [CustomPaint] a canvas whose local `(0, 0)` coincides with the true
  /// screen origin — the same origin [_matches]/[_highlights]' global rects
  /// were computed against — so no manual offset is needed here.
  /// [IgnorePointer] keeps the highlight layer purely visual: it must never
  /// intercept taps meant for the content or the top bar beneath it.
  Widget _buildHighlightOverlay(BuildContext context) {
    final tokens = context.tokens;

    // _visibleMatches is cheap (a filter over already-known semantics data,
    // no render-tree reads) and is recomputed here purely to find
    // _currentIndex's position within it, since the painter addresses
    // highlights positionally within whatever list it is given rather than
    // by nodeId — see the equivalent computation this replaced in build().
    final visibleMatches = _visibleMatches;
    final currentMatch = _currentIndex >= 0 && _currentIndex < _matches.length ? _matches[_currentIndex] : null;
    final visibleCurrentIndex = currentMatch == null ? -1 : visibleMatches.indexOf(currentMatch);

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: FindHighlightPainter(
          highlights: _highlights,
          currentIndex: visibleCurrentIndex,
          // tokens.colors.selectionColor is the same swatch backing the
          // app's text-selection highlight, so find-highlighting and text
          // selection always read as one visual language. shade500 is a
          // saturated blue, so alpha stays low (0.35) — enough to read as
          // "the current one" while the matched text remains fully legible
          // through the tint, the same way a text selection never recolors
          // the text itself.
          currentColor: tokens.colors.selectionColor.shade500.withValues(alpha: 0.35),
          // shade100 is very pale, so a somewhat higher alpha (0.45) still
          // keeps text fully readable while staying visually secondary to
          // the current match above.
          otherColor: tokens.colors.selectionColor.shade100.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  /// Builds the fixed top bar: query field, action buttons, and the live
  /// match counter.
  ///
  /// Wrapped in an explicit [Semantics] (`container: true,
  /// explicitChildNodes: true`) keyed by [_topBarKey], so [_findBarSubtreeId]
  /// can resolve this whole bar's own [SemanticsNode.id] and hand it to
  /// [walkSemantics] as `excludeSubtreeRootIds` — see that method's doc.
  ///
  /// The [Semantics] wrapper is load-bearing, not decorative: a plain
  /// [DecoratedBox]/[Padding]/[Row] chain (what this used to be) owns no
  /// [SemanticsNode] of its own — Flutter merges a childless container's
  /// semantics upward into whichever descendant *does* own one (here, the
  /// query field's [EditableText]) — so [RenderObject.debugSemantics] on
  /// that chain's render object came back `null`, [_findBarSubtreeId]
  /// returned `null`, `excludeSubtreeRootIds` stayed empty, and the query
  /// field matched its own current text every walk (this was caught as
  /// exactly that: typing "mango" made the query field itself become match
  /// #1, at the top-bar's `y` coordinate). `container: true` forces this
  /// subtree to own a real node genuinely wrapping the whole bar (query
  /// field included); `explicitChildNodes: true` keeps that node from
  /// itself being merged into an ancestor. Mirrors the same pattern
  /// `semantics_walker_test.dart`'s `excludeSubtreeRootIds` test already
  /// established for exactly this reason.
  Widget _buildTopBar(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      key: _topBarKey,
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.sf2,
          border: Border(bottom: BorderSide(color: tokens.colors.fg4, width: 1)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp2),
          child: Row(
            children: [
              Expanded(
                child: LayrzTextInput(
                  controller: _queryController,
                  focusNode: _queryFocusNode,
                  onChanged: _handleQueryChanged,
                  onSubmit: (_) => _handleWalkPressed(),
                ),
              ),
              SizedBox(width: tokens.spacing.sp2),
              SpikeButton(label: 'Walk & Highlight', onTap: _handleWalkPressed),
              SizedBox(width: tokens.spacing.sp2),
              SpikeButton(label: 'Next', onTap: _handleNextPressed),
              SizedBox(width: tokens.spacing.sp2),
              Text(
                _matches.isEmpty ? '0 of 0' : '${_currentIndex + 1} of ${_matches.length}',
                style: tokens.typography.body.copyWith(color: tokens.colors.fg2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the scrollable content under test — the mix of widget kinds
  /// [walkSemantics] needs to prove itself against. See the class doc for why
  /// each one is included.
  Widget _buildContent(BuildContext context) {
    final tokens = context.tokens;

    return ListView(
      padding: tokens.spacing.pd3,
      children: [
        for (var i = 0; i < 20; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1),
            child: Text('Sample paragraph number $i about apples, oranges, and bananas.'),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp2),
          child: RichText(
            text: TextSpan(
              style: tokens.typography.body.copyWith(color: tokens.colors.fg1),
              children: const [
                TextSpan(text: 'A rich text span mentions '),
                TextSpan(
                  text: 'mango',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' and then, separately, '),
                TextSpan(
                  text: 'kiwi',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: ' within the same paragraph.'),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp2),
          child: FindSpikeEditableField(tokens: tokens),
        ),
        ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp2),
            child: const Text('This mango mention is excluded from semantics and must never match.'),
          ),
        ),
        SizedBox(
          height: tokens.spacing.sp2,
        ),
        Semantics(
          label: 'A custom-painted mango label standing in for the LayrzSearchable escape hatch.',
          child: SizedBox(
            height: 32,
            child: CustomPaint(
              painter: FindSpikeLabelPainter(text: 'Custom-painted mango label', color: tokens.colors.fg1),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sp2),
        SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: 40,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1),
                child: Text('Virtualized item $index referencing mango only in a few rows like #7 and #23.'),
              );
            },
          ),
        ),
      ],
    );
  }
}
