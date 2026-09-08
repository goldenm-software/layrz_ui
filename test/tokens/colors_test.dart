import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzColorTokens', () {
    test('light factory uses correct defaults', () {
      final tokens = LayrzColorTokens.light();

      expect(tokens.primary, isA<LayrzColorSwatch>());
      expect(tokens.primary.shade500, equals(const Color(0xFF001E60)));
      expect(tokens.sf1, equals(const Color(0xFFFCFCFC)));
      expect(tokens.tonalOpacity, equals(0.2));
    });

    test('light factory respects primaryColor parameter', () {
      final customPrimary = const Color(0xFF123456);
      final tokens = LayrzColorTokens.light(primary: customPrimary);
      expect(tokens.primary, isA<LayrzColorSwatch>());
      expect(tokens.primary.shade500, equals(customPrimary));
    });

    test('light theme has correct surface ramp', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.sf1, equals(const Color(0xFFFCFCFC)));
      expect(tokens.sf2, equals(const Color(0xFFF7F7F7)));
      expect(tokens.sf3, equals(const Color(0xFFF0F0F0)));
      expect(tokens.sf4, equals(const Color(0xFFE8E8E8)));
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
      expect(tokens.warning.shade500, equals(const Color(0xFFEF6C00))); // warningOrange 500
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
      expect(modified.sf1, equals(original.sf1));
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

    test('aiAccent defaults to the raw Layrz accent light blue', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.aiAccent, equals(const Color(0xFF03A9F4)));
    });

    test('aiAccent survives copyWith for other fields', () {
      final original = LayrzColorTokens.light();
      final modified = original.copyWith(primary: const Color(0xFF123456));
      expect(modified.aiAccent, equals(original.aiAccent));
    });

    test('copyWith replaces aiAccent independently', () {
      final original = LayrzColorTokens.light();
      final modified = original.copyWith(aiAccent: const Color(0xFF00FF00));

      expect(modified.aiAccent, equals(const Color(0xFF00FF00)));
      expect(original.aiAccent, equals(const Color(0xFF03A9F4))); // original unchanged
    });

    test('equality accounts for aiAccent', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light().copyWith(aiAccent: const Color(0xFF00FF00));
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode differs when aiAccent differs', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light().copyWith(aiAccent: const Color(0xFF00FF00));
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('selectionColor defaults to LayrzColors.lightBlue', () {
      final tokens = LayrzColorTokens.light();
      expect(tokens.selectionColor, isA<LayrzColorSwatch>());
      expect(tokens.selectionColor, equals(LayrzColors.lightBlue));
      expect(tokens.selectionColor.shade500, equals(const Color(0xFF03A9F4)));
      expect(tokens.selectionColor.shade100, equals(const Color(0xFFB3E5FC)));
    });

    test('selectionColor survives copyWith for other fields', () {
      final original = LayrzColorTokens.light();
      final modified = original.copyWith(primary: const Color(0xFF123456));
      expect(modified.selectionColor, equals(original.selectionColor));
    });

    test('copyWith replaces selectionColor independently, coercing a plain Color into a swatch', () {
      final original = LayrzColorTokens.light();
      final modified = original.copyWith(selectionColor: const Color(0xFF00FF00));

      expect(modified.selectionColor, isA<LayrzColorSwatch>());
      // Mirrors the coercion fallback shared by every other swatch field
      // (danger/success/warning/info/contextual): a plain Color is wrapped
      // with only its 50 shade populated, not a full ramp.
      expect(modified.selectionColor.shade50, equals(const Color(0xFF00FF00)));
      expect(original.selectionColor, equals(LayrzColors.lightBlue)); // original unchanged
    });

    test('copyWith accepts a full LayrzColorSwatch for selectionColor unchanged', () {
      final original = LayrzColorTokens.light();
      final modified = original.copyWith(selectionColor: LayrzColors.blue);

      expect(modified.selectionColor, equals(LayrzColors.blue));
      expect(modified.selectionColor.shade100, equals(LayrzColors.blue.shade100));
    });

    test('equality accounts for selectionColor', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light().copyWith(selectionColor: const Color(0xFF00FF00));
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode differs when selectionColor differs', () {
      final tokens1 = LayrzColorTokens.light();
      final tokens2 = LayrzColorTokens.light().copyWith(selectionColor: const Color(0xFF00FF00));
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });
  });
}
