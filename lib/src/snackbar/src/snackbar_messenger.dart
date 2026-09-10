import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'snackbar.dart';
import 'snackbar_style_spec.dart';
import 'snackbar_view.dart';

/// The maximum number of toasts shown at once in the accordion stack.
///
/// Anything queued beyond this collapses into the "+N / Dismiss all"
/// overflow affordance rather than growing the stack without bound
/// (DESIGN-60 §16.4 — the frozen stacking-cap principle). Callers may pass a
/// different [LayrzSnackbarMessenger.maxVisible] (e.g. `50`) to effectively
/// disable the overflow affordance for their use case.
const int kLayrzSnackbarMaxVisible = 3;

/// The default maximum width of a snackbar card, in logical pixels.
///
/// Matches the design spec's `max-width ~440px` (DESIGN-60 §Anatomy) and
/// `ThemedSnackbarMessenger`'s prior-art `maxWidth` configuration surface.
const double kLayrzSnackbarMaxWidth = 440;

/// Duration of the entry slide+fade+scale animation for a newly-shown toast.
///
/// Matches the design spec's `@keyframes sbUp`/`sbRight` timing: `.26s
/// cubic-bezier(.2,.8,.2,1)` (DESIGN-60 §Motion).
const Duration _kEntryDuration = Duration(milliseconds: 260);

/// Easing curve for the entry slide+fade+scale animation.
///
/// Approximates the design spec's `cubic-bezier(.2,.8,.2,1)` (DESIGN-60
/// §Motion) — a fast-out, gently-settling curve.
const Cubic _kEntryCurve = Cubic(0.2, 0.8, 0.2, 1.0);

/// The at-rest peek offset applied per stacking depth, in logical pixels.
///
/// At rest (no hover), the deck is a compact stack: the front (newest,
/// depth 0) card shows full content, and each older card behind it is offset
/// this many pixels further down per depth, so only a slim sliver of its top
/// edge peeks out — enough to signal "there are more behind" without
/// clipping into unreadable content (DESIGN-60 §STACKING, final).
const double _kRestOffsetStep = 14;

/// The opacity applied to a peeking (depth ≥ 1) card at rest, blended toward
/// full opacity as the deck fans out on hover.
///
/// Subtle — the spec calls for a slight fade to read as "behind", not a
/// strong dim. The front card (depth 0) is always full opacity regardless of
/// hover state.
const double _kRestPeekOpacity = 0.7;

/// Duration of the rest ⇄ fanned accordion transition driven by hover.
///
/// Reuses the entry-animation timing so hover fan-out/collapse feels of a
/// piece with the rest of the stack's motion language.
const Duration _kFanDuration = _kEntryDuration;

/// The release-velocity threshold (logical pixels/second) past which a
/// horizontal swipe dismisses its card, a vertical swipe-down expands the
/// deck, or a vertical swipe-up collapses it — shared by
/// [LayrzSnackbarMessengerState._handleSwipe] and
/// [LayrzSnackbarMessengerState._handlePanEnd].
const double kSwipeVelocityThreshold = 200;

/// The fraction of a card's own measured width past which an accumulated
/// horizontal drag distance dismisses the card on release, independent of
/// release velocity — a slow-but-far drag reads as an intentional swipe just
/// as much as a fast flick does.
const double kSwipeDistanceFraction = 0.35;

/// Duration of the drag-follow settle animation — spring-back to center on
/// an under-threshold release, or fling-off-screen on a past-threshold one.
///
/// Deliberately its own constant (not [_kEntryDuration]/[_kFanDuration]):
/// this is the fastest motion in the file, matching a real swipe's snap
/// rather than the more deliberate entry/fan timings.
const Duration _kDragSettleDuration = Duration(milliseconds: 200);

/// Easing curve for the spring-back leg of the drag settle — a gentle
/// overshoot-free deceleration back to center.
const Curve _kSpringBackCurve = Curves.easeOut;

/// Easing curve for the fling-off-screen leg of the drag settle — starts
/// fast (continuing the release velocity's implied motion) and eases out.
const Curve _kFlingOutCurve = Curves.easeOut;

/// The minimum opacity a card fades to as it is dragged away from center,
/// reached once `|dragDx|` hits the dismiss distance threshold. Never fully
/// `0` mid-drag (that is reserved for the fling-out animation past release)
/// so the card stays faintly visible for as long as the finger is still on
/// it.
const double _kMinDragOpacity = 0.15;

/// One entry in the messenger's live queue: the caller's [LayrzSnackbar]
/// payload plus all of the messenger-owned timing/animation state needed to
/// present it.
///
/// This is intentionally private and mutable — it is bookkeeping for
/// [LayrzSnackbarMessengerState], never exposed to callers. Everything the
/// public API exposes is the immutable [LayrzSnackbar] itself.
class _SnackbarEntry {
  /// Creates a [_SnackbarEntry] for [snackbar], wiring its lifecycle
  /// callbacks and starting its entry animation immediately.
  ///
  /// A [drainController] is only constructed when `snackbar.duration` is
  /// non-null (auto-dismiss). Persistent snackbars (`duration == null`) get
  /// no drain controller at all — [drainController] stays `null`, no timer
  /// runs, and no auto-dismiss is ever scheduled for them.
  _SnackbarEntry({
    required this.snackbar,
    required TickerProvider vsync,
  }) : entryController = AnimationController(vsync: vsync, duration: _kEntryDuration),
       dragController = AnimationController(vsync: vsync, duration: _kDragSettleDuration),
       drainController = snackbar.duration != null
           ? AnimationController(vsync: vsync, duration: snackbar.duration)
           : null {
    entryController.forward();
    final drain = drainController;
    if (drain != null) {
      drain.reverse(from: 1.0);
      drain.addStatusListener(_handleDrainStatus);
    }
  }

  /// The caller-supplied payload this entry presents.
  final LayrzSnackbar snackbar;

  /// Key attached to this entry's rendered card, used to measure its actual
  /// height after layout so the hover fan-out can offset later cards by
  /// exactly enough to clear this one — no fixed constant can do this
  /// reliably since card height varies with description length and actions
  /// (DESIGN-60 §STACKING, final: "pick a mechanism that makes hover show
  /// every card's full content with no overlap").
  final GlobalKey cardKey = GlobalKey();

