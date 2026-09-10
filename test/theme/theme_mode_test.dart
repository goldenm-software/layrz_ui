import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzThemeMode', () {
    test('has exactly light, dark, and system values', () {
      expect(
        LayrzThemeMode.values,
        equals(const [LayrzThemeMode.light, LayrzThemeMode.dark, LayrzThemeMode.system]),
      );
    });

    test('light value exists', () {
      expect(LayrzThemeMode.values, contains(LayrzThemeMode.light));
    });

    test('dark value exists', () {
      expect(LayrzThemeMode.values, contains(LayrzThemeMode.dark));
    });

    test('system value exists', () {
      expect(LayrzThemeMode.values, contains(LayrzThemeMode.system));
    });
  });
}
