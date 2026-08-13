import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzColorTokens', () {
    test('light factory uses correct defaults', () {
      final tokens = LayrzColorTokens.light();

      expect(tokens.primary, equals(const Color(0xFF001E60)));
      expect(tokens.accent, equals(const Color(0xFFFF8200)));
      expect(tokens.background, equals(const Color(0xFFFCFCFC)));
      expect(tokens.tonalOpacity, equals(0.2));
    });

    test('light factory respects primaryColor parameter', () {
      final customPrimary = const Color(0xFF123456);
      final tokens = LayrzColorTokens.light(primary: customPrimary);
      expect(tokens.primary, equals(customPrimary));
    });

    test('light factory respects accentColor parameter', () {
      final customAccent = const Color(0xFF654321);
      final tokens = LayrzColorTokens.light(accent: customAccent);
      expect(tokens.accent, equals(customAccent));
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
      expect(tokens.danger, equals(const Color(0xFFE53935)));
      expect(tokens.success, equals(const Color(0xFF43A047)));
      expect(tokens.warning, equals(const Color(0xFFFB8C00)));
      expect(tokens.info, equals(const Color(0xFF1E88E5)));
    });

    test('light theme has correct structural colors', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.divider, equals(const Color(0xFFE0E0E0)));
      expect(tokens.overlay, equals(Color.fromRGBO(0, 0, 0, 0.5)));
    });

    test('contextual color is distinct from context name', () {
      final tokens = LayrzColorTokens.light();
      // Just verify it exists and is a color
      expect(tokens.contextual, isA<Color>());
      expect(tokens.contextual, equals(const Color(0xFF9E9E9E)));
    });

    test('copyWith creates new instance with replaced fields', () {
      final original = LayrzColorTokens.light();
      final newPrimary = const Color(0xFF999999);
      final modified = original.copyWith(primary: newPrimary);

      expect(modified.primary, equals(newPrimary));
      expect(modified.accent, equals(original.accent));
      expect(modified.background, equals(original.background));
      expect(
        original.primary,
        equals(const Color(0xFF001E60)),
      ); // original unchanged
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
      expect(tokens1, isNot(equals(tokens2)));
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
