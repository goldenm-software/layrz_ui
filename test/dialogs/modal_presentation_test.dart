import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('resolveLayrzModalPresentation', () {
    final defaultTokens = LayrzTokens.light();

    test('returns sheet for xs band', () {
      final result = resolveLayrzModalPresentation(
        width: 500,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.sheet);
    });

    test('returns sheet for sm band', () {
      final result = resolveLayrzModalPresentation(
        width: 800,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.sheet);
    });

    test('returns dialog for md band', () {
      final result = resolveLayrzModalPresentation(
        width: 1000,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });

    test('returns dialog for lg band', () {
      final result = resolveLayrzModalPresentation(
        width: 1400,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });

    test('returns dialog for xl band', () {
      final result = resolveLayrzModalPresentation(
        width: 2000,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });

    test('returns sheet at xs boundary (599)', () {
      final result = resolveLayrzModalPresentation(
        width: 599,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.sheet);
    });

    test('returns sheet at sm boundary (959)', () {
      final result = resolveLayrzModalPresentation(
        width: 959,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.sheet);
    });

    test('returns dialog at md boundary (960)', () {
      final result = resolveLayrzModalPresentation(
        width: 960,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });

    test('returns dialog at lg boundary (1264)', () {
      final result = resolveLayrzModalPresentation(
        width: 1264,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });

    test('returns dialog at xl boundary (1904)', () {
      final result = resolveLayrzModalPresentation(
        width: 1904,
        tokens: defaultTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });

    test('respects app-overridden breakpoint tokens', () {
      final customTokens = LayrzTokens.light().copyWith(
        breakpoints: const LayrzBreakpointTokens(xs: 500, sm: 500),
      );

      // A width that would be "sm" (sheet) under default tokens now falls
      // into "md" (dialog) once the sm ceiling is lowered to 500.
      final result = resolveLayrzModalPresentation(
        width: 700,
        tokens: customTokens,
      );
      expect(result, LayrzModalPresentation.dialog);
    });
  });
}
