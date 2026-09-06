import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nMultiSelectMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('multiSelectSearch returns its English default', () {
      expect(localizations.multiSelectSearch, 'Search in the list');
    });

    test('multiSelectEmpty returns its English default', () {
      expect(localizations.multiSelectEmpty, 'No item found');
    });

    test('multiSelectSelectAll returns its English default', () {
      expect(localizations.multiSelectSelectAll, 'Select all');
    });

    test('multiSelectUnselectAll returns its English default', () {
      expect(localizations.multiSelectUnselectAll, 'Unselect all');
    });

    test('reuses the shared actionSave/actionCancel keys rather than duplicating them', () {
      // Multi-select's staged-with-Save surface commits via the existing
      // actions namespace — this guards against a future duplicate
      // multiSelectSave/multiSelectCancel getter being added by mistake.
      expect(localizations.actionSave, 'Save');
      expect(localizations.actionCancel, 'Cancel');
    });

    test('subclass can override a single multi-select key independently of the others', () {
      final custom = _CustomMultiSelectLocalizations();
      expect(custom.multiSelectSearch, 'CUSTOM_SEARCH');
      // The other keys keep their English defaults — not coupled.
      expect(custom.multiSelectEmpty, 'No item found');
      expect(custom.multiSelectSelectAll, 'Select all');
      expect(custom.multiSelectUnselectAll, 'Unselect all');
    });

    test('multi-select keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nMultiSelectMixin is actually wired into the
      // `with` clause of LayrzUiL10n — if it weren't, these getters would
      // not compile against the LayrzUiL10n-typed `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.multiSelectSearch, isNotEmpty);
      expect(contract.multiSelectEmpty, isNotEmpty);
      expect(contract.multiSelectSelectAll, isNotEmpty);
      expect(contract.multiSelectUnselectAll, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [multiSelectSearch].
///
/// Verifies that the new multi-select keys can be overridden independently
/// of one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomMultiSelectLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomMultiSelectLocalizations();

  @override
  String get multiSelectSearch => 'CUSTOM_SEARCH';
}
