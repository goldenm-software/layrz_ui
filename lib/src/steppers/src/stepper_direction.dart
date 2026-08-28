/// The axis [LayrzStepper] renders along.
///
/// `LayrzStepper` used to infer this from `context.isCompact` (viewport
/// width), with an optional override. That inference is gone: the caller now
/// states the axis explicitly via [LayrzStepper.direction], which is
/// required. An implicit width-derived layout switch inside a component whose
/// caller believes they already chose a layout is a trap — a caller can hand
/// the stepper a bounded box sized for one axis and have it silently render
/// the other because the window happened to be narrow, which is exactly the
/// showroom overflow this enum exists to make impossible. See decision D57's
/// 2026-08-27 update for the full history of the two layouts, and its
/// direction-parameter addendum for why the inference was removed.
enum LayrzStepperDirection {
  /// Renders [LayrzStepperWideHeader]: a full-width row of equal-width flex
  /// cells, one per step, connected by a line. Intended for viewports with
  /// enough horizontal room to show every step's indicator and label
  /// side by side.
  horizontal,

  /// Renders [LayrzStepperCompactLayout]: a vertical accordion where every
  /// step is a header row and only the active step's body expands inline
  /// beneath it. Intended for viewports too narrow for the horizontal
  /// layout to stay legible, but selectable by a caller on any viewport.
  vertical,
}
