import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect;

import "package:flutter/widgets.dart" show immutable;

/// The default minimum shell height, in logical pixels, below which
/// [resolveFoldSplit] refuses to produce a split even for an otherwise
/// qualifying vertical seam.
///
/// See [resolveFoldSplit]'s own doc comment for the full reasoning; in short,
/// this guards the shell's main-axis (vertical) extent, which is a wholly
/// different concern from `minPaneExtent`'s cross-axis (pane width) guard —
/// a vertical seam can map to two comfortably wide panes on a shell that is
/// nonetheless far too short to use (measured: a Z Flip rotated to landscape
/// producing two 502.9dp-wide, 411.4dp-tall panes). `480.0` was chosen from
/// on-device measurement: a Z Fold in portrait with the keyboard open
/// measures a shell height of `435.0`, below this threshold, while the same
/// device with the keyboard closed measures `731.9`, comfortably above it.
const double kLayrzFoldMinSplitHeight = 480.0;

/// The target proportion of the shell's width [resolveFoldSplit] prefers for
/// [LayrzFoldSplit.leadingExtent] when more than one seam qualifies.
///
/// A device like the Galaxy Z TriFold reports **two** qualifying vertical
/// seams at once (splitting its inner screen into three roughly-equal
/// panels), but [LayrzScaffoldShell] keeps a two-pane list/detail model --
/// see [resolveFoldSplit]'s own doc comment. One third is the proportion
/// that resolves that ambiguity the way a list/detail layout actually wants:
/// it selects the seam nearest a `1/3` list-pane / `2/3` detail-pane split,
/// which on a tri-fold picks the FIRST crease (the one closest to the
/// device's own physical thirds) rather than the second one, which would
/// leave an unreasonably wide list pane and an unreasonably narrow detail
/// pane. On any device reporting only one qualifying seam, this constant is
/// a no-op -- there is nothing to choose between.
const double kLayrzFoldPreferredListFraction = 1 / 3;

/// The direction of the physical seam [resolveFoldSplit] detects.
///
/// A foldable's crease can run in either direction depending on device family
/// and orientation, and [resolveFoldSplit] derives this purely from the shape
/// of the reported [DisplayFeature.bounds] — never from a device assumption.
///
/// **Only [vertical] ever reaches a [LayrzFoldSplit].** [horizontal] is kept
/// as a named, documented case because [resolveFoldSplit] still classifies a
/// horizontal seam on the way to rejecting it -- see its own doc comment for
/// why a horizontal seam was tested on real hardware and deliberately never
/// produces a split. Keeping the value documents that this was a decision,
/// not an oversight, and gives a stable name to the case a future change
/// would need to revisit.
enum LayrzFoldAxis {
  /// A vertical seam that splits the shell's content left/right.
  ///
  /// This is the Z Fold's portrait crease (and, equivalently, a Z Flip's
  /// crease once the device is rotated to landscape): a seam that is taller
  /// than it is wide, so the two panes sit side by side. This is the only
  /// axis [resolveFoldSplit] ever returns in a [LayrzFoldSplit].
  vertical,

  /// A horizontal seam that splits the shell's content top/bottom.
  ///
  /// This is the Z Flip's portrait crease (and, equivalently, a Z Fold's
  /// crease once the device is rotated to landscape). [resolveFoldSplit]
  /// recognizes this shape but always returns `null` for it -- see its own
  /// doc comment for the on-device findings that led to that decision.
  horizontal,
}

/// A resolved fold-aware split of a [LayrzScaffoldShell]'s content, produced
/// by [resolveFoldSplit].
///
/// All extents are in the shell's own local coordinate space (logical
/// pixels), already translated out of the whole-view coordinates that
/// [DisplayFeature.bounds] is reported in.
@immutable
class LayrzFoldSplit {
  /// The direction the seam runs, and therefore how the two panes are
  /// arranged relative to each other.
  final LayrzFoldAxis axis;

  /// The main-axis extent of the leading pane (the left pane, since [axis]
  /// is always [LayrzFoldAxis.vertical]), in the shell's local logical pixels.
  final double leadingExtent;

  /// The main-axis extent of the trailing pane (the right pane, since [axis]
  /// is always [LayrzFoldAxis.vertical]), in the shell's local logical pixels.
  final double trailingExtent;

