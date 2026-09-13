import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Refcounts app-wide requests to suppress the browser's native
/// right-click context menu on web, so that many independent widgets can
/// each ask for suppression without fighting over the single global
/// [BrowserContextMenu] flag.
///
/// **Why this exists (DESIGN, see also the `LayrzLayout` selection-overlap
/// bugfix):** [BrowserContextMenu.enabled] is one process-wide static flag,
/// and [BrowserContextMenu.disableContextMenu]/[BrowserContextMenu.enableContextMenu]
/// are asynchronous -- the flag only actually flips once the platform
/// channel round-trip's `Future` resolves, on whatever later microtask that
/// lands on. Before this class existed, `LayrzContextMenu` called those
/// methods directly from its own `initState`/`dispose`, once per instance.
/// `LayrzTable`'s header renders one `LayrzContextMenu` per visible column,
/// so ordinary navigation onto or off of a table page mounted and disposed
/// many independent suppressors in the same frame, each flipping the shared
/// flag off then back on. Because `SelectableRegionState.build()` (in
/// `package:flutter/src/widgets/selectable_region.dart`) reads
/// [BrowserContextMenu.enabled] on every rebuild to decide whether to wrap
/// its child in `PlatformSelectableRegionContextMenu`, an app-shell-level
/// `SelectableRegion` (as built by `LayrzLayout`) could observe that flag
/// changing value while a page transition was rebuilding its own subtree,
/// and the resulting insert/remove of that wrapper changes the `Element`
/// shape at the `SelectionContainer`'s slot enough that Flutter cannot
/// reuse it -- the framework mounts a new `SelectionContainer` state
/// (registering a new `Selectable` with the region) before the old one's
/// `dispose` (which would have unregistered it) has run, tripping
/// `SelectableRegionState`'s `assert(_selectable == null)` in `add()`. This
/// is a confirmed, reported Flutter framework bug (see
/// https://github.com/flutter/flutter/issues/186459), not something
/// `SelectableRegion`'s public API exposes a way to opt out of.
///
/// The fix that is actually within this library's control is to stop
/// flipping the shared flag on every widget's own mount/unmount at all.
/// [LayrzBrowserContextMenuSuppressor] keeps a single app-wide reference
/// count: [acquire] disables the browser context menu only when the count
/// rises from zero, and [release] re-enables it only when the count falls
/// back to zero. As long as at least one suppressing widget remains
/// mounted anywhere in the app -- which is the common case across an
/// ordinary page-to-page navigation, since the incoming page's own
/// suppressors typically mount before or during the same frame the
/// outgoing page's dispose -- the flag never actually changes value, so
/// `SelectableRegionState` never observes a flip mid-transition.
///
/// The reference-count bookkeeping itself runs on every platform (so it can
/// be exercised by widget tests, which always run with [kIsWeb] `false`);
/// only the actual [BrowserContextMenu] platform-channel calls are gated
/// behind [kIsWeb], mirroring [BrowserContextMenu]'s own contract of being a
/// no-op on non-web targets.
abstract final class LayrzBrowserContextMenuSuppressor {
  /// The current number of live suppression requests.
  ///
  /// Exposed for testing; not intended to be read by application code.
  static int get debugRefCount => _refCount;
  static int _refCount = 0;

  /// The in-flight disable/enable call, awaited by [release] so that a
  /// rapid acquire-then-release pair never calls
  /// [BrowserContextMenu.enableContextMenu] while the initial
  /// [BrowserContextMenu.disableContextMenu] call is still pending --
  /// which would otherwise race the two platform-channel calls against
  /// each other and could leave the browser's flag out of sync with
  /// [_refCount].
  static Future<void> _pending = Future<void>.value();

  /// Registers one new request to suppress the browser's native context
  /// menu.
  ///
  /// Increments the shared reference count. If this is the first live
  /// request (count rises from 0 to 1) and the app is running on web,
  /// schedules [BrowserContextMenu.disableContextMenu]; otherwise the
  /// browser's context menu was already suppressed by an earlier request
  /// and no platform call is made. Every call to [acquire] must be paired
  /// with exactly one later call to [release].
  static void acquire() {
    _refCount++;
    if (_refCount == 1 && kIsWeb) {
      _pending = _pending.then((_) => BrowserContextMenu.disableContextMenu());
    }
  }

  /// Releases one previously-registered request to suppress the browser's
  /// native context menu.
  ///
  /// Decrements the shared reference count. If this was the last live
  /// request (count falls from 1 to 0) and the app is running on web,
  /// schedules [BrowserContextMenu.enableContextMenu] once any
  /// still-pending [acquire] call has resolved; otherwise another widget
  /// elsewhere is still relying on suppression and no platform call is
  /// made. Calling [release] without a matching prior [acquire] is a
  /// caller error and is asserted against in debug mode.
  static void release() {
    assert(_refCount > 0, 'LayrzBrowserContextMenuSuppressor.release() called without a matching acquire().');
    _refCount--;
    if (_refCount == 0 && kIsWeb) {
      _pending = _pending.then((_) => BrowserContextMenu.enableContextMenu());
    }
  }
}
