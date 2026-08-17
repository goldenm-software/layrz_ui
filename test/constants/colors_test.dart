import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('Brand Colors', () {
    test('kPrimaryColor is deep navy blue', () {
      expect(kPrimaryColor, equals(const Color(0xFF001E60)));
    });

    test('kLightBackgroundColor is light gray', () {
      expect(kLightBackgroundColor, equals(const Color(0xFFFCFCFC)));
    });
  });
}
