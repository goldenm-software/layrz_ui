import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nSnackbarMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('snackbarDismissLabel returns its English default', () {
      expect(localizations.snackbarDismissLabel, 'Dismiss notification');
    });

    test('snackbarDismissAllLabel returns its English default', () {
      expect(localizations.snackbarDismissAllLabel, 'Dismiss all');
    });

    test('snackbarAnnouncementPrefix returns its English default', () {
      expect(localizations.snackbarAnnouncementPrefix, 'Notification');
    });

    test('the three snackbar keys are distinct strings', () {
      // Guards against a copy-paste default accidentally aliasing two keys.
      final values = {
        localizations.snackbarDismissLabel,
        localizations.snackbarDismissAllLabel,
        localizations.snackbarAnnouncementPrefix,
      };
      expect(values.length, 3);
    });

    test('subclass can override a single snackbar key independently of the others', () {
      final custom = _CustomSnackbarLocalizations();
      expect(custom.snackbarDismissLabel, 'CUSTOM_DISMISS');
      // The other two keys keep their English defaults — not coupled.
      expect(custom.snackbarDismissAllLabel, 'Dismiss all');
      expect(custom.snackbarAnnouncementPrefix, 'Notification');
    });

    test('snackbar keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nSnackbarMixin is actually wired into the `with`
      // clause of LayrzUiL10n — if it weren't, these getters would not
      // compile against the LayrzUiL10n-typed `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.snackbarDismissLabel, isNotEmpty);
      expect(contract.snackbarDismissAllLabel, isNotEmpty);
      expect(contract.snackbarAnnouncementPrefix, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [snackbarDismissLabel].
///
/// Verifies that the new snackbar keys can be overridden independently of
/// one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomSnackbarLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomSnackbarLocalizations();

  @override
  String get snackbarDismissLabel => 'CUSTOM_DISMISS';
}
