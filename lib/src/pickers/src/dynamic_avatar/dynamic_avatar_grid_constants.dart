/// The number of grid columns rendered per row of glyph cells, shared by
/// both the Icon and Emoji tabs of `LayrzDynamicAvatarInput`'s surface —
/// mirrors `LayrzIconSurface`/`LayrzEmojiSurface`'s identical fixed-column
/// reasoning: a fixed count keeps cell size predictable across the dialog
/// and bottom-sheet hosts, both of which already constrain this surface to
/// a known width band.
const int kDynamicAvatarGridColumns = 8;

/// The side length, in logical pixels, of each glyph cell — matches
/// `LayrzIconSurface`/`LayrzEmojiSurface`'s own `44.0` scale.
const double kDynamicAvatarCellExtent = 44.0;