  /// Drives the entry slide+fade+scale transition, `0.0` (just enqueued) to
  /// `1.0` (fully settled in the stack).
  final AnimationController entryController;

  /// Drives the draining hairline, `1.0` (just shown) down to `0.0` (about to
  /// auto-dismiss). Reversed (started at `1.0`, animated toward `0.0`) rather
  /// than forwarded, so [LayrzSnackbarView.progress] can read
  /// `drainController.value` directly.
  ///
  /// `null` for persistent snackbars (`snackbar.duration == null`) — there is
  /// no timer to drive, so no controller is ever created for them.
  final AnimationController? drainController;

  /// Drives the drag-follow settle animation — the spring-back-to-center or
  /// fling-off-screen tween that plays after a horizontal drag is released.
  /// Idle (and irrelevant) for the whole rest of this entry's lifetime; it
  /// only ever runs immediately after [_handlePanEnd] decides which of the
  /// two settle outcomes applies.
  final AnimationController dragController;

  /// The live horizontal drag offset, in logical pixels, applied as an
  /// additional [Transform.translate] on top of this entry's existing
  /// entry-transition transform. `0.0` at rest.
  ///
  /// Updated per-frame during an in-progress horizontal drag
  /// ([LayrzSnackbarMessengerState._handlePanUpdate]), then animated by
  /// [dragController] on release — either back to `0.0` (spring-back) or out
  /// to a full off-screen value (fling-out, immediately followed by
  /// dismissal).
  double dragDx = 0.0;

  /// The raw, un-axis-locked accumulated horizontal delta for the
  /// **in-progress** gesture, tracked from [PanUpdateDetails] regardless of
  /// which axis the gesture is eventually locked to.
  ///
  /// Reset to `0.0` at [PanStartDetails] of a new gesture. Only meaningful
  /// while a gesture is live; irrelevant once locked to horizontal (from
  /// then on [dragDx] itself is the tracked value) and unused for a
  /// vertical-locked gesture.
  double rawDragDx = 0.0;

  /// The raw, un-axis-locked accumulated vertical delta for the
  /// **in-progress** gesture — the counterpart to [rawDragDx], used only to
  /// decide the axis lock.
  double rawDragDy = 0.0;

  /// Whether the axis for the in-progress gesture has been decided yet.
  ///
  /// `null` before enough delta has accumulated to tell; `true` once locked
  /// to horizontal (drag-follow applies); `false` once locked to vertical
  /// (gesture-only expand/collapse applies, no card-follow).
  bool? isHorizontalDrag;

  /// Called when [drainController] reaches `0.0` unpaused — the auto-dismiss path.
  ///
  /// Mutable (not `final`) because the handler needs to close over this very
  /// entry, which does not exist yet at construction time — the owning
  /// [LayrzSnackbarMessengerState] assigns it immediately after constructing
  /// this entry, before the drain animation can possibly complete.
  VoidCallback onExpired = _noop;

  /// A no-op placeholder [onExpired] starts with, replaced immediately by the
  /// owning state. Exists only so [onExpired] can be non-nullable.
  static void _noop() {}

  /// Whether this entry is currently mid-dismissal (exit animation running).
  ///
  /// Guards against double-dismissal — a close-tap racing an in-flight
  /// auto-dismiss, for instance — from tearing down the same entry twice.
  bool isClosing = false;

  void _handleDrainStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      onExpired();
    }
  }

  /// Pauses the draining timer (hover-pause, DESIGN-60 §16.3/§Motion).
  ///
  /// A no-op for persistent snackbars, which have no [drainController].
  void pauseDrain() {
    final drain = drainController;
    if (drain != null && drain.isAnimating) {
      drain.stop();
    }
  }

  /// Resumes the draining timer from wherever it was paused.
  ///
  /// A no-op for persistent snackbars, which have no [drainController].
  void resumeDrain() {
    final drain = drainController;
    if (drain != null && !drain.isAnimating && drain.value > 0) {
      drain.reverse(from: drain.value);
    }
  }

  /// Disposes both animation controllers. Must be called exactly once, when
  /// this entry is removed from the queue for good.
  void dispose() {
    final drain = drainController;
    if (drain != null) {
      drain.removeStatusListener(_handleDrainStatus);
      drain.dispose();
    }
    entryController.dispose();
    dragController.dispose();
  }
}

/// [InheritedWidget] exposing a [LayrzSnackbarMessengerState] to descendants
/// by tree ancestry.
///
/// This is the sole mechanism behind [LayrzSnackbarMessenger.of] and
/// [LayrzSnackbarMessenger.maybeOf] — mirroring how [LayrzTheme] propagates
/// [LayrzThemeData]. There is deliberately no [GlobalKey]-based path:
/// `layrz_theme`'s `ThemedSnackbarMessenger` used a global key and it caused a
/// lot of trouble in practice, so `layrz_ui`'s messenger is ancestry-only.
class _LayrzSnackbarScope extends InheritedWidget {
  /// The state instance this scope exposes to descendants.
  final LayrzSnackbarMessengerState state;

  /// Creates a [_LayrzSnackbarScope] wrapping [child] and exposing [state].
  const _LayrzSnackbarScope({required this.state, required super.child});

  /// Never triggers a rebuild on its own — [state] is a stable [State]
  /// identity for the lifetime of the messenger, and callers observe queue
  /// changes via the [State]'s own `setState`, not via this widget rebuilding.
  @override
  bool updateShouldNotify(_LayrzSnackbarScope oldWidget) => false;
}

