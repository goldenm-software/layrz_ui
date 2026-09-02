/// How [LayrzDateTimeInput] arranges its date and time parts within one
/// anchored panel.
///
/// **DESIGN-51 collapsed into [LayrzDateTimeInput] as this enum** — the two
/// values must be visibly and behaviourally distinct, which is the whole
/// reason the collapse is justified. Both values share the identical commit
/// model (in-panel Cancel/Save — see [LayrzDateTimeInput]'s class doc for
/// why a single-`DateTime`-valued widget still carries a Save button) and
/// fire `onChanged` at the same moment, on Save. What differs is purely
/// *how the two parts are reached*:
///
/// - [tabbed] shows only one part at a time, switched at will via a real
///   tab strip.
/// - [stepped] shows only one part at a time, advanced in a fixed
///   date-then-time order with no way to jump ahead.
enum LayrzDateTimeInputPresentation {
  /// The date grid and the time fields sit behind two selectable tab
  /// headers (labelled via `dateTimePickerDate`/`dateTimePickerTime`) inside
  /// the same panel. Only one half is visible at a time; switching tabs
  /// never commits or closes the panel — see the tab strip's own class doc.
  tabbed,

  /// The date grid is shown first; selecting a date advances to the time
  /// step within the same panel. A back affordance returns to the date
  /// step without discarding the chosen date. There is no way to reach the
  /// time step before a date has been picked.
  stepped,
}
