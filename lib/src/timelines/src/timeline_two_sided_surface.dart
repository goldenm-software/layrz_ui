import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'timeline_connector_painter.dart';
import 'timeline_entry.dart';
import 'timeline_marker.dart';
import 'timeline_side.dart';
import 'timeline_style_spec.dart';

/// The two-sided [LayrzTimeline] layout: a single centred spine, with each
/// entry's content card placed on the [LayrzTimelineSide.start] (left) or
/// [LayrzTimelineSide.end] (right) side.
///
/// [LayrzTimeline] renders this above the compact breakpoint by default, and
/// collapses to [LayrzTimelineOneSidedSurface] below it (see `LayrzTimeline`'s
/// class documentation for why that collapse is not opt-in). A side is
/// resolved per entry: [LayrzTimelineEntry.side] when set, otherwise an
/// automatic left/right alternation driven by the entry's position.
///
/// **Reading order follows chronology, not visual left-then-right.** Because
/// alternating entries visually zig-zag across the spine, a screen reader
/// walking the render tree left-to-right, top-to-bottom would announce them
/// out of chronological order (entry 2 on the right before entry 1's row has
/// fully passed, depending on row heights). [Semantics] with an explicit
/// [SemanticsSortKey] is applied per row (via [OrdinalSortKey]) so traversal
/// order always matches [LayrzTimeline.entries]' list order regardless of
/// which side a card visually lands on.
class LayrzTimelineTwoSidedSurface extends StatelessWidget {
  /// Creates a [LayrzTimelineTwoSidedSurface].
  const LayrzTimelineTwoSidedSurface({
    required this.entries,
    required this.cardBuilder,
    super.key,
  });

  /// The ordered list of entries to render, top to bottom.
  final List<LayrzTimelineEntry> entries;

  /// Builds the content card for a single entry.
  final Widget Function(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) cardBuilder;

  /// Resolves which side entry [index] renders its card on.
  ///
  /// Honours an explicit [LayrzTimelineEntry.side] when set; otherwise
  /// alternates starting from [LayrzTimelineSide.start] for the first entry.
  LayrzTimelineSide _sideOf(int index) {
    final explicit = entries[index].side;
    if (explicit != null) return explicit;
    return index.isEven ? LayrzTimelineSide.start : LayrzTimelineSide.end;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      children: [
        for (int index = 0; index < entries.length; index++)
          Semantics(
            sortKey: OrdinalSortKey(index.toDouble()),
            child: _TwoSidedRow(
              entry: entries[index],
              side: _sideOf(index),
              isFirst: index == 0,
              isLast: index == entries.length - 1,
              cardBuilder: cardBuilder,
              gap: tokens.spacing.sp3,
            ),
          ),
      ],
    );
  }
}

/// A single entry's row within [LayrzTimelineTwoSidedSurface]: a content card
/// on one side, the centred marker/connector column, and an empty spacer on
/// the other side so the spine stays centred regardless of which side is
/// occupied.
class _TwoSidedRow extends StatelessWidget {
  const _TwoSidedRow({
    required this.entry,
    required this.side,
    required this.isFirst,
    required this.isLast,
    required this.cardBuilder,
    required this.gap,
  });

  /// The entry rendered by this row.
  final LayrzTimelineEntry entry;

  /// Which side this row's card renders on.
  final LayrzTimelineSide side;

  /// Whether this is the first entry — suppresses the connector segment
  /// above the marker.
  final bool isFirst;

  /// Whether this is the last entry — suppresses the connector segment
  /// below the marker.
  final bool isLast;

  /// Builds the content card for [entry]. See
  /// [LayrzTimelineTwoSidedSurface.cardBuilder].
  final Widget Function(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) cardBuilder;

  /// The vertical gap left below this row before the next one.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final spec = LayrzTimelineStyleSpec.resolve(accentColor: entry.accentColor, tokens: tokens);
    final isStart = side == LayrzTimelineSide.start;

    // The inter-row gap is applied to the CARD only (via `_gapped`), not to
    // the row as a whole, the same fix as `LayrzTimelineOneSidedSurface`.
    // `IntrinsicHeight` sizes the row to the occupied side's card height
    // (which now includes the gap), and `CrossAxisAlignment.stretch` makes
    // the marker column's `Expanded` connectors stretch to match, so the
    // spine no longer has a bare, unpainted gap between rows.
    final card = _gapped(cardBuilder(context, entry, spec));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: isStart ? card : const SizedBox.shrink()),
          SizedBox(width: tokens.spacing.sp3),
          Column(
            children: [
              Expanded(
                child: isFirst ? const SizedBox.shrink() : LayrzTimelineConnector(color: spec.markerColor),
              ),
              LayrzTimelineMarker(spec: spec, icon: entry.icon),
              Expanded(
                child: isLast ? const SizedBox.shrink() : LayrzTimelineConnector(color: spec.markerColor),
              ),
            ],
          ),
          SizedBox(width: tokens.spacing.sp3),
          Expanded(child: isStart ? const SizedBox.shrink() : card),
        ],
      ),
    );
  }

  /// Wraps [child] with the bottom inter-row gap, unless this is the last
  /// row (which has no following row to separate itself from).
  Widget _gapped(Widget child) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
      child: child,
    );
  }
}
