/// Color Picker namespace, covering strings for the two-tab color picker
/// surface (`lib/src/pickers/src/color/`) — its "Palette"/"Wheel" tab labels,
/// the HEX value readout, the paste-from-clipboard affordance, and the
/// empty-palette hint shown when the caller-supplied swatch set is empty.
mixin LayrzUiL10nColorPickerMixin {
  /// Localized label for the tab that renders the caller-supplied
  /// `Set<Color>` as a grid of selectable swatches.
  ///
  /// Default: "Palette"
  String get colorPickerPaletteTab => 'Palette';

  /// Localized label for the tab that hosts the freeform HSV color wheel.
  ///
  /// Default: "Wheel"
  String get colorPickerWheelTab => 'Wheel';

  /// Localized label for the field that displays the currently selected
  /// color in HEX format (e.g. "#RRGGBB"), shown below the tabs.
  ///
  /// Default: "Hex"
  String get colorPickerHexLabel => 'Hex';

  /// Localized label for the button that reads the system clipboard, parses
  /// a HEX color out of it, and applies it as the current selection.
  ///
  /// Default: "Paste"
  String get colorPickerPasteButton => 'Paste';

  /// Localized hint shown in the palette tab when the caller-supplied
  /// `Set<Color>` is empty, explaining that there is nothing to pick from.
  ///
  /// Default: "No colors in the palette"
  String get colorPickerEmptyPalette => 'No colors in the palette';
}
