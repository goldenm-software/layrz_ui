import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nEmojiPickerMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('emojiPickerSearch returns its English default', () {
      expect(localizations.emojiPickerSearch, 'Search emoji');
    });

    test('emojiPickerEmpty returns its English default', () {
      expect(localizations.emojiPickerEmpty, 'No emoji found');
    });

    test('all ten EmojiGroup labels have non-empty English defaults', () {
      expect(localizations.emojiPickerGroupSmileysEmotion, isNotEmpty);
      expect(localizations.emojiPickerGroupPeopleBody, isNotEmpty);
      expect(localizations.emojiPickerGroupAnimalsNature, isNotEmpty);
      expect(localizations.emojiPickerGroupFoodDrink, isNotEmpty);
      expect(localizations.emojiPickerGroupTravelPlaces, isNotEmpty);
      expect(localizations.emojiPickerGroupActivities, isNotEmpty);
      expect(localizations.emojiPickerGroupObjects, isNotEmpty);
      expect(localizations.emojiPickerGroupSymbols, isNotEmpty);
      expect(localizations.emojiPickerGroupFlags, isNotEmpty);
      expect(localizations.emojiPickerGroupComponent, isNotEmpty);
    });

    test('the ten EmojiGroup labels are distinct strings', () {
      // Guards against a copy-paste default accidentally aliasing two groups.
      final values = {
        localizations.emojiPickerGroupSmileysEmotion,
        localizations.emojiPickerGroupPeopleBody,
        localizations.emojiPickerGroupAnimalsNature,
        localizations.emojiPickerGroupFoodDrink,
        localizations.emojiPickerGroupTravelPlaces,
        localizations.emojiPickerGroupActivities,
        localizations.emojiPickerGroupObjects,
        localizations.emojiPickerGroupSymbols,
        localizations.emojiPickerGroupFlags,
        localizations.emojiPickerGroupComponent,
      };
      expect(values.length, 10);
    });

    test('subclass can override a single emoji picker key independently of the others', () {
      final custom = _CustomEmojiPickerLocalizations();
      expect(custom.emojiPickerSearch, 'CUSTOM_SEARCH');
      // The other keys keep their English defaults — not coupled.
      expect(custom.emojiPickerEmpty, 'No emoji found');
      expect(custom.emojiPickerGroupFlags, 'Flags');
    });

    test('emoji picker keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nEmojiPickerMixin is actually wired into the
      // `with` clause of LayrzUiL10n — if it weren't, these getters would
      // not compile against the LayrzUiL10n-typed `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.emojiPickerSearch, isNotEmpty);
      expect(contract.emojiPickerEmpty, isNotEmpty);
      expect(contract.emojiPickerGroupSmileysEmotion, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [emojiPickerSearch].
///
/// Verifies that the new emoji picker keys can be overridden independently
/// of one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomEmojiPickerLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomEmojiPickerLocalizations();

  @override
  String get emojiPickerSearch => 'CUSTOM_SEARCH';
}
