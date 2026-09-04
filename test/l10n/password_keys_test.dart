import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nPasswordMixin — eye-toggle and login label keys', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('passwordShow returns its English default', () {
      expect(localizations.passwordShow, 'Show password');
    });

    test('passwordHide returns its English default', () {
      expect(localizations.passwordHide, 'Hide password');
    });

    test('passwordShownAnnouncement returns its English default', () {
      expect(localizations.passwordShownAnnouncement, 'Password shown');
    });

    test('passwordHiddenAnnouncement returns its English default', () {
      expect(localizations.passwordHiddenAnnouncement, 'Password hidden');
    });

    test('loginUsernameLabel returns its English default', () {
      expect(localizations.loginUsernameLabel, 'Username');
    });

    test('loginPasswordLabel returns its English default', () {
      expect(localizations.loginPasswordLabel, 'Password');
    });

    test('the six new keys are distinct strings', () {
      // Guards against a copy-paste default accidentally aliasing two keys.
      final values = {
        localizations.passwordShow,
        localizations.passwordHide,
        localizations.passwordShownAnnouncement,
        localizations.passwordHiddenAnnouncement,
        localizations.loginUsernameLabel,
        localizations.loginPasswordLabel,
      };
      expect(values.length, 6);
    });

    test('subclass can override a single key independently of the others', () {
      final custom = _CustomPasswordLocalizations();
      expect(custom.passwordShow, 'CUSTOM_SHOW');
      // The other keys keep their English defaults — not coupled.
      expect(custom.passwordHide, 'Hide password');
      expect(custom.passwordShownAnnouncement, 'Password shown');
      expect(custom.passwordHiddenAnnouncement, 'Password hidden');
      expect(custom.loginUsernameLabel, 'Username');
      expect(custom.loginPasswordLabel, 'Password');
    });

    test('the new keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nPasswordMixin's new getters are actually wired
      // into the `with` clause of LayrzUiL10n — if they weren't, these
      // getters would not compile against the LayrzUiL10n-typed
      // `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.passwordShow, isNotEmpty);
      expect(contract.passwordHide, isNotEmpty);
      expect(contract.passwordShownAnnouncement, isNotEmpty);
      expect(contract.passwordHiddenAnnouncement, isNotEmpty);
      expect(contract.loginUsernameLabel, isNotEmpty);
      expect(contract.loginPasswordLabel, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [LayrzUiL10n.passwordShow].
///
/// Verifies that the new password/login keys can be overridden independently
/// of one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomPasswordLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomPasswordLocalizations();

  @override
  String get passwordShow => 'CUSTOM_SHOW';
}