  /// The thickness of the seam itself, in logical pixels.
  ///
  /// This is the occluded region between the two panes — nonzero for a
  /// [DisplayFeatureType.hinge], and legitimately `0` for a
  /// [DisplayFeatureType.fold], whose crease has no physical thickness. A
  /// `gap` of `0` means the divider between panes should be a hairline, not
  /// a spacer sized to an occlusion that does not exist.
  final double gap;

  /// Creates a new [LayrzFoldSplit].
  ///
  /// - [axis]: The direction the seam runs. Required.
  /// - [leadingExtent]: The main-axis extent of the leading pane, in the shell's
  ///   local logical pixels. Required.
  /// - [trailingExtent]: The main-axis extent of the trailing pane, in the shell's
  ///   local logical pixels. Required.
  /// - [gap]: The thickness of the seam itself, in logical pixels. `0` for a
  ///   creaseless fold. Required.
  const LayrzFoldSplit({
    required this.axis,
    required this.leadingExtent,
    required this.trailingExtent,
    required this.gap,
  });

  /// Returns a copy of this [LayrzFoldSplit] with the given fields replaced.
  ///
  /// - [axis]: Replaces [LayrzFoldSplit.axis] when provided.
  /// - [leadingExtent]: Replaces [LayrzFoldSplit.leadingExtent] when provided.
  /// - [trailingExtent]: Replaces [LayrzFoldSplit.trailingExtent] when provided.
  /// - [gap]: Replaces [LayrzFoldSplit.gap] when provided.
  LayrzFoldSplit copyWith({
    LayrzFoldAxis? axis,
    double? leadingExtent,
    double? trailingExtent,
    double? gap,
  }) {
    return LayrzFoldSplit(
      axis: axis ?? this.axis,
      leadingExtent: leadingExtent ?? this.leadingExtent,
      trailingExtent: trailingExtent ?? this.trailingExtent,
      gap: gap ?? this.gap,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayrzFoldSplit &&
        other.axis == axis &&
        other.leadingExtent == leadingExtent &&
        other.trailingExtent == trailingExtent &&
        other.gap == gap;
  }

  @override
  int get hashCode => Object.hash(axis, leadingExtent, trailingExtent, gap);

  @override
  String toString() =>
      'LayrzFoldSplit(axis: $axis, leadingExtent: $leadingExtent, trailingExtent: $trailingExtent, gap: $gap)';
}

/// Resolves a foldable device's physical seam into a [LayrzFoldSplit] for a
/// shell occupying [shellRect], or `null` when nothing usable is present.
///
/// [DisplayFeature.bounds] is reported in **logical pixels, in the coordinate
/// space of the whole Flutter view** — never divide it by device pixel ratio.
/// Because a shell is typically composed inside other chrome (a navigation
/// rail, a top bar), [shellRect] must be the shell's own global rect (e.g.
/// from `renderBox.localToGlobal(Offset.zero) & renderBox.size`) so this
/// function can translate each feature's bounds into the shell's local space
/// before reasoning about it — treating view-space bounds as already local
/// misplaces the split by exactly the shell's own offset.
///
/// Only [DisplayFeatureType.fold] and [DisplayFeatureType.hinge] are
/// considered; [DisplayFeatureType.cutout] is always skipped — a real device
/// can report a camera cutout as its own feature, and splitting the content
/// there would be a bad bug, not a fold-aware layout.
///
/// The seam's [DisplayFeatureState] (posture) is not filtered on at all —
/// every posture is treated as usable. This was verified against a real
/// emulator, not assumed: a Pixel 10 Pro Fold **boots in
/// [DisplayFeatureState.postureHalfOpened]**, and its viewport is IDENTICAL
/// to [DisplayFeatureState.postureFlat] in that state (851.7 x 882.9 logical
/// pixels at DPR 2.4375, in both postures) — only the posture enum differs;
/// the hinge position and usable area do not. That viewport is itself below
/// the 960dp band threshold even at full width with no rail inset, so this
/// is exactly the device this function exists to fix: skipping
/// `postureHalfOpened` would silently fall through to the narrow list+sheet
/// layout on a hinged device with 851.7dp of width to use. There is
/// therefore no posture this function currently has reason to exclude.
///
/// **Only a vertical seam ever produces a split.** A seam's own shape
/// decides its [LayrzFoldAxis] (a seam wider than it is tall is
/// [LayrzFoldAxis.horizontal]; otherwise it is [LayrzFoldAxis.vertical]),
/// but a horizontal seam is always rejected -- `null` is returned for it,
/// exactly as if it had not been reported at all. This was decided after
/// testing a stacked top/bottom layout on real hardware and finding it
/// caused two distinct, device-confirmed failures when the keyboard was
/// involved:
///
/// 1. On a horizontal seam (Z Flip in portrait), promoting the detail into a
///    modal sheet whenever the keyboard opened destroyed the very focus that
///    opened the keyboard, which closed the keyboard, which reverted the
///    promotion -- an oscillating loop that made it impossible to type.
/// 2. On a vertical seam (Z Fold in portrait) a stacked/keyboard rule was
///    never even the right question: with no presentation change tied to
///    the keyboard, the existing side-by-side split simply keeps its shell
///    height in step with `MediaQuery.viewInsetsOf` the same way any other
///    inline layout would, with no special-case needed.
///
/// Filtering by axis removes the horizontal failure mode by construction:
/// a horizontal seam never splits, so there is no sheet-promotion to
/// oscillate. But the axis filter alone does not rule out a vertical seam on
/// a shell that is wide enough yet far too *short* -- measured on a Z Flip
/// rotated to landscape, which produces a vertical seam mapping to two
/// comfortably wide (502.9dp) but barely tall (411.4dp) panes. [minPaneExtent]
/// only ever guards the panes' cross-axis extent (their width); nothing else
/// guarded the shell's own main-axis extent (its height) until
/// [minSplitHeight] was added. **[minSplitHeight] is that guard**: below it,
/// this function returns `null` for a vertical seam exactly as it would for
/// none at all, regardless of how the pane widths would have come out.
///
/// This also has a deliberate, valuable side effect that subsumes the
/// keyboard problem the deleted stacked layout was trying to solve: on a
/// Z Fold in portrait, opening the keyboard shrinks the shell's own height
/// from a measured `731.9` down to `435.0` — below [minSplitHeight]'s default
/// of [kLayrzFoldMinSplitHeight] (`480.0`) — so **the split disappears on its
/// own** the moment the keyboard opens, falling back to today's layout. This
/// achieves what a `keyboardIsUp` term would have tried to do, but without
/// ever reading `MediaQuery.viewInsetsOf` or switching presentation because
/// of the keyboard specifically -- it is purely a consequence of the shell
/// getting shorter. There is deliberately no keyboard-aware term anywhere in
/// this function; re-adding one would be redundant with this guard, not a
/// complement to it.
///
/// A candidate vertical seam only produces a split when it genuinely crosses
/// [shellRect]: it must span the shell's full height, sit strictly inside
/// the shell's width, and leave both resulting panes at least
/// [minPaneExtent] logical pixels of *width* — a seam that only clips a
/// corner of the shell is not a split. Independently, [shellRect]'s own
/// height must be at least [minSplitHeight] — a different axis and a
/// different concern from [minPaneExtent], guarding the shell as a whole
/// rather than either individual pane.
///
/// **When multiple seams qualify, the one nearest [kLayrzFoldPreferredListFraction]
/// of the shell's width is chosen — not simply the first.** This matters for
/// a device like the Galaxy Z TriFold, which reports two qualifying vertical
/// seams at once (its inner screen splits into three panels). This function
/// still resolves a single two-pane [LayrzFoldSplit] (see
/// [kLayrzFoldPreferredListFraction]'s own doc comment for why a two-pane
/// model is kept rather than adding a third pane): among every seam that
/// independently passes every check above, the one whose
/// [LayrzFoldSplit.leadingExtent] comes closest to
/// `shellRect.width * kLayrzFoldPreferredListFraction` wins, and only that
/// seam's divider is ever drawn — a rejected seam gets no divider of its
/// own. A tie (two seams exactly equidistant from the target) is broken in
/// favor of the leading-most (smallest `leadingExtent`) candidate,
/// deterministically — an arbitrary tiebreak would be a nasty intermittent
/// layout bug. On any device reporting only one qualifying seam (the
/// overwhelming majority), this selection is a no-op: there is nothing to
/// compare it against.
///
/// A zero-thickness seam (`bounds.width == 0`, as with a real device's
/// `fold` feature) is handled without ever dividing by that thickness — the
/// resulting [LayrzFoldSplit.gap] is legitimately `0`. The axis check itself
/// (`bounds.width > bounds.height`) is verified against all four real
/// geometries measured on device, each with a zero-thickness seam on one
/// axis or the other: a Flip in portrait (`width == 0`, tall and thin ->
/// horizontal), a Flip in landscape (`height == 0`, short and wide ->
/// vertical), and a Fold in portrait and landscape (`height == 0` /
/// `width == 0` respectively, mirroring the Flip). Because either dimension
/// can legitimately be `0`, the comparison is strict `>`, not `>=`, on
/// either side, and nothing in this function requires either dimension to
/// be positive.
///
/// - [features]: The display features to consider, typically
///   `MediaQuery.displayFeaturesOf(context)`. Required.
/// - [shellRect]: The shell's own rect, in the same whole-view coordinate
///   space [features] are reported in. Required.
/// - [minPaneExtent]: The minimum cross-axis extent (width), in logical
///   pixels, either resulting pane must clear for the seam to count as a
///   genuine split. Defaults to `120.0`.
/// - [minSplitHeight]: The minimum main-axis extent (height), in logical
///   pixels, [shellRect] itself must clear for a vertical seam to produce a
///   split at all -- a wholly separate guard from [minPaneExtent]. Defaults
///   to [kLayrzFoldMinSplitHeight].
LayrzFoldSplit? resolveFoldSplit({
  required List<DisplayFeature> features,
  required Rect shellRect,
  double minPaneExtent = 120.0,
  double minSplitHeight = kLayrzFoldMinSplitHeight,
}) {
  if (shellRect.height < minSplitHeight) {
    return null;
  }

  // Collect every seam that independently qualifies as a split, rather than
  // returning on the first match -- a multi-seam device (Z TriFold) needs
  // every candidate available before the best one can be chosen below.
  final candidates = <LayrzFoldSplit>[];

  for (final feature in features) {
    if (feature.type != DisplayFeatureType.fold && feature.type != DisplayFeatureType.hinge) {
      continue;
    }
    // No posture (DisplayFeatureState) filter here -- see this function's own
    // doc comment for why every posture is currently treated as usable.

    // Translate the feature's whole-view bounds into the shell's local space.
    final localBounds = feature.bounds.shift(-shellRect.topLeft);

    // A horizontal seam is classified (for LayrzFoldAxis's own documentary
    // value) but always rejected -- see this function's own doc comment for
    // why. Either dimension can legitimately be zero-thickness on real
    // hardware, so this is a strict `>` on both sides, never `>=`, and
    // neither dimension is required to be positive.
    final isHorizontalSeam = localBounds.width > localBounds.height;
    if (isHorizontalSeam) {
      continue;
    }

    // A vertical seam must span the shell's full height and sit strictly
    // inside its width. (The shell's height has already cleared
    // minSplitHeight above, before this loop even starts.)
    if (localBounds.top > 0 || localBounds.bottom < shellRect.height) {
      continue;
    }
    final seamLeft = localBounds.left;
    final seamRight = localBounds.right;
    if (seamLeft <= 0 || seamRight >= shellRect.width) {
      continue;
    }

    final leadingExtent = seamLeft;
    final trailingExtent = shellRect.width - seamRight;
    if (leadingExtent < minPaneExtent || trailingExtent < minPaneExtent) {
      continue;
    }

    candidates.add(
      LayrzFoldSplit(
        axis: LayrzFoldAxis.vertical,
        leadingExtent: leadingExtent,
        trailingExtent: trailingExtent,
        gap: seamRight - seamLeft,
      ),
    );
  }

  if (candidates.isEmpty) {
    return null;
  }
  if (candidates.length == 1) {
    return candidates.first;
  }

  // Multiple qualifying seams (e.g. a Z TriFold's two creases): pick the one
  // whose leadingExtent lands closest to the preferred list-pane proportion
  // of the shell's width -- see kLayrzFoldPreferredListFraction's own doc
  // comment for why a third. Ties are broken toward the leading-most
  // (smallest leadingExtent) candidate, deterministically.
  final target = shellRect.width * kLayrzFoldPreferredListFraction;
  var best = candidates.first;
  var bestDistance = (best.leadingExtent - target).abs();
  for (final candidate in candidates.skip(1)) {
    final distance = (candidate.leadingExtent - target).abs();
    if (distance < bestDistance || (distance == bestDistance && candidate.leadingExtent < best.leadingExtent)) {
      best = candidate;
      bestDistance = distance;
    }
  }
  return best;
}
