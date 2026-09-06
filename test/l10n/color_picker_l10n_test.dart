import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzUiL10nColorPickerMixin', () {
    late LayrzUiL10n localizations;

    setUp(() {
      localizations = LayrzUiL10nDefault();
    });

    test('colorPickerPaletteTab returns its English default', () {
      expect(localizations.colorPickerPaletteTab, 'Palette');
    });

    test('colorPickerWheelTab returns its English default', () {
      expect(localizations.colorPickerWheelTab, 'Wheel');
    });

    test('colorPickerHexLabel returns its English default', () {
      expect(localizations.colorPickerHexLabel, 'Hex');
    });

    test('colorPickerPasteButton returns its English default', () {
      expect(localizations.colorPickerPasteButton, 'Paste');
    });

    test('colorPickerEmptyPalette returns its English default', () {
      expect(localizations.colorPickerEmptyPalette, 'No colors in the palette');
    });

    test('the five color picker keys are distinct strings', () {
      // Guards against a copy-paste default accidentally aliasing two keys.
      final values = {
        localizations.colorPickerPaletteTab,
        localizations.colorPickerWheelTab,
        localizations.colorPickerHexLabel,
        localizations.colorPickerPasteButton,
        localizations.colorPickerEmptyPalette,
      };
      expect(values.length, 5);
    });

    test('subclass can override a single color picker key independently of the others', () {
      final custom = _CustomColorPickerLocalizations();
      expect(custom.colorPickerPaletteTab, 'CUSTOM_PALETTE');
      // The other keys keep their English defaults — not coupled.
      expect(custom.colorPickerWheelTab, 'Wheel');
      expect(custom.colorPickerHexLabel, 'Hex');
      expect(custom.colorPickerPasteButton, 'Paste');
      expect(custom.colorPickerEmptyPalette, 'No colors in the palette');
    });

    test('color picker keys are reachable directly on the LayrzUiL10n contract', () {
      // Confirms LayrzUiL10nColorPickerMixin is actually wired into the
      // `with` clause of LayrzUiL10n — if it weren't, these getters would
      // not compile against the LayrzUiL10n-typed `localizations` above.
      final LayrzUiL10n contract = localizations;
      expect(contract.colorPickerPaletteTab, isNotEmpty);
      expect(contract.colorPickerWheelTab, isNotEmpty);
      expect(contract.colorPickerHexLabel, isNotEmpty);
      expect(contract.colorPickerPasteButton, isNotEmpty);
      expect(contract.colorPickerEmptyPalette, isNotEmpty);
    });
  });
}

/// Minimal [LayrzUiL10n] subclass overriding only [colorPickerPaletteTab].
///
/// Verifies that the new color picker keys can be overridden independently
/// of one another and of unrelated namespaces, confirming they are declared
/// as separate getters rather than aliased.
class _CustomColorPickerLocalizations extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomColorPickerLocalizations();

  @override
  String get colorPickerPaletteTab => 'CUSTOM_PALETTE';
}
