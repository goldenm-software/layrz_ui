/// Which side of the spine a [LayrzTimelineEntry] renders its content card on,
/// when a [LayrzTimeline] is laid out in its two-sided form.
///
/// This has no effect in the one-sided form (including the automatic
/// below-breakpoint collapse): every entry's card renders on the same side of
/// the spine there regardless of its [LayrzTimelineSide], since there is only
/// one side to place it on. It exists purely as an alternating/explicit
/// placement hint for the two-sided layout.
enum LayrzTimelineSide {
  /// Renders the entry's content card to the left of the spine.
  start,

  /// Renders the entry's content card to the right of the spine.
  end,
}
