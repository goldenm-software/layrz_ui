/// Presentation mode for the search input component.
enum LayrzSearchInputMode {
  /// Automatically picks between icon and field modes based on available viewport width.
  ///
  /// The search input renders as a field on regular viewports (>= 960px) and as a
  /// compact magnifier button (icon mode) that opens a panel on narrow viewports (< 960px).
  /// This is the default and recommended mode for responsive layouts.
  auto,

  /// Displays the search input as a collapsed magnifier button.
  ///
  /// The button opens an anchored panel containing the search field. The panel's width
  /// is content-sized (not anchored to the button), ensuring the field is usable.
  /// Escape or tap-outside closes the panel.
  ///
  /// Use this mode in dense toolbars or when space is always constrained.
  icon,

  /// Displays the search input as an inline field.
  ///
  /// The field is always visible with a magnifier prefix and a clear suffix (shown only
  /// when the field has text). This is the traditional form of a search input.
  ///
  /// Use this mode in forms or when horizontal space is abundant.
  field,
}
