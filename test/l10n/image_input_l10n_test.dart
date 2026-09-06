import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nImageInputMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('imageInputHint returns its English default', () {
      expect(localizations.imageInputHint, 'Click or drop an image here');
    });

    test("imageInputLoadError returns its English default", () {
      expect(localizations.imageInputLoadError, "Couldn't load image");
    });

    test('imageInputTooLarge interpolates the caller-provided size label', () {
      expect(localizations.imageInputTooLarge('5 MB'), 'Image too large. Maximum size is 5 MB.');
      expect(localizations.imageInputTooLarge('750 KB'), 'Image too large. Maximum size is 750 KB.');
    });

    test('imageInputReplace returns its English default', () {
      expect(localizations.imageInputReplace, 'Replace');
    });

    test('imageInputClear returns its English default', () {
      expect(localizations.imageInputClear, 'Clear');
    });

    test('the four fixed-string image input keys are distinct', () {
      // Guards against a copy-paste default accidentally aliasing two keys.
      final values = {
        localizations.imageInputHint,
        localizations.imageInputLoadError,
        localizations.imageInputReplace,
        localizations.imageInputClear,
      };
      expect(values.length, 4);
    });

    test('subclass can override a single image input key independently of the others', () {
      final custom = _CustomImageInputLocalizations();
      expect(custom.imageInputHint, 'CUSTOM_HINT');
      // The other keys keep their English defaults — not coupled.
      expect(custom.imageInputLoadError, "Couldn't load image");
      expect(custom.imageInputTooLarge('1 MB'), 'Image too large. Maximum size is 1 MB.');
      expect(custom.imageInputReplace, 'Replace');
      expect(custom.imageInputClear, 'Clear');
    });

    test('image input keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nImageInputMixin is actually wired into the
      // `with` clause of LayrzUiL10n — if it weren't, these getters would
      // not compile against the LayrzUiL10n-typed `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.imageInputHint, isNotEmpty);
      expect(contract.imageInputLoadError, isNotEmpty);
      expect(contract.imageInputTooLarge('1 MB'), isNotEmpty);
      expect(contract.imageInputReplace, isNotEmpty);
      expect(contract.imageInputClear, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [imageInputHint].
///
/// Verifies that the new image input keys can be overridden independently
/// of one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomImageInputLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomImageInputLocalizations();

  @override
  String get imageInputHint => 'CUSTOM_HINT';
}
