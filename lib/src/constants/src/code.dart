/// The line-height factor shared by every code-rendering surface in the
/// design system — [LayrzCodeSurface], [LayrzCodeEditor], and the gutter.
///
/// Every code line box is laid out at `kCodeLineHeightFactor * fontSize`
/// logical pixels tall, enforced with a `StrutStyle` (`forceStrutHeight:
/// true`) so the line boxes are a fixed height regardless of per-line glyph
/// metrics. The gutter's line numbers and any per-line background bands are
/// positioned on the same factor, so numbers, code, and error highlights stay
/// row-for-row aligned. Both the read-only surface and the editable editor
/// must use this single value; a mismatch makes the gutter drift out of sync
/// with the code.
const double kCodeLineHeightFactor = 1.4;
