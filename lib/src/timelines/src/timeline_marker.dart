import 'package:flutter/widgets.dart';

import 'timeline_style_spec.dart';

/// The diameter, in logical pixels, of a [LayrzTimelineMarker] circle.
const double kLayrzTimelineMarkerSize = 32.0;

/// The size, in logical pixels, of the glyph rendered inside a
/// [LayrzTimelineMarker] when [LayrzTimelineEntry.icon] is supplied.
const double kLayrzTimelineMarkerGlyphSize = 16.0;

/// The circular marker rendered on the spine for a single
/// [LayrzTimelineEntry].
///
/// Always excluded from semantics: the marker is purely decorative. Any
/// meaning it might seem to carry — an accent color, an icon — is already
/// present in the entry's [LayrzTimelineEntry.labelText] or
/// [LayrzTimelineEntry.descriptionText], which is what the entry's own
/// semantics node announces. This mirrors why [LayrzStepIndicator] excludes
/// its own content: a marker communicates identity, not independent state, so
/// there is nothing here a screen reader needs to announce a second time.
///
/// Renders a plain filled circle when [icon] is null, or the icon centred
/// inside the circle otherwise. Never uses color alone to distinguish one
/// entry from another (WCAG 1.4.1) — the marker's color is a supplementary
/// accent, and callers who need entries to be distinguishable must also vary
/// [LayrzTimelineEntry.icon] or text content, not [LayrzTimelineEntry.accentColor]
/// alone.
class LayrzTimelineMarker extends StatelessWidget {
  /// Creates a [LayrzTimelineMarker].
  const LayrzTimelineMarker({
    required this.spec,
    this.icon,
    super.key,
  });

  /// The resolved style spec supplying this marker's fill and content colors.
  final LayrzTimelineStyleSpec spec;

  /// The optional icon rendered inside the marker.
  ///
  /// When null, the marker renders as a plain filled dot with no content.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: kLayrzTimelineMarkerSize,
        height: kLayrzTimelineMarkerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: spec.markerColor,
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                size: kLayrzTimelineMarkerGlyphSize,
                color: spec.markerContentColor,
              )
            : null,
      ),
    );
  }
}
