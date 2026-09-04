/// The two hand-tuned footprints [LayrzAiMarker] can render at.
///
/// A single `double size` parameter was replaced with this enum because the
/// star pair does not scale linearly: shrinking the container and scaling
/// the stars down by the same factor makes the small accent star vanish into
/// near-invisibility at compact sizes. Each value below instead maps to its
/// own hand-tuned container dimension and star sizes (see
/// [LayrzAiMarker._dimensionsFor] in `ai_marker.dart`), so both sizes stay
/// legible rather than one being a naive scale of the other.
enum LayrzAiMarkerSize {
  /// The compact footprint, for tight inline contexts (a caption, a dense
  /// list row). Container ~22 logical pixels, with the star pair tuned so
  /// the small accent star still reads as a distinct sparkle rather than a
  /// blur.
  small,

  /// The prominent footprint, for standalone use or as the default overlay
  /// size on [LayrzAiMarker.wrap]. Container ~44 logical pixels.
  big,
}