/// Hosts the transient-feedback overlay for [LayrzSnackbar] toasts.
///
/// [LayrzSnackbarMessenger] is the Material-free drop-in replacement for
/// `ThemedSnackbarMessenger`: it owns a root [Overlay] entry, a FIFO queue of
/// pending toasts, a top-center spaced vertical list (up to [maxVisible]
/// cards, newest on top, each rendered at full size and full opacity with no
/// overlap, scale, or fade between them, so every visible card stays fully
/// readable — the rest collapsed behind a "+N / Dismiss all" affordance),
/// per-toast entry/drain animations, hover-pause (drain only — the list's
/// geometry itself does not react to hover), and every dismissal path
/// (auto-timeout, close-tap, body-tap via `onTap`, and swipe) on any visible
/// card. It renders no toast itself — presentation is delegated entirely to
/// [LayrzSnackbarView].
///
/// **Installation is automatic.** [LayrzApp] installs exactly one
/// [LayrzSnackbarMessenger] in its subtree, the same way it installs
/// [LayrzTheme] — application code never constructs or wires one itself.
/// Access the host from any descendant's [BuildContext]:
/// ```dart
/// LayrzSnackbarMessenger.of(context).show(
///   const LayrzSnackbar(titleText: 'Saved', descriptionText: 'Done.'),
/// );
/// ```
/// `.of(context)`/`.maybeOf(context)` resolve by **tree ancestry only** (an
/// [InheritedWidget] this messenger exposes from its `build`) — there is no
/// [GlobalKey] anywhere in this class. `layrz_theme`'s `ThemedSnackbarMessenger`
/// used a global key and it caused a lot of trouble; this messenger
/// deliberately does not repeat that mistake.
///
/// If application code constructs an additional [LayrzSnackbarMessenger]
/// inside a subtree that already has one as an ancestor (which should not
/// normally happen, since [LayrzApp] installs the only one needed), this
/// widget detects the ancestor, asserts in debug, and renders [child] inertly
/// instead of installing a second overlay — `.of(context)` always resolves to
/// the outermost (first-installed) host either way.
class LayrzSnackbarMessenger extends StatefulWidget {
  /// The subtree this messenger hosts.
  ///
  /// The overlay stack is painted as a sibling above [child] inside this
  /// widget's own [Overlay], so [child] itself is unaffected by toast
  /// presentation — no [Scaffold]-style layout shift occurs.
  final Widget child;

  /// The maximum width of a snackbar card, in logical pixels.
  ///
  /// Defaults to [kLayrzSnackbarMaxWidth] (~440px), matching the design spec.
  final double maxWidth;

  /// The padding applied around the stacked toasts, inset from the edges of
  /// the [Overlay].
  ///
  /// Defaults to `EdgeInsets.all(16)`. On compact viewports, the effective
  /// top inset is the larger of this value's top and the device's top
  /// safe-area padding ([MediaQuery.paddingOf]), so the stack never sits
  /// under a notch or status bar (DESIGN-60 §Compact).
  final EdgeInsets padding;

  /// The maximum number of toasts visible in the accordion stack at once.
  ///
  /// Defaults to [kLayrzSnackbarMaxVisible] (3). Anything queued beyond this
  /// collapses into a "+N / Dismiss all" affordance (DESIGN-60 §16.4). This is
  /// intentionally a plain `int` set at construction — pass a larger value
  /// (e.g. `50`) to a call site that wants the overflow affordance to
  /// effectively never trigger.
  final int maxVisible;

  /// Creates a [LayrzSnackbarMessenger].
  const LayrzSnackbarMessenger({
    super.key,
    required this.child,
    this.maxWidth = kLayrzSnackbarMaxWidth,
    this.padding = const EdgeInsets.all(16),
    this.maxVisible = kLayrzSnackbarMaxVisible,
  });

  /// Returns the [LayrzSnackbarMessengerState] from the nearest ancestor
  /// [LayrzSnackbarMessenger].
  ///
  /// [context] is the [BuildContext] to search upward from. Throws a
  /// [FlutterError] if no ancestor is found — use [maybeOf] when the
  /// ancestor's presence is not guaranteed (e.g. in a widget test that has
  /// not wrapped its tree with a messenger). In application code this should
  /// always succeed, since [LayrzApp] installs the host automatically.
  static LayrzSnackbarMessengerState of(BuildContext context) {
    final state = maybeOf(context);
    assert(
      state != null,
      'LayrzSnackbarMessenger.of() called with a context that does not contain a '
      'LayrzSnackbarMessenger ancestor. This should not happen in application code — '
      'LayrzApp installs the messenger host automatically. In a widget test, wrap the '
      'tree under test with a LayrzSnackbarMessenger.',
    );
    return state!;
  }

  /// Returns the [LayrzSnackbarMessengerState] from the nearest ancestor
  /// [LayrzSnackbarMessenger], or `null` if there is none.
  ///
  /// [context] is the [BuildContext] to search upward from. Resolution is by
  /// tree ancestry via [_LayrzSnackbarScope] — an O(1),
  /// `dependOnInheritedWidgetOfExactType` lookup, mirroring
  /// [LayrzTheme.maybeOf]. There is no [GlobalKey]-based fallback.
  static LayrzSnackbarMessengerState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LayrzSnackbarScope>()?.state;
  }

  @override
  State<LayrzSnackbarMessenger> createState() => LayrzSnackbarMessengerState();
}

/// The [State] backing [LayrzSnackbarMessenger].
///
/// Exposes [show] (and the [showSnackbar] alias) as the imperative entry
/// point callers use via [LayrzSnackbarMessenger.of]/[LayrzSnackbarMessenger.maybeOf].
/// Owns the [Overlay], the queue, all animation controllers, and every
/// dismissal path — see the class-level doc on [LayrzSnackbarMessenger] for
/// the full behavioural contract.
class LayrzSnackbarMessengerState extends State<LayrzSnackbarMessenger> with TickerProviderStateMixin {
  /// The live queue of toasts, newest first. Only the first [widget.maxVisible]
  /// entries are painted in the accordion; earlier ones count toward the "+N"
  /// overflow affordance until they are dismissed or promoted into view.
  final List<_SnackbarEntry> _queue = <_SnackbarEntry>[];

  /// Whether the pointer is currently hovering the stack.
  ///
  /// Drives two things at once: pausing every visible entry's drain timer,
  /// and fanning the compact accordion deck out into a fully-readable,
  /// non-overlapping layout (DESIGN-60 §STACKING, final).
  bool _isHovered = false;

  /// The last-measured rendered height of each entry's card, in logical
  /// pixels, keyed by entry identity.
  ///
  /// Populated after every frame via [_scheduleRemeasure] by reading
  /// `_SnackbarEntry.cardKey`'s `RenderBox`. The hover fan-out uses these to
  /// offset each card by exactly the cumulative height of the cards in front
  /// of it, so every card clears the previous one's content regardless of
  /// how tall it renders (variable description length, actions row, etc.) —
  /// no fixed constant can do this reliably.
  final Map<_SnackbarEntry, double> _measuredHeights = <_SnackbarEntry, double>{};

