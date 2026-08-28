import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'timeline_entry.dart';
import 'timeline_one_sided_surface.dart';
import 'timeline_style_spec.dart';
import 'timeline_two_sided_surface.dart';

/// A vertical spine of dated [LayrzTimelineEntry] events, rendered either
/// one-sided (every card on one side of the spine) or two-sided (cards
/// alternating, or explicitly placed, on either side).
///
/// **The two-sided layout auto-collapses to one-sided below the compact
/// breakpoint (`context.isCompact`, viewport < 960px), by default.** This is
/// not an opt-in flag: a two-sided timeline straddling a spine either wraps
/// its card text into unreadable single-word stacks or the two columns
/// visually merge into the spine on a phone-width viewport, and either way
/// the meaning the two-sidedness carried — grouping or contrasting entries by
/// side — is silently lost. A component that only works correctly above
/// 600px, with an undocumented flag required to make it usable below that, is
/// exactly the trap this default exists to avoid. [twoSided] remains fully
/// overridable in either direction: pass `false` to force one-sided at any
/// width, or force two-sided below the breakpoint by passing
/// [isCompactOverride]: `false` (see that field's own documentation — it
/// exists primarily so this behaviour is unit-testable without faking a real
/// viewport resize, and is not expected to be used by ordinary callers).
///
/// **Reading order always follows [entries]' list order — chronology — not
/// visual left-then-right placement.** In the two-sided layout, alternating
/// cards zig-zag across the spine, which would otherwise announce entries out
/// of chronological order to a screen reader walking the render tree
/// left-to-right; see [LayrzTimelineTwoSidedSurface] for how that is kept
/// correct via an explicit [OrdinalSortKey] per row.
///
/// Markers are purely decorative and excluded from semantics — see
/// [LayrzTimelineMarker]. An entry's accent color is never the only thing
/// distinguishing it (WCAG 1.4.1): vary [LayrzTimelineEntry.icon] or text
/// content instead, or in addition.
///
/// **This widget has no built-in editing of entries.** [entries] is a plain,
/// caller-owned list; adding, removing, or reordering an entry is done by
/// passing a different list on rebuild, the same way any other declarative
/// list widget in this design system works.
///
/// **Does not share layout or marker code with `LayrzStepper`.** Per the
/// implementation plan's ruling, at most the connector-line *painting
/// approach* is shared (a plain colored line), and it is duplicated rather
/// than imported — see [LayrzTimelineConnector]'s own documentation. Stepper
/// markers encode a linear completed/active/pending state machine; timeline
/// entries are arbitrary dated events with no such vocabulary, and importing
/// that vocabulary here would be the wrong direction of coupling.
class LayrzTimeline extends StatelessWidget {
  /// Creates a [LayrzTimeline].
  const LayrzTimeline({
    required this.entries,
    this.twoSided = true,
    this.isCompactOverride,
    super.key,
  });

  /// The ordered list of entries to render, top to bottom.
  ///
  /// Order is significant: it is both the visual top-to-bottom order and the
  /// chronological/semantics reading order (see the class documentation).
  /// Callers are responsible for sorting this list; [LayrzTimeline] does not
  /// parse or sort by [LayrzTimelineEntry.timestampText].
  final List<LayrzTimelineEntry> entries;

  /// Whether to render the two-sided layout when the viewport is not compact.
  ///
  /// Defaults to `true`. Set to `false` to force the one-sided layout at any
  /// width. This flag does not override the compact-breakpoint collapse: even
  /// with `twoSided: true`, a compact viewport still renders one-sided by
  /// default (see the class documentation) — [twoSided] only chooses between
  /// the two layouts on viewports where the collapse does not already apply.
  final bool twoSided;

  /// Overrides the compact-breakpoint decision that otherwise comes from
  /// `context.isCompact`.
  ///
  /// When null (the default), [LayrzTimeline] derives compactness from the
  /// ambient viewport width via `context.isCompact`, which is the correct
  /// behaviour for ordinary use. This override exists so the auto-collapse
  /// can be tested and reasoned about independently of a real viewport
  /// resize, and so a caller in an unusual embedding (e.g. a fixed-width pane
  /// inside a wide viewport) can force the one-sided layout without lying
  /// about the window's actual size elsewhere. Passing `false` here does not
  /// widen a genuinely narrow viewport — it only skips the automatic
  /// derivation for this widget's own layout choice.
  final bool? isCompactOverride;

  @override
  Widget build(BuildContext context) {
    final isCompact = isCompactOverride ?? context.isCompact;
    final resolvedTwoSided = twoSided && !isCompact;

    final cardBuilder = _buildCard;

    return resolvedTwoSided
        ? LayrzTimelineTwoSidedSurface(entries: entries, cardBuilder: cardBuilder)
        : LayrzTimelineOneSidedSurface(entries: entries, cardBuilder: cardBuilder);
  }

  /// Builds the content card for a single [entry], shared by both the
  /// one-sided and two-sided surfaces.
  ///
  /// The card itself carries the entry's full semantics label (label,
  /// description, and timestamp concatenated) as a single merged node, since
  /// the marker rendered alongside it is excluded from semantics entirely.
  Widget _buildCard(BuildContext context, LayrzTimelineEntry entry, LayrzTimelineStyleSpec spec) {
    final tokens = context.tokens;

    final semanticsLabel = [
      entry.labelText,
      if (entry.descriptionText != null) entry.descriptionText!,
      if (entry.timestampText != null) entry.timestampText!,
    ].join('. ');

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: Container(
        padding: tokens.spacing.pd3,
        decoration: BoxDecoration(
          color: spec.cardBackgroundColor,
          borderRadius: BorderRadius.circular(tokens.radius.r2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.labelText,
                    style: tokens.typography.label.copyWith(color: spec.labelColor),
                  ),
                ),
                if (entry.timestampText != null) ...[
                  SizedBox(width: tokens.spacing.sp2),
                  Text(
                    entry.timestampText!,
                    style: tokens.typography.label.copyWith(color: spec.timestampColor),
                  ),
                ],
              ],
            ),
            if (entry.descriptionText != null) ...[
              SizedBox(height: tokens.spacing.sp1),
              Text(
                entry.descriptionText!,
                style: tokens.typography.body.copyWith(color: spec.descriptionColor),
              ),
            ],
            if (entry.content != null) ...[
              SizedBox(height: tokens.spacing.sp2),
              entry.content!,
            ],
          ],
        ),
      ),
    );
  }
}
