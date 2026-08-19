import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('resolveLayrzLayoutPresentation', () {
    final defaultTokens = LayrzTokens.light();

    test('returns drawer for xs band', () {
      final result = resolveLayrzLayoutPresentation(
        width: 500,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.drawer);
    });

    test('returns drawer for sm band', () {
      final result = resolveLayrzLayoutPresentation(
        width: 800,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.drawer);
    });

    test('returns expanded for md band', () {
      final result = resolveLayrzLayoutPresentation(
        width: 1000,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.expanded);
    });

    test('returns expanded for lg band', () {
      final result = resolveLayrzLayoutPresentation(
        width: 1400,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.expanded);
    });

    test('returns expanded for xl band', () {
      final result = resolveLayrzLayoutPresentation(
        width: 2000,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.expanded);
    });

    test('returns drawer at xs boundary (599)', () {
      final result = resolveLayrzLayoutPresentation(
        width: 599,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.drawer);
    });

    test('returns drawer at sm boundary (959)', () {
      final result = resolveLayrzLayoutPresentation(
        width: 959,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.drawer);
    });

    test('returns expanded at md boundary (960)', () {
      final result = resolveLayrzLayoutPresentation(
        width: 960,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.expanded);
    });

    test('returns expanded at lg boundary (1264)', () {
      final result = resolveLayrzLayoutPresentation(
        width: 1264,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.expanded);
    });

    test('returns expanded at xl boundary (1904)', () {
      final result = resolveLayrzLayoutPresentation(
        width: 1904,
        tokens: defaultTokens,
      );
      expect(result, LayrzLayoutPresentation.expanded);
    });
  });
}
