import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/keyboard/keyboard.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/search/search.dart';
import 'package:layrz_ui/src/theme/theme.dart';

import 'find_bar.dart';
import 'find_in_page_controller.dart';

/// [InheritedWidget] exposing a [LayrzFindInPageHostState] to descendants by
/// tree ancestry.
///
/// The sole mechanism behind [LayrzFindInPageHost.of] and
/// [LayrzFindInPageHost.maybeOf] — mirrors [LayrzShortcut]'s own
/// `_LayrzShortcutScope` and [LayrzSnackbarMessenger]'s `_LayrzSnackbarScope`:
/// ancestry-only resolution, no [GlobalKey] anywhere.
class _LayrzFindInPageScope extends InheritedWidget {
  /// The state instance this scope exposes to descendants.
  final LayrzFindInPageHostState state;

  /// Creates a [_LayrzFindInPageScope] wrapping [child] and exposing [state].
  const _LayrzFindInPageScope({required this.state, required super.child});

  /// Never triggers a rebuild on its own — [state] is a stable [State]
  /// identity for the lifetime of the host, and callers observe it via
  /// [LayrzFindInPageController] (a [ChangeNotifier]) directly, not via this
  /// scope rebuilding.
  @override
  bool updateShouldNotify(_LayrzFindInPageScope oldWidget) => false;
}

/// The invisible, app-wide host behind browser-style Ctrl/Cmd+F find-in-page.
///
/// [LayrzFindInPageHost] is installed automatically by [LayrzApp] (gated by
/// `LayrzApp.enableFindInPage`, on by default) — application code never
/// constructs one directly. It wraps the whole app's content and:
///
/// * Owns one [LayrzFindInPageController] for the app's lifetime — see that
///   class's own doc for why its [SemanticsHandle] is only ever held between
///   `open()`/`close()`, not for this host's whole lifetime, which is what
///   keeps the idle cost of a default-on feature at zero.
/// * Registers Ctrl+F (Windows/Linux) or Cmd+F (macOS) via
///   [LayrzShortcut.maybeOf] — `maybeOf`, not `of`, so this host degrades
///   gracefully (no crash, find simply cannot be opened via keyboard) in the
///   rare tree that has no [LayrzShortcut] ancestor, rather than asserting.
///   Deregistered in [State.dispose].
/// * On web only, additionally installs the browser-level JS `keydown`
///   capture ([installFindKeyCapture], from `search/src/find_key_capture.dart`)
///   so the browser's own native find-in-page dialog never opens — Ctrl+F on
///   web must be intercepted at the DOM level, before Flutter's own
///   [LayrzShortcut] path ever sees the key event, or the browser's native
///   dialog opens *underneath* this one. On every other platform,
///   [installFindKeyCapture] resolves to a no-op stub, and [LayrzShortcut]
///   alone handles the chord.
/// * Owns the highlight-painting [OverlayEntry] and the find-bar
///   [OverlayEntry], both inserted into the **root** [Overlay]
///   (`Overlay.of(context, rootOverlay: true)`) — this was the exact fix
///   proven by the DESIGN-109 spike (see its `_ensureHighlightOverlayInserted`
///   doc, in `example/lib/src/sections/find_in_page/find_spike.dart`): the
///   matches/highlights this feature paints carry **global** (screen) rects,
///   and only the root overlay is guaranteed to share the screen's true
///   origin regardless of what chrome (a sidebar, an app bar) the current
///   page sits behind. A page-local `Stack` is not that guarantee.
///
/// ### In-page, not navigation
/// Opening find overlays a bar on top of the **current** page and searches
/// it — nothing here pushes, pops, or otherwise touches a [Navigator] or any
/// router. Closing (via the bar's close button, Escape, or toggling the
/// shortcut again) leaves the user exactly where they were.
///
/// ### Reaching the host
/// `.of(context)`/`.maybeOf(context)` resolve by tree ancestry only, mirroring
/// [LayrzShortcut.of]/[LayrzSnackbarMessenger.of]. Most callers never need to
/// reach this host directly — [LayrzApp] wires it up automatically, and
/// application code only interacts with find-in-page via the keyboard
/// shortcut or the bar's own controls. A caller building custom "open find"
/// UI (e.g. a menu item) can drive it via:
/// ```dart
/// LayrzFindInPageHost.of(context).controller.open();
/// ```
class LayrzFindInPageHost extends StatefulWidget {
  /// The subtree this host wraps — the app's real content, sitting
  /// underneath the find bar and highlight overlay whenever find is open.
  final Widget child;

