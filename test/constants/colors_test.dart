import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('Brand Colors', () {
    test('kLightPrimaryColor is deep navy blue', () {
      expect(kLightPrimaryColor, equals(const Color(0xFF001E60)));
    });

    test('kDarkPrimaryColor is Layrz orange accent', () {
      expect(kDarkPrimaryColor, equals(const Color(0xFFFF9800)));
    });
  });
}
