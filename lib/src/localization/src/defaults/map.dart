import '../contract/map.dart';

/// English default implementations for Map Layer & Zoom namespace.
///
/// **Status**: Out of scope for M1 but reserved for future compatibility.
mixin LayrzDefaultMapLocalizations implements LayrzMapLocalizations {
  @override
  String get mapChangeLayer => 'Change layer';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';
}