  /// Creates a [LayrzFindInPageHost] wrapping [child].
  ///
  /// Application code should not normally construct this directly —
  /// [LayrzApp] installs it automatically when `enableFindInPage` is `true`
  /// (the default).
  const LayrzFindInPageHost({super.key, required this.child});

  /// Returns the [LayrzFindInPageHostState] from the nearest ancestor
  /// [LayrzFindInPageHost].
  ///
  /// [context] is the [BuildContext] to search upward from. Throws (via
  /// `assert`) if no ancestor is found — use [maybeOf] when the ancestor's
  /// presence is not guaranteed.
  static LayrzFindInPageHostState of(BuildContext context) {
    final state = maybeOf(context);
    assert(
      state != null,
      'LayrzFindInPageHost.of() called with a context that does not contain a '
      'LayrzFindInPageHost ancestor. This should not happen in application code — '
      'LayrzApp installs the host automatically when enableFindInPage is true (the '
      'default). In a widget test, wrap the tree under test with a LayrzFindInPageHost.',
    );
    return state!;
  }

  /// Returns the [LayrzFindInPageHostState] from the nearest ancestor
  /// [LayrzFindInPageHost], or `null` if there is none.
  ///
  /// [context] is the [BuildContext] to search upward from. Resolution is by
  /// tree ancestry via [_LayrzFindInPageScope] — an O(1),
  /// `dependOnInheritedWidgetOfExactType` lookup. There is no [GlobalKey]
  /// fallback.
  static LayrzFindInPageHostState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LayrzFindInPageScope>()?.state;
  }

  @override
  State<LayrzFindInPageHost> createState() => LayrzFindInPageHostState();
}

/// The [State] backing [LayrzFindInPageHost].
///
/// Exposes [controller] as the imperative entry point for a caller that wants
/// to drive find-in-page programmatically. See the class-level doc on
/// [LayrzFindInPageHost] for the full behavioural contract.
class LayrzFindInPageHostState extends State<LayrzFindInPageHost> {
  /// The controller owning all search state for this host — see
  /// [LayrzFindInPageController]'s own doc for its full lifecycle contract,
  /// most importantly that it holds a [SemanticsHandle] only while open.
  final LayrzFindInPageController controller = LayrzFindInPageController();

  /// The registered Ctrl/Cmd+F shortcut handle, or `null` if no
  /// [LayrzShortcut] ancestor was found to register against (see
  /// [_registerShortcut]'s doc).
  LayrzShortcutHandle? _shortcutHandle;

  /// The [LayrzShortcutState] [_shortcutHandle] was registered against,
  /// captured at registration time.
  ///
  /// [dispose] deregisters through this cached reference rather than calling
  /// `LayrzShortcut.maybeOf(context)` again — by the time [State.dispose]
  /// runs, this element can already be deactivated (e.g. its whole ancestor
  /// subtree was replaced in the same frame), and
  /// [BuildContext.dependOnInheritedWidgetOfExactType] asserts against
  /// exactly that ("Looking up a deactivated widget's ancestor is unsafe").
  /// Caching the resolved state at registration time — when the context is
  /// known-good — sidesteps that assertion entirely.
  LayrzShortcutState? _shortcutRegistry;

  /// The web-only browser-level Ctrl/Cmd+F interceptor (a no-op handle on
  /// non-web targets) — installed in [initState], disposed in [dispose].
  late final FindKeyCapture _findKeyCapture;

