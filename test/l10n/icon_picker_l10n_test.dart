import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nIconPickerMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('iconPickerSearch returns its English default', () {
      expect(localizations.iconPickerSearch, 'Search icon');
    });

    test('iconPickerEmpty returns its English default', () {
      expect(localizations.iconPickerEmpty, 'No icon found');
    });

    test('the two icon picker keys are distinct strings', () {
      // Guards against a copy-paste default accidentally aliasing two keys.
      final values = {
        localizations.iconPickerSearch,
        localizations.iconPickerEmpty,
      };
      expect(values.length, 2);
    });

    test('subclass can override a single icon picker key independently of the other', () {
      final custom = _CustomIconPickerLocalizations();
      expect(custom.iconPickerSearch, 'CUSTOM_SEARCH');
      // The other key keeps its English default — not coupled.
      expect(custom.iconPickerEmpty, 'No icon found');
    });

    test('icon picker keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nIconPickerMixin is actually wired into the
      // `with` clause of LayrzUiL10n — if it weren't, these getters would
      // not compile against the LayrzUiL10n-typed `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.iconPickerSearch, isNotEmpty);
      expect(contract.iconPickerEmpty, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [iconPickerSearch].
///
/// Verifies that the new icon picker keys can be overridden independently
/// of one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomIconPickerLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomIconPickerLocalizations();

  @override
  String get iconPickerSearch => 'CUSTOM_SEARCH';
}
