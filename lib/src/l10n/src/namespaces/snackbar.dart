/// Snackbar namespace — localized strings for [LayrzSnackbar] and
/// [LayrzSnackbarMessenger].
///
/// Covers the accessibility labels a snackbar toast needs: the per-toast
/// dismiss control, the "dismiss all" affordance shown once the visible
/// stack overflows its cap, and the live-region announcement prefix read
/// out when a toast is first presented to a screen reader.
mixin LayrzUiL10nSnackbarMixin {
  /// Semantic label for the per-toast dismiss ("X") affordance rendered on
  /// [LayrzSnackbar].
  ///
  /// Announced by screen readers on the small, generously-hit-tested close
  /// control that dismisses a single toast immediately, regardless of its
  /// remaining duration. Only rendered when the toast's `isDismissible` is
  /// `true` — when it is `false`, this label is never surfaced because the
  /// control itself does not exist.
  ///
  /// English default: "Dismiss notification"
  String get snackbarDismissLabel => 'Dismiss notification';

  /// Semantic label for the overflow "dismiss all" affordance shown by
  /// [LayrzSnackbarMessenger] once more toasts are queued than fit in the
  /// visible stack.
  ///
  /// This label doubles as the affordance's visible text — it must read as
  /// an actionable command ("Dismiss all"), not a passive counter, so a
  /// tap is never a surprise. Activating it clears every toast currently
  /// queued, visible or collapsed.
  ///
  /// English default: "Dismiss all"
  String get snackbarDismissAllLabel => 'Dismiss all';

  /// Prefix prepended to the live-region announcement made when a
  /// [LayrzSnackbar] is first presented.
  ///
  /// The full announcement is this prefix followed by the toast's
  /// `titleText` and `descriptionText`, so a screen-reader user hears that
  /// a new notification has appeared before its content is read out —
  /// without this, "Saved successfully" alone can be mistaken for page
  /// content rather than a transient alert.
  ///
  /// English default: "Notification"
  String get snackbarAnnouncementPrefix => 'Notification';
}
