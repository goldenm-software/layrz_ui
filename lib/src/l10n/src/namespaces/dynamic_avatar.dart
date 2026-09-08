/// Dynamic Avatar Types namespace, covering strings for `LayrzDynamicAvatarInput`
/// (`lib/src/pickers/src/dynamic_avatar/`) — its four tab labels, its inline
/// URL field's hint/action, and the None/clear affordance.
mixin LayrzUiL10nDynamicAvatarMixin {
  /// Localized label for Base64 avatar type.
  String get dynamicAvatarTypesBASE64 => 'Base64';

  /// Localized hint for no avatar (null state).
  String get dynamicAvatarTypesNONEHint => 'No avatar';

  /// Localized label for URL avatar type.
  String get dynamicAvatarTypesURLUrl => 'URL';

  /// Localized tab label for the Icon tab of `LayrzDynamicAvatarInput`'s
  /// surface.
  ///
  /// Default: "Icon"
  String get dynamicAvatarTabIcon => 'Icon';

  /// Localized tab label for the Emoji tab of `LayrzDynamicAvatarInput`'s
  /// surface.
  ///
  /// Default: "Emoji"
  String get dynamicAvatarTabEmoji => 'Emoji';

  /// Localized hint text for the inline URL field on the URL tab. The field
  /// commits on submit (Enter/Done) — there is no separate "Apply" button.
  ///
  /// Default: "Enter an image URL"
  String get dynamicAvatarUrlHint => 'Enter an image URL';

  /// Localized label for the affordance that clears the current selection,
  /// setting the value back to `null` ("no avatar").
  ///
  /// Default: "Remove avatar"
  String get dynamicAvatarClear => 'Remove avatar';

  /// Localized label for the "All emoji" entry in the Emoji tab's inline
  /// group-filter row.
  ///
  /// Default: "All"
  String get dynamicAvatarEmojiGroupAll => 'All';
}
