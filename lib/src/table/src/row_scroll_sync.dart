import 'package:flutter/widgets.dart';
import 'package:sync_scroll_controller/sync_scroll_controller.dart';

/// Owns the single [SyncScrollControllerGroup] shared by a `LayrzTable`'s
/// header and every data row, and hands each of them a linked
/// [ScrollController] via [join].
///
/// A table row is one widget with three cell regions: a pinned-left cell, a
/// horizontally-scrollable middle cell holding the data columns, and a
/// pinned-right cell. Only the middle regions scroll, and they must all move
/// together — including the header's own middle region — so that column
/// boundaries stay visually aligned as the user drags any one of them.
/// [SyncScrollControllerGroup.addAndGet] is the primitive that makes this
/// work: every [ScrollController] it returns mirrors every other
/// controller from the same group.
///
/// [LayrzTableRowScrollSync] exists as a thin, testable seam around that
/// group so the row widget ([LayrzTableRow]) and the header widget do not
/// each need to reach into `sync_scroll_controller` directly, and so a
/// single instance can be constructed once (typically by the assembling
/// `LayrzTable` widget) and threaded down to every row and to the header.
///
/// **Lifecycle**: [join] must be called once per row (and once for the
/// header) to obtain that widget's own linked controller, and the returned
/// controller must be `dispose`d by whichever widget obtained it (typically
/// from that widget's `State.dispose()`) when it stops using it — e.g. when
/// a row is removed from the visible/virtualized set. Because
/// `sync_scroll_controller` warns that a disposed controller can otherwise
/// be silently reused, give every scrollable that uses a joined controller
/// a unique, stable [Key] (see [LayrzTableRow]'s row key), rather than
/// relying on the list's default key assignment.
class LayrzTableRowScrollSync {
  /// Creates a new [LayrzTableRowScrollSync] backed by a fresh
  /// [SyncScrollControllerGroup].
  ///
  /// [initialScrollOffset] seeds the group's starting horizontal offset,
  /// mirroring [SyncScrollControllerGroup]'s own constructor parameter of
  /// the same name. Defaults to `0.0` (scrolled fully to the start).
  LayrzTableRowScrollSync({double initialScrollOffset = 0.0})
    : _group = SyncScrollControllerGroup(initialScrollOffset: initialScrollOffset);

  /// The underlying group every joined controller is linked through.
  ///
  /// Exposed so advanced callers (e.g. a "scroll all rows back to the
  /// start" action) can drive [SyncScrollControllerGroup.jumpTo],
  /// [SyncScrollControllerGroup.animateTo], or
  /// [SyncScrollControllerGroup.resetScroll] directly, without this class
  /// needing to re-expose every method of the underlying group.
  final SyncScrollControllerGroup _group;

  /// The underlying [SyncScrollControllerGroup] backing every controller
  /// returned by [join].
  SyncScrollControllerGroup get group => _group;

  /// The group's current horizontal scroll offset, in logical pixels.
  ///
  /// Throws (via the underlying group) if no joined controller is currently
  /// attached to a scrollable.
  double get offset => _group.offset;

  /// Returns a new [ScrollController] linked to every other controller
  /// obtained from this [LayrzTableRowScrollSync], via
  /// [SyncScrollControllerGroup.addAndGet].
  ///
  /// Call this once per row's middle (scrolling) cell region, and once for
  /// the header's middle region. Scrolling any one of the returned
  /// controllers moves all the others — including ones joined before or
  /// after this call — to the same offset.
  ///
  /// The caller owns the returned controller's disposal.
  ScrollController join() => _group.addAndGet();

  /// Instantly jumps every currently-attached joined controller to
  /// [offset], with no animation.
  void jumpTo(double offset) => _group.jumpTo(offset);

  /// Resets every currently-attached joined controller's scroll offset to
  /// `0.0`, with no animation.
  void resetScroll() => _group.resetScroll();

  /// Animates every currently-attached joined controller to [offset] over
  /// [duration], using [curve].
  Future<void> animateTo(double offset, {required Curve curve, required Duration duration}) =>
      _group.animateTo(offset, curve: curve, duration: duration);
}