  /// Key on the find bar's own content, resolved to its rendered [RenderBox]
  /// so [_updateExcludeRect] can measure its global rect — see
  /// [LayrzFindInPageController]'s "Self-exclusion" doc for why this
  /// rect-based approach, rather than the spike's debug-only
  /// `debugSemantics` id lookup, is what makes exclusion release-safe.
  final GlobalKey _findBarKey = GlobalKey();

  /// The [OverlayEntry] painting the highlight layer, inserted into the
  /// app's root [Overlay]. `null` until first inserted, and reset to `null`
  /// after being removed in [dispose].
  OverlayEntry? _highlightOverlayEntry;

  /// The [OverlayEntry] hosting [LayrzFindBar] while
  /// [LayrzFindInPageController.isOpen] is `true`. `null` while closed.
  OverlayEntry? _findBarOverlayEntry;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleControllerChanged);
    _findKeyCapture = installFindKeyCapture(onFindPressed: controller.open);
    // A LayrzShortcut ancestor is not guaranteed synchronously available
    // during initState in every embedding (e.g. a test pumping this host in
    // isolation before its own frame settles), and ShortcutRegistry.of
    // requires an Overlay/Navigator context that is only reliably resolvable
    // once this State's own context is fully mounted under LayrzApp. This
    // mirrors the spike's own post-frame deferral for its highlight overlay
    // insertion (see find_spike.dart's initState doc) for the same reason:
    // inserting/registering mid-build is not allowed, so both are deferred to
    // the first post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _registerShortcut();
      _ensureHighlightOverlayInserted();
    });
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    final handle = _shortcutHandle;
    if (handle != null) {
      _shortcutRegistry?.deregister(handle);
    }
    _findKeyCapture.dispose();
    _highlightOverlayEntry?.remove();
    _highlightOverlayEntry = null;
    _findBarOverlayEntry?.remove();
    _findBarOverlayEntry = null;
    controller.dispose();
    super.dispose();
  }

  /// Registers the Ctrl/Cmd+F chord against the nearest [LayrzShortcut]
  /// ancestor, if any.
  ///
  /// Uses [LayrzShortcut.maybeOf] — deliberately, not [LayrzShortcut.of] —
  /// so a tree with no [LayrzShortcut] ancestor (a bare [LayrzFindInPageHost]
  /// under test, for instance) simply cannot open find via keyboard, rather
  /// than throwing. The modifier is [LogicalKeyboardKey.meta] on macOS and
  /// [LogicalKeyboardKey.control] everywhere else — see
  /// [LayrzPlatform.isMacOS].
  void _registerShortcut() {
    final registry = LayrzShortcut.maybeOf(context);
    if (registry == null) return;

    final modifier = LayrzPlatform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;
    _shortcutRegistry = registry;
    _shortcutHandle = registry.register(
      keys: {modifier, LogicalKeyboardKey.keyF},
      onInvoke: controller.toggle,
      debugLabel: 'find-in-page',
    );
  }

  /// Rebuilds the highlight and find-bar overlays whenever the controller's
  /// state changes — matches/highlights for the painter, open/close for
  /// whether the bar overlay entry exists at all.
  void _handleControllerChanged() {
    if (!mounted) return;
    _highlightOverlayEntry?.markNeedsBuild();
    _syncFindBarOverlay();
  }

  /// Inserts [_highlightOverlayEntry] into the app's root [Overlay] if not
  /// already inserted — idempotent, mirrors the spike's
  /// `_ensureHighlightOverlayInserted` exactly, including why `rootOverlay:
  /// true` is load-bearing rather than defensive (see that method's doc).
  void _ensureHighlightOverlayInserted() {
    if (_highlightOverlayEntry != null) return;
    final entry = OverlayEntry(builder: _buildHighlightOverlay);
    _highlightOverlayEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  /// Inserts or removes [_findBarOverlayEntry] to match
  /// [LayrzFindInPageController.isOpen] — the bar exists in the overlay tree
  /// only while find is open, exactly like the controller's own
  /// [SemanticsHandle] (see that class's "Idle cost" doc).
  void _syncFindBarOverlay() {
    if (controller.isOpen) {
      if (_findBarOverlayEntry != null) return;
      final entry = OverlayEntry(builder: _buildFindBarOverlay);
      _findBarOverlayEntry = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
    } else {
      _findBarOverlayEntry?.remove();
      _findBarOverlayEntry = null;
    }
  }

  /// Measures the find bar's own on-screen rect via [_findBarKey] and hands
  /// it to [LayrzFindInPageController.updateExcludeRect] — the release-safe
  /// self-exclusion mechanism described on that controller's class doc.
  /// Scheduled post-frame from [_buildFindBarOverlay] on every build, so it
  /// always reflects the bar's latest layout (a resize, or its very first
  /// layout after opening).
  void _scheduleExcludeRectUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _findBarKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      controller.updateExcludeRect(rect);
    });
  }

  /// Closes find — the single place that decides what "closing find" means,
  /// called from [LayrzFindBar.onClose] rather than letting the bar call
  /// [LayrzFindInPageController.close] directly (see [LayrzFindBar]'s own
  /// doc on why).
  void _handleFindBarClose() {
    controller.close();
  }

  /// Builds the highlight layer's content — a full-screen,
  /// pointer-ignoring [CustomPaint] driven by [FindHighlightPainter],
  /// reading [controller] live. Mirrors the spike's
  /// `_buildHighlightOverlay` exactly, including resolving
  /// [MatchHighlight]'s positional index within the visible-only list to
  /// find [FindHighlightPainter.currentIndex] (the painter addresses
  /// highlights positionally, not by node id).
  Widget _buildHighlightOverlay(BuildContext context) {
    final tokens = LayrzTheme.of(context).tokens;

    final matches = controller.matches;
    final visibleMatches = controller.visibleMatches;
    final currentIndex = controller.currentIndex;
    final currentMatch = currentIndex >= 0 && currentIndex < matches.length ? matches[currentIndex] : null;
    final visibleCurrentIndex = currentMatch == null ? -1 : visibleMatches.indexOf(currentMatch);

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: FindHighlightPainter(
          highlights: controller.highlights,
          currentIndex: visibleCurrentIndex,
          currentColor: tokens.colors.selectionColor.withValues(alpha: 0.35),
          otherColor: tokens.colors.selectionColor.lighten(0.6).withValues(alpha: 0.45),
        ),
      ),
    );
  }

  /// Builds the find bar's overlay content — compact and pinned to the
  /// top-right corner, browser style (matching Chrome's own Ctrl+F find
  /// bar) — and schedules the exclude-rect measurement described on
  /// [_scheduleExcludeRectUpdate].
  ///
  /// The bar is sized to its own content (an [Align] never stretches its
  /// child), so this only supplies the top/right margin and a defensive
  /// upper bound on width: [ConstrainedBox] caps it at the available width
  /// minus that same margin on both sides, via [MediaQuery.sizeOf], so a
  /// very narrow (mobile/compact) viewport shrinks the bar instead of
  /// letting it overflow past the screen's left edge — the bar still stays
  /// anchored top-right in that case, just narrower.
  Widget _buildFindBarOverlay(BuildContext context) {
    _scheduleExcludeRectUpdate();

    final tokens = LayrzTheme.of(context).tokens;
    final margin = tokens.spacing.sp3;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: margin, right: margin),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: (screenWidth - margin * 2).clamp(0.0, double.infinity)),
            child: KeyedSubtree(
              key: _findBarKey,
              child: LayrzFindBar(controller: controller, onClose: _handleFindBarClose),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancestor = context.dependOnInheritedWidgetOfExactType<_LayrzFindInPageScope>();
    if (ancestor != null) {
      assert(
        false,
        'A LayrzFindInPageHost was found further up the tree. LayrzApp already installs '
        'a find-in-page host automatically when enableFindInPage is true — remove this '
        'LayrzFindInPageHost and use LayrzFindInPageHost.of(context) to reach the '
        'existing one instead.',
      );
      return widget.child;
    }

    return _LayrzFindInPageScope(state: this, child: widget.child);
  }
}
