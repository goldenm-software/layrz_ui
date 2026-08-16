import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens.dart';

void main() {
  group('LayrzColorTokens', () {
    test('light factory uses correct defaults', () {
      final tokens = LayrzColorTokens.light();

      expect(tokens.primary, isA<LayrzColorSwatch>());
      expect(tokens.primary.shade500, equals(const Color(0xFF001E60)));
      expect(tokens.background, equals(const Color(0xFFFCFCFC)));
      expect(tokens.tonalOpacity, equals(0.2));
    });

    test('light factory respects primaryColor parameter', () {
      final customPrimary = const Color(0xFF123456);
      final tokens = LayrzColorTokens.light(primary: customPrimary);
      expect(tokens.primary, isA<LayrzColorSwatch>());
      expect(tokens.primary.shade500, equals(customPrimary));
    });

    test('light theme has correct surface colors', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.surface, equals(const Color(0xFFFFFFFF)));
      expect(tokens.surface2, equals(const Color(0xFFF7F7F7)));
      expect(tokens.surface3, equals(const Color(0xFFF0F0F0)));
    });

    test('light theme has correct foreground text colors', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.fg1, equals(const Color(0xFF1A1A2E)));
      expect(tokens.fg2, equals(const Color(0xFF4A4A5A)));
      expect(tokens.fg3, equals(const Color(0xFF9E9E9E)));
      expect(tokens.fg4, equals(const Color(0xFFC4C4C4)));
    });

    test('light theme has correct semantic colors', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.danger.shade500, equals(const Color(0xFFF44336))); // red 500
      expect(tokens.success.shade500, equals(const Color(0xFF4CAF50))); // green 500
      expect(tokens.warning.shade500, equals(const Color(0xFFFF9800))); // orange 500
      expect(tokens.info.shade500, equals(const Color(0xFF2196F3))); // blue 500
    });

    test('light theme has correct structural colors', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.divider, equals(const Color(0xFFE0E0E0)));
      expect(tokens.overlay, equals(Color.fromRGBO(0, 0, 0, 0.5)));
    });

    test('contextual color is distinct from context name', () {
      final tokens = LayrzColorTokens.light();
      // Verify it exists and is a swatch
      expect(tokens.contextual, isA<LayrzColorSwatch>());
      expect(tokens.contextual.shade500, equals(const Color(0xFF9E9E9E)));
    });

    test('copyWith creates new instance with replaced fields', () {
      final original = LayrzColorTokens.light();
      final newPrimary = const Color(0xFF999999);
      final modified = original.copyWith(primary: newPrimary);

      expect(modified.primary, isA<LayrzColorSwatch>());
      expect(modified.primary.shade500, equals(newPrimary));
      expect(modified.background, equals(original.background));
      expect(original.primary.shade500, equals(const Color(0xFF001E60))); // original unchanged
    });

    test('equality works for identical objects', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light();
      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      final original = LayrzColorTokens.light();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different primary colors', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light(primary: const Color(0xFF888888));
      expect(tokens1.primary.shade500, isNot(equals(tokens2.primary.shade500)));
    });

    test('hashCode is stable for same values', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light(primary: const Color(0xFF888888));
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });
  });
}
