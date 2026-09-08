import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/search/src/find_highlight_painter.dart';
import 'package:layrz_ui/src/search/src/word_highlight_resolver.dart';

void main() {
  group('FindHighlightPainter', () {
    const currentColor = Color(0x8000FF00);
    const otherColor = Color(0x800000FF);

    test('shouldRepaint is false for an equivalent (non-identical) highlight list', () {
      const highlights = [
        MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true),
      ];

      final oldPainter = FindHighlightPainter(
        highlights: List.of(highlights),
        currentIndex: 0,
        currentColor: currentColor,
        otherColor: otherColor,
      );
      final newPainter = FindHighlightPainter(
        highlights: List.of(highlights),
        currentIndex: 0,
        currentColor: currentColor,
        otherColor: otherColor,
      );

      expect(newPainter.shouldRepaint(oldPainter), isFalse);
    });

    test('shouldRepaint is true when the highlight list length changes', () {
      final oldPainter = FindHighlightPainter(
        highlights: const [
          MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true),
        ],
        currentIndex: 0,
        currentColor: currentColor,
        otherColor: otherColor,
      );
      final newPainter = FindHighlightPainter(
        highlights: const [],
        currentIndex: -1,
        currentColor: currentColor,
        otherColor: otherColor,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint is true when currentIndex changes', () {
      const highlights = [
        MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true),
        MatchHighlight(rects: [Rect.fromLTWH(20, 0, 10, 10)], isWordLevel: true),
      ];

      final oldPainter = FindHighlightPainter(
        highlights: highlights,
        currentIndex: 0,
        currentColor: currentColor,
        otherColor: otherColor,
      );
      final newPainter = FindHighlightPainter(
        highlights: highlights,
        currentIndex: 1,
        currentColor: currentColor,
        otherColor: otherColor,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint is true when a color changes', () {
      const highlights = [
        MatchHighlight(rects: [Rect.fromLTWH(0, 0, 10, 10)], isWordLevel: true),
      ];

      final oldPainter = FindHighlightPainter(
        highlights: highlights,
        currentIndex: 0,
        currentColor: currentColor,
        otherColor: otherColor,
      );
      final newPainter = FindHighlightPainter(
        highlights: highlights,
        currentIndex: 0,
        currentColor: const Color(0xFFFF0000),
        otherColor: otherColor,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    testWidgets('paints without error for a multi-box (word-wrap) highlight', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomPaint(
            painter: FindHighlightPainter(
              highlights: const [
                MatchHighlight(
                  rects: [Rect.fromLTWH(180, 0, 20, 20), Rect.fromLTWH(0, 20, 20, 20)],
                  isWordLevel: true,
                ),
                MatchHighlight(rects: [Rect.fromLTWH(0, 60, 40, 20)], isWordLevel: false),
              ],
              currentIndex: 0,
              currentColor: currentColor,
              otherColor: otherColor,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
