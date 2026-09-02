/// How [LayrzDateTimeInput] arranges its date and time parts.
///
/// **Deprecated and ignored as of DESIGN-49.** [LayrzDateTimeInput] moved
/// from [LayrzAnchoredPanel] to a picker-private drawer (since promoted to
/// [LayrzEndDrawer] under DESIGN-98) on desktop; the drawer's extra vertical
/// room is enough to show the calendar and the time fields together in one
/// scroll, which is what [LayrzDateTimeSurface] now always does. Both values
/// of this enum reduce to the same layout — there is no remaining tab strip
/// or step sequence to select between.
///
/// **Kept, not removed, as a no-op.** DESIGN-51 was formally recorded as
/// *covered by* DESIGN-49 through this enum (`engineering/milestone-4.md`,
/// decision D75, and the wiki's `LayrzDateTimeInput` page), so silently
/// deleting it would be a breaking API removal with no migration signal for
/// an existing caller that passes `presentation:` explicitly — the value
/// simply stops changing anything, exactly like passing no value at all.
/// [LayrzDateTimeInput.presentation] still accepts either constant; neither
/// is read by [LayrzDateTimeSurface] any longer.
///
/// [tabbed] and [stepped] are documented here purely for their historical
/// meaning, since removing the values themselves (as opposed to their
/// effect) would still be the breaking part of this change.
enum LayrzDateTimeInputPresentation {
  /// Historically: the date grid and the time fields sat behind two
  /// selectable tab headers inside the same panel. No longer has any effect
  /// — see this enum's class doc.
  tabbed,

  /// Historically: the date grid was shown first, and selecting a date
  /// advanced to a separate time step. No longer has any effect — see this
  /// enum's class doc.
  stepped,
}
