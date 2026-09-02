/// How [LayrzDateTimeInput] arranges its date and time parts within one
/// anchored panel.
///
/// **Presentation-only**: both members fire `onChanged` at the same commit
/// moment (once both date and time are chosen) — see [LayrzDateTimeInput]'s
/// class doc for the commit rule this enum must never fork.
enum LayrzDateTimeInputPresentation {
  /// Both the date grid and time fields are visible behind tab labels
  /// (`dateTimePickerDate` / `dateTimePickerTime`), switchable at will.
  tabbed,

  /// The date grid is shown first; selecting a date advances to the time
  /// fields within the same panel.
  stepped,
}
