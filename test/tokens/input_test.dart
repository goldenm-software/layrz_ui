import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzInputColorTokens', () {
    test('light factory exposes the light placeholder values', () {
      const t = LayrzInputColorTokens.light();

      expect(t.idle, const Color(0xFFF7F7F7));
      expect(t.focused, const Color(0xFFF7F7F7));
      expect(t.disabled, const Color(0xFFF7F7F7));
      expect(t.error, const Color(0xFFFFEBEE));
      expect(t.hoverOverlay, const Color(0x0A000000));
      expect(t.pressedOverlay, const Color(0x14000000));
    });

    test('dark factory exposes the dark placeholder values', () {
      const t = LayrzInputColorTokens.dark();

      expect(t.idle, const Color(0xFF322F35));
      expect(t.focused, const Color(0xFF322F35));
      expect(t.disabled, const Color(0xFF322F35));
      expect(t.error, const Color(0xFF513235));
      expect(t.hoverOverlay, const Color(0x0FFFFFFF));
      expect(t.pressedOverlay, const Color(0x1AFFFFFF));
    });

    test('dark error equals danger at 16% over the dark surface', () {
      final tokens = LayrzTokens.dark();
      final derived = Color.alphaBlend(tokens.colors.danger.withValues(alpha: 0.16), tokens.colors.sf2);

      expect(tokens.input.error.toARGB32(), derived.toARGB32());
    });

    test('copyWith replaces only the given fields', () {
      const base = LayrzInputColorTokens.light();
      final copy = base.copyWith(idle: const Color(0xFF111111), pressedOverlay: const Color(0x22000000));

      expect(copy.idle, const Color(0xFF111111));
      expect(copy.pressedOverlay, const Color(0x22000000));
      expect(copy.focused, base.focused);
      expect(copy.disabled, base.disabled);
      expect(copy.error, base.error);
      expect(copy.hoverOverlay, base.hoverOverlay);
    });

    test('copyWith with no arguments equals the original', () {
      const base = LayrzInputColorTokens.dark();

      expect(base.copyWith(), base);
    });

    test('copyWith replaces every field individually', () {
      const base = LayrzInputColorTokens.light();
      const c = Color(0xFF123456);

      expect(base.copyWith(focused: c).focused, c);
      expect(base.copyWith(disabled: c).disabled, c);
      expect(base.copyWith(error: c).error, c);
      expect(base.copyWith(hoverOverlay: c).hoverOverlay, c);
    });

    test('equality and hashCode follow field values', () {
      const a = LayrzInputColorTokens.light();
      const b = LayrzInputColorTokens.light();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const LayrzInputColorTokens.dark(), isFalse);
      expect(a == a.copyWith(error: const Color(0xFF000000)), isFalse);
    });
  });
}
