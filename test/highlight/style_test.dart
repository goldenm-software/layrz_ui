import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

void main() {
  group('LayrzHighlightStyle', () {
    test('defaults bold and italic to false', () {
      const style = LayrzHighlightStyle(color: Color(0xFF112233));
      expect(style.bold, isFalse);
      expect(style.italic, isFalse);
    });

    test('== and hashCode are structural', () {
      const a = LayrzHighlightStyle(color: Color(0xFF000000), bold: true);
      const b = LayrzHighlightStyle(color: Color(0xFF000000), bold: true);
      const c = LayrzHighlightStyle(color: Color(0xFF000000), italic: true);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzHighlightStyle(color: Color(0xFFAABBCC), bold: false, italic: false);
      final copy = original.copyWith(bold: true);

      expect(copy.color, const Color(0xFFAABBCC));
      expect(copy.bold, isTrue);
      expect(copy.italic, isFalse);
    });

    test('copyWith with no arguments returns an equal style', () {
      const original = LayrzHighlightStyle(color: Color(0xFF445566), italic: true);
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('toString includes color, bold, and italic', () {
      const style = LayrzHighlightStyle(color: Color(0xFF010203), bold: true, italic: true);
      final text = style.toString();
      expect(text, contains('bold: true'));
      expect(text, contains('italic: true'));
    });
  });
}