  /// The rest-state peek offset used for an entry before its real height has
  /// ever been measured (e.g. the first frame it appears).
  static const double _kFallbackCardHeight = 76;

  @override
  void dispose() {
    for (final entry in _queue) {
      entry.dispose();
    }
    _queue.clear();
    super.dispose();
  }

  /// Shows [snackbar], enqueueing it at the top of the list.
  ///
  /// The newest toast always renders first (topmost). If the queue already
  /// holds [LayrzSnackbarMessenger.maxVisible] visible entries, the oldest
  /// visible one is pushed into the collapsed "+N" overflow rather than being
  /// evicted — nothing is dropped silently.
  void show(LayrzSnackbar snackbar) {
    final entry = _SnackbarEntry(snackbar: snackbar, vsync: this);
    entry.onExpired = () => _dismiss(entry);
    if (_isHovered) {
      entry.pauseDrain();
    }
    setState(() {
      _queue.insert(0, entry);
    });
  }

  /// Alias for [show], matching the naming some callers expect from
  /// `ThemedSnackbarMessenger`'s prior art.
  void showSnackbar(LayrzSnackbar snackbar) => show(snackbar);

  /// Dismisses [entry] — removes it from the queue and disposes its
  /// controllers. Safe to call more than once for the same entry (guarded by
  /// [_SnackbarEntry.isClosing]); a race between, say, an auto-expiry and a
  /// close-tap firing in the same frame is a no-op on the second call.
  void _dismiss(_SnackbarEntry entry) {
    if (entry.isClosing) return;
    entry.isClosing = true;
    if (!mounted) {
      entry.dispose();
      return;
    }
    setState(() {
      _queue.remove(entry);
    });
    _measuredHeights.remove(entry);
    entry.dispose();
  }

  /// Dismisses every queued toast, visible or collapsed — the "+N / Dismiss
  /// all" affordance's action (DESIGN-60 §16.4).
  void dismissAll() {
    final entries = List<_SnackbarEntry>.from(_queue);
    for (final entry in entries) {
      _dismiss(entry);
    }
  }

  /// Pauses every visible entry's drain and fans the deck out (hover-enter on
  /// the stack).
  void _handleStackEnter() {
    setState(() => _isHovered = true);
    for (final entry in _visibleEntries) {
      entry.pauseDrain();
    }
  }

  /// Resumes every visible entry's drain and collapses the deck back to the
  /// compact accordion (hover-exit off the stack).
  void _handleStackExit() {
    setState(() => _isHovered = false);
    for (final entry in _visibleEntries) {
      entry.resumeDrain();
    }
  }

