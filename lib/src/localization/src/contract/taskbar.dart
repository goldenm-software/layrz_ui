/// Taskbar namespace.
abstract mixin class LayrzTaskbarLocalizations {
  /// Localized text for "About" menu item.
  String get taskbarAbout;

  /// Localized text for theme toggle action.
  ///
  /// **Note**: Dark mode is out of scope (decision D7). This key is retained for
  /// contract stability; dark-mode toggle will be driven by higher-level app logic.
  String get taskbarToggleTheme;

  /// Localized text for "Settings" menu item.
  String get taskbarSettings;

  /// Localized text for "Edit profile" menu item.
  String get taskbarProfile;

  /// Localized text for "Logout" action.
  String get taskbarSignOut;
}
