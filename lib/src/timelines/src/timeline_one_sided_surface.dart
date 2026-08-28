import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'timeline_connector_painter.dart';
import 'timeline_entry.dart';
import 'timeline_marker.dart';
import 'timeline_style_spec.dart';

/// The one-sided [LayrzTimeline] layout: a single spine on the left, with
/// every entry's marker on that spine and its content card to the right.
///
/// This is the layout [LayrzTimeline] renders below the compact breakpoint by
/// default (see `LayrzTimeline`'s class documentation), and is also available
/// explicitly at any width via `LayrzTimeline.twoSided: false`.
///
/// Each entry is a row: a fixed-width column holding the marker and the
/// connector segments above/below it, then the content card filling the
/// remaining width. [IntrinsicHeight] wraps each row so the connector
/// segments can stretch to exactly the card's rendered height regardless of
/// how much text the card holds — the performance cost of an extra
/// intrinsic-height layout pass per entry is accepted here in exchange for
/// not having to hand-roll a [CustomMultiChildLayout] delegate for what is,
/// per entry, a two-column row.
class LayrzTimelineOneSidedSurface extends StatelessWidget {
  /// Creates a [LayrzTimelineOneSidedSurface].
  const LayrzTimelineOneSidedSurface({
    required this.entries,
    required this.cardBuilder,
    super.key,
  });

  /// The ordered list of entries to render, top to bottom.
  final List<LayrzTimelineEntry> entries;

  /// Builds the content card for a single entry.
  ///
  /// Supplied by [LayrzTimeline] so this surface stays unaware of card
  /// chrome (padding, background, radius) — its own responsibility is the
  /// spine and marker column only.
  final Widget Function(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < entries.length; index++)
          _OneSidedRow(
            entry: entries[index],
            isFirst: index == 0,
            isLast: index == entries.length - 1,
            cardBuilder: cardBuilder,
            gap: tokens.spacing.sp3,
          ),
      ],
    );
  }
}

/// A single entry's row within [LayrzTimelineOneSidedSurface]: the marker
/// column on the left, joined to its neighbours by connector segments, and
/// the content card filling the rest of the row's width.
class _OneSidedRow extends StatelessWidget {
  const _OneSidedRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.cardBuilder,
    required this.gap,
  });

  /// The entry rendered by this row.
  final LayrzTimelineEntry entry;

  /// Whether this is the first entry — suppresses the connector segment
  /// above the marker, since there is no previous entry to connect to.
  final bool isFirst;

  /// Whether this is the last entry — suppresses the connector segment
  /// below the marker, since there is no next entry to connect to.
  final bool isLast;

  /// Builds the content card for [entry]. See
  /// [LayrzTimelineOneSidedSurface.cardBuilder].
  final Widget Function(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) cardBuilder;

  /// The vertical gap left below this row before the next one.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final spec = LayrzTimelineStyleSpec.resolve(accentColor: entry.accentColor, tokens: tokens);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : gap),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: kLayrzTimelineMarkerSize,
              child: Column(
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
            ),
            SizedBox(width: tokens.spacing.sp3),
            Expanded(child: cardBuilder(context, entry, spec)),
          ],
        ),
      ),
    );
  }
}
