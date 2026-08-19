/// Map Layer & Zoom namespace.
///
/// **Status**: Out of scope for M1 (flutter_map is Material-built). Included in contract
/// for future reference and forward compatibility.
abstract mixin class LayrzMapLocalizations {
  /// Localized text for "Change layer" layer selector button.
  ///
  /// **Note**: Map component is blocked; this key is reserved.
  String get mapChangeLayer;

  /// Localized text for "Zoom in" action.
  ///
  /// **Note**: Map component is blocked; this key is reserved.
  String get mapZoomIn;

  /// Localized text for "Zoom out" action.
  ///
  /// **Note**: Map component is blocked; this key is reserved.
  String get mapZoomOut;
}
