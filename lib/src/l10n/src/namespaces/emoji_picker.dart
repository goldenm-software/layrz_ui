/// Emoji Picker namespace, covering strings for the emoji-grid surface of
/// `LayrzEmojiInput` (`lib/src/pickers/src/emoji/`) — its search hint, the
/// human-readable label for each of the ten `EmojiGroup` values exposed by
/// the `emojis` package, and the empty state shown when no emoji matches
/// the current search/group filter.
mixin LayrzUiL10nEmojiPickerMixin {
  /// Localized placeholder for the search field in the emoji picker surface.
  ///
  /// Default: "Search emoji"
  String get emojiPickerSearch => 'Search emoji';

  /// Localized empty state message when no emoji matches the current
  /// search text or selected group filter.
  ///
  /// Default: "No emoji found"
  String get emojiPickerEmpty => 'No emoji found';

  /// Localized label for `EmojiGroup.smileysEmotion`.
  ///
  /// Default: "Smileys & Emotion"
  String get emojiPickerGroupSmileysEmotion => 'Smileys & Emotion';

  /// Localized label for `EmojiGroup.peopleBody`.
  ///
  /// Default: "People & Body"
  String get emojiPickerGroupPeopleBody => 'People & Body';

  /// Localized label for `EmojiGroup.animalsNature`.
  ///
  /// Default: "Animals & Nature"
  String get emojiPickerGroupAnimalsNature => 'Animals & Nature';

  /// Localized label for `EmojiGroup.foodDrink`.
  ///
  /// Default: "Food & Drink"
  String get emojiPickerGroupFoodDrink => 'Food & Drink';

  /// Localized label for `EmojiGroup.travelPlaces`.
  ///
  /// Default: "Travel & Places"
  String get emojiPickerGroupTravelPlaces => 'Travel & Places';

  /// Localized label for `EmojiGroup.activities`.
  ///
  /// Default: "Activities"
  String get emojiPickerGroupActivities => 'Activities';

  /// Localized label for `EmojiGroup.objects`.
  ///
  /// Default: "Objects"
  String get emojiPickerGroupObjects => 'Objects';

  /// Localized label for `EmojiGroup.symbols`.
  ///
  /// Default: "Symbols"
  String get emojiPickerGroupSymbols => 'Symbols';

  /// Localized label for `EmojiGroup.flags`.
  ///
  /// Default: "Flags"
  String get emojiPickerGroupFlags => 'Flags';

  /// Localized label for `EmojiGroup.component`.
  ///
  /// This group holds modifier-only building blocks (skin tones, hair
  /// styles) rather than standalone emoji; the label is reserved for
  /// completeness even though skin-tone variants are out of scope for v1.
  ///
  /// Default: "Component"
  String get emojiPickerGroupComponent => 'Component';
}
