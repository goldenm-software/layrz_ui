import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzBadgeAlignment', () {
    test('topRight maps to Alignment.topRight', () {
      expect(LayrzBadgeAlignment.topRight.alignment, equals(Alignment.topRight));
    });

    test('topLeft maps to Alignment.topLeft', () {
      expect(LayrzBadgeAlignment.topLeft.alignment, equals(Alignment.topLeft));
    });

    test('bottomRight maps to Alignment.bottomRight', () {
      expect(LayrzBadgeAlignment.bottomRight.alignment, equals(Alignment.bottomRight));
    });

    test('bottomLeft maps to Alignment.bottomLeft', () {
      expect(LayrzBadgeAlignment.bottomLeft.alignment, equals(Alignment.bottomLeft));
    });

    test('enum has exactly four values in the documented order', () {
      expect(LayrzBadgeAlignment.values, [
        LayrzBadgeAlignment.topRight,
        LayrzBadgeAlignment.topLeft,
        LayrzBadgeAlignment.bottomRight,
        LayrzBadgeAlignment.bottomLeft,
      ]);
    });
  });
}
