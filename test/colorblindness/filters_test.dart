import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Asserts that every element of [actual] is within [precision] of the
/// corresponding element of [expected]. Used instead of plain list equality
/// to tolerate floating-point interpolation error.
void _expectMatrixCloseTo(List<double> actual, List<double> expected, {double precision = 1e-9}) {
  expect(actual.length, equals(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], precision), reason: 'mismatch at index $i');
  }
}

void main() {
  const protanopiaBase = [
    0.567, 0.433, 0.0, 0.0, 0.0, //
    0.558, 0.442, 0.0, 0.0, 0.0,
    0.0, 0.242, 0.758, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  const deuteranopiaBase = [
    0.8, 0.2, 0.0, 0.0, 0.0, //
    0.258, 0.742, 0.0, 0.0, 0.0,
    0.0, 0.141, 0.859, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  group('identityMatrix', () {
    test('is the standard 4x5 identity color matrix', () {
      expect(identityMatrix, equals(const [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]));
    });
  });

  group('protanopiaFilter', () {
    test('returns the identity matrix at strength 0.0', () {
      _expectMatrixCloseTo(protanopiaFilter(0.0), identityMatrix);
    });

    test('returns the base matrix at strength 1.0', () {
      _expectMatrixCloseTo(protanopiaFilter(1.0), protanopiaBase);
    });

    test('returns the midpoint at strength 0.5', () {
      final midpoint = List.generate(20, (i) => (identityMatrix[i] + protanopiaBase[i]) / 2);
      _expectMatrixCloseTo(protanopiaFilter(0.5), midpoint);
    });
  });

  group('deuteranopiaFilter', () {
    test('returns the identity matrix at strength 0.0', () {
      _expectMatrixCloseTo(deuteranopiaFilter(0.0), identityMatrix);
    });

    test('returns the base matrix at strength 1.0', () {
      _expectMatrixCloseTo(deuteranopiaFilter(1.0), deuteranopiaBase);
    });

    test('returns the midpoint at strength 0.5', () {
      final midpoint = List.generate(20, (i) => (identityMatrix[i] + deuteranopiaBase[i]) / 2);
      _expectMatrixCloseTo(deuteranopiaFilter(0.5), midpoint);
    });
  });

  group('other filter functions (identity and full-strength spot checks)', () {
    test('protanomalyFilter', () {
      const base = [
        0.817, 0.183, 0.0, 0.0, 0.0, //
        0.333, 0.667, 0.0, 0.0, 0.0,
        0.0, 0.125, 0.875, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
      _expectMatrixCloseTo(protanomalyFilter(0.0), identityMatrix);
      _expectMatrixCloseTo(protanomalyFilter(1.0), base);
    });

    test('deuteranomalyFilter', () {
      const base = [
        0.8, 0.2, 0.0, 0.0, 0.0, //
        0.3, 0.7, 0.0, 0.0, 0.0,
        0.0, 0.258, 0.742, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
      _expectMatrixCloseTo(deuteranomalyFilter(0.0), identityMatrix);
      _expectMatrixCloseTo(deuteranomalyFilter(1.0), base);
    });

    test('tritanopiaFilter', () {
      const base = [
        0.95, 0.05, 0.0, 0.0, 0.0, //
        0.0, 0.433, 0.567, 0.0, 0.0,
        0.0, 0.475, 0.525, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
      _expectMatrixCloseTo(tritanopiaFilter(0.0), identityMatrix);
      _expectMatrixCloseTo(tritanopiaFilter(1.0), base);
    });

    test('tritanomalyFilter', () {
      const base = [
        0.967, 0.033, 0.0, 0.0, 0.0, //
        0.0, 0.733, 0.267, 0.0, 0.0,
        0.0, 0.183, 0.817, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
      _expectMatrixCloseTo(tritanomalyFilter(0.0), identityMatrix);
      _expectMatrixCloseTo(tritanomalyFilter(1.0), base);
    });
  });

  group('ColorblindFilter.filter', () {
    test('returns a matrix ColorFilter equal to protanopiaFilter(strength) wrapped', () {
      final filter = ColorblindMode.protanopia.filter(1.0);
      expect(filter, equals(ColorFilter.matrix(protanopiaFilter(1.0))));
    });

    test('returns a matrix ColorFilter equal to deuteranopiaFilter(strength) wrapped', () {
      final filter = ColorblindMode.deuteranopia.filter(0.5);
      expect(filter, equals(ColorFilter.matrix(deuteranopiaFilter(0.5))));
    });

    test('ColorblindMode.normal.filter is identity regardless of strength', () {
      for (final strength in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(ColorblindMode.normal.filter(strength), equals(const ColorFilter.matrix(identityMatrix)));
      }
    });
  });
}