  /// Reads back the actual rendered height of every visible card after the
  /// current frame and caches it in [_measuredHeights], then rebuilds so the
  /// hover fan-out (if active) uses up-to-date offsets.
  ///
  /// Scheduled from [_buildToast] on every build of a visible card — cheap,
  /// since it only runs once per already-scheduled frame and a `setState`
  /// with unchanged values is a no-op rebuild in practice.
  void _scheduleRemeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var changed = false;
      for (final entry in _visibleEntries) {
        final renderBox = entry.cardKey.currentContext?.findRenderObject() as RenderBox?;
        final height = renderBox?.size.height;
        if (height != null && height > 0 && _measuredHeights[entry] != height) {
          _measuredHeights[entry] = height;
          changed = true;
        }
      }
      if (changed) setState(() {});
    });
  }

  /// The cumulative fanned-out `top` offset for the card at [index] within
  /// [visible] (newest-first) — the sum of every card in front of it's
  /// measured height plus a gap, so it clears all of them with no overlap.
  ///
  /// Falls back to [_kFallbackCardHeight] for any card not yet measured
  /// (e.g. its first frame), which is close enough to avoid a visible jump
  /// once the real measurement lands a frame later.
  double _fannedOffsetFor(List<_SnackbarEntry> visible, int index, double gap) {
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += (_measuredHeights[visible[i]] ?? _kFallbackCardHeight) + gap;
    }
    return offset;
  }

  /// The last-known rendered width of [entry]'s card, in logical pixels, or
  /// [LayrzSnackbarMessenger.maxWidth] as a fallback when it has never been
  /// laid out yet (e.g. the very first frame it appears, or a `dragDx`
  /// computation running mid-build before layout has occurred this frame).
  ///
  /// Reads `entry.cardKey`'s `RenderBox` directly — the same mechanism
  /// [_scheduleRemeasure] uses to measure card height — rather than
  /// `BuildContext.size`, which asserts when called during `build` (as this
  /// is, from [_buildToast]'s `AnimatedBuilder`).
  ///
  /// [GlobalKey.currentContext] can momentarily still resolve to an element
  /// that is being reparented this very frame — e.g. an entry demoted from
  /// depth 0 to depth 1 when a new toast is enqueued while the deck is
  /// already fanned out, which swaps its wrapper widget between
  /// [KeyedSubtree] and [AnimatedPositioned] at the same [ValueKey]. That
  /// element can be `_ElementLifecycle.inactive` (its `debugIsActive` is
  /// only meaningful in debug builds — see [Element.debugIsActive] — so it
  /// cannot gate this in profile/release), and calling
  /// [Element.findRenderObject] on it throws "Cannot get renderObject of
  /// inactive element". The `try`/`catch` here is the actual guard (works in
  /// every build mode); falling back to [widget.maxWidth] for that one
  /// transient frame is exactly the same graceful fallback already used for
  /// "never laid out yet".
  double _measuredCardWidth(_SnackbarEntry entry) {
    RenderBox? renderBox;
    try {
      renderBox = entry.cardKey.currentContext?.findRenderObject() as RenderBox?;
    } on FlutterError {
      renderBox = null;
    }
    final width = renderBox?.hasSize == true ? renderBox!.size.width : null;
    return (width != null && width > 0) ? width : widget.maxWidth;
  }

  /// The subset of [_queue] currently painted in the list — the newest
  /// [widget.maxVisible] entries, newest first (topmost). Anything past this
  /// counts toward the "+N" overflow badge instead.
  List<_SnackbarEntry> get _visibleEntries => _queue.take(widget.maxVisible).toList(growable: false);

  /// The number of queued toasts not currently visible — the "+N" count.
  int get _overflowCount => _queue.length > widget.maxVisible ? _queue.length - widget.maxVisible : 0;

  @override
  Widget build(BuildContext context) {
    final ancestor = context.dependOnInheritedWidgetOfExactType<_LayrzSnackbarScope>();
    if (ancestor != null) {
      assert(
        false,
        'A LayrzSnackbarMessenger was found further up the tree. LayrzApp already installs '
        'a snackbar host automatically — remove this LayrzSnackbarMessenger and use '
        'LayrzSnackbarMessenger.of(context) to reach the existing one instead.',
      );
      return widget.child;
    }

    return _LayrzSnackbarScope(
      state: this,
      child: Overlay(
        initialEntries: [
          OverlayEntry(builder: (overlayContext) => widget.child),
          OverlayEntry(builder: _buildStackOverlay),
        ],
      ),
    );
  }

  /// Builds the top-center overlay: an accordion deck of the visible toasts
  /// plus the overflow affordance, inset below the safe area on compact.
  ///
  /// **At rest**, the deck is compact: the front (newest, depth 0) card shows
  /// full content on top, and each older card peeks a slim sliver further
  /// down behind it. **On hover**, the deck fans out downward so every
  /// card's full content is visible with no overlap, then collapses back on
  /// hover exit (DESIGN-60 §STACKING, final).
  ///
  /// The front card is deliberately the Stack's one non-positioned child —
  /// giving the Stack a bounded intrinsic size — while every older card is
  /// `Positioned` beneath it. A Stack built from only `Positioned` children
  /// asserts under the unbounded-height constraints this overlay sits in
  /// (Overlay → Positioned → Center); keeping the front card unpositioned is
  /// what avoids that crash.
  ///
  /// [widget.padding]'s left/right insets are applied on this `Positioned`
  /// itself (not just its `top`), so a viewport narrower than [widget.maxWidth]
  /// always keeps a horizontal gutter instead of stretching the card
  /// edge-to-edge. The inner `Center` + `ConstrainedBox(maxWidth)` still caps
  /// and centers the card on wide viewports — the inset only ever tightens
  /// the available width, it never widens it past [widget.maxWidth].
  Widget _buildStackOverlay(BuildContext context) {
    if (_queue.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final l10n = context.l10n;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final effectiveTop = topSafeArea > widget.padding.top ? topSafeArea : widget.padding.top;

    final visible = _visibleEntries;
    final gap = tokens.spacing.sp2;

    return Positioned(
      top: effectiveTop,
      left: widget.padding.left,
      right: widget.padding.right,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: MouseRegion(
            onEnter: (_) => _handleStackEnter(),
            onExit: (_) => _handleStackExit(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_overflowCount > 0) ...[
                  _buildOverflowAffordance(tokens, l10n),
                  SizedBox(height: gap),
                ],
                _buildAccordionDeck(visible, gap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The extent (in logical pixels) the accordion deck's enclosing box must
  /// reserve so every visible card — including the deepest fanned-out one —
  /// falls **inside** the [Stack]'s hit-test region.
  ///
  /// At rest (`_isHovered == false`), behind cards only peek
  /// `_kRestOffsetStep * depth` below the front card, so the compact extent
  /// is the front card's own measured height plus that last, deepest peek
  /// offset — a small sliver taller than the front card alone.
  ///
  /// When fanned out (`_isHovered == true`), every card sits at
  /// [_fannedOffsetFor]'s cumulative offset, so the extent must reach past
  /// the deepest card's own measured height on top of its offset — otherwise
  /// that card would render (paint, via `clipBehavior: Clip.none`) outside
  /// the [Stack]'s laid-out bounds and silently stop receiving pointer
  /// events (a [Stack] only hit-tests within its own layout size; painting
  /// past it is visual only). This is exactly the DESIGN-60 bug this method
  /// exists to close: only the front card was ever inside the Stack's
  /// bounds, so only it could be swiped once the deck was expanded.
  ///
  /// [visible] is newest-first, matching every other helper here, and must
  /// hold at least 2 entries — [_buildAccordionDeck] only calls this when
  /// there is at least one "behind" card to enclose. A card not yet measured
  /// falls back to [_kFallbackCardHeight], the same fallback
  /// [_fannedOffsetFor] uses, so the very first frame (before any
  /// [_scheduleRemeasure] callback has landed) still reserves a sane extent
  /// instead of collapsing toward zero.
  double _deckExtent(List<_SnackbarEntry> visible, double gap) {
    final front = visible.first;
    final frontHeight = _measuredHeights[front] ?? _kFallbackCardHeight;
    final deepest = visible.length - 1;

    if (_isHovered) {
      final deepestHeight = _measuredHeights[visible[deepest]] ?? _kFallbackCardHeight;
      return _fannedOffsetFor(visible, deepest, gap) + deepestHeight;
    }
    return frontHeight + _kRestOffsetStep * deepest;
  }

  /// Builds the accordion [Stack] itself from [visible] (newest-first).
  ///
  /// Depth 0 (the front/newest card) is the Stack's sole non-positioned
  /// child — this bounds the Stack's own intrinsic size, which matters under
  /// the unbounded-height constraints the enclosing `Overlay` → `Positioned`
  /// → `Center` → `Column` chain gives it (see the "single toast" regression
  /// guard test). Every deeper card is [AnimatedPositioned], tweening its
  /// `top` between the compact rest offset (`_kRestOffsetStep * depth`) and
  /// the fanned offset returned by [_fannedOffsetFor] (the cumulative
  /// measured height of every card in front of it), so hover reveals each
  /// card's complete content with no overlap regardless of how tall any of
  /// them render.
  ///
  /// The [Stack] is always wrapped in the same [AnimatedContainer] — with a
  /// single visible card its `height` is left `null` (an unconstrained
  /// [AnimatedContainer] sizes purely from its child, identical to the bare
  /// [Stack] this replaced), and with two or more cards its `height` becomes
  /// [_deckExtent] — enclosing every fanned-out card so it falls **inside**
  /// the Stack's hit-test region (see [_deckExtent]'s doc for why this is
  /// required, not cosmetic: this is exactly the DESIGN-60 bug this wrapper
  /// exists to close, where only the front card was ever inside the Stack's
  /// bounds once fanned, so only it could be swiped).
  ///
  /// Keeping the [AnimatedContainer] present unconditionally (rather than
  /// only wrapping once a second card exists) matters for its own reason:
  /// switching the widget *type* at this position in the tree — bare
  /// [Stack] one build, [AnimatedContainer] the next, as the deck grows from
  /// 1 to 2 entries — makes the framework deactivate and reinflate the whole
  /// subtree at exactly the moment a build is already in flight elsewhere in
  /// it, and this specific tree hits a real framework race from that
  /// (`Cannot get renderObject of inactive element`, from
  /// [_measuredCardWidth] reading a card's [RenderBox] mid-rebuild while its
  /// element is momentarily inactive). Keeping one stable widget type at
  /// this position for every entry count avoids that reinflation entirely.
  /// The inner [Stack]'s own front-card sizing mechanism is untouched either
  /// way; only the outer container's height ever changes.
  Widget _buildAccordionDeck(List<_SnackbarEntry> visible, double gap) {
    final front = visible.first;
    final behind = visible.skip(1).toList(growable: false);

    return AnimatedContainer(
      duration: _kFanDuration,
      curve: _kEntryCurve,
      height: behind.isEmpty ? null : _deckExtent(visible, gap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Deepest-first paint order: a Stack paints later children ON TOP
          // of earlier ones, and the front (newest) card must always be on
          // top — so every "behind" card is added before it, deepest first.
          for (var i = behind.length - 1; i >= 0; i--)
            AnimatedPositioned(
              key: ValueKey(behind[i]),
              duration: _kFanDuration,
              curve: _kEntryCurve,
              top: _isHovered ? _fannedOffsetFor(visible, i + 1, gap) : _kRestOffsetStep * (i + 1),
              left: 0,
              right: 0,
              child: _buildToast(behind[i], depth: i + 1),
            ),
          // Depth 0 — non-positioned (bounds the Stack's own intrinsic
          // size) and painted last, so it always sits on top of every
          // peeking card behind it.
          KeyedSubtree(
            key: ValueKey(front),
            child: _buildToast(front, depth: 0),
          ),
        ],
      ),
    );
  }

  /// Builds one animated toast from [entry] — the entry slide+fade+scale
  /// transition wrapping a [LayrzSnackbarView] driven by the entry's live
  /// drain progress.
  ///
  /// [depth] is this card's position in the accordion (`0` = front/newest).
  /// At rest, only depth `0` is interactive (close/tap/swipe) and deeper
  /// cards are faded toward [_kRestPeekOpacity] as a "there's more behind"
  /// hint; on hover, every card is fully opaque and fully interactive, since
  /// the fan-out makes all of them completely readable
  /// (DESIGN-60 §STACKING, final: "hovered = all interactive").
  ///
  /// The [LayrzSnackbarView] is constructed **inside** the [AnimatedBuilder]'s
  /// `builder` callback, not passed as its static `child`. `progress:` reads
  /// `entry.drainController.value`, which changes every drain tick — if the
  /// view were the untouched `child`, that value would be captured once at
  /// construction and the draining hairline would never advance on its own,
  /// only when some unrelated `setState` (e.g. hover) forced a rebuild. The
  /// swipe [GestureDetector] is built fresh alongside it for the same reason;
  /// only the outer entry-transform math is cheap enough to skip rebuilding,
  /// so it stays wired via the [AnimatedBuilder] itself rather than a `child`.
  ///
  /// [entry.dragController] is included in the same merged [Listenable] so
  /// the drag-follow translate/fade (below) also repaints every tick of the
  /// post-release spring-back/fling-out settle animation, not just during
  /// the live per-frame [_handlePanUpdate] drag itself (which drives its own
  /// `setState` directly, independent of this [AnimatedBuilder]).
  ///
  /// [entry.cardKey] is attached to the rendered card so
  /// [_scheduleRemeasure] can read back its real height after layout — the
  /// fan-out offsets depend on that measurement, so remeasuring is scheduled
  /// on every build of a visible card.
  ///
  /// Drag-follow feedback (DESIGN-60 revised gesture contract, drag-follow
  /// addendum): an in-progress **horizontal** drag translates this card by
  /// `entry.dragDx` — real-time, per-frame, tracking the pointer — and fades
  /// it as `|dragDx|` grows, composed as an *additional* translate/opacity on
  /// top of the existing entry slide+fade+scale transform (never replacing
  /// it). A **vertical** drag never touches `dragDx` — see
  /// [_handlePanUpdate] — so it stays gesture-only exactly as before.
  Widget _buildToast(_SnackbarEntry entry, {required int depth}) {
    final tokens = context.tokens;
    final style = LayrzSnackbarStyleSpec.resolve(
      entry.snackbar.type,
      tokens,
      customColor: entry.snackbar.color,
      customIcon: entry.snackbar.icon,
    );
    final bool isInteractive = depth == 0 || _isHovered;

    _scheduleRemeasure();

    return AnimatedBuilder(
      animation: Listenable.merge([entry.entryController, entry.drainController, entry.dragController]),
      builder: (context, _) {
        final entryT = _kEntryCurve.transform(entry.entryController.value);
        final peekOpacity = depth == 0 ? 1.0 : (_isHovered ? 1.0 : _kRestPeekOpacity);
        final cardWidth = _measuredCardWidth(entry);
        final dismissDistance = cardWidth * kSwipeDistanceFraction;
        final dragFade = (1 - (entry.dragDx.abs() / dismissDistance)).clamp(_kMinDragOpacity, 1.0);
        return AnimatedOpacity(
          duration: _kFanDuration,
          curve: _kEntryCurve,
          opacity: entryT.clamp(0.0, 1.0) * peekOpacity * dragFade,
          child: Transform.translate(
            offset: Offset(entry.dragDx, (1 - entryT) * -14),
            child: Transform.scale(
              scale: 0.97 + (0.03 * entryT),
              child: IgnorePointer(
                ignoring: !isInteractive,
                child: GestureDetector(
                  key: entry.cardKey,
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => _handlePanStart(entry),
                  onPanUpdate: (details) => _handlePanUpdate(entry, details),
                  onPanEnd: (details) => _handlePanEnd(entry, details.velocity.pixelsPerSecond),
                  child: LayrzSnackbarView(
                    snackbar: entry.snackbar,
                    style: style,
                    // Persistent entries have no drainController — the view
                    // never renders the progress bar for them regardless of
                    // this value, so 1.0 is just a harmless placeholder.
                    progress: entry.drainController?.value ?? 1.0,
                    onClose: entry.snackbar.isAutoDismiss ? () => _dismiss(entry) : null,
                    onCardTap: entry.snackbar.onTap != null
                        ? () {
                            entry.snackbar.onTap!();
                            _dismiss(entry);
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handles the start of a pan gesture on [entry] — resets all of its
  /// per-gesture drag-tracking fields so a brand-new gesture never inherits
  /// stray state from a previous one (e.g. a spring-back that was still
  /// mid-animation when a fresh drag began: this stops that settle animation
  /// dead, in whatever position it had reached, rather than letting it fight
  /// the new drag for control of [_SnackbarEntry.dragDx]).
  void _handlePanStart(_SnackbarEntry entry) {
    entry.dragController.stop();
    entry.rawDragDx = 0.0;
    entry.rawDragDy = 0.0;
    entry.isHorizontalDrag = null;
  }

  /// Handles an in-progress pan update on [entry] (DESIGN-60, drag-follow
  /// addendum) — the per-frame counterpart to [_handlePanEnd].
  ///
  /// The axis is locked once, the first time accumulated raw delta clears a
  /// small slop (matching [kPanSlop]'s spirit, avoided by name since that
  /// constant lives in gesture internals, not exported here): whichever of
  /// `|rawDragDx|`/`|rawDragDy|` is larger at that moment decides it for the
  /// rest of this gesture, so a diagonal-ish drag doesn't flicker between
  /// treatments frame to frame. Once locked:
  ///
  /// * **Horizontal** — every subsequent frame's `delta.dx` accumulates into
  ///   [_SnackbarEntry.dragDx] (with `setState` to rebuild [_buildToast], so
  ///   the live translate/fade tracks the pointer in real time) and vertical
  ///   delta is ignored for the rest of the gesture.
  /// * **Vertical** — [_SnackbarEntry.dragDx] is never touched at all;
  ///   per DESIGN-60's brief, vertical drag stays gesture-only (no
  ///   card-follow), with the expand/collapse decision left entirely to
  ///   [_handlePanEnd]'s release-velocity check, exactly as before this
  ///   feature.
  void _handlePanUpdate(_SnackbarEntry entry, DragUpdateDetails details) {
    const double kAxisLockSlop = 6;
    entry.rawDragDx += details.delta.dx;
    entry.rawDragDy += details.delta.dy;

    entry.isHorizontalDrag ??= (entry.rawDragDx.abs() > kAxisLockSlop || entry.rawDragDy.abs() > kAxisLockSlop)
        ? entry.rawDragDx.abs() >= entry.rawDragDy.abs()
        : null;

    if (entry.isHorizontalDrag != true) return;
    setState(() => entry.dragDx += details.delta.dx);
  }

  /// Handles the end of a pan gesture on [entry] (DESIGN-60, revised gesture
  /// contract plus the drag-follow addendum), deciding both the dominant
  /// axis and the direction from [velocity] itself rather than relying on
  /// separate axis-specific recognizers — the axis decided here always
  /// matches [_handlePanUpdate]'s lock (both read the same `dx`-vs-`dy`
  /// magnitude comparison), it is simply re-derived from the release
  /// velocity vector rather than carrying [_SnackbarEntry.isHorizontalDrag]
  /// forward, since a tap-only gesture (never enough delta to lock an axis
  /// at all) still needs a well-defined outcome here (none, in that case —
  /// see the distance-threshold fallback below).
  ///
  /// * **Swipe-down** (dominant vertical axis, positive `dy` past the
  ///   threshold) expands the deck — it latches the exact same
  ///   fanned/hovered state the desktop hover fan-out uses, by calling
  ///   [_handleStackEnter] directly, so a touch user gets the same "see every
  ///   card in full" affordance a mouse user gets from hovering. This works
  ///   regardless of which card (which [entry]/depth) the swipe originated
  ///   on — the whole stack fans, exactly as it does on hover.
  /// * **Swipe-up** (dominant vertical axis, negative `dy` past the
  ///   threshold) collapses the deck back to its compact resting state — the
  ///   exact reverse of swipe-down — by calling [_handleStackExit] directly,
  ///   the same call the desktop hover-exit path uses.
  /// * **Horizontal drag**, either left or right (dominant horizontal axis),
  ///   settles via [_settleDrag]: past the dismiss threshold (release
  ///   [velocity] **or** the accumulated [_SnackbarEntry.dragDx] distance —
  ///   see [kSwipeDistanceFraction]) it flings the card off-screen sideways
  ///   and dismisses [entry]; otherwise it springs the card back to center.
  ///
  /// The dominant axis is whichever of `dx`/`dy` has the larger magnitude,
  /// so a mostly-horizontal flick is never misread as vertical (or vice
  /// versa). A vertical swipe below [kSwipeVelocityThreshold] on the
  /// dominant axis is ignored as an accidental drag rather than a deliberate
  /// gesture; a horizontal one still settles (spring-back) even when under
  /// threshold, since the card visibly moved under the finger and must
  /// visibly return.
  ///
  /// Wired from a single [GestureDetector.onPanEnd] (see [_buildToast])
  /// rather than separate `onVerticalDragEnd`/`onHorizontalDragEnd`
  /// callbacks. Attaching both a vertical and a horizontal drag recognizer to
  /// the same [GestureDetector] makes Flutter's gesture arena run a
  /// [VerticalDragGestureRecognizer] and a [HorizontalDragGestureRecognizer]
  /// side by side, competing for every drag — on a real touch device, an
  /// ambiguous or near-vertical flick regularly lets the vertical recognizer
  /// win the arena even when the user meant a horizontal swipe, so
  /// `onHorizontalDragEnd` silently never fires and dismissal fails. A single
  /// pan recognizer has nothing to compete with in the arena for any drag
  /// direction, so it reliably wins and reports the true velocity vector —
  /// the axis/direction split then happens here, in plain code, instead of
  /// being left to gesture-recognizer arbitration.
  void _handlePanEnd(_SnackbarEntry entry, Offset velocity) {
    final dx = velocity.dx;
    final dy = velocity.dy;

    if (dx.abs() >= dy.abs()) {
      _settleDrag(entry, releaseVelocityDx: dx);
      return;
    }

    if (dy > kSwipeVelocityThreshold) {
      _handleStackEnter();
    } else if (dy < -kSwipeVelocityThreshold) {
      _handleStackExit();
    }
  }

  /// Settles a released horizontal drag on [entry] — the sole decision point
  /// between springing back to center and flinging off-screen to dismiss.
  ///
  /// Past the dismiss threshold on **either** signal — [releaseVelocityDx]'s
  /// magnitude past [kSwipeVelocityThreshold], or the already-accumulated
  /// [_SnackbarEntry.dragDx] past [kSwipeDistanceFraction] of the card's own
  /// measured width — the card animates from its current `dragDx` out to a
  /// full off-screen offset in the same direction it was already moving,
  /// fading to `0` alongside, then calls [_dismiss]. Otherwise it animates
  /// `dragDx` back to `0.0` (and opacity implicitly back to full, since
  /// [_buildToast]'s fade is a pure function of `|dragDx|`).
  ///
  /// Both legs reuse the same [_SnackbarEntry.dragController] — a fresh
  /// [Tween] is built for whichever leg applies and driven by
  /// `dragController.forward(from: 0)`, with a listener re-deriving
  /// `entry.dragDx` from the tween's current value every tick. The listener
  /// is removed once the animation completes so it never leaks onto a later,
  /// unrelated forward of the same controller.
  void _settleDrag(_SnackbarEntry entry, {required double releaseVelocityDx}) {
    final cardWidth = _measuredCardWidth(entry);
    final dismissDistance = cardWidth * kSwipeDistanceFraction;
    final pastVelocity = releaseVelocityDx.abs() > kSwipeVelocityThreshold;
    final pastDistance = entry.dragDx.abs() > dismissDistance;

    if (pastVelocity || pastDistance) {
      final direction = releaseVelocityDx == 0
          ? (entry.dragDx.isNegative ? -1.0 : 1.0)
          : (releaseVelocityDx.isNegative ? -1.0 : 1.0);
      final target = direction * (cardWidth + widget.maxWidth);
      _animateDrag(entry, to: target, curve: _kFlingOutCurve, onDone: () => _dismiss(entry));
    } else {
      _animateDrag(entry, to: 0.0, curve: _kSpringBackCurve, onDone: () {});
    }
  }

  /// Drives [entry]'s [_SnackbarEntry.dragController] from its current
  /// [_SnackbarEntry.dragDx] to [to], calling [onDone] once the animation
  /// completes. Shared plumbing for both [_settleDrag] outcomes (spring-back
  /// and fling-out) — only the destination, easing curve, and completion
  /// callback differ between them.
  void _animateDrag(_SnackbarEntry entry, {required double to, required Curve curve, required VoidCallback onDone}) {
    final tween = Tween<double>(begin: entry.dragDx, end: to);
    final controller = entry.dragController;
    late final AnimationStatusListener statusListener;
    void tick() {
      if (!mounted) return;
      setState(() => entry.dragDx = tween.transform(curve.transform(controller.value)));
    }

    statusListener = (status) {
      if (status != AnimationStatus.completed) return;
      controller.removeListener(tick);
      controller.removeStatusListener(statusListener);
      onDone();
    };

    controller.addListener(tick);
    controller.addStatusListener(statusListener);
    controller.forward(from: 0);
  }

  /// Builds the "+N / Dismiss all" overflow affordance (DESIGN-60 §16.4).
  ///
  /// Deliberately labelled with [LayrzUiL10n.snackbarDismissAllLabel]
  /// ("Dismiss all") rather than rendering a bare count, so it reads as an
  /// actionable control and not a passive counter — a silent tap-to-clear-all
  /// on a number-only chip would be a surprise, unrecoverable action.
  Widget _buildOverflowAffordance(LayrzTokens tokens, LayrzUiL10n l10n) {
    return _OverflowChip(
      count: _overflowCount,
      label: l10n.snackbarDismissAllLabel,
      tokens: tokens,
      onTap: dismissAll,
    );
  }
}

/// The tappable "+N / Dismiss all" chip shown above the stack when more
/// toasts are queued than fit in the visible cap.
///
/// Kept as its own small [StatefulWidget] (rather than inline in the
/// messenger) purely so its hover state doesn't force a rebuild of the whole
/// stack — interaction states vary colour/opacity only (D15), scoped to the
/// smallest subtree that needs it.
class _OverflowChip extends StatefulWidget {
  /// The number of toasts currently collapsed behind this affordance.
  final int count;

  /// The localized, actionable label ("Dismiss all") shown alongside [count].
  final String label;

  /// The active design tokens, for colour and spacing.
  final LayrzTokens tokens;

  /// Called when the chip is tapped — clears the entire queue.
  final VoidCallback onTap;

  /// Creates an [_OverflowChip].
  const _OverflowChip({
    required this.count,
    required this.label,
    required this.tokens,
    required this.onTap,
  });

  @override
  State<_OverflowChip> createState() => _OverflowChipState();
}

class _OverflowChipState extends State<_OverflowChip> {
  /// Tracks hover so the chip's background can vary without touching
  /// geometry (D15).
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final base = tokens.colors.contextual.darken(0.3);

    return Semantics(
      button: true,
      label: '+${widget.count} ${widget.label}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: tokens.motion.dHover,
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
            decoration: BoxDecoration(
              color: _hovered ? base.withValues(alpha: 0.92) : base.withValues(alpha: 0.82),
              borderRadius: tokens.radius.br2,
            ),
            child: Text(
              '+${widget.count} · ${widget.label}',
              style: tokens.typography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
