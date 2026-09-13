import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('ColorblindMode.toJson', () {
    test('serializes every value to its uppercase JSON string', () {
      expect(ColorblindMode.protanopia.toJson(), equals('PROTANOPIA'));
      expect(ColorblindMode.protanomaly.toJson(), equals('PROTANOMALY'));
      expect(ColorblindMode.deuteranopia.toJson(), equals('DEUTERANOPIA'));
      expect(ColorblindMode.deuteranomaly.toJson(), equals('DEUTERANOMALY'));
      expect(ColorblindMode.tritanopia.toJson(), equals('TRITANOPIA'));
      expect(ColorblindMode.tritanomaly.toJson(), equals('TRITANOMALY'));
      expect(ColorblindMode.normal.toJson(), equals('NORMAL'));
    });
  });

  group('ColorblindMode.fromJson', () {
    test('round-trips every value through toJson/fromJson', () {
      for (final mode in ColorblindMode.values) {
        expect(ColorblindMode.fromJson(mode.toJson()), equals(mode));
      }
    });

    test('falls back to ColorblindMode.normal for unrecognized input', () {
      expect(ColorblindMode.fromJson('garbage'), equals(ColorblindMode.normal));
      expect(ColorblindMode.fromJson(''), equals(ColorblindMode.normal));
      expect(ColorblindMode.fromJson('protanopia'), equals(ColorblindMode.normal));
    });
  });
}
